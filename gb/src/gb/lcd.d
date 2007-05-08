module gameboy.lcd;

import gameboy.common;

import std.stream, std.stdio, std.system, std.c.string;

class LCD {
	u8 LCDIMG[0x1680];

	int sx, sy;

	void PutPixel(int px, int py, u8 c) {
		if (px < 0 || px >= 160 || py < 0 || py >= 144) return;
		u8* b = &LCDIMG[py * 40 + px / 4]; c &= 0b11;
		switch (px % 4) {
			case 0b00: *b = (*b & 0b11111100) | (c << 0); break;
			case 0b01: *b = (*b & 0b11110011) | (c << 2); break;
			case 0b10: *b = (*b & 0b11001111) | (c << 4); break;
			case 0b11: *b = (*b & 0b00111111) | (c << 6); break;
		}
	}

	void DrawTile(u16* tile, u8 pal, uint px, uint py) {
		//for (int n = 0; n < 16; n++) writef("%02X ", tile[n]); writefln();
		for (int y = 0; y < 8; y++) {
			u16 v = tile[y];
			for (int x = 0; x < 8; x++) {
				u8 c = ((v >> x) & 0b1) | ((v >> 7 >> x) & 0b10);
				if (c == 0) continue;
				//PutPixel(bmp, px + 8 - x, py + y, ((v >> x) & 0b1));
				PutPixel(px + 7 - x, py + y, c);
			}
		}
	}

	/*
		Bit7   OBJ-to-BG Priority (0=OBJ Above BG, 1=OBJ Behind BG color 1-3)
		 (Used for both BG and Window. BG color 0 is always behind OBJ)
		Bit6   Y flip          (0=Normal, 1=Vertically mirrored)
		Bit5   X flip          (0=Normal, 1=Horizontally mirrored)
		Bit4   Palette number  **Non CGB Mode Only** (0=OBP0, 1=OBP1)
		Bit3   Tile VRAM-Bank  **CGB Mode Only**     (0=Bank 0, 1=Bank 1)
		Bit2-0 Palette number  **CGB Mode Only**     (OBP0-7)
	*/
	void DrawSprite(u16* tile, u8 pal, uint px, uint py, u8 A) {
		const u8 XflipMask = 0b00100000, YflipMask = 0b01000000, PaletteMask = 0b00001000, PriorityMask = 0b10000000;

		for (int y = 0; y < 8; y++) {
			u16 v = tile[y];
			for (int x = 0; x < 8; x++) {
				u8 c = ((v >> x) & 0b1) | ((v >> 7 >> x) & 0b10);
				//if (c == 0 && ((A & PriorityMask) == 0)) continue;
				if (c == 0) continue;
				PutPixel(
					(A & XflipMask) ? (px + 0 + x) : (px + 7 - x),
					(A & YflipMask) ? (py + 7 - y) : (py + 0 + y),
					(objPalette[(A & PaletteMask) != 0] >> (c << 1)) & 0b11
				);
			}
		}
	}

	// Pintamos los sprites con una prioridad
	void DrawSprites(u8* RAM, u8 priority) {
		// 40 sprites
		for (int n = 0; n < 40; n++) {
			u8 Y = RAM[0xFE00 + n * 4 + 0];
			u8 X = RAM[0xFE00 + n * 4 + 1];
			u8 N = RAM[0xFE00 + n * 4 + 2];
			u8 A = RAM[0xFE00 + n * 4 + 3];

			if (priority != ((A >> 7) & 1)) continue;
			DrawSprite(cast(u16*)&RAM[0x8000 + N * 0x10], 0, cast(int)(X) - 0x08, cast(int)(Y) - 0x10, A);
		}
	}

	void DrawScreen(u8* RAM) {
		// Limpiamos la pantalla
		memset(LCDIMG.ptr, 0, LCDIMG.length);

		// Si no está habilitado el lcd, dejamos de mostrar cosas
		if (!lcdEnable) return;

		// Si están habilitados los objetos, pintamos los que tienen prioridad 0
		if (objEnable) DrawSprites(RAM, 1);

		// Background
		for (int y = 0, n = 0; y < 18 + 1; y++) {
			for (int x = 0; x < 20 + 1; x++, n++) {
				int px, py;
				px = x + cast(u8)sx / 8;
				py = y + cast(u8)sy / 8;

				px %= 32; py %= 32;

				if (px >= 32 || py >= 32) continue;
				if (px < 0 || py < 0) continue;

				u8 tile = RAM[mapBackground + py * 0x20 + px];
				DrawTile(cast(u16*)&RAM[tileBGWindow + tile * 0x10], 0, x * 8 - sx % 8, y * 8 - sy % 8);
			}
		}

		// Si están habilitados los objetos, pintamos los que tienen prioridad 1
		if (objEnable) DrawSprites(RAM, 0);
	}

	//
	void ScrollX(u8 x) {
		sx = x;
		//printf("SCROLL: %d, %d\t\t\r", sx, sy);
	}

	void ScrollY(u8 y) {
		sy = y;
		//printf("SCROLL: %d, %d\t\t\r", sx, sy);
	}

	u8 control;

	bool lcdEnable, windowEnable, objEnable, bgEnable;
	u16 mapWindow, mapBackground, tileBGWindow;
	u8 objSize;
	u8 bgPalette;
	u8 objPalette[2];

	void WriteControl(u8 v) {
		control = v;

		lcdEnable     = ((control & 0b10000000) != 0); // Bit 7 - LCD Display Enable             (0=Off, 1=On)
		mapWindow     = ((control & 0b01000000) == 0) ? 0x9800 : 0x9C00; // Bit 6 - Window Tile Map Display Select (0=9800-9BFF, 1=9C00-9FFF)
		windowEnable  = ((control & 0b00100000) != 0); // Bit 5 - Window Display Enable          (0=Off, 1=On)
		tileBGWindow  = ((control & 0b00010000) == 0) ? 0x8800 : 0x8000; // Bit 4 - BG & Window Tile Data Select   (0=8800-97FF, 1=8000-8FFF)
		mapBackground = ((control & 0b00001000) == 0) ? 0x9800 : 0x9C00; // Bit 3 - BG Tile Map Display Select     (0=9800-9BFF, 1=9C00-9FFF)
		objSize       = ((control & 0b00000100) == 0) ? 8 : 16; // Bit 2 - OBJ (Sprite) Size              (0=8x8, 1=8x16)
		objEnable     = ((control & 0b00000010) != 0); // Bit 1 - OBJ (Sprite) Display Enable    (0=Off, 1=On)
		bgEnable      = ((control & 0b00000001) != 0); // Bit 0 - BG Display (for CGB see below) (0=Off, 1=On)
	}

	void WriteStatus() { // FF41 - STAT - LCDC Status (R/W)
		/*
		Bit 6 - LYC=LY Coincidence Interrupt (1=Enable) (Read/Write)
		Bit 5 - Mode 2 OAM Interrupt         (1=Enable) (Read/Write)
		Bit 4 - Mode 1 V-Blank Interrupt     (1=Enable) (Read/Write)
		Bit 3 - Mode 0 H-Blank Interrupt     (1=Enable) (Read/Write)
		Bit 2 - Coincidence Flag  (0:LYC<>LY, 1:LYC=LY) (Read Only)
		Bit 1-0 - Mode Flag       (Mode 0-3, see below) (Read Only)
			0: During H-Blank
			1: During V-Blank
			2: During Searching OAM-RAM
			3: During Transfering Data to LCD Driver
		*/
	}

	u8 ReadControl() {
		return control;
	}

	void SetBackgroundPalette(u8 v) {
		bgPalette = v;
	}

	void SetObjectPalette(u8 p, u8 v) {
		objPalette[p] = v;
	}
}
