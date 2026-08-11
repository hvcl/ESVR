#ifndef TFEDITOR_LABEL
#define TFEDITOR_LABEL

#include <vector>
#include <cmath>
#include <algorithm>
#include <imgui.h>
#include <iostream>
#include <fstream>
#include <utility> // for std::pair
#include <cstdlib> // system() 함수
#include <thread>
#include <atomic>
#include <unordered_map>

// 2D Transfer Function Node 구조체
struct Node {
    float x, y;       // 위치 (Intensity, Gradient Magnitude)
    float radius;     // 원의 크기 (반지름)
    float color[3];   // RGB 색상
    float max_opacity;
    int cluster_id;   // 클러스터 ID
};

std::atomic<bool> isLoading(false); // TSNE 실행 중 여부

std::vector<Node> nodes; // Transfer Function 노드 저장
std::vector<std::pair<float, float>> normalized_embedding;
std::unordered_map<int, std::pair<float, float>> clusterCenters; // 클러스터 중심 좌표 저장
std::unordered_map<int, std::pair<std::vector<float>, float>> clusterColorsOpacities;
std::vector<int> clusterLabels; // 각 포인트의 클러스터 라벨 저장
std::vector<float> clusterRGBA; // 각 포인트의 클러스터 라벨 저장
bool transferFunctionChanged = false;
//std::vector<float> tsne;
static std::unordered_map<int, bool> clusterVisibility;



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

bool runPythonScript(const std::string& scriptName, const std::string& args) {
    std::string command = "python " + scriptName + " " + args;
    int ret = std::system(command.c_str());
    if (ret != 0) {
        std::cerr << "Error running python script. Return code: " << ret << std::endl;
        return false;
    }
    return true;
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

// 📌 클러스터 라벨 로딩 함수
void loadClusterLabels(const std::string& filename) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Error: Could not open cluster file " << filename << std::endl;
        return;
    }

    clusterLabels.clear();
    clusterCenters.clear();
    clusterColorsOpacities.clear();
    std::unordered_map<int, std::vector<std::pair<float, float>>> clusterPoints;

    std::string line;
    // 첫 번째 줄(헤더) 무시
    if (std::getline(file, line)) {
        std::cerr << "Skipping header: " << line << std::endl;
    }

    int cluster_id;
    float x, y;
    char comma;
    while (file >> x >> comma >> y >> comma >> cluster_id) {
        clusterLabels.push_back(cluster_id);
        clusterPoints[cluster_id].emplace_back(x, y);
    }

    for (const auto& kv : clusterPoints) {
        int cluster_id = kv.first;
        const auto& points = kv.second;


        float sum_x = 0.0f, sum_y = 0.0f;
        for (const auto& p : points) {
            sum_x += p.first;
            sum_y += p.second;
        }
        clusterCenters[cluster_id] = { sum_x / points.size(), sum_y / points.size() };
        
        clusterColorsOpacities[cluster_id] = {
            { float(rand()) / RAND_MAX, float(rand()) / RAND_MAX, float(rand()) / RAND_MAX }, // 색상 (std::vector)
            0.5f + 0.5f * (float(rand()) / RAND_MAX) // opacity
        };
    }

    file.close();
}

// 📌 가장 가까운 노드 찾기
int findNearestNodeIndex(float x, float y) {
    int nearestIndex = -1;
    float minDist = std::numeric_limits<float>::max();
    for (int i = 0; i < nodes.size(); ++i) {
        float dx = nodes[i].x - x;
        float dy = nodes[i].y - y;
        float dist = dx * dx + dy * dy;
        if (dist < minDist) {
            minDist = dist;
            nearestIndex = i;
        }
    }
    return nearestIndex;
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
    }
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

std::vector<float> convertToFloatVector() {
    clusterRGBA.clear();
    clusterRGBA.reserve(clusterLabels.size() * 4); // 메모리 미리 할당
    int id = 0;
    std::cout << "convert float vector" << std::endl;

    for (int i =0; i<clusterLabels.size(); i++) {
        id = clusterLabels[i];
        std::vector<float>& clusterColor = clusterColorsOpacities[id].first;


        clusterRGBA.push_back(clusterColor[0]); 
        clusterRGBA.push_back(clusterColor[1]); 
        clusterRGBA.push_back(clusterColor[2]); 
        if (!clusterVisibility[id]) 
            clusterRGBA.push_back(0.0f); 
        else
            clusterRGBA.push_back(clusterColorsOpacities[id].second); 

    }

    return clusterRGBA;
}

// 📌 TSNE 비동기 실행
void runTSNEAsync(const std::string& file) {
    isLoading = true;
    std::cout << "[LOG] Running TSNE script..." << std::endl;

    // if (!runPythonScript("run_tsne.py", file)) {
    //     std::cerr << "[ERROR] TSNE script execution failed!" << std::endl;
    // }

    loadClusterLabels("cluster_labels.txt");
    loadNormalizedData("tsne_data.txt");

    isLoading = false;
    std::cout << "[LOG] TSNE completed. Loaded " << normalized_embedding.size() << " points." << std::endl;
}

// 📌 초기화 함수 (클러스터 기반 색상/opacity 적용)
void init_transferFunction(int count, const char* file) {
    std::thread tsneThread(runTSNEAsync, std::string(file));
    tsneThread.detach();
}

// **Transfer Function UI 렌더링**
void renderTransferFunctionEditor() {
    std::cout << "[LOG] renderTF" << std::endl;

    ImGui::Begin("2D Transfer Function Editor");

    ImGui::BeginChild("Cluster Selection", ImVec2(200, 0), true);
    ImGui::Text("Cluster Visibility");
    //clusterVisibility.clear();
    for (const auto& pair : clusterCenters) {
        int cluster_id = pair.first;
        if (clusterVisibility.find(cluster_id) == clusterVisibility.end()) {
            clusterVisibility[cluster_id] = true;
        }

        std::vector<float>& clusterColor = clusterColorsOpacities[cluster_id].first;
        ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(clusterColor[0], clusterColor[1], clusterColor[2], 1.0f));
        std::string label = "Cluster " + std::to_string(cluster_id);
        bool prevState = clusterVisibility[cluster_id];  // 기존 상태 저장
        if (ImGui::Checkbox(label.c_str(), &clusterVisibility[cluster_id])) {
            if (prevState != clusterVisibility[cluster_id]) {
                transferFunctionChanged = true;  // 변경이 발생했으므로 True
                std::cout << "change" << std::endl;
            }
        }
        ImGui::PopStyleColor();

        //std::cout << "[LOG] cluster Points" << cluster_id << clusterColor[0] << clusterColor[1]<< clusterColor[2] << clusterColorsOpacities[cluster_id].second << std::endl;

    }
    ImGui::EndChild();

    ImGui::SameLine();

    ImGui::BeginChild("Scatter Plot", ImVec2(0, 0), true);
    ImDrawList* drawList = ImGui::GetWindowDrawList();
    ImVec2 canvasPos = ImGui::GetCursorScreenPos();
    ImVec2 canvasSize = ImVec2(600, 600);

    //renderBackground(drawList, canvasPos, canvasSize);

    drawList->AddRectFilled(canvasPos, ImVec2(canvasPos.x + canvasSize.x, canvasPos.y + canvasSize.y), IM_COL32(50, 50, 50, 255));
    drawList->AddRect(canvasPos, ImVec2(canvasPos.x + canvasSize.x, canvasPos.y + canvasSize.y), IM_COL32(255, 255, 255, 255));

	int length = normalized_embedding.size() / 2000.0f;

    for (size_t i = 0; i < normalized_embedding.size(); i+=length) {
        int cluster_id = clusterLabels[i];
        if (!clusterVisibility[cluster_id]) continue;

        auto& point = normalized_embedding[i];
        float normX = clamp(point.first, 0.0f, 600.0f) / 600.0f;
        float normY = clamp(point.second, 0.0f, 600.0f) / 600.0f;

        float x = canvasPos.x + normX * canvasSize.x;
        float y = canvasPos.y + (1.0f - normY) * canvasSize.y;

        std::vector<float>& clusterColor = clusterColorsOpacities[cluster_id].first;
        ImU32 color = IM_COL32(clusterColor[0] * 255, clusterColor[1] * 255, clusterColor[2] * 255, 255);
        drawList->AddCircleFilled(ImVec2(x, y), 2.0f, color);
    }

    ImGui::EndChild();
    ImGui::End();
}

#endif
