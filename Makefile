all: default
default: sdl_bad_utils
test_all: test_sdl_bad_utils

sdl_bad_utils:
	cd julia-src/sdl_bad_utils/;\
	make
test_sdl_bad_utils:
	cd julia-src/sdl_bad_utils/;\
	make test
clean:
	cd julia-src/sdl_bad_utils/;\
	make clean

