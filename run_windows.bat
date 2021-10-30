@echo off

Rem We need a separate build script for Windows since it does not yet have a way to locate
Rem installed packages such as Skia or GLFW. The flags here aim to replace pkg-config.
Rem It's recommended to remove .build after editing this file to make sure that new linker settings
Rem are applied.

Rem For Skia, we need two include paths: one for Loftwing and one for Skia headers themselves
Rem to include other headers.

if "%1" == "" goto missingConfiguration
mkdir .build\x86_64-unknown-windows-msvc\%1\
copy Windows\skia\libskia.dll .build\x86_64-unknown-windows-msvc\%1\libskia.dll
swift run -c %1 -Xcc -IWindows\skia\include -Xcc -IWindows\skia\include\skia_loftwing -Xcc -IWindows\glfw\include -Xlinker -L -Xlinker Windows\glfw -Xswiftc -llibskia -Xlinker -L -Xlinker Windows\skia -v -Xswiftc -Xfrontend -Xswiftc -validate-tbd-against-ir=none
goto end
:missingConfiguration
echo "Usage: run_windows.bat [debug, release]"
:end
