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
 *  $Id: Font.d,v 1.4 2006/04/24 17:36:13 soywiz Exp $
 */

module lunea.driver.Font;

import lunea.driver.Util;

import lunea.driver.Image;
import lunea.Resource;
import std.c.windows.windows, std.math, opengl, SDL_syswm, SDL_ttf;

pragma(lib, "GDI32.LIB");
pragma(lib, "OPENGL32.LIB");

extern(Windows) {
	BOOL wglUseFontBitmapsA(HDC hdc, DWORD first, DWORD count, DWORD listBase);
	BOOL wglUseFontBitmapsW(HDC hdc, DWORD first, DWORD count, DWORD listBase);

	struct ABC {
		int     abcA;
		UINT    abcB;
		int     abcC;
	}

	alias ABC* LPABC;

	alias CHAR TCHAR;

	struct TEXTMETRIC {
		LONG tmHeight;
		LONG tmAscent;
		LONG tmDescent;
		LONG tmInternalLeading;
		LONG tmExternalLeading;
		LONG tmAveCharWidth;
		LONG tmMaxCharWidth;
		LONG tmWeight;
		LONG tmOverhang;
		LONG tmDigitizedAspectX;
		LONG tmDigitizedAspectY;
		TCHAR tmFirstChar;
		TCHAR tmLastChar;
		TCHAR tmDefaultChar;
		TCHAR tmBreakChar;
		BYTE tmItalic;
		BYTE tmUnderlined;
		BYTE tmStruckOut;
		BYTE tmPitchAndFamily;
		BYTE tmCharSet;
	}

	alias TEXTMETRIC* LPTEXTMETRIC;

	BOOL GetCharABCWidthsA(
		HDC hdc,
		UINT uFirstChar,
		UINT uLastChar,
		LPABC lpabc
	);

	BOOL GetTextMetricsA(
		HDC hdc,
		LPTEXTMETRIC lptm
	);
}

class FontWindows {
	GLuint     base;
	HDC        hDC = null;
	ABC[]      abc;
	real       height;
	TEXTMETRIC textMetric;

	private void prepareHDC() {
		if (hDC is null) {
			SDL_SysWMinfo swmi; SDL_GetWMInfo(&swmi);
			hDC = GetDC(cast(HANDLE)swmi.window);
		}
	}

	this(char[] name, int size, bool bold = false, bool italic = false, bool underline = false, bool strikeout = false) {
		HFONT font;
		HFONT oldfont;

		prepareHDC();

		base = glGenLists(256);

		font = CreateFontA(
			-size,
			0,
			0,
			0,
			bold      ? FW_BOLD : FW_NORMAL,
			italic    ? TRUE : FALSE,
			underline ? TRUE : FALSE,
			strikeout ? TRUE : FALSE,
			//ANSI_CHARSET,
			OEM_CHARSET,
			OUT_TT_PRECIS,
			CLIP_DEFAULT_PRECIS,
			ANTIALIASED_QUALITY,
			//CLEARTYPE_QUALITY,
			FF_DONTCARE | DEFAULT_PITCH,
			std.string.toString(name)
		);

		oldfont = cast(HFONT)SelectObject(hDC, font);

		abc.length = 256;
		GetCharABCWidthsA(hDC, 0, 255, cast(LPABC)abc.ptr);

		GetTextMetricsA(hDC, &textMetric);

		wglUseFontBitmapsA(hDC, 0, 255, base);

		SelectObject(hDC, oldfont);
		DeleteObject(font);

		//outputMetrics();

		this.height = textMetric.tmAscent - textMetric.tmDescent;
	}

	void outputMetrics() {
		printf("tmHeight: %d\n",  textMetric.tmHeight);
		printf("tmAscent: %d\n",  textMetric.tmAscent);
		printf("tmDescent: %d\n", textMetric.tmDescent);

		printf("tmInternalLeading: %d\n", textMetric.tmInternalLeading);
		printf("tmExternalLeading: %d\n", textMetric.tmExternalLeading);
		printf("tmAveCharWidth: %d\n", textMetric.tmAveCharWidth);
		printf("tmMaxCharWidth: %d\n", textMetric.tmMaxCharWidth);
		printf("tmWeight: %d\n", textMetric.tmWeight);
		printf("tmOverhang: %d\n", textMetric.tmOverhang);
		printf("tmDigitizedAspectX: %d\n", textMetric.tmDigitizedAspectX);
		printf("tmDigitizedAspectY: %d\n", textMetric.tmDigitizedAspectY);
		printf("tmItalic: %d\n", textMetric.tmItalic);
		printf("tmUnderlined: %d\n", textMetric.tmUnderlined);
		printf("tmStruckOut: %d\n", textMetric.tmStruckOut);
		printf("tmPitchAndFamily: %d\n", textMetric.tmPitchAndFamily);
		printf("tmCharSet: %d\n", textMetric.tmCharSet);
	}

	~this() {
		glDeleteLists(base, 256);
	}

	void draw(char[] text, real x, real y, Color c) {
		glColor4f(c.r, c.g, c.b, c.a);
		glRasterPos2i(cast(int)x, cast(int)(y + this.height));

		glPushAttrib(GL_LIST_BIT);
			glListBase(base);
			glCallLists(text.length, GL_UNSIGNED_BYTE, text.ptr);
		glPopAttrib();
	}

	real width(char[] text) {
		int count = 0;
		for (int n = 0; n < text.length; n++) {
			int c = cast(int)text[n];
			if (c >= abc.length) continue;

			if (n > 0) count += abc[c].abcA;
			count += abc[c].abcB;
			if (n < text.length - 1) count += abc[c].abcC;
		}
		return count;
	}
}

class Font {
	FontWindows font;
	FontTTF fontttf;

	real height() {
		if (font is null && fontttf is null) return 0;
		return font ? font.height : fontttf.height;
	}

	private this() {
		fontttf = null;
		font = null;
	}

	this(char[] name, int size, bool bold = false, bool italic = false, bool underline = false, bool strikeout = false) {
		if (std.string.find(std.string.tolower(name), ".ttf") == -1) {
			font = new FontWindows(name, size, bold, italic, underline, strikeout);
		} else {
			fontttf = new FontTTF(name, size);
		}
	}

	~this() {
		if (font) delete font;
		if (fontttf) delete fontttf;
	}

	void draw(char[] text, real x, real y, Color c) {
		if (font) font.draw(text, x, y, c);
		else if (fontttf) fontttf.draw(text, x, y, c);
	}

	real width(char[] text) {
		if (font) return font.width(text);
		else if (fontttf) return fontttf.width(text);
	}

	static Font fromResource(char[] resource, real height, int range = 250) {
		Font font = new Font;
		font.fontttf = FontTTF.fromResource(resource, height, range);
		return font;
	}
}

class FontTTF {
	real height;
	TTF_Font *font;
	GLuint *textures;
	GLuint list_base;
	int[] sizex;

	static this() {
		TTF_Init();
	}

	static ~this() {
		TTF_Quit();
	}

	private static uint __pow2helper(uint n) {
		uint r = 1; while (r < n) r <<= 1; return r;
	}

	void makeGlyph(char c) {
		uint rw, rh;
		SDL_Color color; color.r = color.g = color.b = 0xff;
		SDL_Surface *glyph = TTF_RenderGlyph_Blended(font, c, color);
		if (glyph is null) throw(new Exception("Can't make te glyph"));
		Image.genTexture(glyph, textures[c], rw, rh);

		int minx, maxx, miny, maxy, advance;
		TTF_GlyphMetrics(font, c, &minx, &maxx, &miny, &maxy, &advance);
		//writefln(cast(char)c, ", ", height," (", minx, ", ", maxx, ", ", miny, ", ", maxy, "), (", glyph.w, ", ", glyph.h, ") --> ", advance, ";  ", TTF_FontAscent(font), TTF_FontDescent(font));
		sizex[c] = advance;
		//widthsadv[c] = glyph.w;

		glNewList(list_base + c, GL_COMPILE);
			glPushMatrix();

			glTranslatef(minx, -maxy + TTF_FontAscent(font) + TTF_FontDescent(font), 0);

			float x = cast(float)glyph.w / cast(float)rw, y = cast(float)glyph.h / cast(float)rh;

			glBindTexture(GL_TEXTURE_2D, textures[c]);
			glBegin(GL_POLYGON);
				glTexCoord2f(0, 0); glVertex2f(0, 0);
				glTexCoord2f(x, 0); glVertex2f(glyph.w, 0);
				glTexCoord2f(x, y); glVertex2f(glyph.w, glyph.h);
				glTexCoord2f(0, y); glVertex2f(0, glyph.h);
			glEnd();

			glPopMatrix();
			glTranslatef(advance, 0, 0);

		glEndList();

		SDL_FreeSurface(glyph);
	}

	this(char[] name, real height, int range = 250) {
	//this(char[] name, int size, bool bold = false, bool italic = false, bool underline = false, bool strikeout = false) {
		font = TTF_OpenFont(std.string.toStringz(name), cast(int)(this.height = height));
		textures = new GLuint[range];
		sizex = new int[range];
		list_base = glGenLists(range);
		glGenTextures(range, textures);
		//TTF_SetFontStyle(font, TTF_STYLE_BOLD);
		for (ubyte n = 32; n < range; n++) makeGlyph(n);
		TTF_CloseFont(font);
	}

	this(TTF_Font *font, real height, int range = 250) {
		this.height = height;
		this.font = font;
		textures = new GLuint[range];
		sizex = new int[range];
		list_base = glGenLists(range);
		glGenTextures(range, textures);
		//TTF_SetFontStyle(font, TTF_STYLE_BOLD);
		for (ubyte n = 32; n < range; n++) makeGlyph(n);
		TTF_CloseFont(font);
	}

	real width(char[] text) {
		real w = 0;
		for (int n = 0; n < text.length; n++) w += sizex[text[n]];
		return w;
	}

	void draw(char[] text, real x, real y, Color c) {
		glColor4f(c.r, c.g, c.b, c.a);

		glPushAttrib(GL_LIST_BIT | GL_CURRENT_BIT  | GL_ENABLE_BIT | GL_TRANSFORM_BIT);
		glDisable(GL_LIGHTING);
		glEnable(GL_TEXTURE_2D);
		glDisable(GL_DEPTH_TEST);
		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

		glListBase(list_base);
		glPushMatrix();
			glLoadIdentity();
			glTranslatef(x, y, 0);
			glCallLists(text.length, GL_UNSIGNED_BYTE, text.ptr);
		glPopMatrix();
	}

	~this() {
		//TTF_CloseFont(font);
		glDeleteLists(list_base, 128);
		glDeleteTextures(128, textures);
		delete textures;
	}

	public static FontTTF fromResource(char[] filename, real height, int range = 250) {
		if (!Resources.have(filename)) throw(new Exception("Can't load resource: " ~ filename ~ "'"));

		return new FontTTF(
			TTF_OpenFontRW(
				SDL_RWFromMem(
					Resources.get(filename),
					Resources.size(filename)
				),
				-1,
				cast(int)height
			),
			height,
			range
		);
	}
}
