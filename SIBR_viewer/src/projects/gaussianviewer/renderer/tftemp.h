#ifndef TFEDITOR
#define TFEDITOR

#include <vector>
#include <algorithm>
#include <imgui.h>
#include <GL/gl.h>

float histogram[256];
float transferFunction[256 * 4];
bool transferFunctionChanged = false;

float points[1000][2];
float colors[1000][3];
int nodeNum = 0;
float nodeInSize = 0.025f;
float nodeOutSize = 0.03f;
float LineWidth = 0.01f;

// Transfer Function Editor 초기화
void init_transferFunction() {
    nodeNum = 2;
    points[0][0] = 0, points[0][1] = 0;
    points[1][0] = 1, points[1][1] = 1;
    colors[0][0] = 0, colors[0][1] = 0, colors[0][2] = 0;
    colors[1][0] = 1, colors[1][1] = 1, colors[1][2] = 1;
}

// Transfer Function GUI 렌더링
void renderTransferFunctionEditor() {
    ImGui::Begin("Transfer Function Editor");

    // 히스토그램 렌더링
    ImGui::Text("Histogram");
    ImGui::PlotHistogram("", histogram, 256, 0, nullptr, 0.0f, 1.0f, ImVec2(600, 100));

    // Transfer Function Curve
    ImGui::Text("Transfer Function");
    ImGui::PushStyleVar(ImGuiStyleVar_FrameRounding, 12.0f);
    ImDrawList* drawList = ImGui::GetWindowDrawList();
    ImVec2 canvasPos = ImGui::GetCursorScreenPos();
    ImVec2 canvasSize = ImVec2(600, 300);
    drawList->AddRectFilled(canvasPos, ImVec2(canvasPos.x + canvasSize.x, canvasPos.y + canvasSize.y), IM_COL32(50, 50, 50, 255));
    drawList->AddRect(canvasPos, ImVec2(canvasPos.x + canvasSize.x, canvasPos.y + canvasSize.y), IM_COL32(255, 255, 255, 255));

    // Transfer Function 노드 렌더링
    for (int i = 0; i < nodeNum; ++i) {
        float x = canvasPos.x + points[i][0] * canvasSize.x;
        float y = canvasPos.y + (1.0f - points[i][1]) * canvasSize.y;

        drawList->AddCircleFilled(ImVec2(x, y), 8.0f, IM_COL32(255, 0, 0, 255));
    }

    // Transfer Function 노드 추가/삭제
    if (ImGui::IsMouseClicked(0)) {
        ImVec2 mousePos = ImGui::GetMousePos();
        if (mousePos.x >= canvasPos.x && mousePos.x <= canvasPos.x + canvasSize.x &&
            mousePos.y >= canvasPos.y && mousePos.y <= canvasPos.y + canvasSize.y) {
            float normX = (mousePos.x - canvasPos.x) / canvasSize.x;
            float normY = 1.0f - (mousePos.y - canvasPos.y) / canvasSize.y;

            // 노드 추가
            points[nodeNum][0] = normX;
            points[nodeNum][1] = normY;
            colors[nodeNum][0] = static_cast<float>(rand()) / RAND_MAX;
            colors[nodeNum][1] = static_cast<float>(rand()) / RAND_MAX;
            colors[nodeNum][2] = static_cast<float>(rand()) / RAND_MAX;
            nodeNum++;
            std::sort(points, points + nodeNum, [](const float a[2], const float b[2]) { return a[0] < b[0]; });
        }
    }

    ImGui::PopStyleVar();
    ImGui::End();
}

#endif
