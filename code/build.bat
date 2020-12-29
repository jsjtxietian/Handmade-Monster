@echo off

call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat" x64

REM Optimization switches /O2
set CommonCompilerFlags=-MTd -nologo -fp:fast -Gm- -GR- -EHa- -Od -Oi -W4 -wd4201 -wd4100 -wd4189 -wd4505 -DHANDMADE_INTERNAL=1 -DHANDMADE_SLOW=1 -DHANDMADE_WIN32=1 -FC -Z7
set CommonLinkerFlags= -incremental:no -opt:ref user32.lib gdi32.lib winmm.lib


IF NOT EXIST ..\build mkdir ..\build

pushd ..\build

del *.pdb > NUL 2> NUL

echo WAITING FOR PDB > lock.tmp
cl %CommonCompilerFlags% ../code/handmade.cpp -Fmhandmade.map -LD /link -incremental:no -opt:ref -PDB:handmade_%random%.pdb -EXPORT:GameGetSoundSamples -EXPORT:GameUpdateAndRender
del lock.tmp

cl %CommonCompilerFlags% ../code/win32_handmade.cpp -Fmwin32_handmade.map /link %CommonLinkerFlags%
popd

echo ----------------------
echo ** Complile Succeed ** 