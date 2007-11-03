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
 *  $Id: Image.d,v 1.8 2006/02/16 23:13:26 soywiz Exp $
 */

module lunea.driver.Image;

private import lunea.Lunea;
private import opengl, SDL, SDL_image;

private import std.math;
private import lunea.Resource;
private import lunea.driver.Screen;
private import lunea.driver.Util;

/*

Normal:
GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA

Light:
GL_ONE, GL_ONE

Dark:
GL_ZERO, GL_SRC_COLOR

*/

class Image {
	Image parent;

	public uint  gltex;

	public int   x,  y;
	public int   w,  h;
	public real  cx, cy;

	public float fw, fh;
	public int   tw, th;
	float[2][4]  texp;

	protected this() {
		parent = null;
		gltex  = 0;
	}

	~this() {
		if (parent !is null) return;
		glDeleteTextures(1, &gltex);
	}

	public Image setCXCY() {
		return setCXCY(0, 0);
	}

	public Image setCXCY(real cx, real cy) {
		this.cx = cast(int)(cx * w);
		this.cy = cast(int)(cy * h);
		return this;
	}

	public void fastDraw(int x, int y) {
		y--;
		glBindTexture(GL_TEXTURE_2D, (parent is null) ? gltex : parent.gltex);
		glTexParameterf(GL_TEXTURE_2D, 0x84FF, 16);
		glBegin(GL_POLYGON);
			glTexCoord2f(texp[0][0], texp[0][1]); glVertex2i(x    , y    );
			glTexCoord2f(texp[1][0], texp[1][1]); glVertex2i(x + w, y    );
			glTexCoord2f(texp[2][0], texp[2][1]); glVertex2i(x + w, y + h);
			glTexCoord2f(texp[3][0], texp[3][1]); glVertex2i(x    , y + h);
		glEnd();
		glBindTexture(GL_TEXTURE_2D, 0);
	}

	public void fastDrawAlpha(int x, int y, real alpha = 1) {
		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glColor4f(1, 1, 1, cast(float)alpha);
		fastDraw(x, y);
		glDisable(GL_BLEND);
	}

	void getDrawPoints(in int[2][4] drwp, real x, real y, real angle, real size) {
		real[4] px, py;

		px[0] = px[3] = cx;
		px[1] = px[2] = cx - w;
		py[0] = py[1] = cy;
		py[2] = py[3] = cy - h;

		real ccos = cos(angle), csin = sin(angle);

		for (int n = 0; n < 4; n++) {
			drwp[n][0] = cast(int)((-px[n] * ccos +py[n] * csin) * size +x);
			drwp[n][1] = cast(int)((-px[n] * csin -py[n] * ccos) * size +y);
		}
	}

	public void draw(real x, real y, real alpha = 1, real angle = 0, real size = 1.0, real r = 1.0, real g = 1.0, real b = 1.0, uint msrc = GL_SRC_ALPHA, uint mdst = GL_ONE_MINUS_SRC_ALPHA) {
		y--;
		glEnable(GL_BLEND);
		glBlendFunc(msrc, mdst);
		glBindTexture(GL_TEXTURE_2D, (parent is null) ? gltex : parent.gltex);
		glColor4f(r, g, b, cast(float)alpha);

		glBegin(GL_POLYGON);
			int[2][4] drwp; getDrawPoints(drwp, x, y, angle, size);
			glTexCoord2f(texp[0][0], texp[0][1]); glVertex2i(drwp[0][0], drwp[0][1]);
			glTexCoord2f(texp[1][0], texp[1][1]); glVertex2i(drwp[1][0], drwp[1][1]);
			glTexCoord2f(texp[2][0], texp[2][1]); glVertex2i(drwp[2][0], drwp[2][1]);
			glTexCoord2f(texp[3][0], texp[3][1]); glVertex2i(drwp[3][0], drwp[3][1]);
		glEnd();

		glBindTexture(GL_TEXTURE_2D, 0);
		glDisable(GL_BLEND);
	}

	public void drawTiled(real x, real y, real width, real height, real alpha = 1) {
		if (width < 0 || height < 0) return;

		Screen.pushClip(new Rect(x, y, width, height));
			int px2 = cast(int)ceil(width / w), py2 = cast(int)ceil(height / h);
			for (int py = 0; py < py2; py++) {
				for (int px = 0; px < px2; px++) {
					draw(x + px * w, y + py * h, alpha);
				}
			}
		Screen.popClip();
	}

	private static uint __pow2helper(uint n) {
		uint r = 1; while (r < n) r <<= 1; return r;
	}

	public Image[] split(int width, int height, int borderx = 0, int bordery = 0, int startx = 0, int starty = 0) {
		Image[] images;

		for (int y = starty; y < this.h; y += height + bordery) {
			for (int x = startx; x < this.w; x += width + borderx) {
				Image current = fromImage(this, x, y, width, height);
				current.cy = current.cx = 0;
				images ~= current;
			}
		}

		return images;
	}

	public static Image fromImage(Image image, int x, int y, int width, int height) {
		return fromImage(image, x, y, width, height, image.cx - x, image.cy - y);
	}

	public static Image fromImage(Image image, int x, int y, int width, int height, real cx, real cy) {
		Image nimage = new Image;

		if (x      < 0) x      = 0; else if (x > image.w) x = image.w;
		if (y      < 0) y      = 0; else if (y > image.h) y = image.h;
		if (width  < 1) width  = 1;
		if (height < 1) height = 1;
		if (width  > image.w - x) width  = image.w - x;
		if (height > image.h - y) height = image.h - y;

		nimage.x      = x;
		nimage.y      = y;
		nimage.w      = width;
		nimage.h      = height;
		nimage.cx     = cx;
		nimage.cy     = cy;
		nimage.tw     = image.tw;
		nimage.th     = image.th;

		nimage.parent = (image.parent is null) ? image : image.parent;

		nimage.updateTexfPoints();

		return nimage;
	}

	private void updateTexfPoints() {
		float twf = cast(float)((parent is null) ? tw : parent.tw);
		float thf = cast(float)((parent is null) ? th : parent.th);

		float sx1 = cast(float)(x    ) / twf;
		float sx2 = cast(float)(x + w) / twf;
		float sy1 = cast(float)(y    ) / thf;
		float sy2 = cast(float)(y + h) / thf;

		texp[0][0] = sx1; texp[0][1] = sy1;
		texp[1][0] = sx2; texp[1][1] = sy1;
		texp[2][0] = sx2; texp[2][1] = sy2;
		texp[3][0] = sx1; texp[3][1] = sy2;
	}

	public static int genTexture(SDL_Surface *surface, uint gltex, out uint rw, out uint rh) {
		rw = __pow2helper(surface.w); rh = __pow2helper(surface.h);
		version (LittleEndian) { SDL_Surface *tsurface = SDL_CreateRGBSurface(SDL_SWSURFACE, rw, rh, 32, 0x000000ff, 0x0000ff00, 0x00ff0000, 0xff000000);
		} else { SDL_Surface *tsurface = SDL_CreateRGBSurface(SDL_SWSURFACE, rw, rh, 32, 0xff000000, 0x00ff0000, 0x0000ff00, 0x000000ff); }
		if (tsurface is null) throw(new Exception("Insufficient memory"));
		SDL_Rect dest; with (dest) { x = y = 0; w = rw; h = rh; }
		SDL_SetAlpha(surface, 0, 0);
		SDL_BlitSurface(surface, null, tsurface, &dest);
		glBindTexture(GL_TEXTURE_2D, gltex);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexImage2D(GL_TEXTURE_2D, 0, 4, rw, rh, 0, GL_RGBA, GL_UNSIGNED_BYTE, tsurface.pixels);
		SDL_FreeSurface(tsurface);
		return 0;
	}

/*
	public static int genTexture(SDL_Surface *surface, uint gltex, out uint rw, out uint rh) {
		rw = __pow2helper(surface.w); rh = __pow2helper(surface.h);
		version (LittleEndian) { SDL_Surface *tsurface = SDL_CreateRGBSurface(SDL_SWSURFACE, rw, rh, 32, 0x000000ff, 0x0000ff00, 0x00ff0000, 0xff000000);
		} else { SDL_Surface *tsurface = SDL_CreateRGBSurface(SDL_SWSURFACE, rw, rh, 32, 0xff000000, 0x00ff0000, 0x0000ff00, 0x000000ff); }
		if (tsurface is null) throw(new Exception("Insufficient memory"));
		SDL_Rect dest; with (dest) { x = y = 0; w = rw; h = rh; }
		SDL_SetAlpha(surface, 0, 0);
		SDL_BlitSurface(surface, null, tsurface, &dest);
		glBindTexture(GL_TEXTURE_2D, gltex);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexImage2D(GL_TEXTURE_2D, 0, 4, rw, rh, 0, GL_RGBA, GL_UNSIGNED_BYTE, tsurface.pixels);
		SDL_FreeSurface(tsurface);
		return 0;
	}

	public static Image fromSurface(SDL_Surface *surface, char[] filename, bool frees = false) {
		if (surface is null) throw(new Exception("Can't load file: '" ~ filename ~ "'"));
		if (surface.w <   1 || surface.h <   1) throw(new Exception("Bitmap is too short"));

		uint _w, _h;
		Image image = new Image;
		glGenTextures(1, &image.gltex);
		genTexture(surface, image.gltex, _w, _h);

		with (image) {
			x  = 0;          y  = 0;
			w  = surface.w;  h  = surface.h;
			cx = surface.w >> 1; cy = surface.h >> 1;
			tw = _w; th = _h;
			fw = cast(float)surface.w / cast(float)tw;
			fh = cast(float)surface.h / cast(float)th;
			texp[0][0] = 0;  texp[0][1] = 0;
			texp[1][0] = fw; texp[1][1] = 0;
			texp[2][0] = fw; texp[2][1] = fh;
			texp[3][0] = 0;  texp[3][1] = fh;
		}

		SDL_FreeSurface(surface);

		if (frees) SDL_FreeSurface(surface);

		return image;
	}
*/

	public static Image fromSurface(SDL_Surface *surface, char[] filename, bool frees = false) {
		if (surface is null) throw(new Exception("Can't load file: '" ~ filename ~ "'"));
		if (surface.w <   1 || surface.h <   1) throw(new Exception("Bitmap is too short"));

		uint rw = __pow2helper(surface.w);
		uint rh = __pow2helper(surface.h);

		Image image = new Image;

		version (LittleEndian) {
			SDL_Surface *tsurface = SDL_CreateRGBSurface(SDL_SWSURFACE, rw, rh, 32, 0x000000ff, 0x0000ff00, 0x00ff0000, 0xff000000);
		} else {
			SDL_Surface *tsurface = SDL_CreateRGBSurface(SDL_SWSURFACE, rw, rh, 32, 0xff000000, 0x00ff0000, 0x0000ff00, 0x000000ff);
		}

		if (tsurface is null) throw(new Exception("Insufficient memory"));

		SDL_Rect dest; with (dest) { x = y = 0; w = rw; h = rh; }
		SDL_SetAlpha(surface, 0, 0);
		SDL_BlitSurface(surface, null, tsurface, &dest);

		with (image) {
			x  = 0;          y  = 0;
			w  = surface.w;  h  = surface.h;
			cx = surface.w >> 1; cy = surface.h >> 1;
			tw = tsurface.w; th = tsurface.h;
			fw = cast(float)surface.w / cast(float)tw;
			fh = cast(float)surface.h / cast(float)th;
			texp[0][0] = 0;  texp[0][1] = 0;
			texp[1][0] = fw; texp[1][1] = 0;
			texp[2][0] = fw; texp[2][1] = fh;
			texp[3][0] = 0;  texp[3][1] = fh;
		}

		SDL_FreeSurface(surface); surface = tsurface;

		glGenTextures(1, &image.gltex);

		glBindTexture(GL_TEXTURE_2D, image.gltex);

		glTexImage2D(GL_TEXTURE_2D, 0, 4, rw, rh, 0, GL_RGBA, GL_UNSIGNED_BYTE, surface.pixels);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

		if (frees) SDL_FreeSurface(surface);

		return image;
	}

	public static Image fromResource(char[] filename) {
		if (!Resources.have(filename)) throw(new Exception("Can't load resource: " ~ filename ~ "'"));

		return fromSurface(IMG_Load_RW(SDL_RWFromMem(Resources.get(filename), Resources.size(filename)), -1), filename, true);
	}

	public static Image fromFile(char[] filename) {
		if (!std.file.exists(filename)) throw(new Exception("Can't load file: " ~ filename ~ "'"));

		return fromSurface(IMG_Load(std.string.toStringz(filename)), filename, true);
	}

	public Image clone() {
		return fromImage(this, 0, 0, this.w, this.h);
	}
}

enum {
	BLEND_NORMAL,
	BLEND_LIGHT,
	BLEND_DARK
}

class ZImage {
	Image image;
	real x, y;
	real size, angle;
	real alpha, red, green, blue;
	int  blendtype = BLEND_NORMAL;

	this(Image image, real x, real y, real size, real angle, real alpha, real red, real green, real blue, int blendtype = BLEND_NORMAL) {
		this.image = image;
		this.x     = x;
		this.y     = y;
		this.size  = size;
		this.angle = angle;
		this.alpha = alpha;
		this.red   = red;
		this.green = green;
		this.blue  = blue;
		this.blendtype = blendtype;
	}

	// public void draw(real x, real y, real alpha = 1, real angle = 0, real size = 1.0, real r = 1.0, real g = 1.0, real b = 1.0, uint msrc = GL_SRC_ALPHA, uint mdst = GL_ONE_MINUS_SRC_ALPHA) {
	void draw(real x, real y) {
		if (image is null) return;
		switch (blendtype) {
			default:
			case BLEND_NORMAL: image.draw(x + this.x, y + this.y, alpha, angle, size, red, green, blue, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); break;
			case BLEND_LIGHT:  image.draw(x + this.x, y + this.y, alpha, angle, size, red, green, blue, GL_ONE, GL_ONE); break;
			case BLEND_DARK:   image.draw(x + this.x, y + this.y, alpha, angle, size, red, green, blue, GL_ZERO, GL_SRC_COLOR); break;
		}
	}

	void draw(real x, real y, real alpha, real angle = 0, real size = 1.0, real red = 1.0, real green = 1.0, real blue = 1.0) {
		if (image is null) return;
		int src, dst;
		switch (blendtype) {
			default:
			case BLEND_NORMAL: src = GL_SRC_ALPHA; dst = GL_ONE_MINUS_SRC_ALPHA; break;
			case BLEND_LIGHT:  src = GL_ONE      ; dst = GL_ONE                ; break;
			case BLEND_DARK:   src = GL_ZERO     ; dst = GL_SRC_COLOR          ; break;
		}

		image.draw(x + this.x, y + this.y, this.alpha * alpha, this.angle + angle, this.size * size, this.red * red, this.green * green, this.blue * blue, src, dst);
	}
}
