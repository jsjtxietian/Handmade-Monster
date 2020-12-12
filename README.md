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