
@echo off
title S I G V E R S E  x86 Release
rem --------------------------------------------------------
rem This is a script-generated file! Edit at your own risk!
rem --------------------------------------------------------
set SIGVERSE_ROOT="K:\dev\SIGVerse\test"
echo Checking for JDK path...
call K:\dev\SIGVerse\SIGViewer\scripts\find_jdk.bat
set CMAKE="C:\Program Files\CMake\bin\cmake.exe"
set VS_VERSION="Visual Studio 14 2015"
set SIGSERVICE_ROOT_PATH="K:\dev\SIGVerse\test\SIGService"
if not exist %SIGSERVICE_ROOT_PATH% (
  echo SIGSERVICE_ROOT_PATH directory could not be found: %SIGSERVICE_ROOT_PATH%
  goto error
)
set LIBOVR_ROOT_PATH="K:\dev\SIGVerse\test\extern\OculusSDK.0.4.3\LibOVR"
if not exist %LIBOVR_ROOT_PATH% (
  echo LIBOVR_ROOT_PATH directory could not be found: %LIBOVR_ROOT_PATH%
  goto error
)
set BOOST_ROOT="K:\dev\SIGVerse\test\extern\boost_1_61_0"
if not exist %BOOST_ROOT% (
  echo BOOST_ROOT directory could not be found: %BOOST_ROOT%
  goto error
)
set OGRE_SDK="K:\dev\SIGVerse\test\extern\OGRE-SDK-1.9.0-vc140-x86-12.03.2016"
if not exist %OGRE_SDK% (
  echo OGRE_SDK directory could not be found: %OGRE_SDK%
  goto error
)
set CEGUI_ROOT_PATH="K:\dev\SIGVerse\test\extern\cegui-0.8.7"
if not exist %CEGUI_ROOT_PATH% (
  echo CEGUI_ROOT_PATH directory could not be found: %CEGUI_ROOT_PATH%
  goto error
)
set X3D_ROOT_PATH="K:\dev\SIGVerse\test\X3D"
if not exist %X3D_ROOT_PATH% (
  echo X3D_ROOT_PATH directory could not be found: %X3D_ROOT_PATH%
  goto error
)
set CEGUI_DEPS_ROOT="K:\dev\SIGVerse\test\extern\cegui-deps-0.8.x-src"
if not exist %CEGUI_DEPS_ROOT% (
  echo CEGUI_DEPS_ROOT directory could not be found: %CEGUI_DEPS_ROOT%
  goto error
)
set GLEW_ROOT_PATH="K:\dev\SIGVerse\test\extern\glew-2.0.0"
if not exist %GLEW_ROOT_PATH% (
  echo GLEW_ROOT_PATH directory could not be found: %GLEW_ROOT_PATH%
  goto error
)
set VS_TOOLS_PATH="C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\Tools\"
if not exist %VS_TOOLS_PATH% (
  echo VS_TOOLS_PATH directory could not be found: %VS_TOOLS_PATH%
  goto error
)
set OPENSSL_ROOT_DIR="K:\dev\SIGVerse\test\extern\openssl-0.9.8k_WIN32"
if not exist %OPENSSL_ROOT_DIR% (
  echo OPENSSL_ROOT_DIR directory could not be found: %OPENSSL_ROOT_DIR%
  goto error
)
set LIBSSH2_ROOT_PATH="K:\dev\SIGVerse\test\extern\libssh2-1.7.0"
if not exist %LIBSSH2_ROOT_PATH% (
  echo LIBSSH2_ROOT_PATH directory could not be found: %LIBSSH2_ROOT_PATH%
  goto error
)
rem Include Paths:
set SIGBUILD_SIGSERVICE_INC=K:\dev\SIGVerse\test\SIGService\Windows\SIGService
set SIGBUILD_X3D_INC=K:\dev\SIGVerse\test\X3D\parser\cpp\X3DParser
set SIGBUILD_OGRE_INC=K:\dev\SIGVerse\test\extern\OGRE-SDK-1.9.0-vc140-x86-12.03.2016\include
set SIGBUILD_BOOST_INC=K:\dev\SIGVerse\test\extern\boost_1_61_0
set SIGBUILD_CEGUI_INC=K:\dev\SIGVerse\test\extern\cegui-0.8.7\cegui\include
set SIGBUILD_LIBSSH2_INC=K:\dev\SIGVerse\test\extern\libssh2-1.7.0\include
set SIGBUILD_OPENSSL_INC=K:\dev\SIGVerse\test\extern\openssl-0.9.8k_WIN32\include
set SIGBUILD_LIBOVR_INC=K:\dev\SIGVerse\test\extern\OculusSDK.0.4.3\LibOVR\Include;K:\dev\SIGVerse\test\extern\OculusSDK.0.4.3\LibOVR\LibOVRKernel\Src
rem Library Paths:
set SIGBUILD_SIGSERVICE_LIB=K:\dev\SIGVerse\test\SIGService\Windows\Release_2010
set SIGBUILD_X3D_LIB=K:\dev\SIGVerse\test\X3D\parser\cpp\Release
set SIGBUILD_OGRE_LIB=K:\dev\SIGVerse\test\extern\OGRE-SDK-1.9.0-vc140-x86-12.03.2016\lib
set SIGBUILD_BOOST_LIB=K:\dev\SIGVerse\test\extern\boost_1_61_0\stage\lib
set SIGBUILD_CEGUI_LIB=K:\dev\SIGVerse\test\extern\cegui-0.8.7\lib;K:\dev\SIGVerse\test\extern\cegui-0.8.7\dependencies\lib\static
set SIGBUILD_LIBSSH2_LIB=K:\dev\SIGVerse\test\extern\libssh2-1.7.0\build\src\Release
set SIGBUILD_OPENSSL_LIB=K:\dev\SIGVerse\test\extern\openssl-0.9.8k_WIN32\lib
set SIGBUILD_ZLIB_LIB=K:\dev\SIGVerse\test\extern\cegui-0.8.7\dependencies\lib\static
set SIGBUILD_LIBOVR_LIB=K:\dev\SIGVerse\test\extern\OculusSDK.0.4.3\LibOVR\Lib\Windows\Win32\Release\VS2015
set SIGBUILD_GLEW_LIB=K:\dev\SIGVerse\test\extern\glew-2.0.0\lib\Release\Win32
call %VS_TOOLS_PATH%\VsDevCmd.bat
if errorlevel 0 goto end
:error
exit /B 1
:end
