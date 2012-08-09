
#Just tests some gl drawing and showing where the cursor is as such.

load("get_c.j")
load("sdl_bad_utils/init_stuff.j")

load("autoffi/gl.j")
load("gl_util.j")

load("sdl_bad_utils/sdl_event.j")
load("sdl_bad_utils/gl_sdl_load_img.j")

function texies() #TODO doesn't work, wrong ) or, ??
  @with_primitive GL_QUADS begin
    gltexcoord(0.0, 0.0)
    glvertex(0, 0)
    gltexcoord(0.0, 1.0)
    glvertex(0, 1)
    gltexcoord(1.0, 1.0)
    glvertex(1, 1)
    gltexcoord(1.0, 0.0)
    glvertex(1, 0)
  end
end

function run_this ()
  println("NOTE/TODO doesn't work if you run it from another directory.
 (unless an identically named file there")
  
  screen_width = 640
  screen_height = 640
  init_stuff()

  mx(i) = -1 + 2*i/screen_width
  my(j) =  1 - 2*j/screen_width
  mx()  = mx(mouse_x())
  my()  = my(mouse_y())
  glenable({GL_TEXTURE_2D, GL_BLEND})
  glshademodel(GL_SMOOTH)
  
  img = gl_sdl_load_img("neverball_128.png") #xonotic.png", 512,512)

  while true
    glcolor(1,1,1)
    
#Draws 'background'
    @with_primitive GL_TRIANGLES begin
      glvertex(-1,-1)
      glvertex(-1,1)
      glvertex(1,0)
    end
#Draws cursor.
    glcolor(1,0,0)
    @with_primitive GL_TRIANGLES begin
      glvertex(mx(),my())
      glvertex(mx()+0.1,my())
      glvertex(mx(),my()+0.1)
    end
  #Draws the image we're testing with.
    glenable({GL_TEXTURE_2D, GL_BLEND})
    glblendfunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    texies()
    gldisable({GL_TEXTURE_2D, GL_BLEND})
    
    finalize_draw()
    flush_events()
  end
end
