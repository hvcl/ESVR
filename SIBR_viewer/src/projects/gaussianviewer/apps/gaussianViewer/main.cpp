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

#include <core/graphics/Window.hpp>
#include <core/view/MultiViewManager.hpp>
#include <core/system/String.hpp>
#include "projects/gaussianviewer/renderer/GaussianView.hpp" 

#include <algorithm>
#include <boost/filesystem.hpp>
#include <regex>
#include <imgui/imgui_internal.h>

namespace fs = boost::filesystem;

std::string findLargestNumberedSubdirectory(const std::string& directoryPath) {
	fs::path dirPath(directoryPath);
	if (!fs::exists(dirPath) || !fs::is_directory(dirPath)) {
		std::cerr << "Invalid directory: " << directoryPath << std::endl;
		return "";
	}

	std::regex regexPattern(R"_(iteration_(\d+))_");
	std::string largestSubdirectory;
	int largestNumber = -1;

	for (const auto& entry : fs::directory_iterator(dirPath)) {
		if (fs::is_directory(entry)) {
			std::string subdirectory = entry.path().filename().string();
			std::smatch match;

			if (std::regex_match(subdirectory, match, regexPattern)) {
				int number = std::stoi(match[1]);

				if (number > largestNumber) {
					largestNumber = number;
					largestSubdirectory = subdirectory;
				}
			}
		}
	}

	return largestSubdirectory;
}


#define PROGRAM_NAME "sibr_3Dgaussian"
using namespace sibr;

static void* User_ReadOpen(ImGuiContext*, ImGuiSettingsHandler*, const char* name)
{
	return (void*)0x1;
}

static void User_ReadLine(ImGuiContext*, ImGuiSettingsHandler* handler, void*, const char* line)
{
	int i;
	if (sscanf(line, "DontShow=%d", &i) == 1)
		if (i)
		{
			*((bool*)handler->UserData) = true;
			return;
		}
	*((bool*)handler->UserData) = false;
}

static void User_WriteAll(ImGuiContext* imgui_ctx, ImGuiSettingsHandler* handler, ImGuiTextBuffer* buf)
{
	// Write a buffer
	// If a window wasn't opened in this session we preserve its settings
	buf->reserve(buf->size() + 96); // ballpark reserve
	buf->appendf("[UserData][UserData]\nDontShow=%d\n", *((bool*)handler->UserData) ? 1 : 0);
	buf->appendf("\n");
}

int main(int ac, char** av) 
{
	// Parse Command-line Args
	CommandLineArgs::parseMainArgs(ac, av);
	GaussianAppArgs myArgs;
	myArgs.displayHelpIfRequired();
	
	if(!myArgs.modelPath.isInit() && myArgs.modelPathShort.isInit())
		myArgs.modelPath = myArgs.modelPathShort.get();
	int device = myArgs.device;

	// rendering size
	uint rendering_width = myArgs.rendering_size.get()[0];
	uint rendering_height = myArgs.rendering_size.get()[1];
	rendering_width = rendering_width > 0 ? rendering_width : 800U;
	rendering_height = rendering_height > 0 ? rendering_height : 800U;
	
	// Window setup
	sibr::Window		window(PROGRAM_NAME, sibr::Vector2i(50, 50), myArgs, getResourcesDirectory() + "/gaussians/" + PROGRAM_NAME + ".ini");

	bool messageRead = false;
	ImGuiSettingsHandler ini_handler;
	ini_handler.TypeName = "UserData";
	ini_handler.UserData = &messageRead;
	ini_handler.TypeHash = ImHash("UserData", 0, 0);
	ini_handler.ReadOpenFn = User_ReadOpen;
	ini_handler.ReadLineFn = User_ReadLine;
	ini_handler.WriteAllFn = User_WriteAll;
	ImGui::GetCurrentContext()->SettingsHandlers.push_back(ini_handler);
	window.loadSettings();

	BasicIBRScene::Ptr scene(new BasicIBRScene());

	std::string plyfile = myArgs.modelPath.get();
	if (plyfile.back() != '/')
		plyfile += "/";
	plyfile += "point_cloud";
	if (!myArgs.iteration.isInit())
	{
		plyfile += "/" + findLargestNumberedSubdirectory(plyfile) + "/point_cloud.ply";
	}
	else
	{
		plyfile += "/iteration_" + myArgs.iteration.get() + "/point_cloud.ply";
	}
	
	// This viewer is independent from cameras.json. Use one deterministic startup view.
	Vector2u usedResolution(rendering_width, rendering_height);

	const unsigned int sceneResWidth = usedResolution.x();
	const unsigned int sceneResHeight = usedResolution.y();
	// Match the former cameras.json[0] exactly, without reading cameras.json.
	// The custom Gaussian rasterizer uses the orthographic scale (orthoRight),
	// so replacing this with a perspective camera makes the projection and
	// covariance computations inconsistent.
	InputCamera::Ptr startupInputCamera = std::make_shared<InputCamera>(
		true,
		sceneResWidth,
		sceneResHeight,
		0,
		695.99998463f,
		695.99998463f,
		0.0f,
		0.0f
	);
	startupInputCamera->name("fixed_camera");
	startupInputCamera->position(Vector3f(0.0f, 0.0f, -10.0f));
	Matrix3f startupOrientation = Matrix3f::Identity();
	startupOrientation.col(1) = -startupOrientation.col(1);
	startupOrientation.col(2) = -startupOrientation.col(2);
	startupInputCamera->rotation(Quaternionf(startupOrientation));
	startupInputCamera->znear(0.01f);
	startupInputCamera->zfar(1000.0f);
	startupInputCamera->orthoTop(1.0f);
	startupInputCamera->orthoRight(1.0f);
	std::vector<InputCamera::Ptr> startupCameras{ startupInputCamera };
	scene->cameras()->setupCamerasFromExisting(startupCameras);

	// Camera handler for main view.
	sibr::InteractiveCameraHandler::Ptr generalCamera(new InteractiveCameraHandler(false));
	generalCamera->setup(startupCameras, Viewport(0, 0, (float)usedResolution.x(), (float)usedResolution.y()), nullptr);
	generalCamera->setTrackballCenter(Vector3f(0.0f, 0.0f, 0.0f));
	generalCamera->setTrackballOnly();

	// Create the Gaussian view and let it host the trackball controls in its unified panel.
	GaussianView::Ptr gaussianView(new GaussianView(
		scene, sceneResWidth, sceneResHeight, plyfile, generalCamera,
		&messageRead, !myArgs.noInterop, device));

	// Add views to mvm.
	MultiViewManager        multiViewManager(window, false);

	if (myArgs.rendering_mode == 1) 
		multiViewManager.renderingMode(IRenderingMode::Ptr(new StereoAnaglyphRdrMode()));
	
	multiViewManager.addIBRSubView("Point view", gaussianView, usedResolution, ImGuiWindowFlags_ResizeFromAnySide | ImGuiWindowFlags_NoBringToFrontOnFocus);
	multiViewManager.addCameraForView("Point view", generalCamera);

	// Main looooooop.
	while (window.isOpened()) 
	{
		sibr::Input::poll();
		window.makeContextCurrent();
		if (sibr::Input::global().key().isPressed(sibr::Key::Escape)) {
			window.close();
		}

		multiViewManager.onUpdate(sibr::Input::global());
		multiViewManager.onRender(window);

		window.swapBuffer();
		CHECK_GL_ERROR;
	}

	return EXIT_SUCCESS;
}
