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

	void DrawTile(u16* tile, u8 pal, int px, int py) {
		//for (int n = 0; n < 16; n++) writef("%02X ", tile[n]); writefln();
		for (int y = 0; y < 8; y++) {
			u16 v = tile[y];
			for (int x = 0; x < 8; x++) {
				//PutPixel(bmp, px + 8 - x, py + y, ((v >> x) & 0b1));
				PutPixel(px + 7 - x, py + y, ((v >> x) & 0b1) | ((v >> 7 >> x) & 0b10));
			}
		}
	}

	void DrawSprite(u16* tile, u8 pal, int px, int py) {
		//for (int n = 0; n < 16; n++) writef("%02X ", tile[n]); writefln();
		for (int y = 0; y < 8; y++) {
			u16 v = tile[y];
			for (int x = 0; x < 8; x++) {
				u8 c = ((v >> x) & 0b1) | ((v >> 7 >> x) & 0b10);
				if (c == 0) continue;
				PutPixel(px + 7 - x, py + y, c);
			}
		}
	}

	void DrawScreen(u8* RAM) {
		//writefln("%08X", RAM);
		for (int y = 0, n = 0; y < 18; y++) {
			for (int x = 0; x < 20; x++, n++) {
				u8 tile = RAM[0x9800 + y * 0x20 + x];
				//writef("%02X", tile);
				DrawTile(cast(u16*)&RAM[0x8000 + tile * 0x10], 0, x * 8, y * 8);
			}
			//writefln();
		}

		// 40 sprites
		for (int n = 0; n < 40; n++) {
			u8 Y = RAM[0xFE00 + n * 4 + 0];
			u8 X = RAM[0xFE00 + n * 4 + 1];
			u8 N = RAM[0xFE00 + n * 4 + 2];
			u8 A = RAM[0xFE00 + n * 4 + 3];

			DrawSprite(cast(u16*)&RAM[0x8000 + N * 0x10], 0, X - 0x08, Y - 0x10);

			if (n == 6) writefln("%02X %02X %02X %02X", X, Y, N, A);
		}
	}
}
