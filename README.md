# Handmade monster

 study note of [Handmade Hero](https://handmadehero.org/)

#### day3,  用define来标志不同static的语义

```c++
#define internal static
#define local_persist static
#define global_variable static
```

#### day5

[Pointer aliasing - Wikipedia](https://en.wikipedia.org/wiki/Pointer_aliasing)

#### day6，用define作为辅助定义相同的函数类型，从代码load dll，失败则利用桩函数。

```c++
#define X_INPUT_GET_STATE(name) DWORD WINAPI name(DWORD dwUserIndex, XINPUT_STATE *pState)
typedef X_INPUT_GET_STATE(x_input_get_state);
X_INPUT_GET_STATE(XInputGetStateStub)
{
    return (ERROR_DEVICE_NOT_CONNECTED);
}
global_variable x_input_get_state *XInputGetState_ = XInputGetStateStub;
#define XInputGetState XInputGetState_

internal void
Win32LoadXInput(void)
{
    HMODULE XInputLibrary = LoadLibraryA("xinput1_3.dll");
    if (XInputLibrary)
    {
        XInputGetState = (x_input_get_state *)GetProcAddress(XInputLibrary, "XInputGetState");
        if (!XInputGetState)
        {
            XInputGetState = XInputGetStateStub;
        }
    }
}
```

#### day9 声音

* DirectSound，注意PlayCursor & WriteCursor，延迟(Audio latency) is determined not by the size of the buffer, but by how far ahead of the PlayCursor you write. The optimal amount of latency is the amount that will cause this frame's audio to coincide with the display of this frame's image. On most platforms, it is very difficult to ascertain the proper amount of latency. It's an unsolved problem, and games with need precise AV sync (like Guitar Hero) go to some lengths to achieve it.
* 定点数，https://zhuanlan.zhihu.com/p/149517485
* 注意手柄的dead zone

#### day10 时间

* Wall clock time，QueryPerformanceCounter，To time a frame, only query the timer once per frame, otherwise your timer will leave out time between last frame's end and this frame's start.
* Processor time，RDTSC，Every x86 family proccessor has a [Timestamp Counter (TSC)](http://en.wikipedia.org/wiki/Time_Stamp_Counter), which increments with every clock cycle since it was reset. RDTSC is a processor intruction that reads the TSC into general purpose registers. For processors before Sandy Bridge but after dynamic clocking, RDTSC gave us actual clocks, Since Sandy Bridge, they give us "nominal" clocks, which is to say the number of clocks elapsed at the chip's nominal frequency. 较新可以使用**RDTSCP**（不受乱序影响，还能返回一个 pid）
* [Acquiring high-resolution time stamps - Win32 apps | Microsoft Docs](https://docs.microsoft.com/en-us/windows/win32/sysinfo/acquiring-high-resolution-time-stamps)
* milo的精度做法：[nativejson-benchmark/timer.h at master · miloyip/nativejson-benchmark (github.com)](https://github.com/miloyip/nativejson-benchmark/blob/master/src/timer.h)，cherno的做法：C++11的high_resolution_clock
* An [intrinsic](http://en.wikipedia.org/wiki/Intrinsic_function) is a compiler-specific extension that allows direct invocation of some processor instruction. They generally need to be extensions to the compiler so they can avoid all the expensive niceties compilers have to afford functions.
* 一些优化文章和参考，[Software optimization resources. C++ and assembly. Windows, Linux, BSD, Mac OS X (agner.org)](https://www.agner.org/optimize/)
* float和double的精度问题，[eelpi.gotdns.org/blog.wiki.html](http://eelpi.gotdns.org/blog.wiki.html)


#### day11
* Unity build
  * [Unity build - Wikipedia](https://en.wikipedia.org/wiki/Unity_build)
  * [c++ - #include all .cpp files into a single compilation unit? - Stack Overflow](https://stackoverflow.com/questions/543697/include-all-cpp-files-into-a-single-compilation-unit)
  * [The Evils of Unity Builds | Engineering Game Development (archive.org)](http://web.archive.org/web/20161021225056/https://engineering-game-dev.com/2009/12/15/the-evils-of-unity-builds/)
* style 1:Virtualise the os to the game，“more expressive interface than necessary”，因为OS很复杂，让简单的(Game)成为service 
* style 2: Game as service to OS，让Game提供给OS渲染画面、声音等

#### day12 Platform-independent Sound Output
* Sound is necessarily temporal. You can drop a frame of video and the user probably won't notice, but if your audio drops out, they probably will notice. Sound bufers are small, and not all platforms will require us to deal with circular buffers. So one option is to do a buffer copy per frame and present the game with a contiguous block of memory. Much like the bitmap, allocate plenty of space for a sound buffer at startup, and reuse it each frame.
* **alloca/malloca** is a compiler feature that allows for dynamic allocation on the stack. Much was learned and discussed, but it should be noted that the function is deprecated and probably shouldn't be used in shipping code.

#### day13 Platform-independent User Input
* Input

  ```c++
  //对于某个按钮，一帧之内记录
  struct game_button_state
  {
      int HalfTransitionCount;
      bool32 EndedDown;
  };
  //对于某stick，记录
  real32 StartX;
  real32 MinX;
  real32 MaxX;
  real32 EndX;
  //union里套struct，提升
  union
  {
      game_button_state Buttons[6];
      struct
      {
          game_button_state Up;
          game_button_state Down;
          game_button_state Left;
          game_button_state Right;
          game_button_state LeftShoulder;
          game_button_state RightShoulder;
      };
  };
  ```
* 所有函数都是internal，给static提示编译器不用external linking

#### day14 Game Memory
* dynamic allocation spreads management across code， make it opaque; allocation is another trip through the platform layer(game as a service to platform). 

* Main Memory Pool is guranteed to run, instead of dynamic allocation.

* Integral promotion https://docs.microsoft.com/en-us/cpp/cpp/standard-conversions?view=msvc-160

  ```C++
  //LL防止溢出
  #define Kilobytes(Value) ((Value)*1024LL)
  
  //define assert(not complete)
  #define Assert(Expression) if(!(Expression)) {*(int *)0 = 0;}
  ```

  
