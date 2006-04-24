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

import std.c.windows.windows, std.math, opengl, SDL_syswm;

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

class Font {
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

	this(char[] name, int size, bit bold = false, bit italic = false, bit underline = false, bit strikeout = false) {
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
		glColor3f(c.r, c.g, c.b);
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