all: default
default: sdl_bad_utils
sdl_bad_utils:
	cd julia-src/sdl_bad_utils/;\
	make
clean:  cd julia-src/sdl_bad_utils/;\
	make clean

