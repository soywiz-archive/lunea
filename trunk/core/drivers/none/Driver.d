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
 *  $Id: Driver.d,v 1.2 2006/02/26 19:01:15 soywiz Exp $
 */

module lunea.driver.Driver;

private import lunea.driver.Main;

public class LuneaDriver {
	static bool cdebug = false;

	static void onStart() {
	}

	static void onExit() {
	}

	static void onBeforeExecute() {
	}

	static void onAfterExecute() {
		msleep(fps_interval);
	}
}

public class Sprite {
	void draw(real x, real y) {
	}

	void draw(real x, real y, real alpha, real angle = 0, real size = 1.0, real red = 1.0, real green = 1.0, real blue = 1.0) {
	}

	void update(real incv) {
	}

	void update(real incpos, real incframe, real inctime) {
	}
}

public class Rect {
}

public static class Screen {
	static void pushClip(Rect rect, bool b) {
	}

	static void popClip() {
	}
}