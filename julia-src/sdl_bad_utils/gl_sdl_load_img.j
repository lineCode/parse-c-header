#  Jasper den Ouden 16-08-2012
# Placed in public domain.

gl_sdl_load_img_lib = load_so("sdl_bad_utils/gl_sdl_load_img.so")

#Cant use @get_c_fun due to it not supporting String conversion yet.
function gl_sdl_load_img(file::String, format::Integer, w::Integer,h::Integer,
                         prepare::Bool)
  if prepare
    glenable({GL_TEXTURE_2D, GL_BLEND})
  end
  val = ccall(dlsym(gl_sdl_load_img_lib, :gl_sdl_load_img),
              GLuint, (Ptr{Uint8},GLenum,GLint,GLint), 
              cstring(file), convert(GLenum, format), w,h)
  if prepare
    gldisable({GL_TEXTURE_2D, GL_BLEND})
  end
  return val
end

gl_sdl_load_img(file::String, format::Integer, w::Integer,h::Integer) = #!
    gl_sdl_load_img(file, format, w,h, true)

gl_sdl_load_img(file::String, format::Integer) = #!
    gl_sdl_load_img(file, format, -1,-1)
gl_sdl_load_img(file::String) = #!
    gl_sdl_load_img(file, -1)
