
gl_sdl_load_img_lib = dlopen("/home/jasper/proj/common-lisp/parse-c-header/src/julia-src/sdl_bad_utils/gl_sdl_load_img.so")

#Cant use @get_c_fun due to it not supporting String conversion yet.
function gl_sdl_load_img(file::String, format::Integer, w::Integer,h::Integer)
  return ccall(dlsym(gl_sdl_load_img_lib, :gl_sdl_load_img),
               GLuint, (Ptr{Uint8},GLenum,GLint,GLint), 
               cstring(file), convert(GLenum, format), w,h)
end

gl_sdl_load_img(file::String, format::Integer) = 
     gl_sdl_load_img(file, format,-1,-1)

gl_sdl_load_img(file::String) = 
     gl_sdl_load_img(file, GL_RGBA,-1,-1)
