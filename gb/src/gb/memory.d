module gameboy.memory;

import gameboy.common;

import gameboy.joypad, gameboy.lcd;

import std.stream, std.stdio, std.string, std.stream, std.c.stdlib, std.zlib;
import std.c.stdio, std.c.string, std.system;

//version = MTRACE;

class Memory {
	u8 MEM[0x10000];
	bool MEM_TRACED[0x10000];
	JoyPAD pad;
	LCD lcd;

	this() {
		memset(MEM.ptr, 0, MEM.length);
		memset(MEM_TRACED.ptr, 0, MEM_TRACED.length);
	}

	void trace(u16 addr) { MEM_TRACED[addr] = true; }
	bool traced(u16 addr) { return MEM_TRACED[addr]; }

	// Guardamos el estado de la memoria
	void save(Stream s) {
		for (u32 n = 0xFF00; n <= 0xFFFF; n++) {
			MEM[n] = r8(n);
		}
		s.writeExact(MEM.ptr, MEM.length);
	}

	// Cargamos el estado de la memoria
	void load(Stream s) {
		s.readExact(MEM.ptr, MEM.length);
		for (u32 n = 0xFF00; n <= 0xFFFF; n++) {
			w8(n, MEM[n]);
		}
	}

	// Obtenemos la dirección fisica de una zona de memória
	void* addr(u16 addr) { return cast(void *)&MEM[addr]; }
	u8* addr8(u16 addr) { return &MEM[addr]; }

	// Lectura de 8 bits en memoria
	u8 r8(u16 addr) {
		//scope(exit) { MEM_TRACED[addr] = true; }
		//MEMTRACE(addr, format("READ %04X -> %02X", addr, MEM[addr]));

		switch (addr) {
			case 0xFF00: return pad.Read();
			case 0xFF40: return lcd.ReadControl(); break;
			case 0xFF44: break; // FF44 - LY - LCDC Y-Coordinate (R)
			default: break;
		}

		return *cast(u8 *)(MEM.ptr + addr);
	}

	// Escritura de 8 bits en memoria
	void w8(u16 addr, u8 v) {
		if (addr >= 0xFE00 && addr < 0xFEA0) {
			//writefln("OAM %04X <- %02X", addr, v);
			//exit(-1);
		}

		if (addr <= 0x4000) {
			//printf("Escribiendo en ROM [%04X]!!\r", addr);
			//return;
		}

		switch (addr) {
			case 0xFF00: pad.Write(v); break;        // FF00 - P1/JOYP - Joypad (R/W)
			case 0xFF0F: break;                      // FF0F - IF - Interrupt Flag (R/W)
			case 0xFF40: lcd.WriteControl(v); break; // FF40 - LCDC - LCD Control (R/W)
			case 0xFF42: lcd.ScrollY = v; break;     // FF42 - SCY - Scroll Y (R/W)
			case 0xFF43: lcd.ScrollX = v; break;     // FF43 - SCX - Scroll X (R/W)
			case 0xFF44: break;                      // FF44 - LY - LCDC Y-Coordinate (R)
			case 0xFF46: { u16 rp = v << 8; MEM[0xFE00..0xFEA0] = MEM[rp..rp + 0xA0]; } break; // FF46 - DMA - DMA Transfer and Start Address (W)
			case 0xFF47: lcd.SetBackgroundPalette(v); break; // FF47 - BGP - BG Palette Data (R/W) - Non CGB Mode Only
			case 0xFF48: lcd.SetObjectPalette(0, v); break; // FF47 - BGP - BG Palette Data (R/W) - Non CGB Mode Only
			case 0xFF49: lcd.SetObjectPalette(1, v); break; // FF47 - BGP - BG Palette Data (R/W) - Non CGB Mode Only

			default: break;
		}

		// FF80-FFFE High RAM (HRAM)

		*cast(u8 *)(MEM.ptr + addr) = v;
	}

	// Lectura de 16 bits en memoria
	u16 r16(u16 addr) {
		static if (endian == Endian.BigEndian) {
			return r8(addr) | (r8(addr + 1) << 8);
		} else {
			return r8(addr + 1) | (r8(addr) << 8);
		}
	}

	// Escritura de 8 bits en memoria
	void w16(u16 addr, u16 v) {
		static if (endian == Endian.BigEndian) {
			w8(addr + 0, (v >> 0) & 0xFF);
			w8(addr + 1, (v >> 8) & 0xFF);
		} else {
			w8(addr + 0, (v >> 8) & 0xFF);
			w8(addr + 1, (v >> 0) & 0xFF);
		}
	}

	void MEMTRACE(int addr, char[] s, bool critical = false) {
		if (addr >= 0xFF00 || critical) {
			writefln("%s", s);
		}
	}
}
