/*
  SDL_ttf:	A companion library to SDL for working with TrueType (tm) fonts
  Copyright (C) 1997, 1998, 1999, 2000, 2001  Sam Lantinga

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Library General Public
  License as published by the Free Software Foundation; either
  version 2 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the GNU
  Library General Public License for more details.

  You should have received a copy of the GNU Library General Public
  License along with this library; if not, write to the Free
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA	02111-1307	USA

  Sam Lantinga
  slouken@libsdl.org
*/

/* $Id: SDL_ttf.d,v 1.1 2006/01/03 23:54:33 soywiz Exp $ */

// convert to D by shinichiro.h

/* This library is a wrapper around the excellent FreeType 2.0 library,
   available at:
   http://www.freetype.org/
*/

import SDL;

extern (C) {

/* The internal structure containing font information */
	struct TTF_Font {}

/* Initialize the TTF engine - returns 0 if successful, -1 on error */
	int TTF_Init();

/* Open a font file and create a font of the specified point size */
	TTF_Font * TTF_OpenFont(char *file, int ptsize);
	TTF_Font * TTF_OpenFontIndex(char *file, int ptsize, long index);

	TTF_Font * TTF_OpenFontRW(SDL_RWops *src, int freesrc, int ptsize);
	TTF_Font * TTF_OpenFontIndexRW(SDL_RWops *src, int freesrc, int ptsize, long index);

/* Set and retrieve the font style
   This font style is implemented by modifying the font glyphs, and
   doesn't reflect any inherent properties of the truetype font file.
*/
	const int TTF_STYLE_NORMAL = 0x00;
	const int TTF_STYLE_BOLD = 0x01;
	const int TTF_STYLE_ITALIC = 0x02;
	const int TTF_STYLE_UNDERLINE = 0x04;
	int TTF_GetFontStyle(TTF_Font *font);
	void TTF_SetFontStyle(TTF_Font *font, int style);

/* Get the total height of the font - usually equal to point size */
	int TTF_FontHeight(TTF_Font *font);

/* Get the offset from the baseline to the top of the font
   This is a positive value, relative to the baseline.
*/
	int TTF_FontAscent(TTF_Font *font);

/* Get the offset from the baseline to the bottom of the font
   This is a negative value, relative to the baseline.
*/
	int TTF_FontDescent(TTF_Font *font);

/* Get the recommended spacing between lines of text for this font */
	int TTF_FontLineSkip(TTF_Font *font);

/* Get the number of faces of the font */
	long TTF_FontFaces(TTF_Font *font);

/* Get the font face attributes, if any */
	int TTF_FontFaceIsFixedWidth(TTF_Font *font);
	char * TTF_FontFaceFamilyName(TTF_Font *font);
	char * TTF_FontFaceStyleName(TTF_Font *font);

/* Get the metrics (dimensions) of a glyph */
	int TTF_GlyphMetrics(TTF_Font *font, Uint16 ch,
												 int *minx, int *maxx,
												 int *miny, int *maxy, int *advance);

/* Get the dimensions of a rendered string of text */
	int TTF_SizeText(TTF_Font *font, char *text, int *w, int *h);
	int TTF_SizeUTF8(TTF_Font *font, char *text, int *w, int *h);
	int TTF_SizeUNICODE(TTF_Font *font, Uint16 *text, int *w, int *h);

/* Create an 8-bit palettized surface and render the given text at
   fast quality with the given font and color.	The 0 pixel is the
   colorkey, giving a transparent background, and the 1 pixel is set
   to the text color.
   This function returns the new surface, or NULL if there was an error.
*/
	SDL_Surface * TTF_RenderText_Solid(TTF_Font *font,
															   char *text, SDL_Color fg);
	SDL_Surface * TTF_RenderUTF8_Solid(TTF_Font *font,
															   char *text, SDL_Color fg);
	SDL_Surface * TTF_RenderUNICODE_Solid(TTF_Font *font,
																  Uint16 *text, SDL_Color fg);

/* Create an 8-bit palettized surface and render the given glyph at
   fast quality with the given font and color.	The 0 pixel is the
   colorkey, giving a transparent background, and the 1 pixel is set
   to the text color.  The glyph is rendered without any padding or
   centering in the X direction, and aligned normally in the Y direction.
   This function returns the new surface, or NULL if there was an error.
*/
	SDL_Surface * TTF_RenderGlyph_Solid(TTF_Font *font,
																Uint16 ch, SDL_Color fg);

/* Create an 8-bit palettized surface and render the given text at
   high quality with the given font and colors.  The 0 pixel is background,
   while other pixels have varying degrees of the foreground color.
   This function returns the new surface, or NULL if there was an error.
*/
	SDL_Surface * TTF_RenderText_Shaded(TTF_Font *font,
																char *text, SDL_Color fg, SDL_Color bg);
	SDL_Surface * TTF_RenderUTF8_Shaded(TTF_Font *font,
																char *text, SDL_Color fg, SDL_Color bg);
	SDL_Surface * TTF_RenderUNICODE_Shaded(TTF_Font *font,
																   Uint16 *text, SDL_Color fg, SDL_Color bg);

/* Create an 8-bit palettized surface and render the given glyph at
   high quality with the given font and colors.  The 0 pixel is background,
   while other pixels have varying degrees of the foreground color.
   The glyph is rendered without any padding or centering in the X
   direction, and aligned normally in the Y direction.
   This function returns the new surface, or NULL if there was an error.
*/
	SDL_Surface * TTF_RenderGlyph_Shaded(TTF_Font *font,
																 Uint16 ch, SDL_Color fg, SDL_Color bg);

/* Create a 32-bit ARGB surface and render the given text at high quality,
   using alpha blending to dither the font with the given color.
   This function returns the new surface, or NULL if there was an error.
*/
	SDL_Surface * TTF_RenderText_Blended(TTF_Font *font,
																 char *text, SDL_Color fg);
	SDL_Surface * TTF_RenderUTF8_Blended(TTF_Font *font,
																 char *text, SDL_Color fg);
	SDL_Surface * TTF_RenderUNICODE_Blended(TTF_Font *font,
																	Uint16 *text, SDL_Color fg);

/* Create a 32-bit ARGB surface and render the given glyph at high quality,
   using alpha blending to dither the font with the given color.
   The glyph is rendered without any padding or centering in the X
   direction, and aligned normally in the Y direction.
   This function returns the new surface, or NULL if there was an error.
*/
	SDL_Surface * TTF_RenderGlyph_Blended(TTF_Font *font,
																  Uint16 ch, SDL_Color fg);

/* For compatibility with previous versions, here are the old functions */
	SDL_Surface* TTF_RenderText(TTF_Font* font, char* text,
								SDL_Color fg, SDL_Color bg) {
		return TTF_RenderText_Shaded(font, text, fg, bg);
	}
	SDL_Surface* TTF_RenderUTF8(TTF_Font* font, char* text,
								SDL_Color fg, SDL_Color bg) {
		return TTF_RenderUTF8_Shaded(font, text, fg, bg);
	}
	SDL_Surface* TTF_RenderUNICODE(TTF_Font* font, Uint16* text,
								SDL_Color fg, SDL_Color bg) {
		return TTF_RenderUNICODE_Shaded(font, text, fg, bg);
	}

/* Close an opened font file */
	void TTF_CloseFont(TTF_Font *font);

/* De-initialize the TTF engine */
	void TTF_Quit();

/* We'll use SDL for reporting errors */
//#define TTF_SetError	SDL_SetError
	char* TTF_GetError() {
		return SDL_GetError();
	}
}
