# Install script for directory: C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "C:/Users/user/gaussian-splatting/SIBR_viewers/install")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "Release")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "FALSE")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/addshadow.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/blur.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/colored_mesh.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/colored_mesh.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/copy.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/copy_depth.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/depthRenderer.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/depthRenderer.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/emotive_relight.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/emotive_relight.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/hdrEnvMap.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/hdrEnvMap.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/longlat.gp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/longlat.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/longlatColor.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/longlatDepth.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/noproj.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/normalRenderer.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/normalRenderer.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/normalRendererGen.gp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/normalRendererGen.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/poisson_diverg.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/poisson_interp.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/poisson_jacobi.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/poisson_restrict.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/positionReflectedDirRenderer.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/positionReflectedDirRenderer.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/positionRenderer.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/positionRenderer.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/shadowMapRenderer.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/shadowMapRenderer.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/texture-invert.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/texture.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/texture.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/textured_mesh.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/textured_mesh.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/textured_mesh_flipY.vert")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core" TYPE PROGRAM FILES
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/addshadow.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/blur.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/colored_mesh.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/colored_mesh.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/copy.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/copy_depth.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/depthRenderer.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/depthRenderer.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/emotive_relight.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/emotive_relight.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/hdrEnvMap.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/hdrEnvMap.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/longlat.gp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/longlat.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/longlatColor.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/longlatDepth.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/noproj.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/normalRenderer.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/normalRenderer.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/normalRendererGen.gp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/normalRendererGen.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/poisson_diverg.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/poisson_interp.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/poisson_jacobi.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/poisson_restrict.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/positionReflectedDirRenderer.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/positionReflectedDirRenderer.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/positionRenderer.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/positionRenderer.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/shadowMapRenderer.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/shadowMapRenderer.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/texture-invert.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/texture.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/texture.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/textured_mesh.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/textured_mesh.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/textured_mesh_flipY.vert"
      )
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/addshadow.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/blur.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/colored_mesh.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/colored_mesh.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/copy.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/copy_depth.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/depthRenderer.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/depthRenderer.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/emotive_relight.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/emotive_relight.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/hdrEnvMap.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/hdrEnvMap.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/longlat.gp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/longlat.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/longlatColor.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/longlatDepth.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/noproj.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/normalRenderer.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/normalRenderer.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/normalRendererGen.gp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/normalRendererGen.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/poisson_diverg.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/poisson_interp.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/poisson_jacobi.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/poisson_restrict.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/positionReflectedDirRenderer.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/positionReflectedDirRenderer.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/positionRenderer.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/positionRenderer.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/shadowMapRenderer.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/shadowMapRenderer.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/texture-invert.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/texture.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/texture.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/textured_mesh.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/textured_mesh.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/textured_mesh_flipY.vert")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core" TYPE PROGRAM FILES
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/addshadow.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/blur.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/colored_mesh.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/colored_mesh.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/copy.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/copy_depth.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/depthRenderer.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/depthRenderer.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/emotive_relight.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/emotive_relight.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/hdrEnvMap.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/hdrEnvMap.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/longlat.gp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/longlat.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/longlatColor.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/longlatDepth.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/noproj.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/normalRenderer.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/normalRenderer.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/normalRendererGen.gp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/normalRendererGen.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/poisson_diverg.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/poisson_interp.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/poisson_jacobi.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/poisson_restrict.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/positionReflectedDirRenderer.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/positionReflectedDirRenderer.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/positionRenderer.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/positionRenderer.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/shadowMapRenderer.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/shadowMapRenderer.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/texture-invert.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/texture.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/texture.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/textured_mesh.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/textured_mesh.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/textured_mesh_flipY.vert"
      )
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/addshadow.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/blur.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/colored_mesh.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/colored_mesh.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/copy.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/copy_depth.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/depthRenderer.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/depthRenderer.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/emotive_relight.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/emotive_relight.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/hdrEnvMap.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/hdrEnvMap.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/longlat.gp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/longlat.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/longlatColor.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/longlatDepth.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/noproj.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/normalRenderer.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/normalRenderer.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/normalRendererGen.gp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/normalRendererGen.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/poisson_diverg.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/poisson_interp.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/poisson_jacobi.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/poisson_restrict.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/positionReflectedDirRenderer.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/positionReflectedDirRenderer.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/positionRenderer.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/positionRenderer.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/shadowMapRenderer.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/shadowMapRenderer.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/texture-invert.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/texture.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/texture.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/textured_mesh.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/textured_mesh.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/textured_mesh_flipY.vert")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core" TYPE PROGRAM FILES
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/addshadow.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/blur.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/colored_mesh.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/colored_mesh.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/copy.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/copy_depth.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/depthRenderer.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/depthRenderer.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/emotive_relight.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/emotive_relight.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/hdrEnvMap.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/hdrEnvMap.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/longlat.gp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/longlat.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/longlatColor.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/longlatDepth.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/noproj.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/normalRenderer.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/normalRenderer.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/normalRendererGen.gp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/normalRendererGen.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/poisson_diverg.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/poisson_interp.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/poisson_jacobi.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/poisson_restrict.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/positionReflectedDirRenderer.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/positionReflectedDirRenderer.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/positionRenderer.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/positionRenderer.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/shadowMapRenderer.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/shadowMapRenderer.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/texture-invert.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/texture.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/texture.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/textured_mesh.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/textured_mesh.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/renderer/shaders/textured_mesh_flipY.vert"
      )
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "sibr_renderer_install" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/user/gaussian-splatting/SIBR_viewers/install/lib/sibr_renderer_rwdi.lib")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "C:/Users/user/gaussian-splatting/SIBR_viewers/install/lib" TYPE STATIC_LIBRARY OPTIONAL FILES "C:/Users/user/gaussian-splatting/SIBR_viewers/install/lib/sibr_renderer_rwdi.lib")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "sibr_renderer_install" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/sibr_renderer_rwdi.dll")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin" TYPE SHARED_LIBRARY FILES "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/sibr_renderer_rwdi.dll")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "sibr_renderer_install" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/user/gaussian-splatting/SIBR_viewers/install/lib/sibr_renderer.lib")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "C:/Users/user/gaussian-splatting/SIBR_viewers/install/lib" TYPE STATIC_LIBRARY OPTIONAL FILES "C:/Users/user/gaussian-splatting/SIBR_viewers/install/lib/sibr_renderer.lib")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "sibr_renderer_install" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/sibr_renderer.dll")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin" TYPE SHARED_LIBRARY FILES "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/sibr_renderer.dll")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "sibr_renderer_install" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/user/gaussian-splatting/SIBR_viewers/install/lib/sibr_renderer_d.lib")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "C:/Users/user/gaussian-splatting/SIBR_viewers/install/lib" TYPE STATIC_LIBRARY OPTIONAL FILES "C:/Users/user/gaussian-splatting/SIBR_viewers/install/lib/sibr_renderer_d.lib")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "sibr_renderer_install" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/sibr_renderer_d.dll")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin" TYPE SHARED_LIBRARY FILES "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/sibr_renderer_d.dll")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/sibr_renderer_rwdi.pdb")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin" TYPE FILE OPTIONAL FILES "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/sibr_renderer_rwdi.pdb")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/sibr_renderer_d.pdb")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin" TYPE FILE OPTIONAL FILES "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/sibr_renderer_d.pdb")
  endif()
endif()

