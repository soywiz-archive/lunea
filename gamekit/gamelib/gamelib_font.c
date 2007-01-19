#include "gamelib.h"
#include "gamelib_internal.h"

int __FontCreateGlyph(TTF_Font *font, Font ttf, int c) {
	int minx, maxx, miny, maxy, advance;
	int rw = 1, rh = 1; SDL_Rect dest; SDL_Color color = {0xff, 0xff, 0xff};
	SDL_Surface *temp, *glyph = TTF_RenderGlyph_Blended(font, c, color);
	if (glyph == 0) return -1;

	temp = __SDL_CreateRGBSurfaceForOpenGL(glyph->w, glyph->h, &rw, &rh);

	dest.x = dest.y = 0; dest.w = rw; dest.h = rh;
	SDL_SetAlpha(glyph, 0, 0);
	SDL_BlitSurface(glyph, 0, temp, &dest);
	glBindTexture(GL_TEXTURE_2D, ttf->textures[c]);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexImage2D(GL_TEXTURE_2D, 0, 4, rw, rh, 0, GL_RGBA, GL_UNSIGNED_BYTE, temp->pixels);
	SDL_FreeSurface(temp); TTF_GlyphMetrics(font, c, &minx, &maxx, &miny, &maxy, &advance);
	ttf->w[c] = advance;

	glNewList (ttf->listBase + c, GL_COMPILE);
		glPushMatrix();

		glTranslatef(minx, -maxy + TTF_FontAscent(font) + TTF_FontDescent(font), 0);

		float x = (float)glyph->w / (float)rw, y = (float)glyph->h / (float)rh;

		glBindTexture(GL_TEXTURE_2D, ttf->textures[c]);
		glBegin(GL_POLYGON);
			glTexCoord2f(0, 0); glVertex2f(0, 0);
			glTexCoord2f(x, 0); glVertex2f(glyph->w, 0);
			glTexCoord2f(x, y); glVertex2f(glyph->w, glyph->h);
			glTexCoord2f(0, y); glVertex2f(0, glyph->h);
		glEnd();

		glPopMatrix();
		glTranslatef(advance, 0, 0);
	glEndList();

	glBindTexture(GL_TEXTURE_2D, 0);

	SDL_FreeSurface(glyph);

	return 0;
}

__inline Font FontLoadFromStreamEx(Stream s, int freesrc, int height) {
	Font f; int n;
	TTF_Font *ttf = TTF_OpenFontRW(s, freesrc, height);
	f = (Font)malloc(_Font);
	if (!ttf || !f) return NULL;
	f->listBase = glGenLists(0x100);
	f->h = height;
	glGenTextures(0x100, f->textures);
	for (n = 32; n < 0x100; n++) __FontCreateGlyph(ttf, f, n);
	TTF_CloseFont(ttf);

	return f;
}

Font FontLoadFromStream(Stream s, int height) {
	return FontLoadFromStreamEx(s, 0, height);
}

Font FontLoadFromMemory(void *ptr, int length, int height) {
	return FontLoadFromStreamEx(SDL_RWFromMem(ptr, length), 1, height);
}

Font FontLoadFromFile(char *filename, int height) {
	Font f = FontLoadFromStreamEx(SDL_RWFromFile(filename, "rb"), 1, height);

	if (!f) {
		SDL_SetError("Can't open ttf font '%s'", filename);
		GamePrintError();
	}

	return f;
}

int FontWidth(Font f, char *text) {
	int r = 0, n, l;
	for (n = 0, l = strlen(text); n < l; n++) r += f->w[(int)text[n]];
	return r;
}

void FontFree(Font f) {
	if (f == NULL) return;

	glDeleteTextures(0x100, f->textures);
	glDeleteLists(f->listBase, 0x100);

	free(f);
}

void DrawFont(Font font, int x, int y, char *text) {
	glPushAttrib(GL_LIST_BIT | GL_CURRENT_BIT  | GL_ENABLE_BIT | GL_TRANSFORM_BIT);
		glLoadIdentity();

		glDisable(GL_LIGHTING); glEnable(GL_TEXTURE_2D);
		glDisable(GL_DEPTH_TEST); glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

		glListBase(font->listBase);
		glPushMatrix();
			glTranslatef((float)x, (float)y, 0.0f);
			glScalef(1.0f, 1.0f, 1.0f);
			glCallLists(strlen(text), GL_UNSIGNED_BYTE, text);
		glPopMatrix();
	glPopAttrib();
}
