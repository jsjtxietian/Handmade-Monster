# Handmade monster

 study note of [Handmade Hero](https://handmadehero.org/)

#### Intro to C

* [Semantic Compression (caseymuratori.com)](https://caseymuratori.com/blog_0015)
* 如何问问题：
  *  http://sscce.org/
  * http://www.catb.org/~esr/faqs/smart-questions.html
  * https://xyproblem.info/

#### day3

用define来标志不同static的语义

```c++
#define internal static
#define local_persist static
#define global_variable static
```

#### day5

[Pointer aliasing - Wikipedia](https://en.wikipedia.org/wiki/Pointer_aliasing)

[GCC 4 编译警告：warning: dereferencing type-punned pointer will break strict-aliasing rules 有什么比较好的解决办法？ - 知乎 (zhihu.com)](https://www.zhihu.com/question/19707376/answer/1174526354)

#### day6 XInput

用define作为辅助定义相同的函数类型，从代码load dll，失败则利用桩函数。

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
* Processor time，RDTSC，Every x86 family proccessor has a [Timestamp Counter (TSC)](http://en.wikipedia.org/wiki/Time_Stamp_Counter), which increments with every clock cycle since it was reset. RDTSC is a processor intruction that reads the TSC into general purpose registers. For processors before Sandy Bridge but after dynamic clocking, RDTSC gave us actual clocks, Since Sandy Bridge, they give us "nominal" clocks, which is to say the number of clocks elapsed at the chip's nominal frequency. 较新可以使用**RDTSCP**（不受乱序影响，还能返回一个 pid）**用来profile**
* [Acquiring high-resolution time stamps - Win32 apps | Microsoft Docs](https://docs.microsoft.com/en-us/windows/win32/sysinfo/acquiring-high-resolution-time-stamps)
* milo的精度做法：[nativejson-benchmark/timer.h at master · miloyip/nativejson-benchmark (github.com)](https://github.com/miloyip/nativejson-benchmark/blob/master/src/timer.h)，cherno的做法：C++11的high_resolution_clock
* An [intrinsic](http://en.wikipedia.org/wiki/Intrinsic_function) is a compiler-specific extension that allows direct invocation of some processor instruction. They generally need to be extensions to the compiler so they can avoid all the expensive niceties compilers have to afford functions.
* 一些优化文章和参考，[Software optimization resources. C++ and assembly. Windows, Linux, BSD, Mac OS X (agner.org)](https://www.agner.org/optimize/)
* float和double的精度问题，[eelpi.gotdns.org/blog.wiki.html](http://eelpi.gotdns.org/blog.wiki.html)


#### day11 游戏架构
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

#### day17 Unified Keyboard and Gamepad Input

4个控制器 + 键盘输入，共5个Input结构体，统一键盘和控制器输入。将DPAD隐射位stick(1)；记录stick的平均值，将stick的dash操作映射为MoveUp等。

```C++
struct game_controller_input
{
    bool32 IsConnected;
    bool32 IsAnalog;    
    real32 StickAverageX;
    real32 StickAverageY;
    
    union
    {
        game_button_state Buttons[12];
        struct
        {
            game_button_state MoveUp;
            game_button_state MoveDown;
            game_button_state MoveLeft;
            game_button_state MoveRight;
            
            game_button_state ActionUp;
            game_button_state ActionDown;
            game_button_state ActionLeft;
            game_button_state ActionRight;
            
            game_button_state LeftShoulder;
            game_button_state RightShoulder;

            game_button_state Back;
            game_button_state Start;
            
            game_button_state Terminator;
        };
    };
};
//12 和 struct的数量相对应；offsetof也可以
Assert((&Input->Controllers[0].Terminator - &Input->Controllers[0].Buttons[0]) == (ArrayCount(Input->Controllers[0].Buttons)));
```

#### day20 Audio Sync

* 几种处理audio的方式，always hit frame rate；overwrite the next frame，frame of lag；gurad thread。

* 一帧之内：gather Input => update the game (physics & render prep) => render => wait the flip (流水线)

* audio lag vs. Input lag，如果在第一帧渲染的同时就在另一个core上开启下一帧的Input & update，计算下一帧的声音，那么，等到下一帧的渲染结束并wait后，可能可以达到audio sync的效果（计算好声音到画面实际显示的时间大于一帧多）；但提前计算了Input，会导致Input lag

* audio clock和wall clock不一定同（PlayCursor和WriteCursor更新有延迟）

* Here is how sound output computation works. We define a safety value that is the number of samples we think our game update loop may vary by (let's say up to 2ms)

  When we wake up to write audio, we will look and see what the play cursor position is and we will forecast ahead where we think the play cursor will be on the next frame boundary.
  We will then look to see if the write cursor is before that by at least our safety value.  If it is, the target fill position is that frame boundary plus one frame.  This gives us perfect audio sync in the case of a card that has low enough latency.
  If the write cursor is _after_ that safety margin, then we assume we can never sync the audio perfectly, so we will write one frame's worth of audio plus the safety margin's worth of guard samples.
  对于低延迟，也就是WriteCursor在本帧之内，就从WriteCursor写到WriteCursor + SamplesPerFrame的那一帧的边界；对于高延迟，例如，write cursor在下帧，写到WriteCursor + SamplesPerFrame + SafetyMargin (small)

* keep code fluid and a little bit messy in early stages

#### day21 Load Game Code dynamically

* 因为Game as a service to platform，可以platform动态加载Game编译好的dll（memory等都是platform创建而传给Game的），Game要用platform的函数可以让platform传函数指针。
* dll，注意 extern "C" to prevent name mangling
* 不自己写dll读取函数的原因：希望debugger能自动拿到读取的dll的调试信息
* [Potential Errors Passing CRT Objects Across DLL Boundaries | Microsoft Docs](https://docs.microsoft.com/en-us/cpp/c-runtime-library/potential-errors-passing-crt-objects-across-dll-boundaries?redirectedfrom=MSDN&view=msvc-160)

#### day23 Looped Live Code Editing

* 每次reload dll的时候，vs会锁pdb文件，每次生成pbd加上时间戳（锁ddl可以靠copyfile重命名绕过）
* DSL或lua等脚本语言，与其发明个新语言，为啥不写个更好的C preprocessor（C也可以hot reload）
* 因为良好的架构，playback很简单，记下record开始时候的game memory（有相同的base address，因此指针之类也不用变）和之后所有的Input。C++的面向对象有vtable指针，没法直接用这个办法。
* [Address space layout randomization - Wikipedia](https://en.wikipedia.org/wiki/Address_space_layout_randomization)

#### day25 Clean up

* [Memory-mapped file - Wikipedia](https://en.wikipedia.org/wiki/Memory-mapped_file)
* [Direct memory access - Wikipedia](https://en.wikipedia.org/wiki/Direct_memory_access)

#### day26 Game Architecture

* 建筑的隐喻，UML as Blueprint，容易失败，耗时太长
* software designer as urban planner，malleable architecture，draw boundary
* temporal coupling；layout coupling； idealogical coupling；fluidity
* 在架构上，不给update和render阶段划boundaries（cache加速）。仅仅
  1. Input
  2. Update & Render Prep（and then sound prep）
  3. GPU
* Resources：Load 、Streaming
* Immediate mode（IMGUI），调用方不需要记住目标方的handle，不知道目标方的lifetime；Retained mode，
  * [Immediate mode GUI - Wikipedia](https://en.wikipedia.org/wiki/Immediate_mode_GUI)
  * [Retained mode - Wikipedia](https://en.wikipedia.org/wiki/Retained_mode)

#### day35 Tile Map

* Use floating point to store colors, because it will make it a lot more eaiser when we have to do some math about colors

* 帧时间也丢进Input里

* 判断移动和碰撞的时候，一个简单的办法，尝试减少移动步幅多移动几次（直接判断移动的目标是否valid会有这样的问题）

* 把tile的坐标打包进一个32位的int，map级和map内的

* https://software.intel.com/sites/landingpage/IntrinsicsGuide/

* 从persistent memory使用内存：

  ```c++
  #define PushStruct(Arena, type) (type *)PushSize_(Arena, sizeof(type))
  #define PushArray(Arena, Count, type) (type *)PushSize_(Arena, (Count)*sizeof(type))
  void * PushSize_(memory_arena *Arena, memory_index Size)
  {
      Assert((Arena->Used + Size) <= Arena->Size);
      void *Result = Arena->Base + Arena->Used;
      Arena->Used += Size;
      
      return(Result);
  }
  ```

* Use random.org to generate some random numbers and use them to generate screen randomly；Allocate space for tiles only when we access

* define和const，define没有type

#### day40 BMP

* use `#pragma pack(push, 1) and #pragma pack(pop)` to pack our struct correctly。bmp图片，前14个字节是文件信息头，紧接着是40个字节的图像信息头，不需要struct自动补齐
* Design a very specific BMP to help debug our rendering.  BMP byte order: should determined by masks
* Define `FindLeastSignificantSetBit` and `bit_scan_result` in intrinsics；Define `COMPILER_MSVC` and `COMPILER_LLVM` macro variables；Use `_BitScanForward` MSVC compiler intrinsic when we are using windows
* hot load，在编译游戏dll和pdb时，dll会先被编译好，然后几乎立马被读取，那时pdb很可能还没完成，导致vs无法加载新的pdb。解决方案：在编译时搞个lock file，在load dll的时候检测lockfile，如果在的话就等待。
* Write a `static_check` bat file to make sure we never type `static`
* Microsoft Spy++是一个非常好的查看Windows操作系统的窗口、消息、进程、线程信息的工具。
* RESOURCE: How do I switch a window between normal and fullscreen? https://devblogs.microsoft.com/oldnewthing/20100412-00/?p=14353

#### day50 Player Movement & Collision

* [Tagged union - Wikipedia](https://en.wikipedia.org/wiki/Tagged_union)

* [2006--degreve--reflection_refraction.pdf (stanford.edu)](https://graphics.stanford.edu/courses/cs148-10-summer/docs/2006--degreve--reflection_refraction.pdf) Reflect speed when player hits the wall (or make the speed align the wall). This can be implemented by a clever verctor math `v' = v - 2 * Inner(v, r) * r`. r means the vector of the reflecting direction.

* 如果检测**一帧**后会移动到的地方是不是有碰撞，player会stick against wall，会因为一直认为自己会撞进墙而卡住，撞墙的时候要考虑加速度和速度，速度依然指向墙内。

  * search in time：相对于只检测目标点是否碰撞，而是用检测碰撞点，然后把player移动到碰撞点，然后用normal和剩余的动量（否则会损失部分进入墙的动量）更新速度尝试移动，如果继续碰撞，设置一个最大循环次数。float精度问题：把player稍微从墙推开一些
  
* search in position：在目标点附近searchable set中检测最近的、可达（flood fill）的目标点。
  
* [_rotl, _rotl64, _rotr, _rotr64 | Microsoft Docs](https://docs.microsoft.com/en-us/cpp/c-runtime-library/reference/rotl-rotl64-rotr-rotr64?view=msvc-160)

* Minkowski sum

* 碰撞测试：

  * [Hyperplane separation theorem](https://link.zhihu.com/?target=http%3A//en.wikipedia.org/wiki/Hyperplane_separation_theorem) （或称separating axis theorem/SAT）：凸形状相交测试的基本原理。在[怎样判断平面上一个矩形和一个圆形是否有重叠？ - Milo Yip 的回答](http://www.zhihu.com/question/24251545/answer/27184960)中，其实背后也是使用了SAT。
  * [Gilbert-Johnson-Keerthi distance algorithm](https://link.zhihu.com/?target=http%3A//en.wikipedia.org/wiki/Gilbert%E2%80%93Johnson%E2%80%93Keerthi_distance_algorithm) (GJK距离算法)：计算两个凸形状的距离（可用于相交测试）
  * [Sweep and prune](https://link.zhihu.com/?target=http%3A//en.wikipedia.org/wiki/Sweep_and_prune)：用于broad phase碰撞检测，找出物体AABB是否相交。对于时空上连续的物体运动，算法最坏O(n^2)、最好O(n)。

  

#### day62 Hash-based World Storage & Spatially Partitioning Entities & Hitpoints Attack

* 整个世界的entity都在更新，Divide entities into high (靠近相机的区块，camera space entities，记录float坐标), low (记录tile坐标) and dormant categories，然后更新之。每人都有自己virtual的update函数太慢了。

* 删去dormant entity，high low entity有各自的index，只在low entity创建entity，会被相机激活为high；entity list ：free list / compact the array

* slot map：https://seanmiddleditch.com/2013-01-05-data-structures-for-game-developers-the-slot-map/

* spatial hash：

  * https://www.gamedev.net/articles/programming/general-and-gameplay-programming/spatial-hashing-r2697/  
  * perfect hash http://hhoppe.com/proj/perfecthash/
  * http://www.cs.ucf.edu/~jmesit/publications/scsc%202005.pdf

* 压缩sparse：octree、quad tree、kd tree、RLE

* always write usage code first

* ```c++
  #define InvalidCodePath Assert(!"InvalidCodePath");
  ```



#### day69 Simulation Region & Collision

* 大世界的限制：float精度 => 局部坐标系（现有：low的tile position & offset转到high的float2）。很多entity的限制：cpu（现有，区分low&high，两套更新代码）。
* ”利用虚拟相机（simulation region），去间断更新世界“，放弃low entity的概念，low entity只作为存储格式。
  * Define sim_entity and stored_entity. stored_entity is for storage and sim_entity is for simulation. Every frame, pull relevant entities to our simulation region, simulate it and render it. 
  * BeginSim: eneities copied into sim, position translated to float, indexes change to ref
  * EndSim: entites copied to sim, postion translated to int & float, ref change to indexes
  * Sim放在transientmemory里
  * 在simulation region外再有一个high boundary，在high boundary中所有的entities都会被考虑，但只有simulation region会被模拟（防止simulation region的entity走出去一些，或者外围的物体有体积，但没有被物理模拟等情况）；也可以考虑将跨区块的entity存两份，一边一份
* [Lyapunov stability - Wikipedia](https://en.wikipedia.org/wiki/Lyapunov_stability)
* iterative movement中要考虑物理问题（更新4次），Avoid callbacks, plain switch statements are just better on every aspect.
* Collision: [Double dispatch - Wikipedia](https://en.wikipedia.org/wiki/Double_dispatch)
  * [C9 Lectures: Dr. Ralf Lämmel - Advanced Functional Programming - The Expression Problem | Going Deep | Channel 9 (msdn.com)](https://channel9.msdn.com/Shows/Going+Deep/C9-Lectures-Dr-Ralf-Laemmel-Advanced-Functional-Programming-The-Expression-Problem)
  * AAA/Adventure style：entity types are few / responses are few
  * fundamental qualities/properties, entites are compositon of these qualities
  * 如果把两两的collision规则存在哈希表，那么快速删除一个物体的碰撞规则就很麻烦。 every time we just insert two entries so that we can query with each one.



#### day78 Stairwells 

* 4D向量：四元数、颜色

* 碰撞区分inside/outside：behaviour & robustness上的考虑

* 两个AABB矩形碰撞：互相至少有一个重合点，[2D collision detection - Game development | MDN (mozilla.org)](https://developer.mozilla.org/en-US/docs/Games/Techniques/2D_collision_detection)

* ```c++
  //C不允许直接对一个::member做sizeof
  ArrayCount(((game_input *)0)->Controllers)
//C++
  sizeof(decltype(game_input::Controllers[0]))//报错
  sizeof(game_input::Controllers))//g++
  //用std::declval
  ```
  



#### day87 Ground 

* Ground/Rooms，Constructive Solid Geometry
  * [Polygon soup - Wikipedia](https://en.wikipedia.org/wiki/Polygon_soup) 多边形模型的最一般化类型是「多边形汤」，它是多边形的集合，而那些多边形之间并没有几何上的连系，也不含拓扑信息。
  * Quake：filled and carve，不可能掉出世界(其他地方都是solid)
  * Unreal：empty and fill
  * Robustness > efficiency
* Mega Texture
  * [Talk:MegaTexture - Wikipedia](https://en.wikipedia.org/wiki/Talk%3AMegaTexture)
  * [浅谈Virtual Texture - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/138484024)
* ABI
  * [X86调用约定 - 维基百科，自由的百科全书 (wikipedia.org)](https://zh.wikipedia.org/wiki/X86调用约定)
  * [你们说的ABI，Application Binary Interface到底是什么东西？ - 知乎 (zhihu.com)](https://www.zhihu.com/question/381069847)
* Premultiplied Alpha—— Non-Premultiplied Alpha does not distribute over liner interpolation
  * [Alpha compositing - Wikipedia](https://en.wikipedia.org/wiki/Alpha_compositing)
  * [Premultiplied alpha (microsoft.github.io)](https://microsoft.github.io/Win2D/html/PremultipliedAlpha.htm)
* arcsynthesis [Learning Modern 3D Graphics Programming (roiatalla.com)](https://www.roiatalla.com/public/arcsynthesis/html/index.html)
* Memory is a big line



#### day92  Push Buffer rendering & Filling Rotated and Scaled Rectangles

* 定义Push Buffer，方便对渲染的排序（不让游戏架构管sort），quickly、minimaly

* a renderer working
  * Explicit surface rasteriser：先求出三角形和每一行的交点，光栅化需要的部分
  * Implicit surface rasteriser：选出4*4的boundary，走遍boundary所有的pixel，mask掉不要的

* ```c++
  #define InvalidDefaultCase default: {InvalidCodePath;} break
  ```

* Ridiculous Trick: Prepend the type_name with RenderGroupEntryType to make the Identifier, and #define PushRenderElement macro for a type-safe way of correctly setting the type field in one step
  
  
  ```c++
  enum render_group_entry_type
  {
      RenderGroupEntryType_render_entry_clear,
      RenderGroupEntryType_render_entry_bitmap,
      RenderGroupEntryType_render_entry_rectangle,
  };
  #define PushRenderElement(Group, type) (type *)PushRenderElement_(Group, sizeof(type), RenderGroupEntryType_##type)
  ```

* [Graphics Pipeline | The ryg blog (wordpress.com)](https://fgiesen.wordpress.com/category/graphics-pipeline/)

* The PushBuffer is an abstraction layer relying on memory for communication instead of a bunch of functions, casey prefer API design in this way in general

* Downsample, upsample，Mipmaps，Texture sampling handles anti-aliasing for the alpha'd bitmaps（MSAA for edges）



#### day

* the nature of rendering without subpixel accuracy：The number of pixels and texels isn't dividing out evenly，linear blend
* how to do smooth subpixel rendering for pixel art graphics, that doesn't blur but still moves smoothly：显式写pixel shader；MSAA；Manual pre upsample
* 94

