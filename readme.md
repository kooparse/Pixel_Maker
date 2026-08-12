# Pixel Maker

_I'm not accepting pull requests, but the code is available publicly as I think
it is valuable information for people who are looking to make their abstraction
layer on top of graphic APIs._

This code is a thin layer on top of Metal and DirectX 11 APIs. The goal of this
module is to write graphics code once while keeping some sort of simplicity in
the API. Currently it powers all my projects that play with graphics.

I liked the "immediate" feeling of the DX11 API, its inner state machine
reduces boilerplate and goes more in my programming style. So internally, I
create pipeline states (PSO) on the fly and then cache them in a lookup table.
If you have many PSOs, this could have some incidence on the first few frames,
but I think it's manageable with relatively simple techniques.

The library can load Slang shaders as well, and you'll get binding information
alongside the corresponding shader program; I use the Slang reflection system
to find the name of bindings, slot numbers, and types.

## API Reference

### Context
- `create_context`
- `destroy_context`
- `get_capabilities`
- `get_storage_alignment`
- `get_constant_alignment`

### Swapchain
- `get_swapchain_texture`
- `get_swapchain_pixel_format`
- `get_swapchain_interval`
- `set_swapchain_interval`

### Frame
- `begin_frame`
- `present`
- `get_backbuffer_index`
- `get_last_frame_gpu_time`

### Command buffer
- `create_command_buffer`
- `submit_command_buffer`
- `begin_debug_group`
- `end_debug_group`

### Textures
- `create_texture`
- `create_texture_view`
- `destroy_texture`
- `replace_texture_region`
- `create_texture_2d_rgba8`
- `is_null`
- `get_desc`

### Samplers
- `create_sampler_state`
- `destroy_sampler_state`

### Buffers
- `create_buffer`
- `destroy_buffer`
- `lock_buffer`
- `unlock_buffer`

### Readback buffer
- `create_readbackbuffer`
- `destroy_readbackbuffer`
- `lock_readbackbuffer`
- `unlock_readbackbuffer`

### Copy pass
- `begin_copy_pass`
- `end_copy_pass`
- `copy_texture`
- `generate_mipmaps`
- `copy_texture_to_readbackbuffer`

### Render pass
- `begin_render_pass`
- `end_render_pass`
- `set_buffer`
- `set_viewport`
- `set_viewports`
- `set_vertex_buffer`
- `set_texture`
- `set_sampler_state`
- `draw`
- `draw_indexed`

### Shaders
- `compile_shader`
- `destroy_shader`

## Notes

Right now, your project has to link dynamically with slang-compiler.dll or
libslang.dylib (on macOS). Make sure those sit next to your executable.

# Thanks

The first version was written by Stefan a year ago; at that time, we had OpenGL
for Windows and we were more into a Metal-ish kind of API, where you had to
create PSOs upfront. So special thanks goes to him! He also convinced me that
it was a good idea to actually spend a bit of time making an abstraction layer
and use Slang as our shader language. You can reach him
[there](https://ostef.github.io/).

The article written by Sebastian Aaltonen, [No Graphics
API](https://www.sebastianaaltonen.com/blog/no-graphics-api) opened my eyes on
many things, and drove me towards this similar design (but DX11 is blocking me
a bit tho, and I'm not ready to move on).

# License

MIT License

Copyright (c) 2026 Alexandre Chêne

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

This project links against the Slang compiler, which is distributed under the
Apache License 2.0 with LLVM Exceptions. See the full text at
[github.com/shader-slang/slang/blob/master/LICENSE](https://github.com/shader-slang/slang/blob/master/LICENSE).
