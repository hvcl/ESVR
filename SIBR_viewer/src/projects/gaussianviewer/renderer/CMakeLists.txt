# Copyright (C) 2023, Inria
# GRAPHDECO research group, https://team.inria.fr/graphdeco
# All rights reserved.
# 
# This software is free for non-commercial, research and evaluation use 
# under the terms of the LICENSE.md file.
# 
# For inquiries contact sibr@inria.fr and/or George.Drettakis@inria.fr

set(SIBR_PROJECT "gaussian")
project(sibr_${SIBR_PROJECT} LANGUAGES CXX)

# Use the modified rasterizer sources bundled with ESVR.
set(CUDA_RASTERIZER_SOURCE_DIR "${CMAKE_SOURCE_DIR}/extlibs/CudaRasterizer/CudaRasterizer")
add_subdirectory("${CUDA_RASTERIZER_SOURCE_DIR}"
    "${CMAKE_BINARY_DIR}/extlibs/CudaRasterizer/build")
set_target_properties(CudaRasterizer PROPERTIES FOLDER "extlibs")
ibr_install_target(CudaRasterizer COMPONENT CudaRasterizer_install)
include_directories("${CMAKE_SOURCE_DIR}/extlibs/CudaRasterizer"
    "${CUDA_RASTERIZER_SOURCE_DIR}")

find_package(CUDAToolkit REQUIRED)

file(GLOB SOURCES "*.cpp" "*.h" "*.hpp")
list(REMOVE_ITEM SOURCES
	"${CMAKE_CURRENT_SOURCE_DIR}/GaussianSurfaceRenderer.cpp"
	"${CMAKE_CURRENT_SOURCE_DIR}/GaussianSurfaceRenderer.hpp"
	"${CMAKE_CURRENT_SOURCE_DIR}/GaussianView_FA.cpp"
	"${CMAKE_CURRENT_SOURCE_DIR}/GaussianView_novram.cpp"
	"${CMAKE_CURRENT_SOURCE_DIR}/GaussianView_withVRAM.cpp"
)
source_group("Source Files" FILES ${SOURCES})

file(GLOB SHADERS "shaders/*.frag" "shaders/*.vert" "shaders/*.geom")
source_group("Source Files\\shaders" FILES ${SHADERS})

file(GLOB SOURCES "*.cpp" "*.h" "*.hpp" "shaders/*.frag" "shaders/*.vert" "shaders/*.geom")
list(REMOVE_ITEM SOURCES
	"${CMAKE_CURRENT_SOURCE_DIR}/GaussianSurfaceRenderer.cpp"
	"${CMAKE_CURRENT_SOURCE_DIR}/GaussianSurfaceRenderer.hpp"
	"${CMAKE_CURRENT_SOURCE_DIR}/GaussianView_FA.cpp"
	"${CMAKE_CURRENT_SOURCE_DIR}/GaussianView_novram.cpp"
	"${CMAKE_CURRENT_SOURCE_DIR}/GaussianView_withVRAM.cpp"
)

## Specify target rules
add_library(${PROJECT_NAME} SHARED ${SOURCES})

include_directories(.)

if (WIN32)
target_link_libraries(${PROJECT_NAME}
	${GLEW_LIBRARIES}
	${OPENGL_LIBRARIES}
	glfw3
	sibr_system
	sibr_view
	sibr_assets
	sibr_renderer
	sibr_basic
	CUDA::cudart
	CudaRasterizer

)
else()
target_link_libraries(${PROJECT_NAME}
	${GLEW_LIBRARIES}
	${OPENGL_LIBRARIES}
	glfw
	sibr_system
	sibr_view
	sibr_assets
	sibr_renderer
	sibr_basic
	CUDA::cudart
	CudaRasterizer
)
endif()

add_definitions(-DSIBR_EXP_ULR_EXPORTS)

set_target_properties(${PROJECT_NAME} PROPERTIES FOLDER "projects/${SIBR_PROJECT}/renderer")

## High level macro to install in an homogen way all our ibr targets
include(install_runtime)
ibr_install_target(${PROJECT_NAME}
    INSTALL_PDB                         ## mean install also MSVC IDE *.pdb file (DEST according to target type)
	SHADERS ${SHADERS}
	RSC_FOLDER ${SIBR_PROJECT}

    #STANDALONE  ${INSTALL_STANDALONE}   ## mean call install_runtime with bundle dependencies resolution
    COMPONENT   ${PROJECT_NAME}_install ## will create custom target to install only this project
)
