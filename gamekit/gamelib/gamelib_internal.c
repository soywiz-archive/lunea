#include "gamelib.h"
#include "gamelib_internal.h"

int __texPow2 = 0;
int __texRectangle = 0;

__inline int __NextPowerOfTwo(int v) {
	int c = 1; while ((c <<= 1) < v); return c;
}

void __checkTexRectangle() {
	__texRectangle = (strstr(glGetString(GL_EXTENSIONS), "EXT_texture_rectangle") != NULL) ? 1 : -1;
}

void __checkPow2() {
	__texPow2 = 1;
}


SDL_Surface *__SDL_CreateRGBSurfaceForOpenGL(int w, int h, int *rw, int *rh) {
	SDL_Surface *i;

	if (__texPow2 == 0) __checkPow2();
	if (__texRectangle == 0) __checkTexRectangle();

	if (__texPow2 > 0) {
		*rw = __NextPowerOfTwo(w);
		*rh = __NextPowerOfTwo(h);
	} else {
		*rw = w;
		*rh = h;
	}

	if (__texRectangle > 0) {
		if (*rw > *rh) *rh = *rw; else *rw = *rh;
	}

	#if SDL_BYTEORDER == SDL_BIG_ENDIAN
		i = SDL_CreateRGBSurface(SDL_SWSURFACE, *rw, *rh, 32, 0xff000000, 0x00ff0000, 0x0000ff00, 0x000000ff);
	#else
		i = SDL_CreateRGBSurface(SDL_SWSURFACE, *rw, *rh, 32, 0x000000ff, 0x0000ff00, 0x00ff0000, 0xff000000);
	#endif

	return i;
}

void GamePrintError() {
	fprintf(stderr, "ERROR: '%s'\n", SDL_GetError());
}

void GamePrintFatalError() {
	GamePrintError();
	GameQuit();
}
