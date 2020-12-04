@echo off

call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat" x64

mkdir ..\..\build
pushd ..\..\build
set PWD=%~dp0
echo %PWD%
cl -Zi ../HandmadeMonster/code/win32_handmade.cpp user32.lib
popd