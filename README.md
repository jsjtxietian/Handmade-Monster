# Handmade monster

 study note of [Handmade Hero](https://handmadehero.org/)

* day3,  用define来标志不同static的语义

  ```c++
  #define internal static
  #define local_persist static
  #define global_variable static
  ```
  
* day5，[Pointer aliasing - Wikipedia](https://en.wikipedia.org/wiki/Pointer_aliasing)
  
* day6，用define作为辅助定义相同的函数类型，从代码load dll，失败则利用桩函数。

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

* day9
  
  * DirectSound，注意PlayCursor & WriteCursor，延迟(Audio latency) is determined not by the size of the buffer, but by how far ahead of the PlayCursor you write. The optimal amount of latency is the amount that will cause this frame's audio to coincide with the display of this frame's image. On most platforms, it is very difficult to ascertain the proper amount of latency. It's an unsolved problem, and games with need precise AV sync (like Guitar Hero) go to some lengths to achieve it.
  * 定点数，https://zhuanlan.zhihu.com/p/149517485
  * 注意手柄的dead zone