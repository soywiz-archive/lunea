#include "gamelib.h"
#include "gamelib_internal.h"

SDL_Surface *_screen;
char key[SDLK_LAST];
//char keyp[SDLK_LAST];
char RequestExit = 0;
int  FPS = 60;

int screenWidth = 0, screenHeight = 0;
int screenWidthReal = 0, screenHeightReal = 0;

void GameQuit() {
	SDL_Quit();
	exit(0);
}

void GameInit() {
	if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) < 0) GamePrintFatalError();
	if (TTF_Init() != 0) GamePrintFatalError();
	if (Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 1024) == -1) GamePrintFatalError();
	//if (SDLNet_Init() == -1) GamePrintFatalError();

	SDL_EnableUNICODE(1);

	memset(key, 0, sizeof(key));
	//memset(keyp, 0, sizeof(keyp));
}

void KeyboardUpdate() {
	SDL_Event event;

	while (SDL_PollEvent(&event)) {
		switch (event.type) {
			case SDL_KEYDOWN:  key[event.key.keysym.sym] = 1; break;
			case SDL_KEYUP  :  key[event.key.keysym.sym] = 0; break;
			//case SDL_PRESSED:  keyp[event.key.keysym.sym] = 1; break;
			//case SDL_RELEASED: keyp[event.key.keysym.sym] = 0; break;
			case SDL_QUIT   :  RequestExit = 1;               break;
		}
	}
}

void KeyboardSetDelay(int delay, int interval) {
	SDL_EnableKeyRepeat(delay, interval);
}

void VideoModeSetTitle(char *title) {
	SDL_WM_SetCaption(title, title);
}

void VideoModeSetEx(int widthScreen, int heightScreen, int widthDraw, int heightDraw, int windowed) {
	int buffers;

	SDL_GL_SetAttribute(SDL_GL_SWAP_CONTROL, 1);
	//SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 6);

    if (!(_screen = SDL_SetVideoMode(widthScreen, heightScreen, 32, SDL_OPENGLBLIT | (windowed ? 0 : SDL_FULLSCREEN)))) {
    	GamePrintFatalError();
    }

    screenWidthReal = widthDraw; screenHeightReal = heightDraw;
    screenWidth = widthScreen; screenHeight = heightScreen;

    //glReadBuffer(GL_AUX0);
    //glDrawBuffer(GL_AUX0);
    //glDrawBuffer(GL_AUX1);
    //glGetIntegerv(GL_AUX_BUFFERS, &buffers);
    //printf("GL_AUX_BUFFERS: %d\n", buffers);

    //printf(glGet(GL_AUX_BUFFERS));

    //glReadBuffer(GL_AUX0);
    //glDrawBuffer(GL_NONE);

    //glCopyPixels
    //glReadPixels

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glColor4f(0.0f, 0.0f, 0.0f, 1.0f);

    //char *ext = (char*)glGetString( GL_EXTENSIONS ); printf("%s", ext);
}

void VideoModeSet(int width, int height, int windowed) {
	VideoModeSetEx(width, height, width, height, windowed);
}

void VideoModeClear() {
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

//int lasttime; int _abs(int a) { return (a > 0) ? a : -a; }

void VideoModeFrame() {
	KeyboardUpdate();
	//SDL_Delay(1000 / FPS);

	/*
	while (1) {
		int dtime = abs(lasttime - SDL_GetTicks());
		if (dtime >= 1000 / FPS) break;
	}
	*/

	//if (lasttime)
	SDL_GL_SwapBuffers();
	VideoModeClear();
	//lasttime = SDL_GetTicks();
}

// TODO
void VideoModeEnable2D() {
	glViewport(0, 0, 640, 480);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	glMatrixMode(GL_TEXTURE   ); glLoadIdentity();

	glMatrixMode(GL_PROJECTION); glLoadIdentity();
	glOrtho(0, 640, 480, 0, -1.0, 1.0);
	glTranslatef(0, 1, 0);

	glMatrixMode(GL_MODELVIEW); glLoadIdentity();

	glShadeModel(GL_SMOOTH);

	glEnable(GL_SCISSOR_TEST);
	glEnable(GL_TEXTURE_2D);
}

// TODO
void VideoModeDisable2D() {
}

// TODO
void VideoModeSetFPS(int fps) {
	FPS = fps;
}

// TODO
int VideoModeGetFPS() {
	return FPS;
}

void MouseShow() { SDL_ShowCursor(1); }
void MouseHide() { SDL_ShowCursor(0); }

__inline void ColorSet(float r, float g, float b, float a) {
	glColor4f(r, g, b, a);
}

Image ImageDuplicate(Image i) {
	Image r = malloc(sizeof(_Image));
	memcpy(r, i, sizeof(_Image));
	return r;
}

#undef main

int main(int argc, char* argv[]) {
	return gamelib_main(argc, argv);
}
