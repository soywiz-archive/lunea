/*
 *  Lunea library
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
 *  $Id: Lunea.d,v 1.4 2006/01/15 20:29:31 soywiz Exp $
 */

module lunea.Lunea;

public import lunea.Util;
public import lunea.Resource;
//public import lunea.ProcessThread;
//public import lunea.Process;

version(Windows) {
	private import std.c.windows.windows;
} else {
	pragma(msg, "Linux version not implemented yet");
	static assert(0);
}

static class Program {
	// Variable used to know when the application is running
	static int running = true;

	// Array of strings with the arguments passed to program
	static char[][] arguments;

	// String with the path of the program
	static char[] name;

	// String with the application title
	static char[] title;

	// Number of milliseconds between frames
	static int fps_interval;

	//
	private static real _fps;
	static real fps() {
		return _fps;
	}

	static void fps(real fps) {
		fps = fmin(fmax(1, fps), 300);
		_fps = fps;
		fps_interval = cast(int)(1000 / fps);
	}
}

public alias Program.running luneaRunning;
public alias Program.arguments arguments;
public alias Program.name program;
public alias Program.title title;
public alias Program.fps_interval fps_interval;
public alias Program.fps fps;

static this() {
	version(Windows) {
		// Obtain the path of program and sets the program variable
		char[MAX_PATH] pathbuf;
		int clength = GetModuleFileNameA(null, pathbuf.ptr, pathbuf.length);
		program = pathbuf[0 .. clength];
	} else {
		throw(new Exception("Linux version not implemented yet"));
	}

	// Sets the Frames per Second to 60
	fps = 60;
}

static ~this() {
}