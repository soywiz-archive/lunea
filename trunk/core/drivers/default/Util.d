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
 *  $Id: Util.d,v 1.7 2006/02/16 23:13:26 soywiz Exp $
 */

module lunea.driver.Util;

public import lunea.std.Math, lunea.std.String;

private import std.stdio;

public class Rect {
	int x1, y1, x2, y2;

	public int w() { return x2 - x1 + 1; }
	public int h() { return y2 - y1 + 1; }
	public alias w width;
	public alias h height;

	private void set(int x1, int y1, int x2, int y2) {
		this.x1 = x1;
		this.x2 = x2;
		this.y1 = y1;
		this.y2 = y2;
	}

	private this() {
	}

	public this(int x1, int y1, int w, int h) {
		set(x1, y1, x1 + w - 1, y1 + h - 1);
	}

	public this(real x1, real y1, real w, real h) {
		set(cast(int)x1, cast(int)y1, cast(int)(x1 + w - 1), cast(int)(y1 + h - 1));
	}

	static public Rect fromCoords(int x1, int y1, int x2, int y2) {
		Rect r = new Rect;
		r.set(x1, y1, x2, y2);
		return r;
	}

	static public Rect fromCoords(real x1, real y1, real x2, real y2) {
		Rect r = new Rect;
		r.set(cast(int)x1, cast(int)y1, cast(int)x2, cast(int)y2);
		return r;
	}

	static public Rect intersect(Rect r1, Rect r2) {
		return Rect.fromCoords(
			max(r1.x1, r2.x1),
			max(r1.y1, r2.y1),
			min(r1.x2, r2.x2),
			min(r1.y2, r2.y2)
		);
	}

	string toString() {
		return "[" ~ String.valueOf(x1) ~ ", " ~ String.valueOf(y1) ~ ", " ~ String.valueOf(x2) ~ ", " ~ String.valueOf(y2) ~ "]";
	}
}

class Color {
	float r, g, b, a;

	static Color white;
	static Color black;
	static Color red;
	static Color whitest;
	static Color blackst;

	static this() {
		Color.white   = new Color(1.0, 1.0, 1.0, 1.0);
		Color.black   = new Color(0.0, 0.0, 0.0, 1.0);
		Color.whitest = new Color(1.0, 1.0, 1.0, 0.7);
		Color.blackst = new Color(0.0, 0.0, 0.0, 0.7);
		Color.red     = new Color(1.0, 0.0, 0.0, 1.0);
	}

	this(real r, real g, real b, real a = 1.0) {
		this.r = cast(float)r;
		this.g = cast(float)g;
		this.b = cast(float)b;
		this.a = cast(float)a;
	}

	/*this(float r, float g, float b, float a = 1.0) {
		this.r = r;
		this.g = g;
		this.b = b;
		this.a = a;
	}*/

	static ubyte __hex(byte c) {
		return (
			(c >= '0' && c <= '9') ? (c - '0') :
			(c >= 'A' && c <= 'F') ? (c - 'A' + 10) :
			(c >= 'a' && c <= 'f') ? (c - 'a' + 10) :
			0
		);
	}

	static ubyte __hex(char[] c) {
		return (__hex(c[0]) << 4) | __hex(c[1]);
	}

	static Color fromHex(char[] hex) {
		real r = 0, g = 0, b = 0, a = 1;

		if (hex.length >= 2) r = cast(real)(__hex(hex[0..2])) / 255;
		if (hex.length >= 4) g = cast(real)(__hex(hex[2..4])) / 255;
		if (hex.length >= 6) b = cast(real)(__hex(hex[4..6])) / 255;
		if (hex.length >= 8) a = cast(real)(__hex(hex[6..8])) / 255;

		return new Color(r, g, b, a);
	}
}