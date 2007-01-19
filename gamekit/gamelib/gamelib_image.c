#include "gamelib.h"
#include "gamelib_internal.h"
#include <GL/glext.h>

//
// http://www.opengl.org/registry/specs/EXT/framebuffer_object.txt
// http://www.codesampler.com/oglsrc/oglsrc_14.htm
// http://www.gamedev.net/reference/articles/article2331.asp
// http://www.gamedev.net/reference/articles/article2333.asp
//
// Note: The EXT_framebuffer_object extension is an excellent replacement for
//       the WGL_ARB_pbuffer and WGL_ARB_render_texture combo which is normally
//       used to create dynamic textures. An example of this older technique
//       can be found here:
//
//       http://www.codesampler.com/oglsrc/oglsrc_7.htm#ogl_offscreen_rendering
//
GLuint fbo = -1, fbrb = -1;

PFNGLISRENDERBUFFEREXTPROC glIsRenderbufferEXT = NULL;
PFNGLBINDRENDERBUFFEREXTPROC glBindRenderbufferEXT = NULL;
PFNGLDELETERENDERBUFFERSEXTPROC glDeleteRenderbuffersEXT = NULL;
PFNGLGENRENDERBUFFERSEXTPROC glGenRenderbuffersEXT = NULL;
PFNGLRENDERBUFFERSTORAGEEXTPROC glRenderbufferStorageEXT = NULL;
PFNGLGETRENDERBUFFERPARAMETERIVEXTPROC glGetRenderbufferParameterivEXT = NULL;
PFNGLISFRAMEBUFFEREXTPROC glIsFramebufferEXT = NULL;
PFNGLBINDFRAMEBUFFEREXTPROC glBindFramebufferEXT = NULL;
PFNGLDELETEFRAMEBUFFERSEXTPROC glDeleteFramebuffersEXT = NULL;
PFNGLGENFRAMEBUFFERSEXTPROC glGenFramebuffersEXT = NULL;
PFNGLCHECKFRAMEBUFFERSTATUSEXTPROC glCheckFramebufferStatusEXT = NULL;
PFNGLFRAMEBUFFERTEXTURE1DEXTPROC glFramebufferTexture1DEXT = NULL;
PFNGLFRAMEBUFFERTEXTURE2DEXTPROC glFramebufferTexture2DEXT = NULL;
PFNGLFRAMEBUFFERTEXTURE3DEXTPROC glFramebufferTexture3DEXT = NULL;
PFNGLFRAMEBUFFERRENDERBUFFEREXTPROC glFramebufferRenderbufferEXT = NULL;
PFNGLGETFRAMEBUFFERATTACHMENTPARAMETERIVEXTPROC glGetFramebufferAttachmentParameterivEXT = NULL;
PFNGLGENERATEMIPMAPEXTPROC glGenerateMipmapEXT = NULL;

void InitializeFrameBufferObject() {
	char *ext = (char*)glGetString(GL_EXTENSIONS);

	if (strstr(ext, "EXT_framebuffer_object") == NULL) {
		SDL_SetError("EXT_framebuffer_object extension was not found");
		GamePrintFatalError();
	} else {
		glIsRenderbufferEXT = (PFNGLISRENDERBUFFEREXTPROC)SDL_GL_GetProcAddress("glIsRenderbufferEXT");
		glBindRenderbufferEXT = (PFNGLBINDRENDERBUFFEREXTPROC)SDL_GL_GetProcAddress("glBindRenderbufferEXT");
		glDeleteRenderbuffersEXT = (PFNGLDELETERENDERBUFFERSEXTPROC)SDL_GL_GetProcAddress("glDeleteRenderbuffersEXT");
		glGenRenderbuffersEXT = (PFNGLGENRENDERBUFFERSEXTPROC)SDL_GL_GetProcAddress("glGenRenderbuffersEXT");
		glRenderbufferStorageEXT = (PFNGLRENDERBUFFERSTORAGEEXTPROC)SDL_GL_GetProcAddress("glRenderbufferStorageEXT");
		glGetRenderbufferParameterivEXT = (PFNGLGETRENDERBUFFERPARAMETERIVEXTPROC)SDL_GL_GetProcAddress("glGetRenderbufferParameterivEXT");
		glIsFramebufferEXT = (PFNGLISFRAMEBUFFEREXTPROC)SDL_GL_GetProcAddress("glIsFramebufferEXT");
		glBindFramebufferEXT = (PFNGLBINDFRAMEBUFFEREXTPROC)SDL_GL_GetProcAddress("glBindFramebufferEXT");
		glDeleteFramebuffersEXT = (PFNGLDELETEFRAMEBUFFERSEXTPROC)SDL_GL_GetProcAddress("glDeleteFramebuffersEXT");
		glGenFramebuffersEXT = (PFNGLGENFRAMEBUFFERSEXTPROC)SDL_GL_GetProcAddress("glGenFramebuffersEXT");
		glCheckFramebufferStatusEXT = (PFNGLCHECKFRAMEBUFFERSTATUSEXTPROC)SDL_GL_GetProcAddress("glCheckFramebufferStatusEXT");
		glFramebufferTexture1DEXT = (PFNGLFRAMEBUFFERTEXTURE1DEXTPROC)SDL_GL_GetProcAddress("glFramebufferTexture1DEXT");
		glFramebufferTexture2DEXT = (PFNGLFRAMEBUFFERTEXTURE2DEXTPROC)SDL_GL_GetProcAddress("glFramebufferTexture2DEXT");
		glFramebufferTexture3DEXT = (PFNGLFRAMEBUFFERTEXTURE3DEXTPROC)SDL_GL_GetProcAddress("glFramebufferTexture3DEXT");
		glFramebufferRenderbufferEXT = (PFNGLFRAMEBUFFERRENDERBUFFEREXTPROC)SDL_GL_GetProcAddress("glFramebufferRenderbufferEXT");
		glGetFramebufferAttachmentParameterivEXT = (PFNGLGETFRAMEBUFFERATTACHMENTPARAMETERIVEXTPROC)SDL_GL_GetProcAddress("glGetFramebufferAttachmentParameterivEXT");
		glGenerateMipmapEXT = (PFNGLGENERATEMIPMAPEXTPROC)SDL_GL_GetProcAddress("glGenerateMipmapEXT");

		if(
			!glIsRenderbufferEXT || !glBindRenderbufferEXT || !glDeleteRenderbuffersEXT ||
			!glGenRenderbuffersEXT || !glRenderbufferStorageEXT || !glGetRenderbufferParameterivEXT ||
			!glIsFramebufferEXT || !glBindFramebufferEXT || !glDeleteFramebuffersEXT ||
			!glGenFramebuffersEXT || !glCheckFramebufferStatusEXT || !glFramebufferTexture1DEXT ||
			!glFramebufferTexture2DEXT || !glFramebufferTexture3DEXT || !glFramebufferRenderbufferEXT||
			!glGetFramebufferAttachmentParameterivEXT || !glGenerateMipmapEXT
		) {
			SDL_SetError("One or more EXT_framebuffer_object functions were not found");
			GamePrintFatalError();
		}
	}

	glGenFramebuffersEXT(1, &fbo);

	//glGenRenderbuffersEXT(1, &fbrb);
	//glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, fbrb);
	//glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, GL_DEPTH_COMPONENT24, 128, 128);

	GLenum status = glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT);

	switch (status) {
		case GL_FRAMEBUFFER_COMPLETE_EXT: break;
		default: case GL_FRAMEBUFFER_UNSUPPORTED_EXT:
			SDL_SetError("Can't initialize framebuffer object");
			GamePrintFatalError();
		break;
	}
}

void RemoveFrameBufferObject() {
	if (fbo) {
		glDeleteFramebuffersEXT(1, &fbo);
		fbo = 0;
	}
}

// TODO: Implementar usando pbuffer o extbufs si no está disponible la extensión
// framebuffer.
int ImageStartDrawing(Image i) {
	if (i == NULL) {
		SDL_SetError("ImageStartDrawing - without image");
		GamePrintError();
		return -1;
	}

	if (fbo == -1) InitializeFrameBufferObject();

	glFlush();

	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fbo);
	glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, i->gltex, 0);
	//glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, GL_RENDERBUFFER_EXT, fbrb);

	glViewport(0, 0, i->w, i->h);
	//glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	glMatrixMode(GL_TEXTURE   );
	glPushMatrix();

	glLoadIdentity();

	glMatrixMode(GL_PROJECTION);
	glPushMatrix();
	glLoadIdentity();
	//glOrtho(0, i->w, i->h, 0, -1.0, 1.0);
	glOrtho(0, i->w, 0, i->h, -1.0, 1.0);
	glTranslatef(0, 1, 0);

	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();
	glLoadIdentity();

	glShadeModel(GL_SMOOTH);
	glEnable(GL_SCISSOR_TEST);
	glEnable(GL_TEXTURE_2D);

	return 0;
}

void ImageStopDrawing() {
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);

	glViewport(0, 0, screenWidthReal, screenHeightReal);

	glMatrixMode(GL_MODELVIEW);
	glPopMatrix();
	glMatrixMode(GL_PROJECTION);
	glPopMatrix();
	glMatrixMode(GL_TEXTURE   );
	glPopMatrix();

	glMatrixMode(GL_MODELVIEW);

	//if (fbo) {
	//	glDeleteFramebuffersEXT(1, &fbo);
	//	fbo = 0;
	//}
}

void __ImageUpdateCallList(Image i) {
	if (i->callList) glDeleteLists(i->callList, 1);
	i->callList = glGenLists(1);
	glNewList(i->callList, GL_COMPILE);
		glBindTexture(GL_TEXTURE_2D, i->gltex);
		glTexParameterf(GL_TEXTURE_2D, 0x84FF, 16);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glEnable(GL_BLEND);
		glBegin(GL_POLYGON);
			glTexCoord2f(i->texp[0].x, i->texp[0].y); glVertex2f(0    - i->cx, 0    - i->cy);
			glTexCoord2f(i->texp[1].x, i->texp[1].y); glVertex2f(i->w - i->cx, 0    - i->cy);
			glTexCoord2f(i->texp[2].x, i->texp[2].y); glVertex2f(i->w - i->cx, i->h - i->cy);
			glTexCoord2f(i->texp[3].x, i->texp[3].y); glVertex2f(0    - i->cx, i->h - i->cy);
		glEnd();
	glEndList();
}

void __ImageUpdateTexPoints(Image i) {
	float fx1, fx2, fy1, fy2;

	//printf("(%f,%f)-(%f,%f)", (float)i->x, (float)i->y, (float)i->w, (float)i->h);

	fx1 = (float)i->x / (float)i->rw;
	fy1 = (float)i->y / (float)i->rh;

	fx2 = (float)(i->w + i->x) / (float)i->rw;
	fy2 = (float)(i->h + i->y) / (float)i->rh;

	//printf("(%f,%f)-(%f,%f)", fx1, fy1, fx2, fy2);

	i->texp[0].x = fx1; i->texp[0].y = fy1;
	i->texp[1].x = fx2; i->texp[1].y = fy1;
	i->texp[2].x = fx2; i->texp[2].y = fy2;
	i->texp[3].x = fx1; i->texp[3].y = fy2;

	__ImageUpdateCallList(i);
}

void __ImageInit(Image i) {
	i->callList = 0;
}

void __ImagePrepareNew(Image i, int w, int h, int rw, int rh) {
	i->father = NULL;
	i->y = i->x = 0;
	i->w = w; i->h = h;
	i->rw = rw; i->rh = rh;
	i->cy = i->cx = 0;

	//printf("i.RH:%f\n", i->rh);

	__ImageUpdateTexPoints(i);
}

Image ImageCreate(int w, int h) {
	int rw = __NextPowerOfTwo(w), rh = __NextPowerOfTwo(h);
	Image i;
	if ((i = malloc(sizeof(_Image))) == NULL) return NULL;
	__ImageInit(i);

	__ImagePrepareNew(i, w, h, rw, rh);

	glGenTextures(1, &i->gltex);
	glBindTexture(GL_TEXTURE_2D, i->gltex);
	glTexImage2D(GL_TEXTURE_2D, 0, 4, rw, rh, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	//glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

	return i;
}

Image ImageCreateFromSubImage(Image vpi, int x, int y, int w, int h) {
	Image i;

	if (vpi == NULL) return NULL;

	if ((i = malloc(sizeof(_Image))) == NULL) return NULL;
	__ImageInit(i);

	i->gltex = vpi->gltex;

	if (x < 0) {
		w += x;
		x = 0;
	}

	if (y < 0) {
		h += y;
		y = 0;
	}

	if (x + w > vpi->x + vpi->w) {
		w = vpi->x + vpi->w - x;
	}

	if (y + h > vpi->y + vpi->h) {
		h = vpi->y + vpi->h - y;
	}

	if (w < 0) w = 0;
	if (h < 0) h = 0;

	i->x = x; i->y = y;
	i->w = w; i->h = h;
	i->rw = vpi->rw; i->rh = vpi->rh;
	i->cy = i->cx = 0;

	i->father = (vpi->father == NULL) ? vpi : vpi->father;

	__ImageUpdateTexPoints(i);

	//i->parent = (pi->parent != NULL) ? pi->parent : pi;

	return i;
}

__inline Image ImageLoadFromStreamEx(Stream s, int freesrc) {
	int rw, rh;
	SDL_Surface *surface;
	SDL_Surface *surfaceogl;
	Image i;

	surface = IMG_Load_RW(s, freesrc);
	if (!surface) {
		return NULL;
	}

	surfaceogl = __SDL_CreateRGBSurfaceForOpenGL(surface->w, surface->h, &rw, &rh);
	if (!surfaceogl) {
		return NULL;
	}

	SDL_SetAlpha(surface, 0, SDL_ALPHA_OPAQUE);
	SDL_BlitSurface(surface, 0, surfaceogl, 0);

	if ((i = malloc(sizeof(_Image))) == NULL) return NULL;
	__ImageInit(i);

	__ImagePrepareNew(i, surface->w, surface->h, rw, rh);

	glGenTextures(1, &i->gltex);
	glBindTexture(GL_TEXTURE_2D, i->gltex);
	glTexImage2D(GL_TEXTURE_2D, 0, 4, rw, rh, 0, GL_RGBA, GL_UNSIGNED_BYTE, surfaceogl->pixels);
	//glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	//glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	//glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	//glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	//glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

	SDL_FreeSurface(surface);
	SDL_FreeSurface(surfaceogl);

	return i;
}

Image ImageLoadFromStream(Stream s) {
	return ImageLoadFromStreamEx(s, 0);
}

Image ImageLoadFromMemory(void *ptr, int length) {
	return ImageLoadFromStreamEx(SDL_RWFromMem(ptr, length), 1);
}

Image ImageLoadFromFile(char *filename) {
	Image i = ImageLoadFromStreamEx(SDL_RWFromFile(filename, "rb"), 1);

	if (!i) {
		SDL_SetError("Can't open image '%s'", filename);
		GamePrintError();
	}

	return i;
}

void ImageFree(Image i) {
	if (i == NULL) return;

	// Textura final, liberar
	if (i->father == NULL) {
		glDeleteTextures(1, &i->gltex);
	}

	free(i);
}

void ImageSetCXY(Image i, int cx, int cy) {
	if (i == NULL) return;
	i->cx = cx; i->cy = cy;
	__ImageUpdateCallList(i);
}

void DrawImageEx(Image i, int x, int y, float size, float angle) {
	float r = 1.0, g = 1.0, b = 1.0, alpha = 1.0;

	if (i == NULL) return;
	if (alpha < 0) alpha = 0;
	if (alpha > 1) alpha = 1;

	x -= i->cx;
	y -= i->cy;

	y--;
	glColor4f(r, g, b, alpha);
	//glBlendFunc(GL_DST_ALPHA, GL_ZERO);
	//glBlendFunc(GL_SRC_ALPHA,GL_ONE);

	//glPushMatrix();
	//glPopMatrix();

	/*
	glMatrixMode(GL_PROJECTION);
	glPushMatrix();

	glTranslatef((float)x, (float)y, 0.0f);
	*/

	//glTranslatef(-i->cy, -i->cx, 0.0f);
	//glRotatef(angle, 0, 0, 1);


	glMatrixMode(GL_MODELVIEW);
	glPushMatrix();

	//glLoadIdentity();

	glTranslatef((float)x + i->cx, (float)y + i->cy, 0.0f);

	//glTranslatef(-0.5, -0.5, 0.0f);
	glRotatef(angle, 0, 0, 1);
	glScalef(size, size, size);

	//printf("%d\n", i->callList); glCallList(i->callList);

	glBindTexture(GL_TEXTURE_2D, i->gltex);
	glTexParameterf(GL_TEXTURE_2D, 0x84FF, 16);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glEnable(GL_BLEND);
	glBegin(GL_POLYGON);
		glTexCoord2f(i->texp[0].x, i->texp[0].y); glVertex2f(0    - i->cx, 0    - i->cy);
		glTexCoord2f(i->texp[1].x, i->texp[1].y); glVertex2f(i->w - i->cx, 0    - i->cy);
		glTexCoord2f(i->texp[2].x, i->texp[2].y); glVertex2f(i->w - i->cx, i->h - i->cy);
		glTexCoord2f(i->texp[3].x, i->texp[3].y); glVertex2f(0    - i->cx, i->h - i->cy);
	glEnd();

	//glTranslatef(i->cx, i->cy, 0.0f);

	glMatrixMode(GL_MODELVIEW);
	glPopMatrix();

	/*

	glMatrixMode(GL_PROJECTION);
	glPopMatrix();
	*/

	glBindTexture(GL_TEXTURE_2D, 0);
}

void DrawImage(Image i, int x, int y) {
	DrawImageEx(i, x, y, 1.0f, 0.0f);
}

void DrawClear() {
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}