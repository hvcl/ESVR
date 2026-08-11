#ifndef TFEDITOR_2D
#define TFEDITOR_2D

#include <vector>
#include <cmath>
#include <algorithm>
#include <imgui.h>
#include <iostream>


// 2D Transfer Function Node 구조체
struct Node {
    float x, y;       // 위치 (Intensity, Gradient Magnitude)
    float radius;     // 원의 크기 (반지름)
    float color[3];   // RGB 색상
};

///*** 유진 ***///
struct Point {
    float x, y;
};

std::vector<std::vector<Point>> polygons; // 여러 개의 다각형 저장
std::vector<ImU32> polygonColors; // 다각형별 색상 저장
int currentPolygonIndex = -1; // 현재 활성화된 다각형
int selectedPointIndex = -1; // 드래그 중인 점

// 새로운 색상 생성 함수
ImU32 GenerateRandomColor() {
    int r = rand() % 256;
    int g = rand() % 256;
    int b = rand() % 256;
    return IM_COL32(r, g, b, 150); // 투명도 150
}
///***    ***/// 

std::vector<Node> nodes; // Transfer Function 노드 저장
std::vector<float> fa_values;   // FA 값 저장
std::vector<float> opacities;   // Opacity 값 저장
bool transferFunctionChanged = false;

const int TF_SIZE = 256 * 256 * 4;  // 각각의 (intensity, gradient) 쌍에 대해 RGBA 값을 저장
float transferFunction[TF_SIZE];    // 2D Transfer Function 배열
int selectedNode = -1;
bool shouldOpenPopup = false;
float selectedRadius = 0.1f;
int tfWidth = 600, tfHeight = 300;
ImDrawList* backgroundDrawList = nullptr;
bool backgroundInitialized = false;



// 클램핑 함수
template <typename T>
T clamp(T value, T min, T max) {
    return (value < min) ? min : (value > max) ? max : value;
}

void loadFAFromFile(const std::string& filename, int count) {
    std::ifstream file(filename);

    if (!file.is_open()) {
        std::cerr << "Error: Could not open histogram file " << filename << std::endl;
        return;
    }
	float temp;
    for (int i = 0; i < count; i++) {
        if (!(file >> temp)) {
            std::cerr << "Error: Not enough data in histogram file." << std::endl;
            break;
        }
		fa_values.push_back(temp);
    }

    file.close();
}

void loadOpacityFromFile(const std::string& filename, int count) {
    std::ifstream file(filename);

    if (!file.is_open()) {
        std::cerr << "Error: Could not open histogram file " << filename << std::endl;
        return;
    }

	float temp;
    for (int i = 0; i < count; i++) {
        if (!(file >> temp)) {
            std::cerr << "Error: Not enough data in histogram file." << std::endl;
            break;
        }
		opacities.push_back(temp);
    }

    file.close();
}



// **초기화 함수: FA 및 Opacity 데이터 추가**
void init_transferFunction(int count) {
    // FA 및 Opacity 데이터 로드
    //fa_values = fa_data;
    //opacities = opacity_data;
	
	loadOpacityFromFile("opacity_values.txt", count);
	loadFAFromFile("fa_values.txt", count);
	
    nodes.clear();
    std::cout << "FA and Opacity data loaded: " << fa_values.size() << " points." << std::endl;
	
	backgroundInitialized = false;
	
}


// **배경을 초기화 시 한 번만 렌더링**
void renderBackground(ImDrawList* drawList, ImVec2 canvasPos, ImVec2 canvasSize) {
    // 배경 박스
    drawList->AddRectFilled(canvasPos, ImVec2(canvasPos.x + canvasSize.x, canvasPos.y + canvasSize.y),
                            IM_COL32(50, 50, 50, 255));
    drawList->AddRect(canvasPos, ImVec2(canvasPos.x + canvasSize.x, canvasPos.y + canvasSize.y),
                      IM_COL32(255, 255, 255, 255));

    // **배경 Scatter Plot 추가**
    if (!fa_values.empty() && !opacities.empty()) {
		//fa_values.size();
		int length = fa_values.size() / 2000.0f;
        for (size_t i = 0; i < fa_values.size(); i+= length) {
            float normX = clamp(opacities[i], 0.0f, 1.0f);
            float normY = clamp(fa_values[i], 0.0f, 1.0f);

            float x = canvasPos.x + normX * canvasSize.x;
            float y = canvasPos.y + (1.0f - normY) * canvasSize.y;

            drawList->AddCircleFilled(ImVec2(x, y), 1.0f, IM_COL32(150, 150, 150, 100));
        }
    }
}


// **Transfer Function UI 렌더링**
void renderTransferFunctionEditor() {
    ImGui::Begin("2D Transfer Function Editor");
    ImGui::Text("2D Transfer Function");

    ImGuiIO& io = ImGui::GetIO();
    ImDrawList* drawList = ImGui::GetWindowDrawList();
    ImVec2 canvasPos = ImGui::GetCursorScreenPos();
    ImVec2 canvasSize = ImVec2(600, 600);

    // 배경을 한 번만 렌더링
    renderBackground(drawList, canvasPos, canvasSize);

    // 마우스 입력 감지
    ImGui::InvisibleButton("Canvas", canvasSize);
    bool isHovered = ImGui::IsItemHovered();
    ImVec2 mousePos = ImGui::GetMousePos();

    // 어떤 키 눌렸는지 확인하고 싶으면..
    // std::cout << "Pressed keys: ";
    // for (int i = 0; i < IM_ARRAYSIZE(ImGui::GetIO().KeysDown); i++) {
    //     if (ImGui::GetIO().KeysDown[i]) {
    //         std::cout << i ;
    //     }
    // }
    // std::cout << std::endl;

    // Button to add polygon
    if (ImGui::Button("Add Polygon")) {
        std::cout << "Polygon Added" << std::endl;
        polygons.push_back({}); // 새로운 다각형 추가
        polygonColors.push_back(GenerateRandomColor()); // 새로운 색상 추가
        currentPolygonIndex = (int)polygons.size() - 1;
    }

    if (currentPolygonIndex == -1) return; // 다각형이 하나도 없으면 처리 안 함
    std::vector<Point>& currentPolygon = polygons[currentPolygonIndex];

    // Ctrl + 클릭으로 점 선택 (모든 다각형에서 검색)
    if (io.KeyCtrl && ImGui::IsMouseClicked(0)) {
        selectedPointIndex = -1;
        currentPolygonIndex = -1;
        
        for (size_t polyIdx = 0; polyIdx < polygons.size(); polyIdx++) {
            auto& polygon = polygons[polyIdx];
            for (size_t i = 0; i < polygon.size(); i++) {
                ImVec2 p = ImVec2(canvasPos.x + polygon[i].x * canvasSize.x,
                                canvasPos.y + polygon[i].y * canvasSize.y);
                if (ImLengthSqr(ImVec2(mousePos.x - p.x, mousePos.y - p.y)) < 25.0f) {
                    selectedPointIndex = (int)i;
                    currentPolygonIndex = (int)polyIdx; // 선택한 다각형의 인덱스 저장
                    break;
                }
            }
            if (selectedPointIndex != -1) break; // 선택되면 중단
        }
    }

    // Ctrl + 드래그로 점 이동 (선택된 다각형에서만 이동)
    if (io.KeyCtrl && ImGui::IsMouseDragging(0) && selectedPointIndex != -1 && currentPolygonIndex != -1) {
        std::cout << "Moving point on polygon " << currentPolygonIndex << std::endl;
        float normX = (mousePos.x - canvasPos.x) / canvasSize.x;
        float normY = (mousePos.y - canvasPos.y) / canvasSize.y;
        polygons[currentPolygonIndex][selectedPointIndex] = {normX, normY};
    }

    // 다각형 삭제 시, 인덱스 업데이트
    if (!polygons.empty() && ImGui::GetIO().KeysDown[259]) { // Backspace
        polygons.pop_back();
        polygonColors.pop_back(); // 색상도 함께 삭제
        std::cout << "Deleted polygon " << currentPolygonIndex << std::endl;

        // 남아 있는 다각형이 있으면 마지막 다각형 선택, 없으면 -1
        if (polygons.empty()) {
            currentPolygonIndex = -1;
            selectedPointIndex = -1;
        } else {
            currentPolygonIndex = (int)polygons.size() - 1;
            selectedPointIndex = -1; // 새로 선택하도록 초기화
        }
    }

    // Shift + 클릭으로 점 추가 (Shift + Left Click)
    if (isHovered && ImGui::GetIO().KeyShift && ImGui::IsMouseClicked(0)) {
        std::cout << "point added on" << currentPolygonIndex <<  std::endl;
        float normX = (mousePos.x - canvasPos.x) / canvasSize.x;
        float normY = (mousePos.y - canvasPos.y) / canvasSize.y;
        currentPolygon.push_back({normX, normY});
    }

    // 모든 다각형을 순회하며 그리기
    for (size_t polygonIdx = 0; polygonIdx < polygons.size(); polygonIdx++) {
        const auto& polygon = polygons[polygonIdx];
        ImU32 fillColor = polygonColors[polygonIdx];

        if (polygon.size() < 3) continue;

        // 내부 색칠 (삼각형 분할)
        for (size_t i = 1; i < polygon.size() - 1; i++) {
            ImVec2 p0 = ImVec2(canvasPos.x + polygon[0].x * canvasSize.x,
                               canvasPos.y + polygon[0].y * canvasSize.y);
            ImVec2 p1 = ImVec2(canvasPos.x + polygon[i].x * canvasSize.x,
                               canvasPos.y + polygon[i].y * canvasSize.y);
            ImVec2 p2 = ImVec2(canvasPos.x + polygon[i + 1].x * canvasSize.x,
                               canvasPos.y + polygon[i + 1].y * canvasSize.y);
            drawList->AddTriangleFilled(p0, p1, p2, fillColor);
        }
    }

    // 현재 다각형의 점과 선을 그리기
    for (const auto& polygon : polygons) {
        for (size_t i = 0; i < polygon.size(); i++) {
            ImVec2 p1 = ImVec2(canvasPos.x + polygon[i].x * canvasSize.x,
                                canvasPos.y + polygon[i].y * canvasSize.y);

            // 점 그리기
            drawList->AddCircleFilled(p1, 5.0f, IM_COL32(0, 255, 0, 255));

            // 선 그리기 (다음 점이 있으면)
            if (i > 0) {
                ImVec2 p0 = ImVec2(canvasPos.x + polygon[i - 1].x * canvasSize.x,
                                    canvasPos.y + polygon[i - 1].y * canvasSize.y);
                drawList->AddLine(p0, p1, IM_COL32(255, 0, 0, 255), 2.0f);
            }
        }

        // 폐곡선 유지
        if (polygon.size() > 2) {
            ImVec2 first = ImVec2(canvasPos.x + polygon[0].x * canvasSize.x,
                                  canvasPos.y + polygon[0].y * canvasSize.y);
            ImVec2 last = ImVec2(canvasPos.x + polygon.back().x * canvasSize.x,
                                 canvasPos.y + polygon.back().y * canvasSize.y);
            drawList->AddLine(last, first, IM_COL32(255, 0, 0, 255), 2.0f);
        }
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
						float opacity = std::max(0.0f, 1.0f - distance);  // 중심에서 1, 외곽에서 0

						int index = (x * 256 + y) * 4;
						transferFunction[index + 0] = node.color[0];
						transferFunction[index + 1] = node.color[1];
						transferFunction[index + 2] = node.color[2];
						transferFunction[index + 3] = std::max(transferFunction[index + 3], opacity);  // 겹치는 부분은 최대 투명도 적용
					}
				}
			}

		}
	}
	
	
}

#endif
