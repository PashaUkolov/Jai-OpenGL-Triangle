#import "Basic";
#import "GL";
#import "Window_Creation";
#import "Input";
#import "Simp";
#import "String";
#import "Math";


Vertex :: struct {
    x : float;
    y : float;
    z : float;
}

check_compile_errors :: (shader : GLuint) -> bool, info_log : string {
    success : s32;
    glGetShaderiv (shader, GL_COMPILE_STATUS, *success);
    if !success
    {
        info_len : s32;
        glGetShaderiv (shader, GL_INFO_LOG_LENGTH, *info_len);
        info_data := cast (*u8) alloc (info_len, temp);
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
    glGetProgramiv (program, GL_LINK_STATUS, *success);
    if !success
    {
        info_len : s32;
        glGetProgramiv (program, GL_INFO_LOG_LENGTH, *info_len);
        info_data := cast (*u8) alloc (info_len, temp);
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
    uniform mat4 projection;
    void main() {
        gl_Position  = vec4(pos.x, pos.y, pos.z, 1.0);
    }
    END
    
    FRAGMENT_SHADER :: #string END
    #version 330
    out vec4 color;
    void main() {
        color = vec4(0.2, 0.5, 0.0, 1.0);
    }
    END
    
    WIDTH:= 500;
    HEIGHT:= 500;
    
    window := create_window(WIDTH, HEIGHT, "gl test");
    set_render_target(window);
    
    vertexShader : GLuint = glCreateShader(GL_VERTEX_SHADER);
    vertexSource := VERTEX_SHADER;
    glShaderSource(vertexShader, 1, *vertexSource.data, null);
    glCompileShader(vertexShader);
    success, infoLog := check_compile_errors (vertexShader);
	if !success
	{
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
	if !success
	{
		log_error ("Could not link shader: %", success);
	}
    
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    
    w : float = 100;
	h : float = 100;
	xpos : float = 10;
	ypos : float = 10;
    vertices : [3] Vertex;
    
    vertices[0] = .{-0.5, -0.5, 0.0};
    vertices[1] = .{0.5, -0.5, 0.0};
    vertices[2] = .{0.0, 0.5, 0.0};
    //vertices[3] = .{w + xpos, ypos + h, 0.0};
    
    vao : u32;
    vbo : u32;
    glGenVertexArrays(1, *vao);
    glBindVertexArray(vao);
    
    glGenBuffers(1, *vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, size_of(Vertex) * 3, *vertices, GL_STATIC_DRAW); 
    
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, size_of(Vertex), cast (*void) 0);
    glEnableVertexAttribArray(0);
    
    windowShouldClose := false;
    while !windowShouldClose {
        clear_render_target(.2, .3, .3, 1);
        update_window_events();
        
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glUseProgram(shaderID);
        glBindVertexArray(vao);
        
        //orthoProjection := orthographic_projection_matrix(0, cast(float)WIDTH, cast(float)HEIGHT, 0, 0, 1);
		//glUniformMatrix4fv(glGetUniformLocation(shaderID, "projection"), 1, false, xx *orthoProjection);
        
        glDrawArrays(GL_TRIANGLES, 0, 3);
        
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