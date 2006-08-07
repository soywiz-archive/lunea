/*
 *  Lunea library (gl2d)
 *  Copyright (C) 2005  Carlos Ballesteros Velasco
 *
 *  This file is part of Lunea.
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 *  $Id: Screen.d,v 1.13 2006/04/24 17:36:13 soywiz Exp $
 */

module lunea.driver.Screen;

import
	lunea.driver.Util,
	lunea.driver.Font
;

import SDL, SDL_syswm, SDL_mouse, opengl, std.c.windows.windows, std.string;

private import std.stdio;

char[] SDL_GetErrorS() {
	return std.string.toString(SDL_GetError());
}

version (Windows) {
	extern (Windows) {
		DWORD   SetClassLongA (HWND hWnd, int nIndex, LONG dwNewLong);
		HICON   LoadIconA     (HINSTANCE hInstance, LPCSTR lpIconName);
		DWORD   DestroyIcon  (HICON hIcon);
		HGLOBAL LoadResource  (HMODULE hModule, HRSRC hResInfo);
		HRSRC   FindResourceA (HMODULE hModule, LPCTSTR lpName, LPCTSTR lpType);
		DWORD   SizeofResource(HMODULE hModule, HRSRC hResInfo);
		//HMODULE GetModuleHandleA(LPCSTR lpModuleName);

		const int GCL_HICON = (-14);

		alias SetClassLongA SetClassLong;
		alias LoadIconA LoadIcon;
		alias FindResourceA FindResource;
		alias GetModuleHandleA GetModuleHandle;
	}
}

Font debugFont;

class Screen {
	static bool setted = false;
	static int width = 0, height = 0;
	static SDL_Surface *screensf;

	static public alias width w;
	static public alias height h;

	static Rect[] clips;
	static Rect   cclip;

	version (Windows) static private HICON icon;

	static this() {
		if (!(SDL_WasInit(SDL_INIT_EVERYTHING) & SDL_INIT_VIDEO)) {
			if (SDL_InitSubSystem(SDL_INIT_VIDEO) < 0) {
				throw new Exception("Unable to initialize SDL: " ~ SDL_GetErrorS());
			}
		}
	}

	static ~this() {
		version (Windows) DestroyIcon(icon);
		SDL_QuitSubSystem(SDL_INIT_VIDEO);
	}

	static void set(int width, int height, char[] title, bool fullscreen = false) {
		Screen.width  = width;
		Screen.height = height;
		Screen.setted = true;

		SDL_WM_SetCaption(std.string.toStringz(title), null);

		version (Windows) {
			HWND hwnd;
			HINSTANCE handle = GetModuleHandle(null);
			icon = LoadIcon(handle, "icon");
			SDL_SysWMinfo wminfo; SDL_GetWMInfo(&wminfo);
			hwnd = cast(HANDLE)wminfo.window;
			SetClassLong(hwnd, GCL_HICON, cast(LONG)icon);
		}

		if ((screensf = SDL_SetVideoMode(width, height, 0, SDL_OPENGL | SDL_DOUBLEBUF)) == null) {
			throw new Exception("Unable to create SDL screen: " ~ SDL_GetErrorS());
		}
		//SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
		initViewport();

		SDL_Cursor *cursor = SDL_GetCursor();
		cursor.wm_cursor.curs = cast(void *)LoadCursorA(null, IDC_ARROW);
		SDL_SetCursor(cursor);

		//debugFont = new Font("Arial", 14);
	}

	static void initViewport() {
		glViewport(0, 0, Screen.width, Screen.height);

		glMatrixMode(GL_TEXTURE   ); glLoadIdentity();
		glMatrixMode(GL_PROJECTION); glLoadIdentity();

		glOrtho(0, Screen.width, Screen.height, 0, -1.0, 1.0 );
		glTranslatef(0, 1, 0);

		glMatrixMode(GL_MODELVIEW); glLoadIdentity();

		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glShadeModel(GL_SMOOTH);

		glEnable(GL_SCISSOR_TEST);
		glEnable(GL_TEXTURE_2D);

		glDisable(0x809D);
		//glDisable(GL_DEPTH_TEST);
		glDisable(GL_LINE_SMOOTH);

/*
#define GL_TEXTURE_MAX_ANISOTROPY_EXT     0x84FE
#define GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT 0x84FF
*/

		glLineWidth(1.0f);

		glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);
		//glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_FASTEST);
		glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);

		cclip = new Rect(0, 0, Screen.width, Screen.height);

		//glDrawBuffer(GL_NONE);
		//writefln(GL_AUX_BUFFERS);
	}

	static void clip(Rect rect) {
		cclip = rect;
		//return;

		glScissor(
			rect.x1,
			Screen.height - rect.y2 - 1,
			rect.w,
			rect.h
		);
	}

	static void pushClip(Rect rect, bool intersect = true) {
		clips ~= cclip;
		if (intersect) rect = Rect.intersect(cclip, rect);
		clip(rect);
	}

	static void popClip() {
		clip(clips[clips.length - 1]);
		clips.length = clips.length - 1;
	}

	static void clear() {
		glClearColor(0, 0, 0, 0);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	}

	static void flip() {
		SDL_GL_SwapBuffers();
	}

	static void drawFillBox(real x1, real y1, real x2, real y2, real r, real g, real b, real alpha = 1.0) {
		glEnable(GL_BLEND);
			glColor4f(cast(float)r, cast(float)g, cast(float)b, cast(float)alpha);
			glBegin(GL_POLYGON);
				glVertex2i(cast(int)x1, cast(int)y1);
				glVertex2i(cast(int)x2, cast(int)y1);
				glVertex2i(cast(int)x2, cast(int)y2);
				glVertex2i(cast(int)x1, cast(int)y2);
			glEnd();
		glDisable(GL_BLEND);
	}

	static void drawFillBox(real x1, real y1, real x2, real y2, Color c) {
		glEnable(GL_BLEND);
			glColor4f(c.r, c.g, c.b, c.a);
			glBegin(GL_POLYGON);
				glVertex2i(cast(int)x1, cast(int)y1 - 1);
				glVertex2i(cast(int)x2 + 1, cast(int)y1 - 1);
				glVertex2i(cast(int)x2 + 1, cast(int)y2);
				glVertex2i(cast(int)x1, cast(int)y2);
			glEnd();
		glDisable(GL_BLEND);
	}

	static void drawFillBox(real x1, real y1, real x2, real y2, Color c1, Color c2, Color c3, Color c4) {
		glEnable(GL_BLEND);
			glBegin(GL_POLYGON);
				glColor4f(c1.r, c1.g, c1.b, c1.a);
				glVertex2i(cast(int)x1, cast(int)y1 - 1);
				glColor4f(c2.r, c2.g, c2.b, c2.a);
				glVertex2i(cast(int)x2 + 1, cast(int)y1 - 1);
				glColor4f(c3.r, c3.g, c3.b, c3.a);
				glVertex2i(cast(int)x2 + 1, cast(int)y2);
				glColor4f(c4.r, c4.g, c4.b, c4.a);
				glVertex2i(cast(int)x1, cast(int)y2);
			glEnd();
		glDisable(GL_BLEND);
	}

	static void drawBox(real x1, real y1, real x2, real y2, Color c) {
		drawBox(cast(int)x1, cast(int)y1, cast(int)x2, cast(int)y2, c);
	}

	static void drawBox(int x1, int y1, int x2, int y2, Color c) {
		glEnable(GL_BLEND);
			glColor4f(c.r, c.g, c.b, c.a);
			glBegin(GL_LINE_LOOP);
				glVertex2i(x1, y1);
				glVertex2i(x2 + 1, y1);
				glVertex2i(x2, y2);
				glVertex2i(x1, y2);
			glEnd();
		glDisable(GL_BLEND);
	}

	static void drawBox(Rect rect, Color c) {
		drawBox(rect.x1, rect.y1, rect.x2, rect.y2, c);
	}

	static void drawLine(int x1, int y1, int x2, int y2, Color c) {
		glEnable(GL_BLEND);
			glColor4f(c.r, c.g, c.b, c.a);
			glBegin(GL_LINES);
				glVertex2i(x1, y1);
				glVertex2i(x2 + 1, y2);
			glEnd();
		glDisable(GL_BLEND);
	}

	static void drawLine(real x1, real y1, real x2, real y2, Color c) {
		drawLine(cast(int)x1, cast(int)y1, cast(int)x2, cast(int)y2, c);
	}

	static void drawPixel(int x1, int y1, Color c) {
		glEnable(GL_BLEND);
			glColor4f(c.r, c.g, c.b, c.a);
			glBegin(GL_POINTS); glVertex2i(x1, y1); glEnd();
		glDisable(GL_BLEND);
	}

	static void drawPixel(real x1, real y1, Color c) {
		drawPixel(cast(int)x1, cast(int)y1, c);
	}

	static void savePng(string file) {
		SDL_SaveBMP(screensf, toStringz(file));
	}
}