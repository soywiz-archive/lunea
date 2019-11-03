#include <stdio.h>
#include <SDL/SDL.h>
#include <SDL/SDL_image.h>
#include <SDL/SDL_mixer.h>
#include <SDL/SDL_ttf.h>
#include <SDL/SDL_opengl.h>
#include <SDL/SDL_net.h>
#include <windows.h>

#ifndef false
#define false 0
#endif

#ifndef true
#define true (!false)
#endif

#ifndef null
#define null NULL
#endif

#undef main

#define main gamelib_main

typedef SDL_RWops* Stream;

#include "gamelib_image.h"
#include "gamelib_font.h"

// *Image;

extern SDL_Surface *_screen;
extern char key[SDLK_LAST];
//extern char keyp[SDLK_LAST];
extern char RequestExit;
extern int  FPS;

extern int screenWidth, screenHeight;
extern int screenWidthReal, screenHeightReal;

void GameInit();
void GameQuit();

void KeyboardUpdate();
void KeyboardSetDelay(int delay, int interval);

void VideoModeSetTitle(char *title);
void VideoModeSetEx(int widthScreen, int heightScreen, int widthDraw, int heightDraw, int windowed);
void VideoModeSet(int width, int height, int windowed);
void VideoModeFrame();
void VideoModeEnable2D();
void VideoModeDisable2D();
void VideoModeSetFPS(int fps);
int  VideoModeGetFPS();

void DrawClear();

void ColorSet(float r, float g, float b, float a);

typedef SDL_RWops* Stream;
