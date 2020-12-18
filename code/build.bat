@echo off

call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat" x64

set CommonCompilerFlags=-MT -nologo -Gm- -GR- -EHa- -Od -Oi -W4 -wd4201 -wd4100 -wd4189 -DHANDMADE_INTERNAL=1 -DHANDMADE_SLOW=1 -DHANDMADE_WIN32=1 -FC -Z7 -Fmwin32_handmade.map
set CommonLinkerFlags= -opt:ref user32.lib gdi32.lib winmm.lib


IF NOT EXIST ..\build mkdir ..\build
pushd ..\build
cl %CommonCompilerFlags% ../code/win32_handmade.cpp /link %CommonLinkerFlags%
popd

echo ----------------------
echo ** Complile Succeed **