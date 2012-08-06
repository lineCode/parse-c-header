#!/bin/bash
rm init_stuff.so sdl_event.so

gcc -shared init_stuff.c -fPIC \
    -o init_stuff.so -std=c99 -lGL -lGLU -lm `sdl-config --cflags --libs`

#Just a little SDL stuff.
gcc -shared sdl_event.c -fPIC \
    -o sdl_event.so -std=c99 -lGL -lGLU -lm `sdl-config --cflags --libs`