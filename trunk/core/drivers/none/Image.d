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
 *  $Id: Image.d,v 1.1 2006/01/05 17:31:57 soywiz Exp $
 */

module lunea.driver.Image;

public import lunea.Lunea;

private import lunea.Resource;

class Image {
	public int   x,  y;
	public int   w,  h;
	public real  cx, cy;

	protected this() {
	}

	~this() {
	}

	public void fastDraw(int x, int y) {
	}

	public void draw(real x, real y, real alpha = 1, real angle = 0, real size = 1.0, real r = 1.0, real g = 1.0, real b = 1.0) {
	}

	public Image[] split(int width, int height, int borderx = 0, int bordery = 0, int startx = 0, int starty = 0) {
		Image[] retval;
		return retval;
	}

	public static Image fromImage(Image image, int x, int y, int width, int height) {
		return null;
	}

	public static Image fromResource(string filename) {
		return null;
	}

	public static Image fromFile(string filename) {
		return null;
	}

	public Image clone() {
		return null;
	}
}