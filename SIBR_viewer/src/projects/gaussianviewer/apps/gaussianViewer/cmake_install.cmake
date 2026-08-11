# Install script for directory: C:/Users/user/gaussian-splatting/SIBR_viewers/src/projects/gaussianviewer/apps/gaussianViewer

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

if(CMAKE_INSTALL_COMPONENT STREQUAL "SIBR_gaussianViewer_app_install" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/SIBR_gaussianViewer_app_rwdi.exe")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin" TYPE EXECUTABLE FILES "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/SIBR_gaussianViewer_app_rwdi.exe")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "SIBR_gaussianViewer_app_install" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/SIBR_gaussianViewer_app.exe")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin" TYPE EXECUTABLE FILES "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/SIBR_gaussianViewer_app.exe")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "SIBR_gaussianViewer_app_install" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/SIBR_gaussianViewer_app_d.exe")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin" TYPE EXECUTABLE FILES "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/SIBR_gaussianViewer_app_d.exe")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/SIBR_gaussianViewer_app_rwdi.pdb")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin" TYPE FILE OPTIONAL FILES "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/SIBR_gaussianViewer_app_rwdi.pdb")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/SIBR_gaussianViewer_app_d.pdb")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin" TYPE FILE OPTIONAL FILES "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/SIBR_gaussianViewer_app_d.pdb")
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "SIBR_gaussianViewer_app_install" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ww][Ii][Tt][Hh][Dd][Ee][Bb][Ii][Nn][Ff][Oo])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/msvcp140.dll;C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/msvcp140_1.dll;C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/msvcp140_2.dll;C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/msvcp140_atomic_wait.dll;C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/msvcp140_codecvt_ids.dll;C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/vcruntime140_1.dll;C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/vcruntime140.dll;C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/concrt140.dll")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin" TYPE FILE FILES
      "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Redist/MSVC/14.38.33130/x64/Microsoft.VC143.CRT/msvcp140.dll"
      "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Redist/MSVC/14.38.33130/x64/Microsoft.VC143.CRT/msvcp140_1.dll"
      "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Redist/MSVC/14.38.33130/x64/Microsoft.VC143.CRT/msvcp140_2.dll"
      "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Redist/MSVC/14.38.33130/x64/Microsoft.VC143.CRT/msvcp140_atomic_wait.dll"
      "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Redist/MSVC/14.38.33130/x64/Microsoft.VC143.CRT/msvcp140_codecvt_ids.dll"
      "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Redist/MSVC/14.38.33130/x64/Microsoft.VC143.CRT/vcruntime140_1.dll"
      "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Redist/MSVC/14.38.33130/x64/Microsoft.VC143.CRT/vcruntime140.dll"
      "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Redist/MSVC/14.38.33130/x64/Microsoft.VC143.CRT/concrt140.dll"
      )
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "SIBR_gaussianViewer_app_install" OR NOT CMAKE_INSTALL_COMPONENT)
  set(target 						"SIBR_gaussianViewer_app")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "SIBR_gaussianViewer_app_install" OR NOT CMAKE_INSTALL_COMPONENT)
  set(inst_run_CONFIG_TYPE 			"RelWithDebInfo")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "SIBR_gaussianViewer_app_install" OR NOT CMAKE_INSTALL_COMPONENT)
  set(inst_run_INSTALL_FOLDER 		"C:/Users/user/gaussian-splatting/SIBR_viewers/install")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "SIBR_gaussianViewer_app_install" OR NOT CMAKE_INSTALL_COMPONENT)
  set(app	 						"C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/SIBR_gaussianViewer_app_rwdi.exe")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "SIBR_gaussianViewer_app_install" OR NOT CMAKE_INSTALL_COMPONENT)
  set(dirsToLookFor 				"C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/boost/boost-1.71/lib64-msvc-14.1;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/assimp/Assimp-4.1.0/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/glew/glew-2.0.0/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/opencv/install/x64/vc17/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/boost/boost-1.71;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/assimp/Assimp-4.1.0;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/glew/glew-2.0.0;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/glew/glew-2.0.0/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/glew/glew-2.0.0/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/assimp/Assimp-4.1.0/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/assimp/Assimp-4.1.0/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/bin/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/bin/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/bin/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/doc;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/doc/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/doc/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/doc/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/examples;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/examples/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/examples/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/examples/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/include;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/include/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/include/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/include/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/lib/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/lib/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/lib/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/presets;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/presets/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/presets/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/presets/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/embree3/embree-3.6.1.x64.vc14.windows;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/embree3/embree-3.6.1.x64.vc14.windows/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/embree3/embree-3.6.1.x64.vc14.windows/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/embree3/embree-3.6.1.x64.vc14.windows/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/eigen3/eigen;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/eigen3/eigen/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/eigen3/eigen/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/eigen3/eigen/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/boost/boost-1.71/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/boost/boost-1.71/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/boost/boost-1.71/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/boost;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/nativefiledialog/nfd;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/nativefiledialog/nfd/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/nativefiledialog/nfd/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/nativefiledialog/nfd/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/opencv/install;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/opencv/install/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/opencv/install/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/opencv/install/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/glfw/glfw-3.2.1;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/glfw/glfw-3.2.1/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/glfw/glfw-3.2.1/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/glfw/glfw-3.2.1/bin")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "SIBR_gaussianViewer_app_install" OR NOT CMAKE_INSTALL_COMPONENT)
  			if("${CMAKE_INSTALL_CONFIG_NAME}" STREQUAL "${inst_run_CONFIG_TYPE}")
				message(STATUS "Installing ${target} dependencies...")

				file(GET_RUNTIME_DEPENDENCIES
					EXECUTABLES ${app}
					RESOLVED_DEPENDENCIES_VAR _r_deps
					UNRESOLVED_DEPENDENCIES_VAR _u_deps
					CONFLICTING_DEPENDENCIES_PREFIX _c_deps
					DIRECTORIES ${dirsToLookFor}
					PRE_EXCLUDE_REGEXES "api-ms-*"
					POST_EXCLUDE_REGEXES ".*system32/.*\\.dll" ".*SysWOW64/.*\\.dll"
				)
			
				if(_u_deps)
					message(WARNING "There were unresolved dependencies for executable ${EXEC_FILE}: \"${_u_deps}\"!")
				endif()
				if(_c_deps_FILENAMES)
					message(WARNING "There were conflicting dependencies for executable ${EXEC_FILE}: \"${_c_deps_FILENAMES}\"!")
				endif()
			
				foreach(_file ${_r_deps})
					file(INSTALL
					DESTINATION "${inst_run_INSTALL_FOLDER}/bin"
					TYPE SHARED_LIBRARY
					FOLLOW_SYMLINK_CHAIN
					FILES "${_file}"
				)
				endforeach()
			endif()
		
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "SIBR_gaussianViewer_app_install" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/msvcp140.dll;C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/msvcp140_1.dll;C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/msvcp140_2.dll;C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/msvcp140_atomic_wait.dll;C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/msvcp140_codecvt_ids.dll;C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/vcruntime140_1.dll;C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/vcruntime140.dll;C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/concrt140.dll")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin" TYPE FILE FILES
      "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Redist/MSVC/14.38.33130/x64/Microsoft.VC143.CRT/msvcp140.dll"
      "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Redist/MSVC/14.38.33130/x64/Microsoft.VC143.CRT/msvcp140_1.dll"
      "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Redist/MSVC/14.38.33130/x64/Microsoft.VC143.CRT/msvcp140_2.dll"
      "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Redist/MSVC/14.38.33130/x64/Microsoft.VC143.CRT/msvcp140_atomic_wait.dll"
      "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Redist/MSVC/14.38.33130/x64/Microsoft.VC143.CRT/msvcp140_codecvt_ids.dll"
      "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Redist/MSVC/14.38.33130/x64/Microsoft.VC143.CRT/vcruntime140_1.dll"
      "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Redist/MSVC/14.38.33130/x64/Microsoft.VC143.CRT/vcruntime140.dll"
      "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Redist/MSVC/14.38.33130/x64/Microsoft.VC143.CRT/concrt140.dll"
      )
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "SIBR_gaussianViewer_app_install" OR NOT CMAKE_INSTALL_COMPONENT)
  set(target 						"SIBR_gaussianViewer_app")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "SIBR_gaussianViewer_app_install" OR NOT CMAKE_INSTALL_COMPONENT)
  set(inst_run_CONFIG_TYPE 			"Release")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "SIBR_gaussianViewer_app_install" OR NOT CMAKE_INSTALL_COMPONENT)
  set(inst_run_INSTALL_FOLDER 		"C:/Users/user/gaussian-splatting/SIBR_viewers/install")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "SIBR_gaussianViewer_app_install" OR NOT CMAKE_INSTALL_COMPONENT)
  set(app	 						"C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/SIBR_gaussianViewer_app.exe")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "SIBR_gaussianViewer_app_install" OR NOT CMAKE_INSTALL_COMPONENT)
  set(dirsToLookFor 				"C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/boost/boost-1.71/lib64-msvc-14.1;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/assimp/Assimp-4.1.0/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/glew/glew-2.0.0/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/opencv/install/x64/vc17/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/boost/boost-1.71;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/assimp/Assimp-4.1.0;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/glew/glew-2.0.0;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/glew/glew-2.0.0/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/glew/glew-2.0.0/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/assimp/Assimp-4.1.0/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/assimp/Assimp-4.1.0/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/bin/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/bin/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/bin/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/doc;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/doc/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/doc/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/doc/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/examples;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/examples/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/examples/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/examples/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/include;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/include/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/include/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/include/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/lib/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/lib/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/lib/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/presets;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/presets/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/presets/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/presets/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/embree3/embree-3.6.1.x64.vc14.windows;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/embree3/embree-3.6.1.x64.vc14.windows/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/embree3/embree-3.6.1.x64.vc14.windows/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/embree3/embree-3.6.1.x64.vc14.windows/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/eigen3/eigen;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/eigen3/eigen/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/eigen3/eigen/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/eigen3/eigen/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/boost/boost-1.71/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/boost/boost-1.71/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/boost/boost-1.71/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/boost;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/nativefiledialog/nfd;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/nativefiledialog/nfd/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/nativefiledialog/nfd/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/nativefiledialog/nfd/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/opencv/install;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/opencv/install/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/opencv/install/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/opencv/install/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/glfw/glfw-3.2.1;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/glfw/glfw-3.2.1/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/glfw/glfw-3.2.1/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/glfw/glfw-3.2.1/bin")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "SIBR_gaussianViewer_app_install" OR NOT CMAKE_INSTALL_COMPONENT)
  			if("${CMAKE_INSTALL_CONFIG_NAME}" STREQUAL "${inst_run_CONFIG_TYPE}")
				message(STATUS "Installing ${target} dependencies...")

				file(GET_RUNTIME_DEPENDENCIES
					EXECUTABLES ${app}
					RESOLVED_DEPENDENCIES_VAR _r_deps
					UNRESOLVED_DEPENDENCIES_VAR _u_deps
					CONFLICTING_DEPENDENCIES_PREFIX _c_deps
					DIRECTORIES ${dirsToLookFor}
					PRE_EXCLUDE_REGEXES "api-ms-*"
					POST_EXCLUDE_REGEXES ".*system32/.*\\.dll" ".*SysWOW64/.*\\.dll"
				)
			
				if(_u_deps)
					message(WARNING "There were unresolved dependencies for executable ${EXEC_FILE}: \"${_u_deps}\"!")
				endif()
				if(_c_deps_FILENAMES)
					message(WARNING "There were conflicting dependencies for executable ${EXEC_FILE}: \"${_c_deps_FILENAMES}\"!")
				endif()
			
				foreach(_file ${_r_deps})
					file(INSTALL
					DESTINATION "${inst_run_INSTALL_FOLDER}/bin"
					TYPE SHARED_LIBRARY
					FOLLOW_SYMLINK_CHAIN
					FILES "${_file}"
				)
				endforeach()
			endif()
		
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "SIBR_gaussianViewer_app_install" OR NOT CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Dd][Ee][Bb][Uu][Gg])$")
    list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
     "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/msvcp140.dll;C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/msvcp140_1.dll;C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/msvcp140_2.dll;C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/msvcp140_atomic_wait.dll;C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/msvcp140_codecvt_ids.dll;C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/vcruntime140_1.dll;C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/vcruntime140.dll;C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/concrt140.dll")
    if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
      message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
    endif()
    file(INSTALL DESTINATION "C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin" TYPE FILE FILES
      "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Redist/MSVC/14.38.33130/x64/Microsoft.VC143.CRT/msvcp140.dll"
      "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Redist/MSVC/14.38.33130/x64/Microsoft.VC143.CRT/msvcp140_1.dll"
      "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Redist/MSVC/14.38.33130/x64/Microsoft.VC143.CRT/msvcp140_2.dll"
      "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Redist/MSVC/14.38.33130/x64/Microsoft.VC143.CRT/msvcp140_atomic_wait.dll"
      "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Redist/MSVC/14.38.33130/x64/Microsoft.VC143.CRT/msvcp140_codecvt_ids.dll"
      "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Redist/MSVC/14.38.33130/x64/Microsoft.VC143.CRT/vcruntime140_1.dll"
      "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Redist/MSVC/14.38.33130/x64/Microsoft.VC143.CRT/vcruntime140.dll"
      "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Redist/MSVC/14.38.33130/x64/Microsoft.VC143.CRT/concrt140.dll"
      )
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "SIBR_gaussianViewer_app_install" OR NOT CMAKE_INSTALL_COMPONENT)
  set(target 						"SIBR_gaussianViewer_app")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "SIBR_gaussianViewer_app_install" OR NOT CMAKE_INSTALL_COMPONENT)
  set(inst_run_CONFIG_TYPE 			"Debug")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "SIBR_gaussianViewer_app_install" OR NOT CMAKE_INSTALL_COMPONENT)
  set(inst_run_INSTALL_FOLDER 		"C:/Users/user/gaussian-splatting/SIBR_viewers/install")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "SIBR_gaussianViewer_app_install" OR NOT CMAKE_INSTALL_COMPONENT)
  set(app	 						"C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin/SIBR_gaussianViewer_app_d.exe")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "SIBR_gaussianViewer_app_install" OR NOT CMAKE_INSTALL_COMPONENT)
  set(dirsToLookFor 				"C:/Users/user/gaussian-splatting/SIBR_viewers/install/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/boost/boost-1.71/lib64-msvc-14.1;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/assimp/Assimp-4.1.0/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/glew/glew-2.0.0/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/opencv/install/x64/vc17/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/boost/boost-1.71;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/assimp/Assimp-4.1.0;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/glew/glew-2.0.0;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/glew/glew-2.0.0/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/glew/glew-2.0.0/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/assimp/Assimp-4.1.0/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/assimp/Assimp-4.1.0/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/bin/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/bin/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/bin/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/doc;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/doc/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/doc/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/doc/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/examples;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/examples/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/examples/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/examples/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/include;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/include/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/include/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/include/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/lib/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/lib/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/lib/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/presets;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/presets/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/presets/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/ffmpeg/presets/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/embree3/embree-3.6.1.x64.vc14.windows;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/embree3/embree-3.6.1.x64.vc14.windows/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/embree3/embree-3.6.1.x64.vc14.windows/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/embree3/embree-3.6.1.x64.vc14.windows/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/eigen3/eigen;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/eigen3/eigen/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/eigen3/eigen/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/eigen3/eigen/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/boost/boost-1.71/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/boost/boost-1.71/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/boost/boost-1.71/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/boost;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/nativefiledialog/nfd;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/nativefiledialog/nfd/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/nativefiledialog/nfd/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/nativefiledialog/nfd/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/opencv/install;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/opencv/install/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/opencv/install/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/opencv/install/bin;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/glfw/glfw-3.2.1;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/glfw/glfw-3.2.1/lib;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/glfw/glfw-3.2.1/lib64;C:/Users/user/gaussian-splatting/SIBR_viewers/extlibs/glfw/glfw-3.2.1/bin")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "SIBR_gaussianViewer_app_install" OR NOT CMAKE_INSTALL_COMPONENT)
  			if("${CMAKE_INSTALL_CONFIG_NAME}" STREQUAL "${inst_run_CONFIG_TYPE}")
				message(STATUS "Installing ${target} dependencies...")

				file(GET_RUNTIME_DEPENDENCIES
					EXECUTABLES ${app}
					RESOLVED_DEPENDENCIES_VAR _r_deps
					UNRESOLVED_DEPENDENCIES_VAR _u_deps
					CONFLICTING_DEPENDENCIES_PREFIX _c_deps
					DIRECTORIES ${dirsToLookFor}
					PRE_EXCLUDE_REGEXES "api-ms-*"
					POST_EXCLUDE_REGEXES ".*system32/.*\\.dll" ".*SysWOW64/.*\\.dll"
				)
			
				if(_u_deps)
					message(WARNING "There were unresolved dependencies for executable ${EXEC_FILE}: \"${_u_deps}\"!")
				endif()
				if(_c_deps_FILENAMES)
					message(WARNING "There were conflicting dependencies for executable ${EXEC_FILE}: \"${_c_deps_FILENAMES}\"!")
				endif()
			
				foreach(_file ${_r_deps})
					file(INSTALL
					DESTINATION "${inst_run_INSTALL_FOLDER}/bin"
					TYPE SHARED_LIBRARY
					FOLLOW_SYMLINK_CHAIN
					FILES "${_file}"
				)
				endforeach()
			endif()
		
endif()

