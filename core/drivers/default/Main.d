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
 *  $Id: Main.d,v 1.3 2006/01/20 23:52:31 soywiz Exp $
 */

module lunea.driver.Main;

public import lunea.Lunea;

public import
	lunea.driver.Screen,
	lunea.driver.Input,
	lunea.driver.Animation,
	lunea.driver.Image,
	lunea.driver.Audio,
	lunea.driver.Font,
	lunea.driver.Util,
	lunea.driver.Driver
;

private import std.c.time, std.math, std.stdio;

pragma(lib, "kernel32.lib");
pragma(lib, "opengl32.lib");
pragma(lib, "SDL.lib");
pragma(lib, "SDL_image.lib");
pragma(lib, "SDL_mixer.lib");
pragma(lib, "SDL_ttf.lib");

version (Windows) {
	private import std.c.windows.windows;

	extern(C) void SDL_SetModuleHandle(void *hInst);
}

static this() {
	if (SDL_Init(SDL_INIT_NOPARACHUTE) < 0) throw new Error("Error loading SDL");

	version (Windows) {
		SDL_SetModuleHandle(GetModuleHandleA(null));
	}
}

static ~this() {
	SDL_Quit();
}