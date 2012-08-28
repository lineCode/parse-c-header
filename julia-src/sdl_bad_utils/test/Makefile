
default: test

test:
	echo Testing gl image loading and drawing; \
	julia img.j > result/img; \
	cd result; \
	echo $(USER)" `git status |wc -l` `git log |head -n 1` time `date +%s` `wc -l img`" > /tmp/sdl_bad_utils_test_tmp;\
	cat run_list >> /tmp/sdl_bad_utils_test_tmp;\
	mv /tmp/sdl_bad_utils_test_tmp run_list; \
	head -n 1 run_list
# identical to img.j except without image.
#	julia gl_sdl.j > result/gl_sdl;\
