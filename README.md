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

  