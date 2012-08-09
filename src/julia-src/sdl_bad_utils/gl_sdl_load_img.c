#include <GL/gl.h>
#include <SDL/SDL.h>
#include <SDL/SDL_image.h>

void texture_enter_gl(GLuint index, SDL_Surface* surf,
		      GLenum format, int w,int h)
		      
{
  glBindTexture(GL_TEXTURE_2D, index);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

  glTexImage2D(GL_TEXTURE_2D, 0, 4, w,h, 0, 
	       format, GL_UNSIGNED_BYTE, surf->pixels);
}

GLuint gl_sdl_load_img(char* file, GLenum format, GLint w,GLint h)
{
  SDL_Surface *surf = IMG_Load(file);
  if( surf==NULL ){ return 0; } //Failure.
  GLuint index = 0;
  glGenTextures(1, &index); //Get an index.
  if( w<0 ){ w= surf->w; } //Use existing size if none specifically given.
  if( h<0 ){ h= surf->h; }
  texture_enter_gl(index, surf, format, w,h);

  SDL_FreeSurface(surf); //Just want it in video memory.
  return index;
}
