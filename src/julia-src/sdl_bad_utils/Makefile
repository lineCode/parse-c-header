all: init_stuff sdl_event gl_sdl_load_img
default: all

init_stuff:
	gcc -shared init_stuff.c -fPIC \
	    -o init_stuff.so -std=c99 -lGL -lm `sdl-config --cflags --libs`;
sdl_event:
	gcc -shared sdl_event.c -fPIC \
	    -o sdl_event.so -std=c99 -lGL -lm `sdl-config --cflags --libs`;
gl_sdl_load_img:
	gcc -shared gl_sdl_load_img.c -fPIC \
	    -o gl_sdl_load_img.so -std=c99 -lGL -l SDL_image -lm \
	    `sdl-config --cflags --libs`;
