module gameboy.lcd;

import gameboy.common;

import std.stream, std.stdio, std.system;

class LCD {
	u8 LCDIMG[0x1680];

	// Guardamos el estado del LCD
	void save(Stream s) { throw(new Exception("TO DO")); }

	// Cargamos el estado del LCD
	void load(Stream s) { throw(new Exception("TO DO")); }

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

	void DrawTile(u16* tile, u8 pal, int px, int py, bool trans = false, bool xflip = false, bool yflip = false) {
		//for (int n = 0; n < 16; n++) writef("%02X ", tile[n]); writefln();
		for (int y = 0; y < 8; y++) {
			u16 v = tile[y];
			for (int x = 0; x < 8; x++) {
				//PutPixel(bmp, px + 8 - x, py + y, ((v >> x) & 0b1));
				PutPixel(px + 7 - x, py + y, ((v >> x) & 0b1) | ((v >> 7 >> x) & 0b10));
			}
		}
	}

	void DrawScreen(u8* VRAM) {
		//writefln("%08X", VRAM);
		for (int y = 0, n = 0; y < 18; y++) {
			for (int x = 0; x < 20; x++, n++) {
				u8 tile = VRAM[0x1800 + y * 0x20 + x];
				//writef("%02X", tile);
				DrawTile(cast(u16*)&VRAM[0x0000 + tile * 0x10], 0, x * 8, y * 8);
			}
			//writefln();
		}
		//writefln();
	}
}
