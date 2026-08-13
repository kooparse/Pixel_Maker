quit   := false;

MAX_FRAME_IN_FLIGHT :: 2;
VERTEX_BIND_INDEX   :: 10;

vertex_buffers        : [MAX_FRAME_IN_FLIGHT] GFX_Buffer;
ortho_buffer          : GFX_Buffer;

window_width    := 1200.;
window_height   := 800.;

Vertex :: struct {
    position : Vector2;
};

main :: () {
    window_flags := SDL_WindowFlags.SDL_WINDOW_RESIZABLE;

    #if OS == .WINDOWS {
        SDL_HINT_WINDOWS_DPI_SCALING    :: "SDL_WINDOWS_DPI_SCALING";
        SDL_HINT_WINDOWS_DPI_AWARENESS  :: "SDL_WINDOWS_DPI_AWARENESS";

        SDL_SetHint(SDL_HINT_WINDOWS_DPI_AWARENESS, "permonitorv2");
        SDL_SetHint(SDL_HINT_WINDOWS_DPI_SCALING, "1");
    } else {
        window_flags |= .SDL_WINDOW_ALLOW_HIGHDPI;
    }

    window := SDL_CreateWindow("Demo", SDL_WINDOWPOS_UNDEFINED , SDL_WINDOWPOS_UNDEFINED, xx window_width, xx window_height, window_flags);
    assert(window != null);

    dw, dh: s32;
    SDL_GL_GetDrawableSize(window, *dw, *dh);

    dpi_scale := xx (dw / window_width);
    log("dpi_scale: %", dpi_scale);

    platform_window: *void;

    winfo : SDL_SysWMinfo;
    SDL_GetWindowWMInfo(window, *winfo);

    #if OS == {
        case .MACOS;
            assert(winfo.subsystem == .SDL_SYSWM_COCOA);
            platform_window = winfo.info.cocoa.window;
        case .WINDOWS;
            assert(winfo.subsystem == .SDL_SYSWM_WINDOWS);
            platform_window = winfo.info.win.window;
    }

    // First we need to create a context.
    success := create_context(platform_window);
    assert(success == true);

    // We can load and compile Slang shader. Shader could be packed in memory too (like now).
    vertex_shader, pixel_shader := add_shader("ui", "ui.slang", SHADER_SRC);

    stride       := size_of(Vertex);
    capacity     := cast(u64, stride * 6);

    for 0..MAX_FRAME_IN_FLIGHT - 1 {
        vertex_buffers[it] = create_buffer("UI Vertices", size_of(Vertex) * 6, xx size_of(Vertex), null, .CPU_WRITE, .VERTEX_BUFFER);
    }

    ortho_buffer = create_buffer("Ortho Matrix", size_of(Matrix4), size_of(Matrix4), null, .CPU_WRITE, .CONSTANT_BUFFER);

    while !quit {
        reset_temporary_storage();

        begin_frame();

        event: SDL_Event;
        while SDL_PollEvent(*event) {
            if event.type == {
                case SDL_QUIT; quit = true;
            }
        }

        vertex_buffer := *vertex_buffers[get_backbuffer_index()];

        // Copy ortho matrix to GPU buffer.
        {
            lock_buffer(*ortho_buffer, .WRITE_AND_FLUSH);
            ortho := orthographic_projection_matrix(0, window_width * dpi_scale, window_height * dpi_scale, 0, -1, 1, depth_range_01=true);
            memcpy(ortho_buffer.data_ptr, *ortho, size_of(Matrix4));
            unlock_buffer(*ortho_buffer);
        }

        // Copy vertices to GPU buffer.
        {

            vertices := Vector2.[
                .{ (window_width / 2) , window_height * 0.2 },
                .{ (window_width / 2 + window_width / 4), window_height * 0.8 },
                .{ (window_width / 2 - window_width / 4), window_height * 0.8 }
            ];

            angle := cast(float) seconds_since_init() * 0.5;
            pivot := Vector2.{ window_width / 2, window_height / 2 };

            for * vertices {
                x := it.x - pivot.x;
                y := it.y - pivot.y;

                new_x := x * cos(angle) - y * sin(angle);
                new_y := x * sin(angle) + y * cos(angle);

                it.x = new_x + pivot.x;
                it.y = new_y + pivot.y;

                it.* *= dpi_scale;
            }

            lock_buffer(vertex_buffer, .WRITE_AND_FLUSH);
            memcpy(vertex_buffer.data_ptr, vertices.data, size_of(Vector2) * vertices.count);
            unlock_buffer(vertex_buffer);
        }

        {
            command_buffer := create_command_buffer("Frame");
            screen_texture := get_swapchain_texture();

            pass_desc: GFX_Render_Pass_Desc;

            set_color_attachment(*pass_desc, 0, screen_texture);
            clear_color(*pass_desc, 0, xyzw(0, 0, 0, 1));

            pass: GFX_Render_Pass;
            begin_render_pass(*pass, "Debug name for my Render Pass", *command_buffer, pass_desc);
            {
                reset_render_state();

                set_pso_name("Debug name for my PSO");
                set_vertex_shader(vertex_shader);
                set_pixel_shader(pixel_shader);
                set_color_format(get_swapchain_pixel_format());
                set_blend_mode(.ADDITIVE);
                set_vertex_layout(Vertex, VERTEX_BIND_INDEX);

                set_cull_face(.NONE);

                set_viewport(*pass, .{ width = window_width * dpi_scale, height = window_height * dpi_scale });

                vert := get_binding(vertex_shader, struct { ortho: GFX_Pipeline_Binding; });
                set_buffer(*pass, vert.ortho, *ortho_buffer, 0, ortho_buffer.size);

                set_vertex_buffer(*pass, VERTEX_BIND_INDEX, vertex_buffer, 0, vertex_buffer.size, size_of(Vertex));
                draw(*pass, 3, 1);
            }
            end_render_pass(*pass);

            submit_command_buffer(*command_buffer);
            present();
        }

    }

    if quit {
        SDL_DestroyWindow(window);
        destroy_context();
    }
}

#import "Basic";
#import "Math";
#import, file "../module.jai"(MAX_FRAME_IN_FLIGHT = 2);

using, except(NO) SDL :: #import "SDL";

SHADER_SRC :: #string END
struct Vertex_Out {
    float4 position     : SV_Position;
};

struct Vertex {
    float2 position     : TEXCOORD0;
};

ConstantBuffer<float4x4>  ortho;

[shader("vertex")]
Vertex_Out vertex_main(Vertex vertex) {
    Vertex_Out result;

    float4 position     = float4(vertex.position.xy, 0, 1);
    result.position     = mul(ortho, position);

    return result;
}

[shader("fragment")]
float4 fragment_main(Vertex_Out input) : SV_Target {
    return float4(1, 1, 1, 1);
}
END


