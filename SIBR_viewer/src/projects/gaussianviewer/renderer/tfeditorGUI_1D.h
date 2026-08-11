
#ifndef TFEDITOR
#define TFEDITOR

#include <vector>
#include <algorithm>
#include <imgui.h>
#include <GL/gl.h>
#include <fstream>
#include <iostream>

// 구조체로 변경
struct Point {
    float x, y;          // 위치
    float color[3];      // 색상 (RGB)
};

Point points[1000];
int nodeNum = 0;
float histogram[256];
float transferFunction[256 * 4];
bool transferFunctionChanged = false;

template <typename T>
T clamp(T value, T min, T max) {
    return (value < min) ? min : (value > max) ? max : value;
}

void loadHistogramFromFile(const std::string& filename) {
    std::ifstream file(filename);

    if (!file.is_open()) {
        std::cerr << "Error: Could not open histogram file " << filename << std::endl;
        return;
    }

    for (int i = 0; i < 256; i++) {
        if (!(file >> histogram[i])) {
            std::cerr << "Error: Not enough data in histogram file." << std::endl;
            break;
        }
		histogram[i] *= 15.0f;

    }

    file.close();
}


// Transfer Function Editor 초기화
void init_transferFunction() {
    nodeNum = 2;
    points[0] = {0.0f, 0.0f, {0.0f, 0.0f, 0.0f}};
    points[1] = {1.0f, 1.0f, {1.0f, 1.0f, 1.0f}};
}

std::vector<float> lowPoints;
int lp_count = 0;

struct Range {
    float range[2];      // 색상 (RGB)
};

std::vector<Range> descendingRanges;

void findLowPoints() {
    lowPoints.clear();
	lp_count = 0;

    // 첫 번째와 마지막 노드는 제외
    for (int i = 1; i < nodeNum - 1; ++i) {
        if (points[i].y <= points[i - 1].y && points[i].y <= points[i + 1].y) {
            lowPoints.push_back(points[i].x); // Low point 저장
			lp_count += 1;
        }
    }
	lowPoints.push_back(1.0f); // Low point 저장
	lp_count += 1;
	
	//for (float val : lowPoints) {
	//	printf("%f ", val);
	//}
	//printf("\n");
}

int rg_count = 0;


void findDescendingRanges() {
    descendingRanges.clear();
	rg_count = 0;

	for (int i = 0; i < nodeNum-1; ++i) {
        if (points[i].y > points[i + 1].y ) {
			Range r;
			r.range[0] = points[i].x;     // 내리막길 시작점
			r.range[1] = points[i+1].x; // 내리막길 끝점
			descendingRanges.push_back(r);
			rg_count++;
        }
    }

    // 📌 디버깅 출력
    //printf("Descending Ranges:\n");
    //for (const auto& r : descendingRanges) {
    //   printf("Range: [%f, %f]\n", r.range[0], r.range[1]);
    //}
}

static int selectedNode = -1; // 현재 선택된 노드
static bool isDragging = false; // 드래그 상태 확인
static bool shouldOpenPopup = false;
static int popNum = -1;

void renderTransferFunctionEditor() {
    ImGui::Begin("Transfer Function Editor");

    // 히스토그램 렌더링
    ImGui::Text("Histogram");
	loadHistogramFromFile("histogram.txt");
    ImGui::PlotHistogram("", histogram, 256, 0, nullptr, 0.0f, 1.0f, ImVec2(600, 100));
	
    // Transfer Function Curve 렌더링
    ImGui::Text("Transfer Function");
    ImGui::PushStyleVar(ImGuiStyleVar_FrameRounding, 12.0f);

    ImDrawList* drawList = ImGui::GetWindowDrawList();
    ImVec2 canvasPos = ImGui::GetCursorScreenPos();
    ImVec2 canvasSize = ImVec2(600, 300);

    // 배경 영역
    drawList->AddRectFilled(canvasPos, ImVec2(canvasPos.x + canvasSize.x, canvasPos.y + canvasSize.y), IM_COL32(50, 50, 50, 255));
    drawList->AddRect(canvasPos, ImVec2(canvasPos.x + canvasSize.x, canvasPos.y + canvasSize.y), IM_COL32(255, 255, 255, 255));


	for (int i = 0; i < nodeNum - 1; ++i) {
        // 현재 노드와 다음 노드의 좌표
        ImVec2 startPoint(canvasPos.x + points[i].x * canvasSize.x,
                          canvasPos.y + (1.0f - points[i].y) * canvasSize.y);
        ImVec2 endPoint(canvasPos.x + points[i + 1].x * canvasSize.x,
                        canvasPos.y + (1.0f - points[i + 1].y) * canvasSize.y);

        // 선형 보간을 사용하여 색상 그라데이션 생성
        ImU32 startColor = IM_COL32(points[i].color[0] * 255, points[i].color[1] * 255, points[i].color[2] * 255, 255);
        ImU32 endColor = IM_COL32(points[i + 1].color[0] * 255, points[i + 1].color[1] * 255, points[i + 1].color[2] * 255, 255);

        // 곡선 및 색상 시각화
        drawList->AddLine(startPoint, endPoint, IM_COL32(200, 200, 200, 255), 2.0f);
    }
	
	    // 2. 아래 직사각형에 색 그라데이션 추가
    ImVec2 gradientStart(canvasPos.x, canvasPos.y + canvasSize.y + 10);
    ImVec2 gradientEnd(canvasPos.x + canvasSize.x, canvasPos.y + canvasSize.y + 40);
    for (int i = 0; i < nodeNum - 1; ++i) {
        // 각 노드의 X 위치
        float startX = points[i].x * canvasSize.x;
        float endX = points[i + 1].x * canvasSize.x;

        // 색상
        ImU32 startColor = IM_COL32(points[i].color[0] * 255, points[i].color[1] * 255, points[i].color[2] * 255, 255);
        ImU32 endColor = IM_COL32(points[i + 1].color[0] * 255, points[i + 1].color[1] * 255, points[i + 1].color[2] * 255, 255);

        // 그라데이션 부분 직사각형
        drawList->AddRectFilledMultiColor(
            ImVec2(gradientStart.x + startX, gradientStart.y),
            ImVec2(gradientStart.x + endX, gradientEnd.y),
            startColor, endColor, endColor, startColor);
    }


    // 마우스 상태 확인
    ImGui::InvisibleButton("Canvas", canvasSize);
    bool isHovered = ImGui::IsItemHovered(); // 영역 안에 있는지 확인

    ImVec2 mousePos = ImGui::GetMousePos();

    // Transfer Function 노드 렌더링 및 상호작용
    for (int i = 0; i < nodeNum; ++i) {
        float x = canvasPos.x + points[i].x * canvasSize.x;
        float y = canvasPos.y + (1.0f - points[i].y) * canvasSize.y;

        drawList->AddCircleFilled(ImVec2(x, y), 8.0f, IM_COL32(points[i].color[0] * 255, points[i].color[1] * 255, points[i].color[2] * 255, 255));

        float dx = mousePos.x - x;
        float dy = mousePos.y - y;
        float distance = sqrt(dx * dx + dy * dy);

        // 노드 클릭 감지
        if (isHovered && ImGui::IsMouseClicked(0) && distance <= 8.0f) {
            selectedNode = i; // 선택된 노드 저장
            isDragging = true; // 드래그 상태 시작
        }

        // 노드 이동 처리 (드래그 중)
        if (isDragging && selectedNode == i) {
            if (ImGui::IsMouseDown(0)) { // 마우스가 계속 눌려 있는 동안
                float normX = (mousePos.x - canvasPos.x) / canvasSize.x;
                float normY = 1.0f - (mousePos.y - canvasPos.y) / canvasSize.y;

                // 경계값 클램핑
                normX = clamp(normX, 0.0f, 1.0f);
                normY = clamp(normY, 0.0f, 1.0f);

                // 노드 순서 유지
				if (i == 0) {
					normX = points[i].x; // X 위치 고정
				} else if (i == nodeNum - 1) {
					normX = points[i].x; // X 위치 고정
				} else {
					// 중간 노드만 X, Y 모두 이동 가능
					// 노드 순서 유지
					if (i > 0 && normX < points[i - 1].x) normX = points[i - 1].x;
					if (i < nodeNum - 1 && normX > points[i + 1].x) normX = points[i + 1].x;
				}

                points[i].x = normX;
                points[i].y = normY;
                transferFunctionChanged = true;
            } else if (ImGui::IsMouseReleased(0)) { // 마우스 버튼을 떼면 드래그 종료
                isDragging = false;
                selectedNode = -1;
            }
        }
		
		if (ImGui::IsMouseClicked(1) && distance <= 8.0f && i != 0 && i != nodeNum - 1) { // 시작/끝 노드는 삭제 불가
            for (int j = i; j < nodeNum - 1; ++j) {
                points[j] = points[j + 1];
            }
            nodeNum--;
            transferFunctionChanged = true;
            break;
        }
	
	
		if (ImGui::IsMouseClicked(2) && distance <= 8.0f) {
			shouldOpenPopup = true;
			popNum = i;

			/*
            //ImVec2 mousePos = ImGui::GetMousePos();
            if (distance <= 8.0f) { // 노드 크기 이내 클릭 시
				points[i].color[0] = static_cast<float>(rand()) / RAND_MAX;
				points[i].color[1] = static_cast<float>(rand()) / RAND_MAX;
				points[i].color[2] = static_cast<float>(rand()) / RAND_MAX;
				ImGui::CloseCurrentPopup(); // 기존 팝업 닫기
				std::cout << "distance inside" << std::endl;

                ImGui::OpenPopup("Change Color");
            }
			
			if (ImGui::IsPopupOpen("Change Color")) {

            if (ImGui::BeginPopup("Change Color")) {
				std::cout << "inside begin" << std::endl;

				ImVec2 popupPos = ImGui::GetMousePos();
				ImGui::SetNextWindowPos(popupPos, ImGuiCond_Always); // 마우스 위치에 팝업 표시
                ImGui::Text("Change Node Color");
                if (ImGui::ColorEdit3("Color", points[i].color)) {
                    transferFunctionChanged = true; // 변경된 경우 플래그 설정
                }
                ImGui::EndPopup();
            }else {
				std::cout << "Popup is open but not rendering" << std::endl;
			}
			}
			else {
				    std::cout << "Popup is not open" << std::endl;

			}*/
        }
    }
	
	if (shouldOpenPopup) {
		ImGui::OpenPopup("Change Color");
		shouldOpenPopup = false; // 팝업 요청 상태 초기화

	}
	if (ImGui::BeginPopup("Change Color")) {
		ImVec2 popupPos = ImGui::GetMousePos();
		ImGui::SetNextWindowPos(popupPos, ImGuiCond_Always); // 마우스 위치에 팝업 표시
		ImGui::Text("Change Node Color");
		float colorNew[3] = { points[popNum].color[0], points[popNum].color[1], points[popNum].color[2] };

		if (ImGui::ColorEdit3("Color", colorNew)) {
			points[popNum].color[0] = colorNew[0];
			points[popNum].color[1] = colorNew[1];
			points[popNum].color[2] = colorNew[2];
			transferFunctionChanged = true; // 변경된 경우 플래그 설정
		}
		ImGui::EndPopup();

	}
	if (popNum != -1 && !ImGui::IsPopupOpen("Change Color")) {
		popNum = -1; // 팝업이 닫힌 후 popNum 초기화
	}
	
	if (ImGui::IsMouseClicked(0) && ImGui::GetIO().KeyShift) {
        ImVec2 mousePos = ImGui::GetMousePos();
        if (mousePos.x >= canvasPos.x && mousePos.x <= canvasPos.x + canvasSize.x &&
            mousePos.y >= canvasPos.y && mousePos.y <= canvasPos.y + canvasSize.y) {
            float normX = (mousePos.x - canvasPos.x) / canvasSize.x;
            float normY = 1.0f - (mousePos.y - canvasPos.y) / canvasSize.y;

            // 노드 추가
			points[nodeNum] = {normX, normY, {0.0f, 0.0f, 0.0f}};
            //points[nodeNum] = {normX, normY, {static_cast<float>(rand()) / RAND_MAX, static_cast<float>(rand()) / RAND_MAX, static_cast<float>(rand()) / RAND_MAX}};
    
			nodeNum++;
            std::sort(points, points + nodeNum, [](const Point& a, const Point& b) { return a.x < b.x; });
			
			int addedIndex = -1;
			
			//sorting 후 index 찾기.
			for (int i = 0; i < nodeNum; ++i) {
				if (points[i].x == normX && points[i].y == normY) {
					addedIndex = i;
					break;
				}
			}

			// 양 옆 노드가 존재하는지 확인하고 색상 평균 계산
			if (addedIndex > 0 && addedIndex < nodeNum - 1) {
				for (int k = 0; k < 3; ++k) { // RGB 각각 평균 계산
					points[addedIndex].color[k] = (points[addedIndex - 1].color[k] + points[addedIndex + 1].color[k]) / 2.0f;
				}
			}
        }
		
		transferFunctionChanged = true;
    }

    ImGui::PopStyleVar();
    ImGui::End();

    // Transfer Function 업데이트
    if (transferFunctionChanged) {
        for (int i = 0; i < nodeNum - 1; ++i) {
            int startIdx = static_cast<int>(points[i].x * 255);
            int endIdx = static_cast<int>(points[i + 1].x * 255);
            for (int j = startIdx; j <= endIdx; ++j) {
                float t = (j - startIdx) / static_cast<float>(endIdx - startIdx);
                transferFunction[j * 4 + 0] = (1 - t) * points[i].color[0] + t * points[i + 1].color[0];
                transferFunction[j * 4 + 1] = (1 - t) * points[i].color[1] + t * points[i + 1].color[1];
                transferFunction[j * 4 + 2] = (1 - t) * points[i].color[2] + t * points[i + 1].color[2];
                transferFunction[j * 4 + 3] = (1 - t) * points[i].y + t * points[i + 1].y; // Alpha
            }
        }
		
		findLowPoints();
		findDescendingRanges();
    }
	
	if (transferFunctionChanged) {
		FILE* transferFunc;
		fopen_s(&transferFunc, "transferFunc.txt", "w");
		for (int j = 0; j < 256; j++) {
			fprintf(transferFunc, "%f %f %f %f\n", float(transferFunction[j*4 + 0]),  float(transferFunction[j*4 + 1]),  float(transferFunction[j*4 + 2]),  float(transferFunction[j*4 + 3]));
		}
		fclose(transferFunc);
	}
}
#endif
