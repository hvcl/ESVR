#ifndef TFEDITOR_TSNE
#define TFEDITOR_TSNE

#include <vector>
#include <cmath>
#include <algorithm>
#include <imgui.h>
#include <iostream>
#include <fstream>
#include <utility> // for std::pair
#include <cstdlib>      // system() 함수
#include <thread>
#include <atomic>


// 2D Transfer Function Node 구조체
struct Node {
    float x, y;       // 위치 (Intensity, Gradient Magnitude)
    float radius;     // 원의 크기 (반지름)
    float color[3];   // RGB 색상
	float max_opacity;
};

std::atomic<bool> isLoading(false); // TSNE 실행 중 여부

std::vector<Node> nodes; // Transfer Function 노드 저장
std::vector<std::pair<float, float>> normalized_embedding;
bool transferFunctionChanged = false;
std::vector<float> tsne;

const int TF_SIZE = 256 * 256 * 4;  // 각각의 (intensity, gradient) 쌍에 대해 RGBA 값을 저장
float transferFunction[TF_SIZE];    // 2D Transfer Function 배열
int selectedNode = -1;
bool shouldOpenPopup = false;
float selectedRadius = 0.1f;
int tfWidth = 600, tfHeight = 300;
ImDrawList* backgroundDrawList = nullptr;
bool backgroundInitialized = false;
bool initial = false;

template <typename T>
T clamp(T value, T min, T max) {
    return (value < min) ? min : (value > max) ? max : value;
}

bool fileExists(const std::string& filename) {
    std::ifstream file(filename);
    return file.good();
}


bool runPythonScript(const std::string& scriptName, const std::string& args)
{

    const std::string outputFile = "tsne_data.txt";

    // tsne_data.txt가 이미 존재하면 실행하지 않고 true 반환
    if (fileExists(outputFile)) {
        std::cout << "File " << outputFile << " already exists. Skipping script execution." << std::endl;
        return true;
    }

    // 예: "python my_script.py arg1 arg2"
    std::string command = "python " + scriptName + " " + args;
    int ret = std::system(command.c_str());
    if (ret != 0) {
        std::cerr << "Error running python script. Return code: " << ret << std::endl;
        return false;
    }
    return true;
}

void renderClusterWithAlpha(ImDrawList* drawList, ImVec2 pos, float radius, float color[3], float max_opacity) {
    int num_steps = 10; // 원의 레이어 개수 (더 많을수록 부드러움)
    
    for (int i = 0; i < num_steps; i++) {
        float t = (float)i / (float)(num_steps - 1); // 0 ~ 1 사이의 비율
        float alpha = max_opacity / num_steps;  // 비율이 증가할수록 점점 투명하게
        
        float step_radius = radius * (1.0f - t); // 점점 작아지는 원
        ImU32 color_with_alpha = IM_COL32(color[0] * 255, color[1] * 255, color[2] * 255, alpha * 255);

        // ✅ 내부 채워진 원 (조금 더 투명하게)
        drawList->AddCircleFilled(pos, step_radius, color_with_alpha);

        // ✅ 외곽을 좀 더 투명한 원으로 표현 (Blending 효과 증가)
    }
}


void loadNormalizedData(const std::string& filename) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Error: Could not open file " << filename << std::endl;
        return;
    }

    std::string header;
    std::getline(file, header); // 헤더 건너뛰기

    float x, y;
    char comma; // 입력에서 쉼표를 건너뛰기 위한 변수
    while (file >> x >> comma >> y) {
        normalized_embedding.push_back({x, y});
    }

    file.close();
}

void runTSNEAsync(const std::string& file) {
    isLoading = true;  // 로딩 시작
    std::cout << "[LOG] Running TSNE script..." << std::endl;

    std::string args(file);
    bool success = runPythonScript("run_tsne.py", args);

    if (!success) {
        std::cerr << "[ERROR] TSNE script execution failed!" << std::endl;
    }

    loadNormalizedData("tsne_data.txt");
    isLoading = false;  // 로딩 완료
    std::cout << "[LOG] TSNE completed. Loaded " << normalized_embedding.size() << " points." << std::endl;
}

// **초기화 함수: FA 및 Opacity 데이터 추가**
void init_transferFunction(int count, const char* file) {


	//std::string args(file);

	//bool success = runPythonScript("run_tsne.py", args);
    //if (!success) {
    //    // 스크립트 실행 실패 시 로직(로그 출력, 예외 처리 등)
    //    std::cerr << "Failed to run python script." << std::endl;
    //}

	
	//loadNormalizedData("tsne_data.txt");
	
    //nodes.clear();
    //std::cout << "FA and Opacity data loaded: " << normalized_embedding.size() << " points." << std::endl;
	
	//backgroundInitialized = false;
	
	std::thread tsneThread(runTSNEAsync, std::string(file));
    tsneThread.detach(); // 메인 스레드와 분리하여 백그라운드 실행
	
}

std::vector<float> convertToFloatVector() {
    tsne.reserve(normalized_embedding.size() * 2); // 메모리 미리 할당

    for (const auto& pair : normalized_embedding) {
        tsne.push_back(pair.first);  // x 값 추가
        tsne.push_back(pair.second); // y 값 추가
    }

    return tsne;
}


void renderBackground(ImDrawList* drawList, ImVec2 canvasPos, ImVec2 canvasSize) {
    // Draw background rectangle
    drawList->AddRectFilled(canvasPos, ImVec2(canvasPos.x + canvasSize.x, canvasPos.y + canvasSize.y), IM_COL32(50, 50, 50, 255));
    drawList->AddRect(canvasPos, ImVec2(canvasPos.x + canvasSize.x, canvasPos.y + canvasSize.y), IM_COL32(255, 255, 255, 255));

    // Draw scatter plot
		int length = normalized_embedding.size() / 2000.0f;
    for (int i = 0; i < normalized_embedding.size(); i+=length) {
		auto& point = normalized_embedding[i];
        float normX = clamp(point.first, 0.0f, 600.0f) / 600.0f; // Assuming the values are already normalized
        float normY = clamp(point.second, 0.0f, 600.0f) / 600.0f;

        float x = canvasPos.x + normX * canvasSize.x;
        float y = canvasPos.y + (1.0f - normY) * canvasSize.y;

        drawList->AddCircleFilled(ImVec2(x, y), 1.0f, IM_COL32(150, 150, 150, 100)); // Adjust color and size as needed
    }
}


void Spinner(ImDrawList* draw_list, ImVec2 pos, float radius, int num_segments, float thickness, ImU32 color) {
    float start = (float)ImGui::GetTime() * 4.0f; // 회전 속도
    float end = start + IM_PI * 1.5f; // 반원을 그리는 형태

    for (int i = 0; i < num_segments; i++) {
        float a = start + ((float)i / (float)num_segments) * (end - start);
        float x = pos.x + cosf(a) * radius;
        float y = pos.y + sinf(a) * radius;
        float x2 = pos.x + cosf(a + 0.2f) * radius;
        float y2 = pos.y + sinf(a + 0.2f) * radius;
        draw_list->AddLine(ImVec2(x, y), ImVec2(x2, y2), color, thickness);
    }
}

// **Transfer Function UI 렌더링**
void renderTransferFunctionEditor() {
    ImGui::Begin("2D Transfer Function Editor");

	
	if (isLoading) {
		ImGui::Text("Running t-SNE... Please wait!");
		ImVec2 pos = ImGui::GetCursorScreenPos();
		ImDrawList* draw_list = ImGui::GetWindowDrawList();
		
		// Spinner 호출 (회전하는 원)
		Spinner(draw_list, ImVec2(pos.x + 20, pos.y + 10), 10.0f, 12, 2.0f, IM_COL32(255, 255, 255, 255));
		
		return;
	}

    ImGui::Text("2D Transfer Function");

    ImDrawList* drawList = ImGui::GetWindowDrawList();
    ImVec2 canvasPos = ImGui::GetCursorScreenPos();
    ImVec2 canvasSize = ImVec2(600, 600);
	
	// python script 시작 if 처음이면
	
	// 아니면 아래 
	
	
	
	
	
	

    // **배경을 한 번만 렌더링**
    renderBackground(drawList, canvasPos, canvasSize);

    // 배경 박스
    //drawList->AddRectFilled(canvasPos, ImVec2(canvasPos.x + canvasSize.x, canvasPos.y + canvasSize.y), IM_COL32(50, 50, 50, 255));
    //drawList->AddRect(canvasPos, ImVec2(canvasPos.x + canvasSize.x, canvasPos.y + canvasSize.y), IM_COL32(255, 255, 255, 255));

    // **배경 Scatter Plot 추가 (opacities vs fa_values)**
    //if (!fa_values.empty() && !opacities.empty()) {
    //    for (size_t i = 0; i < 2000; i++) {
    //        float normX = clamp(opacities[i], 0.0f, 1.0f);  // X축 (Opacity)
    //        float normY = clamp(fa_values[i], 0.0f, 1.0f);   // Y축 (FA)
    //
    //        float x = canvasPos.x + normX * canvasSize.x;
    //        float y = canvasPos.y + (1.0f - normY) * canvasSize.y;
	//
    //        drawList->AddCircleFilled(ImVec2(x, y), 2.0f, IM_COL32(150, 150, 150, 100)); // 회색 반투명 점
    //    }
    //}

    // 마우스 입력 감지
    ImGui::InvisibleButton("Canvas", canvasSize);
    bool isHovered = ImGui::IsItemHovered();
    ImVec2 mousePos = ImGui::GetMousePos();

    // 노드 렌더링 (원 형태)
    for (int i = 0; i < nodes.size(); i++) {
        Node& n = nodes[i];
        float x = canvasPos.x + n.x * canvasSize.x;
        float y = canvasPos.y + (1.0f - n.y) * canvasSize.y;

        // 원 그리기 (반지름 적용)
        //drawList->AddCircleFilled(ImVec2(x, y), n.radius * canvasSize.x, IM_COL32(n.color[0] * 255, n.color[1] * 255, n.color[2] * 255, 180));
        //drawList->AddCircle(ImVec2(x, y), n.radius * canvasSize.x, IM_COL32(255, 255, 255, 255), 16, 2.0f);
		renderClusterWithAlpha(drawList, ImVec2(x, y), n.radius * canvasSize.x, n.color, n.max_opacity);


        // 마우스 클릭 감지
        float dx = mousePos.x - x;
        float dy = mousePos.y - y;
        float distance = sqrt(dx * dx + dy * dy);

        // 노드 선택 및 이동
        if (isHovered && ImGui::IsMouseClicked(0) && distance <= n.radius * canvasSize.x) {
            selectedNode = i;
        }
        if (selectedNode == i && ImGui::IsMouseDragging(0) && ImGui::GetIO().KeyCtrl) {
            float normX = (mousePos.x - canvasPos.x) / canvasSize.x;
            float normY = 1.0f - (mousePos.y - canvasPos.y) / canvasSize.y;
            nodes[i].x = clamp(normX, 0.0f, 1.0f);
            nodes[i].y = clamp(normY, 0.0f, 1.0f);
            transferFunctionChanged = true;
        }


        // 색상 변경 팝업
        if (ImGui::IsMouseClicked(1) && distance <= n.radius * canvasSize.x) {
            shouldOpenPopup = true;
            selectedNode = i;
        }
		
		if (selectedNode == i && ImGui::IsKeyPressed(ImGui::GetKeyIndex(ImGuiKey_Delete))) {
			std::cout << "inside delete"<< std::endl;
			nodes.erase(nodes.begin() + i);
			selectedNode = -1;  // 선택된 노드가 없도록 리셋
			transferFunctionChanged = true;
			break;
		}

    }

    // 색상 팝업
    if (shouldOpenPopup && selectedNode != -1) {
        ImGui::OpenPopup("Change Color");
        shouldOpenPopup = false;
    }
    if (ImGui::BeginPopup("Change Color")) {
        float colorNew[3] = { nodes[selectedNode].color[0], nodes[selectedNode].color[1], nodes[selectedNode].color[2] };
        if (ImGui::ColorEdit3("Color", colorNew)) {
            nodes[selectedNode].color[0] = colorNew[0];
            nodes[selectedNode].color[1] = colorNew[1];
            nodes[selectedNode].color[2] = colorNew[2];
            transferFunctionChanged = true;
        }
        ImGui::EndPopup();
    }

    // **마우스 클릭 시 노드 추가**
    if (isHovered && ImGui::IsMouseClicked(0) && ImGui::GetIO().KeyShift) {
        float normX = (mousePos.x - canvasPos.x) / canvasSize.x;
        float normY = 1.0f - (mousePos.y - canvasPos.y) / canvasSize.y;
        nodes.push_back({ normX, normY, 0.01f, { float(rand()) / RAND_MAX, float(rand()) / RAND_MAX, float(rand()) / RAND_MAX }, 1.0f });
        transferFunctionChanged = true;
		selectedNode = nodes.size() - 1 ;

    }
	
    // 반지름 조절 슬라이더
    if (selectedNode != -1) {
        ImGui::SliderFloat("Radius", &nodes[selectedNode].radius, 0.01f, 0.2f);
		ImGui::SliderFloat("Opacity", &nodes[selectedNode].max_opacity, 0.0f, 1.0f); // opacity 조절 추가
        transferFunctionChanged = true;
    }

    ImGui::End();
	
	if (transferFunctionChanged) {
		for (int i = 0; i < TF_SIZE; i += 4) {
			transferFunction[i + 0] = 0;  // R
			transferFunction[i + 1] = 0;  // G
			transferFunction[i + 2] = 0;  // B
			transferFunction[i + 3] = 0;  // A (Opacity)
		}
		
		
        for (const auto& node : nodes) {
			int centerX = static_cast<int>(node.x * 255);
			int centerY = static_cast<int>(node.y * 255);
			int radius = static_cast<int>(node.radius * 255);  // 반지름을 적절한 스케일로 조정

			for (int dx = -radius; dx <= radius; ++dx) {
				for (int dy = -radius; dy <= radius; ++dy) {
					int x = centerX + dx;
					int y = centerY + dy;
					if (x >= 0 && x < 256 && y >= 0 && y < 256) {
						float distance = sqrt(dx * dx + dy * dy) / radius;
						float opacity = std::max(0.0f, node.max_opacity * (1.0f - distance));  // 중심에서 1, 외곽에서 0

						int index = (x * 256 + y) * 4;
						
						//blending 위해 추가된 부분
						float prev_opacity = transferFunction[index + 3];
						transferFunction[index + 3] = std::max(prev_opacity, opacity);

						if (opacity > 0) {
							float weight = opacity / (prev_opacity + opacity + 1e-6); // 작은 값 추가하여 0 나누기 방지
							
							transferFunction[index + 0] = transferFunction[index + 0] * (1 - weight) + node.color[0] * weight;
							transferFunction[index + 1] = transferFunction[index + 1] * (1 - weight) + node.color[1] * weight;
							transferFunction[index + 2] = transferFunction[index + 2] * (1 - weight) + node.color[2] * weight;

						}
						
						//transferFunction[index + 0] = node.color[0];
						//transferFunction[index + 1] = node.color[1];
						//transferFunction[index + 2] = node.color[2];
						//transferFunction[index + 3] = std::max(transferFunction[index + 3], opacity);  // 겹치는 부분은 최대 투명도 적용
					}
				}
			}

		}
	}
	
	
}

#endif
