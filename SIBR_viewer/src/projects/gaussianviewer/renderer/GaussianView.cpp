/*
 * Copyright (C) 2023, Inria
 * GRAPHDECO research group, https://team.inria.fr/graphdeco
 * All rights reserved.
 *
 * This software is free for non-commercial, research and evaluation use 
 * under the terms of the LICENSE.md file.
 *
 * For inquiries contact sibr@inria.fr and/or George.Drettakis@inria.fr
 */

#include <projects/gaussianviewer/renderer/GaussianView.hpp>
#include <core/graphics/GUI.hpp>
#include <core/view/InteractiveCameraHandler.hpp>
#include <rasterizer.h>
#include <cuda_rasterizer/config.h>
#include <imgui_internal.h>
#include "tfeditorGUI.h"


// Define the types and sizes that make up the contents of each Gaussian 
// in the trained model.
typedef sibr::Vector3f Pos;
struct Scale
{
	float scale[3];
};
struct Rot
{
	float rot[4];
};

struct RichPoint
{
	Pos pos;
	float opacity;
	Scale scale;
	Rot rot;
};

float sigmoid(const float m1)
{
	return 1.0f / (1.0f + exp(-m1));
}

float inverse_sigmoid(const float m1)
{
	return log(m1 / (1.0f - m1));
}
static size_t g_fpsGpuPeakBytes = 0;

static inline double bytesToGB(const size_t bytes)
{
	return static_cast<double>(bytes) / (1024.0 * 1024.0 * 1024.0);
}

static void resetFpsGpuPeak()
{
	g_fpsGpuPeakBytes = 0;
}

static void updateFpsGpuPeak()
{
	size_t free_mem = 0;
	size_t total_mem = 0;
	if (cudaMemGetInfo(&free_mem, &total_mem) == cudaSuccess)
	{
		const size_t used_mem = total_mem - free_mem;
		g_fpsGpuPeakBytes = std::max(g_fpsGpuPeakBytes, used_mem);
	}
}

# define CUDA_SAFE_CALL_ALWAYS(A) \
A; \
cudaDeviceSynchronize(); \
if (cudaPeekAtLastError() != cudaSuccess) \
SIBR_ERR << cudaGetErrorString(cudaGetLastError());

#if DEBUG || _DEBUG
# define CUDA_SAFE_CALL(A) CUDA_SAFE_CALL_ALWAYS(A)
#else
# define CUDA_SAFE_CALL(A) A
#endif

// Load the Gaussians from the given file.
int loadPly(const char* filename,
	std::vector<Pos>& pos,
	std::vector<float>& opacities,
	std::vector<Scale>& scales,
	std::vector<Rot>& rot,
	sibr::Vector3f& minn,
	sibr::Vector3f& maxx)
{
	std::ifstream infile(filename, std::ios_base::binary);

	if (!infile.good())
		SIBR_ERR << "Unable to find model's PLY file, attempted:\n" << filename << std::endl;

	// "Parse" header (it has to be a specific format anyway)
	std::string buff;
	std::getline(infile, buff);
	std::getline(infile, buff);

	std::string dummy;
	std::getline(infile, buff);
	std::stringstream ss(buff);
	int count;
	ss >> dummy >> dummy >> count;

	// Output number of Gaussians contained
	SIBR_LOG << "Loading " << count << " Gaussian splats" << std::endl;

	while (std::getline(infile, buff))
		if (buff.compare("end_header") == 0)
			break;

	// Read all Gaussians at once (AoS)
	std::vector<RichPoint> points(count);
	//infile.read((char*)points.data(), count * sizeof(RichPoint));

    for (size_t i = 0; i < count; ++i) {
        // Read position
        infile.read(reinterpret_cast<char*>(&points[i].pos), sizeof(Pos));

        // Read opacity
        infile.read(reinterpret_cast<char*>(&points[i].opacity), sizeof(float));

        // Read scale
        infile.read(reinterpret_cast<char*>(&points[i].scale), sizeof(Scale));

        // Read rotation
        infile.read(reinterpret_cast<char*>(&points[i].rot), sizeof(Rot));

    }
	
	// Resize our SoA data
	pos.resize(count);
	scales.resize(count);
	rot.resize(count);
	opacities.resize(count);

	// Gaussians are done training, they won't move anymore. Arrange
	// them according to 3D Morton order. This means better cache
	// behavior for reading Gaussians that end up in the same tile 
	// (close in 3D --> close in 2D).
	minn = sibr::Vector3f(FLT_MAX, FLT_MAX, FLT_MAX);
	maxx = -minn;
	for (int i = 0; i < count; i++)
	{
		maxx = maxx.cwiseMax(points[i].pos);
		minn = minn.cwiseMin(points[i].pos);
	}
	std::vector<std::pair<uint64_t, int>> mapp(count);
	for (int i = 0; i < count; i++)
	{
		sibr::Vector3f rel = (points[i].pos - minn).array() / (maxx - minn).array();
		sibr::Vector3f scaled = ((float((1 << 21) - 1)) * rel);
		sibr::Vector3i xyz = scaled.cast<int>();

		uint64_t code = 0;
		for (int i = 0; i < 21; i++) {
			code |= ((uint64_t(xyz.x() & (1 << i))) << (2 * i + 0));
			code |= ((uint64_t(xyz.y() & (1 << i))) << (2 * i + 1));
			code |= ((uint64_t(xyz.z() & (1 << i))) << (2 * i + 2));
		}

		mapp[i].first = code;
		mapp[i].second = i;
	}
	auto sorter = [](const std::pair < uint64_t, int>& a, const std::pair < uint64_t, int>& b) {
		return a.first < b.first;
	};
	std::sort(mapp.begin(), mapp.end(), sorter);
	std::vector<unsigned char> data8(count);

	std::vector<float> temp_scale;
	temp_scale.resize(count);
	

	// Move data from AoS to SoA
	for (int k = 0; k < count; k++)
	{
		int i = mapp[k].second;
		pos[k] = points[i].pos;

		// Normalize quaternion
		float length2 = 0;
		for (int j = 0; j < 4; j++)
			length2 += points[i].rot.rot[j] * points[i].rot.rot[j];
		float length = sqrt(length2);
		for (int j = 0; j < 4; j++)
			rot[k].rot[j] = points[i].rot.rot[j] / length;

		// PLY stores Gaussian scales in log space. This conversion is part of
		// the splat data path and is unrelated to spherical harmonics.
		for (int j = 0; j < 3; ++j)
			scales[k].scale[j] = std::exp(points[i].scale.scale[j]);

		opacities[k] = sigmoid(points[i].opacity);	// Activate alpha
		temp_scale[k] = scales[k].scale[0];

		data8[k] = static_cast<unsigned char>(opacities[k]  * 255);

	}

 	auto max_iter = std::max_element(opacities.begin(), opacities.end());
    auto min_iter = std::min_element(opacities.begin(), opacities.end());

    float max_value = *max_iter;
    float min_value = *min_iter;


    // Print opacity range
	SIBR_LOG << "Opacity range: " << min_value << " (logit " << inverse_sigmoid(min_value)
		<< ") to " << max_value << " (logit " << inverse_sigmoid(max_value) << ")" << std::endl;

	// Print position range
	SIBR_LOG << "Position range: min " << minn.transpose() << ", max " << maxx.transpose() << std::endl;
	

	auto max_iter1 = std::max_element(temp_scale.begin(), temp_scale.end());
    auto min_iter1 = std::min_element(temp_scale.begin(), temp_scale.end());
    float max_value1 = *max_iter1;
    float min_value1 = *min_iter1;

    // Print scale range
	SIBR_LOG << "Scale range: " << min_value1 << " to " << max_value1
		<< " (log range " << log(min_value1) << " to " << log(max_value1) << ")" << std::endl;

	// Compute histogram
	int histo[256] = { 0 };
	
	for (int i = 0; i < count; i++) {
		int index = (int)data8[i];
		if (index >= 0 && index < 256) {
			histo[index]++;
		}
	}

	// Save histogram to a file
	FILE* histogram;
	fopen_s(&histogram, "histogram.txt", "w");
	for (int j = 0; j < 256; j++) {
		fprintf(histogram, "%f\n", float(histo[j]) / count);
	}
	fclose(histogram);

	SIBR_LOG << "Histogram saved to histogram.txt" << std::endl;
	return count;
}



void savePly(const char* filename,
	const std::vector<Pos>& pos,
	const std::vector<float>& opacities,
	const std::vector<Scale>& scales,
	const std::vector<Rot>& rot)
{
	// Read all Gaussians at once (AoS)
	int count = 3;
	std::vector<RichPoint> points(count);

	// Output number of Gaussians contained
	SIBR_LOG << "Saving " << count << " Gaussian splats" << std::endl;

	std::ofstream outfile(filename, std::ios_base::binary);

	outfile << "ply\nformat binary_little_endian 1.0\nelement vertex " << count << "\n";

	std::string props1[] = { "x", "y", "z" };
	std::string props2[] = { "opacity", "scale_0", "scale_1", "scale_2", "rot_0", "rot_1", "rot_2", "rot_3" };

	for (auto s : props1)
		outfile << "property float " << s << std::endl;
	for (auto s : props2)
		outfile << "property float " << s << std::endl;
	outfile << "end_header" << std::endl;

	count = 0;
	for (int i = 0; i < pos.size(); i++)
	{
		points[count].pos = pos[i];
		points[count].rot = rot[i];
		// Exponentiate scale
		for (int j = 0; j < 3; j++)
			points[count].scale.scale[j] = log(scales[i].scale[j]);
		// Activate alpha
		points[count].opacity = inverse_sigmoid(opacities[i]);
		count++;
	}
	outfile.write((char*)points.data(), sizeof(RichPoint) * points.size());
}



namespace sibr
{
	// A simple copy renderer class. Much like the original, but this one
	// reads from a buffer instead of a texture and blits the result to
	// a render target. 
	class BufferCopyRenderer
	{

	public:

		BufferCopyRenderer()
		{
			_shader.init("CopyShader",
				sibr::loadFile(sibr::getShadersDirectory("gaussian") + "/copy.vert"),
				sibr::loadFile(sibr::getShadersDirectory("gaussian") + "/copy.frag"));

			_flip.init(_shader, "flip");
			_width.init(_shader, "width");
			_height.init(_shader, "height");
		}

		void process(uint bufferID, IRenderTarget& dst, int width, int height, bool disableTest = true)
		{
			if (disableTest)
				glDisable(GL_DEPTH_TEST);
			else
				glEnable(GL_DEPTH_TEST);

			_shader.begin();
			_flip.send();
			_width.send();
			_height.send();

			dst.clear();
			dst.bind();

			glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, bufferID);

			sibr::RenderUtility::renderScreenQuad();

			dst.unbind();
			_shader.end();
		}

		/** \return option to flip the texture when copying. */
		bool& flip() { return _flip.get(); }
		int& width() { return _width.get(); }
		int& height() { return _height.get(); }

	private:

		GLShader			_shader; 
		GLuniform<bool>		_flip = false; ///< Flip the texture when copying.
		GLuniform<int>		_width = 1000;
		GLuniform<int>		_height = 800;

	};
}

std::function<char* (size_t N)> resizeFunctional(void** ptr, size_t& S) {
	auto lambda = [ptr, &S](size_t N) {
		if (N > S)
		{
			if (*ptr)
				CUDA_SAFE_CALL(cudaFree(*ptr));
			CUDA_SAFE_CALL(cudaMalloc(ptr, 2 * N));
			S = 2 * N;
		}
		return reinterpret_cast<char*>(*ptr);
	};
	return lambda;
}

sibr::GaussianView::GaussianView(const sibr::BasicIBRScene::Ptr & ibrScene, uint render_w, uint render_h, const std::string& ply_file,
	const std::shared_ptr<InteractiveCameraHandler>& cameraHandler, bool* messageRead, bool useInterop, int device) :
	_scene(ibrScene),
	_cameraHandler(cameraHandler),
	_dontshow(messageRead),
	sibr::ViewBase(render_w, render_h)
{
	int num_devices;
	CUDA_SAFE_CALL_ALWAYS(cudaGetDeviceCount(&num_devices));
	_device = device;
	if (device >= num_devices)
	{
		if (num_devices == 0)
			SIBR_ERR << "No CUDA devices detected!";
		else
			SIBR_ERR << "Provided device index exceeds number of available CUDA devices!";
	}
	CUDA_SAFE_CALL_ALWAYS(cudaSetDevice(device));
	cudaDeviceProp prop;
	CUDA_SAFE_CALL_ALWAYS(cudaGetDeviceProperties(&prop, device));
	if (prop.major < 7)
	{
		SIBR_ERR << "Sorry, need at least compute capability 7.0+!";
	}

	_copyRenderer = new BufferCopyRenderer();
	_copyRenderer->flip() = true;
	_copyRenderer->width() = render_w;
	_copyRenderer->height() = render_h;

	std::vector<uint> imgs_ulr;
	const auto & cams = ibrScene->cameras()->inputCameras();
	for(size_t cid = 0; cid < cams.size(); ++cid) {
		if(cams[cid]->isActive()) {
			imgs_ulr.push_back(uint(cid));
		}
	}
	_scene->cameras()->debugFlagCameraAsUsed(imgs_ulr);
	init_transferFunction();
	//findLowPoints();
	
	// Load the PLY data (AoS) to the GPU (SoA)
	std::vector<Pos> pos;
	std::vector<Rot> rot;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
	std::vector<Scale> scale;
	std::vector<float> opacity;
	
	const char* file = ply_file.c_str();
	count = loadPly(file, pos, opacity, scale, rot, _scenemin, _scenemax);

	_boxmin = _scenemin;
	_boxmax = _scenemax;

	int P = count;
	
	// Allocate GPU memory
	CUDA_SAFE_CALL_ALWAYS(cudaMalloc((void**)&pos_cuda, sizeof(Pos) * P));
	CUDA_SAFE_CALL_ALWAYS(cudaMemcpy(pos_cuda, pos.data(), sizeof(Pos) * P, cudaMemcpyHostToDevice));
	
	CUDA_SAFE_CALL_ALWAYS(cudaMalloc((void**)&rot_cuda, sizeof(Rot) * P));
	CUDA_SAFE_CALL_ALWAYS(cudaMemcpy(rot_cuda, rot.data(), sizeof(Rot) * P, cudaMemcpyHostToDevice));
	
	CUDA_SAFE_CALL_ALWAYS(cudaMalloc((void**)&opacity_cuda, sizeof(float) * P));
	CUDA_SAFE_CALL_ALWAYS(cudaMemcpy(opacity_cuda, opacity.data(), sizeof(float) * P, cudaMemcpyHostToDevice));
	
	CUDA_SAFE_CALL_ALWAYS(cudaMalloc((void**)&scale_cuda, sizeof(Scale) * P));
	CUDA_SAFE_CALL_ALWAYS(cudaMemcpy(scale_cuda, scale.data(), sizeof(Scale) * P, cudaMemcpyHostToDevice));
	
	SIBR_LOG << "Allocated " << ((sizeof(Pos) + sizeof(Rot) + sizeof(float) + sizeof(Scale)) * P / (1024*1024)) << " MB for " << P << " Gaussians" << std::endl;
	CUDA_SAFE_CALL_ALWAYS(cudaMalloc((void**)&transferFunction_cuda, sizeof(transferFunction)));
	CUDA_SAFE_CALL_ALWAYS(cudaMemcpy(transferFunction_cuda, transferFunction, sizeof(transferFunction), cudaMemcpyHostToDevice));

	// Create space for view parameters
	CUDA_SAFE_CALL_ALWAYS(cudaMalloc((void**)&view_cuda, sizeof(sibr::Matrix4f)));
	CUDA_SAFE_CALL_ALWAYS(cudaMalloc((void**)&proj_cuda, sizeof(sibr::Matrix4f)));
	CUDA_SAFE_CALL_ALWAYS(cudaMalloc((void**)&rect_cuda, 2 * count * sizeof(int)));

	partial_rgb_global = nullptr;
	partial_T_global = nullptr;
	const int depth_bins = DVR_DEPTH_BINS;
	size_t rgb_size = depth_bins * 3 * 800 * 800 * sizeof(float);
	size_t T_size   = depth_bins * 800 * 800 * sizeof(float);

	CUDA_SAFE_CALL_ALWAYS(cudaMalloc(&partial_rgb_global, rgb_size));
	CUDA_SAFE_CALL_ALWAYS(cudaMalloc(&partial_T_global, T_size));
	CUDA_SAFE_CALL_ALWAYS(cudaMemset(partial_rgb_global, 0, rgb_size));
	CUDA_SAFE_CALL_ALWAYS(cudaMemset(partial_T_global, 0, T_size));


	// Create GL buffer ready for CUDA/GL interop
	glCreateBuffers(1, &imageBuffer);
	glNamedBufferStorage(imageBuffer, render_w * render_h * 3 * sizeof(float), nullptr, GL_DYNAMIC_STORAGE_BIT);

	if (useInterop)
	{
		if (cudaPeekAtLastError() != cudaSuccess)
		{
			SIBR_ERR << "A CUDA error occurred in setup:" << cudaGetErrorString(cudaGetLastError()) << ". Please rerun in Debug to find the exact line!";
		}
		cudaGraphicsGLRegisterBuffer(&imageBufferCuda, imageBuffer, cudaGraphicsRegisterFlagsWriteDiscard);
		useInterop &= (cudaGetLastError() == cudaSuccess);
	}
	if (!useInterop)
	{
		fallback_bytes.resize(render_w * render_h * 4 * sizeof(float));
		cudaMalloc(&fallbackBufferCuda, fallback_bytes.size());
		_interop_failed = true;
	}

	geomBufferFunc = resizeFunctional(&geomPtr, allocdGeom);
	binningBufferFunc = resizeFunctional(&binningPtr, allocdBinning);
	imgBufferFunc = resizeFunctional(&imgPtr, allocdImg);
}

void sibr::GaussianView::setScene(const sibr::BasicIBRScene::Ptr & newScene)
{
	_scene = newScene;

	// Tell the scene we are a priori using all active cameras.
	std::vector<uint> imgs_ulr;
	const auto & cams = newScene->cameras()->inputCameras();
	for (size_t cid = 0; cid < cams.size(); ++cid) {
		if (cams[cid]->isActive()) {
			imgs_ulr.push_back(uint(cid));
		}
	}
	_scene->cameras()->debugFlagCameraAsUsed(imgs_ulr);
}

void sibr::GaussianView::updateTransferFunction()
{
	CUDA_SAFE_CALL_ALWAYS(cudaMemcpy(transferFunction_cuda, transferFunction, sizeof(transferFunction), cudaMemcpyHostToDevice));
}

void sibr::GaussianView::onRenderIBR(sibr::IRenderTarget & dst, const sibr::Camera & eye)
{
	{
		// Convert view and projection to target coordinate system
		float orthoRight;

		if (measuringFPS || measuringFPS_swap) {
			// Keep projection/intrinsics consistent with the current view at FPS measurement start.
			if (frameCounter == 0) {
				rotatingCam = eye;
			}

			auto view_mat = rotatingCam.view();
			auto proj_mat = rotatingCam.viewproj();
			view_mat.row(1) *= -1;
			view_mat.row(2) *= -1;
			proj_mat.row(1) *= -1;

			// Compute additional view parameters
			// Copy frame-dependent data to GPU
			CUDA_SAFE_CALL(cudaMemcpy(view_cuda, view_mat.data(), sizeof(sibr::Matrix4f), cudaMemcpyHostToDevice));
			CUDA_SAFE_CALL(cudaMemcpy(proj_cuda, proj_mat.data(), sizeof(sibr::Matrix4f), cudaMemcpyHostToDevice));
			if (cameraPos) {
				SIBR_LOG << "curr cam" << eye.position() <<  eye.center() <<  eye.up() << std::endl;
				cameraPos = false;
			}
		} else {
			// Convert view and projection to target coordinate system
			auto view_mat = eye.view();
			auto proj_mat = eye.viewproj(); 
			view_mat.row(1) *= -1;
			view_mat.row(2) *= -1;
			proj_mat.row(1) *= -1;

			// Compute additional view parameters
			// Copy frame-dependent data to GPU
			CUDA_SAFE_CALL(cudaMemcpy(view_cuda, view_mat.data(), sizeof(sibr::Matrix4f), cudaMemcpyHostToDevice));
			CUDA_SAFE_CALL(cudaMemcpy(proj_cuda, proj_mat.data(), sizeof(sibr::Matrix4f), cudaMemcpyHostToDevice));

			if (cameraPos) {
				SIBR_LOG << "curr cam" << eye.position() <<  eye.center() <<  eye.up() << std::endl;
				cameraPos = false;
			}
		}

		float* image_cuda = nullptr;
		if (!_interop_failed)
		{
			// Map OpenGL buffer resource for use with CUDA
			size_t bytes;
			CUDA_SAFE_CALL(cudaGraphicsMapResources(1, &imageBufferCuda));
			CUDA_SAFE_CALL(cudaGraphicsResourceGetMappedPointer((void**)&image_cuda, &bytes, imageBufferCuda));
		}
		else
		{
			image_cuda = fallbackBufferCuda;
		}

		orthoRight = measuringFPS || measuringFPS_swap ? rotatingCam.orthoRight() : eye.orthoRight();

		// Rasterize
		int* rects = _fastCulling ? rect_cuda : nullptr;
		float* boxmin = _cropping ? (float*)&_boxmin : nullptr;
		float* boxmax = _cropping ? (float*)&_boxmax : nullptr;

		const int depth_bins = DVR_DEPTH_BINS;

		size_t rgb_size = depth_bins * 3 * 800 * 800 * sizeof(float);
		size_t T_size   = depth_bins * 800 * 800 * sizeof(float);

		CUDA_SAFE_CALL_ALWAYS(cudaMemset(partial_rgb_global, 0, rgb_size));
		CUDA_SAFE_CALL_ALWAYS(cudaMemset(partial_T_global, 0, T_size));

		CudaRasterizer::Rasterizer::forward(
			geomBufferFunc,
			binningBufferFunc,
			imgBufferFunc,
			count,
			_resolution.x(), _resolution.y(),
			//overlap_cuda,
			pos_cuda,
			opacity_cuda,
			transferFunction_cuda,
			scale_cuda,
			_scalingModifier,
			rot_cuda,
			view_cuda,
			proj_cuda,
			orthoRight,
			std::max(step_size, 0.01f),
			image_cuda,
			partial_rgb_global,
			partial_T_global,
			rects,
			boxmin,
			boxmax
		);


		if (!_interop_failed)
		{
			// Unmap OpenGL resource for use with OpenGL
			CUDA_SAFE_CALL(cudaGraphicsUnmapResources(1, &imageBufferCuda));
		}
		else
		{
			CUDA_SAFE_CALL(cudaMemcpy(fallback_bytes.data(), fallbackBufferCuda, fallback_bytes.size(), cudaMemcpyDeviceToHost));
			glNamedBufferSubData(imageBuffer, 0, fallback_bytes.size(), fallback_bytes.data());
		}
		// Copy image contents to framebuffer
		_copyRenderer->process(imageBuffer, dst, _resolution.x(), _resolution.y());
	}

	if (cudaPeekAtLastError() != cudaSuccess)
	{
		SIBR_ERR << "A CUDA error occurred during rendering:" << cudaGetErrorString(cudaGetLastError()) << ". Please rerun in Debug to find the exact line!";
	}


	
	if (measuringFPS || measuringFPS_swap) {
		auto now = std::chrono::high_resolution_clock::now();
		float currentTime = std::chrono::duration_cast<std::chrono::microseconds>(now - startTime).count() / 1e6f;
		float deltaTime = currentTime - lastFrameTime;
		lastFrameTime = currentTime;

		if ((frameCounter % 100) == 0) {
			updateFpsGpuPeak();
		}

		float fps = (deltaTime > 0.0f) ? 1.0f / deltaTime : 0.0f;

		if (frameCounter >= fpsSampleStart && frameCounter < fpsSampleEnd) {
			fpsSum += fps;
		}
		frameCounter++;

		if (frameCounter == fpsSampleEnd) {
			updateFpsGpuPeak();
			float avgFps = fpsSum / (fpsSampleEnd - fpsSampleStart);
			SIBR_LOG << "Average FPS: " << avgFps << std::endl;
			SIBR_LOG << "Peak GPU memory during FPS run: " << bytesToGB(g_fpsGpuPeakBytes) << " GB" << std::endl;
			measuringFPS = false;
			measuringFPS_swap = false;
		}
	}
}

void sibr::GaussianView::onUpdate(Input& input) {
	if (measuringFPS) {
		static float cameraAngle = 0.0f;
		cameraAngle += 0.5f;  
		if (cameraAngle > 360.0f) cameraAngle = 0.0f;
		
		sibr::Vector3f center(0.0f,0.0f,0.0f);
		float radius = 10.0f;
		float radians = cameraAngle * 3.14159265f / 180.0f;

        float height = 0.0f;
		// float height = 3.0f * std::cos(radians * 0.5f); // Oscillate over half a period.
		
		sibr::Vector3f eye = center + sibr::Vector3f(
			radius * std::cos(radians),
			height,
			radius * std::sin(radians)
		);
		
		// Up vector.
		sibr::Vector3f up(0.0f, 1.0f, 0.0f);
		
		// Apply the rotating camera.
		rotatingCam.setLookAt(eye, center, up);
	}
	if (measuringFPS_swap) {
		static float cameraAngle = 0.0f;
		cameraAngle += 0.5f;
		if (cameraAngle > 360.0f) cameraAngle = 0.0f;

		sibr::Vector3f center(0.0f, 0.0f, 0.0f);
		float radius = 10.0f;

		float radians = cameraAngle * 3.14159265f / 180.0f;

		float height = 0.0f;
		// float height = 3.0f * std::cos(radians * 0.5f);

		// x axis rotation
		sibr::Vector3f eye = center + sibr::Vector3f(
			height,
			radius * std::cos(radians),
			radius * std::sin(radians)
		);
		sibr::Vector3f up(1.0f, 0.0f, 0.0f);

		rotatingCam.setLookAt(eye, center, up);
	}
}


void sibr::GaussianView::onGUI()
{
	if (ImGui::Begin("Gaussian Viewer Controls")) {
		if (_cameraHandler) {
				static bool manualCameraInitialized = false;
				static float manualCameraPos[3] = { 0.0f, 0.0f, 0.0f };
				static float manualCameraFocal[3] = { 0.0f, 0.0f, 0.0f };
				static float manualCameraUp[3] = { 0.0f, 1.0f, 0.0f };
				static float manualCameraOrtho[2] = { 1.0f, 1.0f };
				static char manualCameraFile[512] = "camera_params.txt";

				auto fillFromCurrentCamera = [&]() {
					const InputCamera& camera = _cameraHandler->getCamera();
					const Vector3f pos = camera.position();
					const Vector3f focal = camera.center();
					const Vector3f up = camera.up();
					manualCameraPos[0] = pos.x();
					manualCameraPos[1] = pos.y();
					manualCameraPos[2] = pos.z();
					manualCameraFocal[0] = focal.x();
					manualCameraFocal[1] = focal.y();
					manualCameraFocal[2] = focal.z();
					manualCameraUp[0] = up.x();
					manualCameraUp[1] = up.y();
					manualCameraUp[2] = up.z();
					manualCameraOrtho[0] = camera.orthoRight();
					manualCameraOrtho[1] = camera.orthoTop();
				};

				auto applyManualCamera = [&]() {
					const Vector3f pos(manualCameraPos[0], manualCameraPos[1], manualCameraPos[2]);
					const Vector3f focal(manualCameraFocal[0], manualCameraFocal[1], manualCameraFocal[2]);
					const Vector3f up(manualCameraUp[0], manualCameraUp[1], manualCameraUp[2]);
					if ((pos - focal).norm() < 1e-6f || up.norm() < 1e-6f) {
						SIBR_WRG << "Camera parameters ignored: invalid focal point or up vector." << std::endl;
						return;
					}

					InputCamera camera(_cameraHandler->getCamera());
					camera.setLookAt(pos, focal, up);
					camera.orthoRight(std::max(manualCameraOrtho[0], 1e-6f));
					camera.orthoTop(std::max(manualCameraOrtho[1], 1e-6f));
					_cameraHandler->fromCamera(camera, false, true);
				};

				if (!manualCameraInitialized) {
					fillFromCurrentCamera();
					manualCameraInitialized = true;
				}

				if (ImGui::CollapsingHeader("Set camera from pos/focal/up")) {
					ImGui::Indent();
					ImGui::InputFloat3("Position", manualCameraPos, 6);
					ImGui::InputFloat3("Focal point", manualCameraFocal, 6);
					ImGui::InputFloat3("View up", manualCameraUp, 6);
					ImGui::InputFloat2("Ortho right/top", manualCameraOrtho, 6);
					ImGui::InputText("Camera parameter file", manualCameraFile, 512);

					if (ImGui::Button("Use Current Camera Values")) {
						fillFromCurrentCamera();
					}
					ImGui::SameLine();
					if (ImGui::Button("Set Camera")) {
						applyManualCamera();
					}

					if (ImGui::Button("Save Camera Parameters")) {
						std::ofstream out(manualCameraFile);
						if (out.good()) {
							out << manualCameraPos[0] << " " << manualCameraPos[1] << " " << manualCameraPos[2] << std::endl;
							out << manualCameraFocal[0] << " " << manualCameraFocal[1] << " " << manualCameraFocal[2] << std::endl;
							out << manualCameraUp[0] << " " << manualCameraUp[1] << " " << manualCameraUp[2] << std::endl;
							out << manualCameraOrtho[0] << " " << manualCameraOrtho[1] << std::endl;
						}
						else {
							SIBR_WRG << "Could not save camera parameters to " << manualCameraFile << std::endl;
						}
					}
					ImGui::SameLine();
					if (ImGui::Button("Load Camera Parameters")) {
						std::ifstream in(manualCameraFile);
						if (in >> manualCameraPos[0] >> manualCameraPos[1] >> manualCameraPos[2]
							>> manualCameraFocal[0] >> manualCameraFocal[1] >> manualCameraFocal[2]
							>> manualCameraUp[0] >> manualCameraUp[1] >> manualCameraUp[2]
							>> manualCameraOrtho[0] >> manualCameraOrtho[1]) {
							applyManualCamera();
						}
						else {
							SIBR_WRG << "Could not load camera parameters from " << manualCameraFile << std::endl;
						}
					}
					ImGui::Unindent();
				}
		}

		if (ImGui::CollapsingHeader("Rendering", ImGuiTreeNodeFlags_DefaultOpen)) {
			ImGui::TextUnformatted("Render Mode: Ellipsoids");
			ImGui::SliderFloat("Scaling Modifier", &_scalingModifier, 0.001f, 1.0f);
			if (_cameraHandler) {
				ImGui::Checkbox("Show trackball", &_cameraHandler->getTrackball().drawThis);
			}
			ImGui::Checkbox("Fast culling", &_fastCulling);
			ImGui::Checkbox("Crop Box", &_cropping);

			if (_cropping) {
				ImGui::Indent();
				ImGui::SliderFloat("Box Min X", &_boxmin.x(), _scenemin.x(), _scenemax.x());
				ImGui::SliderFloat("Box Min Y", &_boxmin.y(), _scenemin.y(), _scenemax.y());
				ImGui::SliderFloat("Box Min Z", &_boxmin.z(), _scenemin.z(), _scenemax.z());
				ImGui::SliderFloat("Box Max X", &_boxmax.x(), _scenemin.x(), _scenemax.x());
				ImGui::SliderFloat("Box Max Y", &_boxmax.y(), _scenemin.y(), _scenemax.y());
				ImGui::SliderFloat("Box Max Z", &_boxmax.z(), _scenemin.z(), _scenemax.z());
				ImGui::InputText("Output PLY", _buff, 512);
				if (ImGui::Button("Save Cropped PLY")) {
					std::vector<Pos> pos(count);
					std::vector<Rot> rot(count);
					std::vector<float> opacity(count);
					std::vector<Scale> scale(count);
					CUDA_SAFE_CALL_ALWAYS(cudaMemcpy(pos.data(), pos_cuda, sizeof(Pos) * count, cudaMemcpyDeviceToHost));
					CUDA_SAFE_CALL_ALWAYS(cudaMemcpy(rot.data(), rot_cuda, sizeof(Rot) * count, cudaMemcpyDeviceToHost));
					CUDA_SAFE_CALL_ALWAYS(cudaMemcpy(opacity.data(), opacity_cuda, sizeof(float) * count, cudaMemcpyDeviceToHost));
					CUDA_SAFE_CALL_ALWAYS(cudaMemcpy(scale.data(), scale_cuda, sizeof(Scale) * count, cudaMemcpyDeviceToHost));
					savePly(_buff, pos, opacity, scale, rot);
				}
				ImGui::Unindent();
			}
		}

		if (ImGui::CollapsingHeader("Performance and Debug", ImGuiTreeNodeFlags_DefaultOpen)) {
			ImGui::InputFloat("Sampling Step Size", &step_size, 0.01f, 0.1f, 3);
			step_size = std::max(step_size, 0.01f);

			if (ImGui::Button(measuringFPS ? "Stop FPS Measurement" : "Start FPS Measurement")) {
				measuringFPS = !measuringFPS;
				if (measuringFPS) {
					frameCounter = 0;
					fpsSum = 0.0f;
					cameraAngle = 0.0f;
					resetFpsGpuPeak();
				}
			}
			if (ImGui::Button(measuringFPS_swap ? "Stop FPS Measurement (Swap)" : "Start FPS Measurement (Swap)")) {
				measuringFPS_swap = !measuringFPS_swap;
				if (measuringFPS_swap) {
					frameCounter = 0;
					fpsSum = 0.0f;
					cameraAngle = 0.0f;
					resetFpsGpuPeak();
				}
			}
			if (ImGui::Button("Print Camera Position")) {
				cameraPos = true;
			}
		}
	}
	ImGui::End();

	renderTransferFunctionEditor();

	if (transferFunctionChanged ) { 
		updateTransferFunction();
        transferFunctionChanged = false; 
	}


	if(!*_dontshow && !accepted && _interop_failed)
		ImGui::OpenPopup("Error Using Interop");

	if (!*_dontshow && !accepted && _interop_failed && ImGui::BeginPopupModal("Error Using Interop", NULL, ImGuiWindowFlags_AlwaysAutoResize)) {
		ImGui::SetItemDefaultFocus();
		ImGui::SetWindowFontScale(2.0f);
		ImGui::Text("This application tries to use CUDA/OpenGL interop.\n"\
			" It did NOT work for your current configuration.\n"\
			" For highest performance, OpenGL and CUDA must run on the same\n"\
			" GPU on an OS that supports interop.You can try to pass a\n"\
			" non-zero index via --device on a multi-GPU system, and/or try\n" \
			" attaching the monitors to the main CUDA card.\n"\
			" On a laptop with one integrated and one dedicated GPU, you can try\n"\
			" to set the preferred GPU via your operating system.\n\n"\
			" FALLING BACK TO SLOWER RENDERING WITH CPU ROUNDTRIP\n");

		ImGui::Separator();

		if (ImGui::Button("  OK  ")) {
			ImGui::CloseCurrentPopup();
			accepted = true;
		}
		ImGui::SameLine();
		ImGui::Checkbox("Don't show this message again", _dontshow);
		ImGui::EndPopup();
	}
}

sibr::GaussianView::~GaussianView()
{
	// Cleanup
	cudaFree(pos_cuda);
	cudaFree(rot_cuda);
	cudaFree(scale_cuda);
	cudaFree(opacity_cuda);
	
	cudaFree(transferFunction_cuda);

	cudaFree(view_cuda);
	cudaFree(proj_cuda);
	cudaFree(rect_cuda);


	if (!_interop_failed)
	{
		cudaGraphicsUnregisterResource(imageBufferCuda);
	}
	else
	{
		cudaFree(fallbackBufferCuda);
	}
	glDeleteBuffers(1, &imageBuffer);

	if (geomPtr)
		cudaFree(geomPtr);
	if (binningPtr)
		cudaFree(binningPtr);
	if (imgPtr)
		cudaFree(imgPtr);

	cudaFree(partial_rgb_global);
	cudaFree(partial_T_global);

	delete _copyRenderer;
}
