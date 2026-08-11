# Install script for directory: C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view

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
     "C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alpha_colored_mesh.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alpha_colored_mesh.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alpha_colored_per_triangle_normals.geom;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alpha_colored_per_triangle_normals.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alpha_colored_per_vertex_normals.geom;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alpha_colored_per_vertex_normals.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alpha_points.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alpha_points.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alpha_uv_tex.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alpha_uv_tex_array.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alphaimgview.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alphaimgview.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/anaglyph.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/anaglyph.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/axisgizmo.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/axisgizmo.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/camstub.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/camstub.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/depth.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/depth.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/depthonly.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/depthonly.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/image_viewer.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/image_viewer.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/mesh_color.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/mesh_color.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/mesh_debugview.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/mesh_debugview.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/mesh_normal.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/mesh_normal.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/number.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/number.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/skybox.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/skybox.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/text-imgui.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/text-imgui.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/texture.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/texture.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/topview.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/topview.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/uv_mesh.vert")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core" TYPE PROGRAM FILES
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alpha_colored_mesh.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alpha_colored_mesh.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alpha_colored_per_triangle_normals.geom"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alpha_colored_per_triangle_normals.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alpha_colored_per_vertex_normals.geom"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alpha_colored_per_vertex_normals.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alpha_points.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alpha_points.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alpha_uv_tex.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alpha_uv_tex_array.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alphaimgview.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alphaimgview.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/anaglyph.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/anaglyph.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/axisgizmo.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/axisgizmo.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/camstub.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/camstub.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/depth.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/depth.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/depthonly.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/depthonly.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/image_viewer.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/image_viewer.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/mesh_color.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/mesh_color.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/mesh_debugview.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/mesh_debugview.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/mesh_normal.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/mesh_normal.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/number.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/number.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/skybox.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/skybox.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/text-imgui.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/text-imgui.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/texture.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/texture.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/topview.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/topview.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/uv_mesh.vert"
      )
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alpha_colored_mesh.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alpha_colored_mesh.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alpha_colored_per_triangle_normals.geom;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alpha_colored_per_triangle_normals.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alpha_colored_per_vertex_normals.geom;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alpha_colored_per_vertex_normals.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alpha_points.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alpha_points.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alpha_uv_tex.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alpha_uv_tex_array.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alphaimgview.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alphaimgview.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/anaglyph.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/anaglyph.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/axisgizmo.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/axisgizmo.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/camstub.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/camstub.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/depth.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/depth.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/depthonly.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/depthonly.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/image_viewer.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/image_viewer.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/mesh_color.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/mesh_color.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/mesh_debugview.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/mesh_debugview.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/mesh_normal.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/mesh_normal.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/number.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/number.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/skybox.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/skybox.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/text-imgui.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/text-imgui.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/texture.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/texture.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/topview.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/topview.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/uv_mesh.vert")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core" TYPE PROGRAM FILES
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alpha_colored_mesh.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alpha_colored_mesh.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alpha_colored_per_triangle_normals.geom"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alpha_colored_per_triangle_normals.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alpha_colored_per_vertex_normals.geom"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alpha_colored_per_vertex_normals.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alpha_points.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alpha_points.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alpha_uv_tex.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alpha_uv_tex_array.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alphaimgview.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alphaimgview.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/anaglyph.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/anaglyph.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/axisgizmo.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/axisgizmo.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/camstub.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/camstub.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/depth.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/depth.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/depthonly.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/depthonly.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/image_viewer.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/image_viewer.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/mesh_color.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/mesh_color.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/mesh_debugview.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/mesh_debugview.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/mesh_normal.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/mesh_normal.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/number.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/number.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/skybox.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/skybox.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/text-imgui.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/text-imgui.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/texture.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/texture.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/topview.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/topview.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/uv_mesh.vert"
      )
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alpha_colored_mesh.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alpha_colored_mesh.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alpha_colored_per_triangle_normals.geom;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alpha_colored_per_triangle_normals.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alpha_colored_per_vertex_normals.geom;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alpha_colored_per_vertex_normals.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alpha_points.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alpha_points.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alpha_uv_tex.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alpha_uv_tex_array.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alphaimgview.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/alphaimgview.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/anaglyph.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/anaglyph.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/axisgizmo.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/axisgizmo.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/camstub.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/camstub.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/depth.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/depth.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/depthonly.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/depthonly.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/image_viewer.frag;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/image_viewer.vert;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/mesh_color.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/mesh_color.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/mesh_debugview.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/mesh_debugview.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/mesh_normal.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/mesh_normal.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/number.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/number.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/skybox.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/skybox.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/text-imgui.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/text-imgui.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/texture.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/texture.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/topview.fp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/topview.vp;C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core/uv_mesh.vert")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "C:/Users/user/gaussian-splatting/SIBR_viewers/install/shaders/core" TYPE PROGRAM FILES
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alpha_colored_mesh.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alpha_colored_mesh.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alpha_colored_per_triangle_normals.geom"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alpha_colored_per_triangle_normals.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alpha_colored_per_vertex_normals.geom"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alpha_colored_per_vertex_normals.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alpha_points.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alpha_points.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alpha_uv_tex.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alpha_uv_tex_array.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alphaimgview.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/alphaimgview.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/anaglyph.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/anaglyph.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/axisgizmo.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/axisgizmo.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/camstub.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/camstub.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/depth.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/depth.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/depthonly.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/depthonly.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/image_viewer.frag"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/image_viewer.vert"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/mesh_color.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/mesh_color.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/mesh_debugview.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/mesh_debugview.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/mesh_normal.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/mesh_normal.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/number.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/number.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/skybox.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/skybox.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/text-imgui.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/text-imgui.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/texture.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/texture.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/topview.fp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/topview.vp"
      "C:/Users/user/gaussian-splatting/SIBR_viewers/src/core/view/shaders/uv_mesh.vert"
      )
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/user/gaussian-splatting/SIBR_viewers/install/lib/sibr_view_rwdi.lib")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "C:/Users/user/gaussian-splatting/SIBR_viewers/install/lib" TYPE STATIC_LIBRARY OPTIONAL FILES "C:/Users/user/gaussian-splatting/SIBR_viewers/install/lib/sibr_view_rwdi.lib")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/sibr_view_rwdi.dll")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin" TYPE SHARED_LIBRARY FILES "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/sibr_view_rwdi.dll")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/user/gaussian-splatting/SIBR_viewers/install/lib/sibr_view.lib")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "C:/Users/user/gaussian-splatting/SIBR_viewers/install/lib" TYPE STATIC_LIBRARY OPTIONAL FILES "C:/Users/user/gaussian-splatting/SIBR_viewers/install/lib/sibr_view.lib")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/sibr_view.dll")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin" TYPE SHARED_LIBRARY FILES "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/sibr_view.dll")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/user/gaussian-splatting/SIBR_viewers/install/lib/sibr_view_d.lib")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "C:/Users/user/gaussian-splatting/SIBR_viewers/install/lib" TYPE STATIC_LIBRARY OPTIONAL FILES "C:/Users/user/gaussian-splatting/SIBR_viewers/install/lib/sibr_view_d.lib")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/sibr_view_d.dll")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin" TYPE SHARED_LIBRARY FILES "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/sibr_view_d.dll")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/sibr_view_rwdi.pdb")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin" TYPE FILE OPTIONAL FILES "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/sibr_view_rwdi.pdb")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/sibr_view_d.pdb")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin" TYPE FILE OPTIONAL FILES "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/sibr_view_d.pdb")
  endif()
endif()

