
load("get_c.j")
load("sdl_bad_utils/init_stuff.j")

load("gl/gl.j")
load("gl/gl_util.j")

load("sdl_bad_utils/sdl_event.j")

function run_this ()
  screen_width = 640
  screen_height = 640
  init_stuff()

  mx(i) = -1 + 2*i/screen_width
  my(j) = 1 - 2*j/screen_width
  mx()  = mx(mouse_x())
  my()  = my(mouse_y())

  while true
    glcolor(1.0,1.0,1.0)
    @with_primitive GL_TRIANGLES begin
      glvertex(-1,-1)
      glvertex(-1,1)
      glvertex(1,0)
      glcolor(1.0,0.0,0.0)
      glvertex(mx(),my())
      glvertex(mx()+0.1,my())
      glvertex(mx(),my()+0.1)
    end
    finalize_draw()
    while poll_event()!=0
    end
  end
end
