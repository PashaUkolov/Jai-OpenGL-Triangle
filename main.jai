#import "Basic";
#import "GL";
#import "Window_Creation";
#import "Input";
#import "Simp";
#import "String";
#import "Math";
#import "stb_image";

// #load "MidiInterface.jai";

Vertex :: struct {
    x : float;
    y : float;
    z : float;
    u : float;
    v : float;
}

check_compile_errors :: (shader : GLuint) -> bool, info_log : string {
    success : s32;
    glGetShaderiv(shader, GL_COMPILE_STATUS, *success);
    if !success {
        info_len : s32;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, *info_len);
        info_data := cast (*u8) alloc (info_len);
        glGetShaderInfoLog (shader, xx info_len, xx *info_len, info_data);
        result : string;
        result.data = info_data;
        result.count = info_len;
        
        return false, result;
    }
    
    return true, "";
}

check_link_errors :: (program : GLuint) -> bool, info_log : string {
    success : s32;
    glGetProgramiv(program, GL_LINK_STATUS, *success);
    if !success {
        info_len : s32;
        glGetProgramiv(program, GL_INFO_LOG_LENGTH, *info_len);
        info_data := cast (*u8) alloc (info_len);
        glGetProgramInfoLog (program, xx info_len, xx *info_len, info_data);
        result : string;
        result.data = info_data;
        result.count = info_len;
        
        return false, result;
    }
    
    return true, "";
}

main :: () {
    VERTEX_SHADER :: #string END
    #version 330
    layout (location = 0) in vec3 pos;
    layout (location = 1) in vec2 texCoord;

    out vec2 aTexCoord;

    uniform mat4 projection;
    void main() {
        gl_Position  = vec4(pos.x, pos.y, pos.z, 1.0);
        aTexCoord = texCoord;
    }
    END
    
    FRAGMENT_SHADER :: #string END
    #version 330
    out vec4 color;

    in vec2 aTexCoord;

    uniform sampler2D myTexture;

    void main() {
        color = texture(myTexture, aTexCoord);
        // color = vec4(aTexCoord.x, aTexCoord.y, 0.0, 1.0);
    }
    END
    
    // createMidiDevice();
    
    WIDTH:= 500;
    HEIGHT:= 500;
    
    window := create_window(WIDTH, HEIGHT, "gl test");
    set_render_target(window);
    
    vertexShader : GLuint = glCreateShader(GL_VERTEX_SHADER);
    vertexSource := VERTEX_SHADER;
    glShaderSource(vertexShader, 1, *vertexSource.data, null);
    glCompileShader(vertexShader);
    success, infoLog := check_compile_errors (vertexShader);
	if !success {
		log_error ("Could not compile vertex shader: %", infoLog);
	}
    
    fragmentShader := glCreateShader(GL_FRAGMENT_SHADER);
    fragmentSource := FRAGMENT_SHADER;
    glShaderSource(fragmentShader, 1, *fragmentSource.data, null);
    glCompileShader(fragmentShader);
    success, infoLog = check_compile_errors (fragmentShader);
	if !success {
		log_error ("Could not compile fragment shader: %", infoLog);
	}
    
    shaderID := glCreateProgram();
    glAttachShader(shaderID, vertexShader);
    glAttachShader(shaderID, fragmentShader);
    glLinkProgram(shaderID);
    success, infoLog = check_link_errors (shaderID);
	if !success {
		log_error ("Could not link shader: %", success);
	}
    
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    
    vertices : [4] Vertex;
    indices: [6] u32;

    // vertices[0] = .{-0.5, -0.5, 0.0, 1.0, 1.0};
    // vertices[1] = .{0.5, -0.5, 0.0, 1.0, 0.0};
    // vertices[2] = .{-0.5, 0.5, 0.0, 0.0, 1.0};
    vertices[0] = .{0.5, 0.5, 0.0, 1.0, 1.0};
    vertices[1] = .{0.5, -0.5, 0.0, 1.0, 0.0};
    vertices[2] = .{-0.5, -0.5, 0.0, 0.0, 0.0};
    vertices[3] = .{-0.5, 0.5, 0.0, 0.0, 1.0};

    indices = .[0, 1, 3, 1, 2, 3];
    
    vao, vbo : u32;
    ebo : u32;
    glGenVertexArrays(1, *vao);
    glBindVertexArray(vao);
    
    glGenBuffers(1, *ebo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, size_of(u32) * 6, *indices, GL_STATIC_DRAW);

    glGenBuffers(1, *vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, size_of(Vertex) * 4, *vertices, GL_STATIC_DRAW); 

    h, w, channels : s32;
    data := stbi_load("Sprite.png", *w, *h, *channels, 0);
    defer stbi_image_free(data);

    if !data {
        print("failed to load an image");
    }

    print("texture width %, texture height %", w, h);

    texture : GLuint;
    glGenTextures(1, *texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, cast(u32)w, cast(u32)h, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
    glGenerateMipmap(GL_TEXTURE_2D);
   
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, size_of(Vertex), cast (*void) 0);
    glEnableVertexAttribArray(0);

    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, size_of(Vertex), cast(*void) (size_of(float) * 3));
    glEnableVertexAttribArray(1);
    
    windowShouldClose := false;
    while !windowShouldClose {
        clear_render_target(.2, .3, .3, 1);
        update_window_events();
        
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glUseProgram(shaderID);
        glBindTexture(GL_TEXTURE_2D, texture);
        glBindVertexArray(vao);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
        
        //orthoProjection := orthographic_projection_matrix(0, cast(float)WIDTH, cast(float)HEIGHT, 0, 0, 1);
		//glUniformMatrix4fv(glGetUniformLocation(shaderID, "projection"), 1, false, xx *orthoProjection);
        
        // glDrawArrays(GL_TRIANGLES, 0, 3);
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, cast(*void)0);
        
        for event : events_this_frame {
            if event.key_code == .ESCAPE {
                if event.key_pressed {
                    windowShouldClose = true;
                }
            }
            if event.type == .QUIT {
                windowShouldClose = true;
                break;
            }
        }
        swap_buffers(window);
    }
    print("Program ended gracefully! \n");
}