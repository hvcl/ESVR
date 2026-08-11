#ifndef TFEDITOR
#define TFEDITOR

#include <GLFW/glfw3.h>
#include <iostream>
#include <vector>

// Transfer Function Part
float histogram[256];
float transferFunction[256 * 4];
bool transferFunctionChanged = false;

float points[1000][2];
float colors[1000][3];
int nodeNum = 0;
int tfWidth = 600;
int tfHeight = 300;

float nodeInSize = 0.025;
float nodeOutSize = 0.03;
float LineWidth = 0.01;

GLFWwindow* window1;

// GLFW 창 크기 변경 콜백
void framebuffer_size_callback(GLFWwindow* window, int width, int height) {
    glViewport(0, 0, width, height);
    tfWidth = width;
    tfHeight = height;
}

// GLFW 마우스 클릭 콜백
void mouseClick_transferFunction(GLFWwindow* window, int button, int action, int mods) {
    double xpos, ypos;
    glfwGetCursorPos(window, &xpos, &ypos);

    float mousePos[2] = {
        (float(xpos) / tfWidth * 2 - 1) / 1.6f + 0.5f,
        ((1 - float(ypos) / tfHeight) * 2 - 1) / 1.6f + 0.5f
    };

    if (button == GLFW_MOUSE_BUTTON_RIGHT && action == GLFW_PRESS) {
        if (mods & GLFW_MOD_SHIFT) {
            for (int i = 1; i < nodeNum - 1; i++) {
                if (abs(mousePos[0] - points[i][0]) < nodeOutSize && abs(mousePos[1] - points[i][1]) < nodeOutSize) {
                    for (int j = i; j < nodeNum - 1; j++) {
                        points[j][0] = points[j + 1][0];
                        points[j][1] = points[j + 1][1];
                        colors[j][0] = colors[j + 1][0];
                        colors[j][1] = colors[j + 1][1];
                        colors[j][2] = colors[j + 1][2];
                    }
                    nodeNum--;
                }
            }
        } else {
            for (int i = 0; i < nodeNum; i++) {
                if (abs(mousePos[0] - points[i][0]) < nodeOutSize && abs(mousePos[1] - points[i][1]) < nodeOutSize) {
                    colors[i][0] = float(rand()) / RAND_MAX;
                    colors[i][1] = float(rand()) / RAND_MAX;
                    colors[i][2] = float(rand()) / RAND_MAX;
                    break;
                }
            }
        }
    }

    if (button == GLFW_MOUSE_BUTTON_LEFT && action == GLFW_PRESS) {
        if (mods & GLFW_MOD_SHIFT) {
            if (mousePos[0] > 1) mousePos[0] = 1;
            if (mousePos[0] < 0) mousePos[0] = 0;
            if (mousePos[1] > 1) mousePos[1] = 1;
            if (mousePos[1] < 0) mousePos[1] = 0;

            for (int i = 1; i < nodeNum; i++) {
                if (mousePos[0] < points[i][0]) {
                    for (int j = nodeNum + 1; j > i; j--) {
                        points[j][0] = points[j - 1][0];
                        points[j][1] = points[j - 1][1];
                        colors[j][0] = colors[j - 1][0];
                        colors[j][1] = colors[j - 1][1];
                        colors[j][2] = colors[j - 1][2];
                    }
                    points[i][0] = mousePos[0];
                    points[i][1] = mousePos[1];
                    colors[i][0] = float(rand()) / RAND_MAX;
                    colors[i][1] = float(rand()) / RAND_MAX;
                    colors[i][2] = float(rand()) / RAND_MAX;
                    nodeNum++;
                    break;
                }
            }
        }
    }
}

// GLFW 초기화 및 렌더링 설정
void init_transferFunction() {
    nodeNum = 2;
    points[0][0] = 0, points[0][1] = 0;
    points[1][0] = 1, points[1][1] = 1;
    colors[0][0] = 0, colors[0][1] = 0, colors[0][2] = 0;
    colors[1][0] = 1, colors[1][1] = 1, colors[1][2] = 1;
}

// Transfer Function 렌더링
void renderScene_transferFunction() {
    transferFunctionChanged = true;

    glClearColor(1, 1, 1, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glBegin(GL_QUADS);
    int start_index = 0, stop_index = 1;

    for (int i = 0; i < 256; i++) {
        if (float(i) / 255 > points[stop_index][0]) stop_index++, start_index++;
        float t_a = ((float(i) / 255 - points[start_index][0]) * points[stop_index][1] +
                     (points[stop_index][0] - float(i) / 255) * points[start_index][1]) /
                    (points[stop_index][0] - points[start_index][0]);
        glColor4f(((float(i) / 255 - points[start_index][0]) * colors[stop_index][0] +
                   (points[stop_index][0] - float(i) / 255) * colors[start_index][0]) /
                      (points[stop_index][0] - points[start_index][0]),
                  ((float(i) / 255 - points[start_index][0]) * colors[stop_index][1] +
                   (points[stop_index][0] - float(i) / 255) * colors[start_index][1]) /
                      (points[stop_index][0] - points[start_index][0]),
                  ((float(i) / 255 - points[start_index][0]) * colors[stop_index][2] +
                   (points[stop_index][0] - float(i) / 255) * colors[start_index][2]) /
                      (points[stop_index][0] - points[start_index][0]),
                  t_a);

        glVertex2f(float(i) / 256, 0);
        glVertex2f(float(i) / 256, histogram[i] * 5);
        glVertex2f(float(i + 1) / 256, histogram[i] * 5);
        glVertex2f(float(i + 1) / 256, 0);
    }
    glEnd();
}



#endif
