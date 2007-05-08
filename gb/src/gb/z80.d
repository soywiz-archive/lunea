module gameboy.z80;

public import gameboy.common;

import pdcurses;

import gameboy.lcd;
import gameboy.joypad;
import gameboy.memory;

import std.stdio, std.string, std.stream, std.c.stdlib, std.zlib, std.system, std.c.string;

// Diferentes versiones (depuración etc.)
//version = trace;

/*
	References:
	- http://www.work.de/nocash/pandocs.htm
	- BasicBoy

	CPU          - 8-bit (Similar to the Z80 processor)
	Clock Speed  - 4.194304MHz (4.295454MHz for SGB, max. 8.4MHz for CGB)
	Work RAM     - 8K Byte (32K Byte for CGB)
	Video RAM    - 8K Byte (16K Byte for CGB)
	Screen Size  - 2.6"
	Resolution   - 160x144 (20x18 tiles)
	Max sprites  - Max 40 per screen, 10 per line
	Sprite sizes - 8x8 or 8x16
	Palettes     - 1x4 BG, 2x3 OBJ (for CGB: 8x4 BG, 8x3 OBJ)
	Colors       - 4 grayshades (32768 colors for CGB)
	Horiz Sync   - 9198 KHz (9420 KHz for SGB)
	Vert Sync    - 59.73 Hz (61.17 Hz for SGB)
	Sound        - 4 channels with stereo sound
	Power        - DC6V 0.7W (DC3V 0.7W for GB Pocket, DC3V 0.6W for CGB)

	External Memory and Hardware
	The areas from 0000-7FFF and A000-BFFF may be used to connect external hardware.
	The first area is typically used to address ROM (read only, of course), cartridges
	with Memory Bank Controllers (MBCs) are additionally using this area to output data
	(write only) to the MBC chip. The second area is often used to address external RAM,
	or to address other external hardware (Real Time Clock, etc). External memory is
	often battery buffered, and may hold saved game positions and high scrore tables
	(etc.) even when the gameboy is turned of, or when the cartridge is removed. For
	specific information read the chapter about Memory Bank Controllers.

	Regs:
	16bit Hi   Lo   Name/Function
	AF    A    -    Accumulator & Flags
	BC    B    C    BC
	DE    D    E    DE
	HL    H    L    HL
	SP    -    -    Stack Pointer
	PC    -    -    Program Counter/Pointer

	Flags:
	C - Carry Flag
	H - Half-Carry Flag
	N - Add-Sub Flag
	Z - Zero Flag
*/

/*

GB  - GameBoy
SGB - SuperGameBoy - Cartuchos de GameBoy usados en la SuperNintendo (SNES). El clock se aumenta, y existe
      la posibilidad de ponerle un borde al juego, que se añade en juegos compatibles. Añade también la posibilidad
      de paletas de color.
CGB - GameBoyColor. Se duplica la velocidad del reloj. La pantalla soporta 15bits de colores; 5 bits por registro.

Ni la SuperGameBoy ni la GameBoyColor están planeadas soportarse por ahora.

*/

// Interface usado para mantener la portabilidad entre diferentes plataformas y sistemas
interface GameboyHostSystem {
	void UpdateScreen(int type, u8* LCDSCR);
	void attach(GameBoy gb);
}

// Clase encargada de emular una GameBoy
class GameBoy {
	// Al crear la instancia
	this(GameboyHostSystem ghs) {
		this.ghs = ghs;        // GameboyHostSystem
		this.lcd = new LCD;    // Display LCD
		this.mem = new Memory; // Memoria
		this.pad = new JoyPAD; // JoyPAD
		ghs.attach(this);
		this.mem.pad = this.pad;
		this.mem.lcd = this.lcd;
		IE = this.mem.addr8(0xFFFF);
		IF = this.mem.addr8(0xFF0F);
	}

	// Al borrar la instancia
	~this() {
		console.clear();
		console.refresh();
		//dump();
	}

	bool pexit = false;

	void close() {
		pexit = true;
	}

	// Cabecera de la ROM en la posición 0x100
	align(1) struct RomHeader {
		u8  entry[0x4];   // 0100-0103 - Entry Point
		u8  logo [0x30];  // 0104-0133 - Nintendo Logo
		u8  title[0x10];  // 0134-0143 - Title
		u8  manu [0x4];   // 013F-0142 - Manufacturer Code
		u8  cgbf;         // 0143      - CGB Flag
		u16 nlcode;       // 0144-0145 - New Licensee Code
		u8  scgf;         // 0146      - SGB Flag
		u8  type;         // 0147      - Cartridge Type
		u8  romsize;      // 0148      - ROM Size
		u8  ramsize;      // 0149      - RAM Size
		u8  region;       // 014A      - Destination Code: 00 JAP | 01 NO JAP
		u8  liccode;      // 014B      - Old Licensee Code
		u8  mromvn;       // 014C      - Mask ROM Version number
		u8  hchecksum;    // 014D      - Header Checksum (x=0:FOR i=0134h TO 014Ch:x=x-MEM[i]-1:NEXT)
		u16 gchecksum;    // 014E-014F - Global Checksum (Produced by adding all bytes of the cartridge (except for the two checksum bytes))
	}

	char[] romName() {
		char[] title;
		char *ptr = cast(char *)rh.title;
		int len = strlen(ptr);
		for (int n = 0; n < len; n++) {
			if (ptr[n] >= 32 && ptr[n] <= 0x7F) {
				title ~= ptr[n];
			} else {
				title ~= "";
			}
		}
		return strip(title);
	}

	GameboyHostSystem ghs;
	Stream    rom; // Stream
	RomHeader *rh; // Header
	Memory    mem; // Memoria
	LCD       lcd; // LCD
	JoyPAD    pad; // JoyPAD

	bool dotrace;

	// Registros
	static if (endian == Endian.BigEndian) {
		union { u16 AF; struct { u8 A; u8 F; } } union { u16 BC; struct { u8 B; u8 C; } }
		union { u16 DE; struct { u8 D; u8 E; } } union { u16 HL; struct { u8 H; u8 L; } }
	} else {
		union { u16 AF; struct { u8 F; u8 A; } } union { u16 BC; struct { u8 C; u8 B; } }
		union { u16 DE; struct { u8 E; u8 D; } } union { u16 HL; struct { u8 L; u8 H; } }
	}
	u16 SP;  // Stack Pointer
	u16 PC;  // Program Counter
	u8  IME; // Interrupt Master Enable Flag (Write Only)
	u8 *IE; // FFFF - IE - Interrupt Enable (R/W)
	u8 *IF; // FF0F - IF - Interrupt Flag (R/W)

	// Carry Flag
	static const u8 CFMASK = 0b00010000;
	bool CF() { return (F & CFMASK) != 0; }
	void CF(bool set) { if (set) F |= CFMASK; else F &= ~CFMASK; }

	// Half Carry Flag
	static const u8 HFMASK = 0b00100000;
	bool HF() { return (F & HFMASK) != 0; }
	void HF(bool set) { if (set) F |= HFMASK; else F &= ~HFMASK; }

	// Add/Sub-Flag
	static const u8 NFMASK = 0b01000000;
	bool NF() { return (F & NFMASK) != 0; }
	void NF(bool set) { if (set) F |= NFMASK; else F &= ~NFMASK; }

	// Zero Flag
	static const u8 ZFMASK = 0b10000000;
	bool ZF() { return (F & ZFMASK) != 0; }
	void ZF(bool set) { if (set) F |= ZFMASK; else F &= ~ZFMASK; }

	// Mostramos un volcado de los registros y de los entornos de la pila
	void RegDump(Stream s) {
		s.writefln(
			"PC:[%04X] | " "AF:%04X " "BC:%04X "
			"DE:%04X " "HL:%04X "
			"| SP:%04X " "| IME:%02X | "
			"Z%d " "N%d "
			"H%d " "C%d ",
			PC, AF, BC, DE,
			HL, SP, IME,
			ZF, NF, HF, CF
		);
		s.writefln("STACK {");
			//for (int n = SP - 12; n <= SP + 18; n += 2) {
			for (int n = SP - 6; n <= SP + 0; n += 2) {
				if (n < 0xFFFE) {
					s.writefln("  %04X: %04X", n, mem.r16(n));
				}
			}
		s.writefln("}");
	}

	// Utilitarios
	int cycles;   // Cantidad de ciclos * 1000 ejecutados
	int vbcycles; // Cantidad de ciclos de reloj usado para las scanlines
	u64 mmsec;    // Microsegundos

	bool sgb = false; // Emulacion de Super GameBoy
	bool cgb = false; // Emulación de GameBoy Color

	// Cargamos la rom
	void loadRom(char[] name) { loadRom(new File(name, FileMode.In)); }
	void loadRom(Stream s) {
		rom = s;
		rh = cast(RomHeader *)(mem.addr(0x100));
	}

	void unloadRom() {
		if (rom) rom.close();
	}

	// Elegimos el banco0 de la rom (será fijo siempre)
	void switchRomBank0(u8 bank) {
		rom.position = 0x4000 * bank;
		rom.readExact(mem.addr8(0x0000), 0x4000);
	}

	// Elegimos el banco1 de la rom (se puede cambiar para roms mayores de 32K)
	void switchRomBank1(u8 bank) {
		rom.position = 0x4000 * bank;
		rom.readExact(mem.addr8(0x4000), 0x4000);
	}

	// Inicializamos la emulación y establecemos ciertas zona de memória y el valor
	// de los registros. El resto de la memória puede contener cualquier valor, aunque
	// generalmente los emuladores la vacían a 0. Aún así, los propios juegos deben
	// definir la memória que quieran usar.
	void init() {
		switchRomBank0(0);
		switchRomBank1(1);

		AF = 0x01B0; BC = 0x0013;
		DE = 0x00D8; HL = 0x014D;
		SP = 0xFFFE; PC = 0x0100;
		mw8(0xFF05, 0x00); // TIMA
		mw8(0xFF06, 0x00); // TMA
		mw8(0xFF07, 0x00); // TAC
		mw8(0xFF10, 0x80); // NR10
		mw8(0xFF11, 0xBF); // NR11
		mw8(0xFF12, 0xF3); // NR12
		mw8(0xFF14, 0xBF); // NR14
		mw8(0xFF16, 0x3F); // NR21
		mw8(0xFF17, 0x00); // NR22
		mw8(0xFF19, 0xBF); // NR24
		mw8(0xFF1A, 0x7F); // NR30
		mw8(0xFF1B, 0xFF); // NR31
		mw8(0xFF1C, 0x9F); // NR32
		mw8(0xFF1E, 0xBF); // NR33
		mw8(0xFF20, 0xFF); // NR41
		mw8(0xFF21, 0x00); // NR42
		mw8(0xFF22, 0x00); // NR43
		mw8(0xFF23, 0xBF); // NR30
		mw8(0xFF24, 0x77); // NR50
		mw8(0xFF25, 0xF3); // NR51
		mw8(0xFF26, sgb ? 0xF0 : 0xF1); // NR52
		mw8(0xFF40, 0x91); // LCDC
		mw8(0xFF42, 0x00); // SCY
		mw8(0xFF43, 0x00); // SCX
		mw8(0xFF45, 0x00); // LYC
		mw8(0xFF47, 0xFC); // BGP
		mw8(0xFF48, 0xFF); // OBP0
		mw8(0xFF49, 0xFF); // OBP1
		mw8(0xFF4A, 0x00); // WY
		mw8(0xFF4B, 0x00); // WX
		mw8(0xFFFF, 0x00); // IE
	}

	void mw16(u16 addr, u8 v) {
		mem.w16(addr, v);
	}

	u16 mr16(u16 addr) {
		return mem.r16(addr);
	}

	u8 mr8(u16 addr) {
		return mem.r8(addr);
	}

	void mw8(u16 addr, u8 v) {
		//if (addr == 0xC021) printf("MEM[%04X] <- (%02X) | PC(%04X)\r", addr, v, PC);
		//if (addr == 0xFF88) printf("MEM[%04X] <- (%02X) | PC(%04X)\r", addr, v, PC);
		//if (addr == 0xC212) printf("MEM[%04X] <- (%02X) | PC(%04X)\r", addr, v, PC);
		mem.w8(addr, v);
	}

	// Un VBLANK se ejecuta 59.7 veces por segundo en la GB y 61.1 en SGB
	// Un scanline se ejecuta (59.7 / 154)
	void incScanLine() {
		u8* scanline = mem.addr8(0xFF44);
		/*
			FF44 - LY - LCDC Y-Coordinate (R)
			The LY indicates the vertical line to which the present data is transferred
			to the LCD Driver. The LY can take on any value between 0 through 153. The
			values between 144 and 153 indicate the V-Blank period. Writing will reset the counter.
		*/
		*scanline = (*scanline + 1) % 154;

		// Si el scanline es 144, estamos ya en una línea offscreen y por tanto aprovechamos para generar
		// la interrupción V-Blank
		if (*scanline == 144) {
			lcd.DrawScreen(mem.addr8(0x0000));
			ghs.UpdateScreen(0, lcd.LCDIMG.ptr);
			interrupt(0x40);
		}
	}

	// Procesa las interrupciones
	void interrupt_process() {
		if (!IME) return;

		bool check(u8 b) { return (*IF & b) && (*IE & b); }

		if (check(0b00001)) { IME = false; RST(0x40 >> 3); RES(0, IF); return; } // V-Blank
		if (check(0b00010)) { IME = false; RST(0x48 >> 3); RES(1, IF); return; } // LCD STAT
		if (check(0b00100)) { IME = false; RST(0x50 >> 3); RES(2, IF); return; } // Timer
		if (check(0b01000)) { IME = false; RST(0x58 >> 3); RES(3, IF); return; } // Serial
		if (check(0b10000)) { IME = false; RST(0x60 >> 3); RES(4, IF); return; } // Joypad
	}

	// Produce una interrupción
	void interrupt(u8 type) {
		switch (type) {
			case 0x40: SET(0, IF); break; // V-Blank
			case 0x48: SET(1, IF); break; // LCD STAT
			case 0x50: SET(2, IF); break; // Timer
			case 0x58: SET(3, IF); break; // Serial
			case 0x60: SET(4, IF); break; // Joypad
		} // switch

		interrupt_process();
	}

	// Crea una dump de memória
	void save(Stream s) {
		mem.save(s);
		s.writeExact(&A, (&IME - &A) + IME.sizeof);
	}

	void save(char[] name) {
		writef("Saving (%s)...", name);
		try {
			File f = new File(name, FileMode.OutNew);
			save(f);
			f.close();
			writefln("Ok");
		} catch {
			writefln("Error");
		}
	}

	void load(Stream s) {
		mem.load(s);
		s.readExact(&A, (&IME - &A) + IME.sizeof);
		stop = false;
	}

	void load(char[] name) {
		writef("Loading (%s)...", name);
		try {
			File f = new File(name, FileMode.In);
			load(f);
			f.close();
			writefln("Ok");
		} catch {
			writefln("Error");
		}
	}

	void dump() {
		save("dump");
	}

	// Añade ciclos para simular el retraso
	void updateCycles() {
		static const int slcyc = (0x400000 / 4) / 9198;

		while (vbcycles >= slcyc) {
			incScanLine();
			vbcycles -= slcyc;
		}
	}

	void writeMem(u16 addr, int line, int lines = 5) {
		for (int y = 0, n = addr; y < lines; y++) {
			console.move(line + y, 0);

			console.print(format("%04X: [", n));

			for (int x = 0; x < 16; x++) {
				if (x != 0) console.print(" ");
				console.print(format("%02X", mem.r8(n + x)));
			}

			console.print(format("] ["));

			for (int x = 0; x < 16; x++) {
				u8 b = mem.r8(n + x);
				console.addch(b);
			}

			console.print(format("]"));

			n += 16;
		}
	}

	void updateStatus() {
		console.move(0, 0);
		console.print(repeat("-", 80));
		console.move(1, 8);
		console.print(format("PC: %04X | SP: %04X | AF: %04X | BC: %04X | DE: %04X | HL: %04X", PC, SP, AF, BC, DE, HL));
		console.move(2, 0);
		console.print(repeat("-", 80));
		console.move(3, 2);
		console.print("F1-F4 - Guardar estados | F5-F8 - Cargar estados | ENTER,ESPACIO,Z,X botones");
		console.move(4, 0);
		console.print(repeat("-", 80));

		writeMem(0xFE00, 5);

		//writeMem(0xFF80, 11, 8);
		//writeMem(0xC200, 11, 8);
		writeMem(0x2000, 11, 8);

		console.move(20, 0);

		console.refresh();

		//printf("PC: %04X\r", PC);
	}

	bool stop, stopped;
	bool showinst;
	u16 CPC;

	// Interpreta una sucesión de opcodes
	void interpret() {
		void *APC;
		u8 op;
		void *reg_cb;
		bool hl;
		int cp = 0;

		stop = false;
		dotrace = false;

		void traceInstruction(int PC, int count = 1) {
			while (count > 0) {
				u8* addr = mem.addr8(PC);
				writef("TRACE: ");
				writef("%04X: ", PC);
				char[] casm = disasm(addr, PC);
				writef("%s", casm);
				for (int n = 0; n < 0x0E - cast(int)casm.length; n++) writef(" ");
				writef("[");
				for (u8* p = mem.addr8(PC); p < addr; p++) writef("%02X", *p);
				writefln("]");
				PC = addr - mem.addr8(0);
				count--;
			}
		}

		u8 getr8(u8 r) {
			switch (r & 0b111) {
				case 0b000: return B; case 0b001: return C;
				case 0b010: return D; case 0b011: return E;
				case 0b100: return H; case 0b101: return L;
				case 0b110: return mem.r8(HL); case 0b111: return A;
			}
		}

		void setr8(u8 r, u8  v) {
			switch (r & 0b111) {
				case 0b000: B = v; return; case 0b001: C = v; return;
				case 0b010: D = v; return; case 0b011: E = v; return;
				case 0b100: H = v; return; case 0b101: L = v; return;
				case 0b110: mw8(HL, v); return; case 0b111: A = v; return;
			}
		}

		u16* addrr16(u8 r) {
			switch (r & 0b11) {
				case 0b000: return &BC; case 0b001: return &DE;
				case 0b010: return &HL; case 0b011: return &SP;
			}
		}

		u16* addrr16pp(u8 r) {
			switch (r & 0b11) {
				case 0b000: return &BC; case 0b001: return &DE;
				case 0b010: return &HL; case 0b011: return &AF;
			}
		}

		bool getflag(u8 r) {
			switch (r & 0b11) {
				case 0b000: return !ZF; case 0b001: return ZF;
				case 0b010: return !CF; case 0b011: return CF;
			}
		}

		u16  getr16(u8 r) { return *addrr16(r); }
		u16  getr16pp(u8 r) { return *addrr16pp(r); }
		void setr16(u8 r, u16 v) { *addrr16(r) = v; }
		void setr16pp(u8 r, u16 v) { *addrr16pp(r) = v; }

		// Leer parámetros
		u8  pu8 () { return *cast(u8 *)APC; } s8  ps8 () { return *cast(s8 *)APC; }
		u16 pu16() { return *cast(u16*)APC; } s16 ps16() { return *cast(s16*)APC; }

		// Bucle principal
		while (!pexit) {
			CPC = PC;

			cp++;

			//printf("%04X - %s\t\t\t\r", strip(disasm(PC)));
			if ((cp % 0x10) == 0) updateCycles();
			version (trace) {
			} else {
				if ((cp % 0x3000) == 0) updateStatus();
			}

			if (stop) {
				stopped = true;
				ghs.UpdateScreen(0, lcd.LCDIMG.ptr);
				continue;
			} else {
				stopped = false;
			}

			// Decodificamos la instrucción
			op = mem.r8(PC++);

			APC = mem.addr(PC);

			showinst = false;

			// Trazamos la instrucción si corresponde
			version(trace) {
				if (dotrace) {
					showinst = true;
				} else {
					showinst = false;
					/*if (!mem.traced(CPC)) {
						showinst = true;
						traceInstruction(CPC);
						mem.trace(CPC);
					}*/
				}
			}

			PC += opargs[op];

			if (op != 0xCB) {
				vbcycles += opcycles[op];
			}else {
				vbcycles += opcycles_cb[op];
			}

			switch (op) {
				case 0x00:                         break; // NOP
				case 0x01: BC = pu16;              break; // LD  BC, nnnn
				case 0x02: mw8(BC, A);             break; // LD  (BC), A
				case 0x03: INC(BC);                break; // INC BC
				case 0x04: INC(B);                 break; // INC B
				case 0x05: DEC(B);                 break; // DEC B
				case 0x06: B = pu8;                break; // LD  B, nn
				case 0x07: RLC(A);                 break; // RLC A
				case 0x08: mw16(pu16, SP);         break; // LD  (nnnn), SP // special (old ex af,af)
				case 0x09: ADDHL(BC);              break; // ADD HL, BC
				case 0x0A: A = mr16(BC);           break; // LD  A, (BC)
				case 0x0B: DEC(BC);                break; // DEC BC
				case 0x0C: INC(C);                 break; // INC C
				case 0x0D: DEC(C);                 break; // DEC C
				case 0x0E: C = pu8;                break; // LD  C, nn
				case 0x0F: RRC(A);                 break; // RRC A
				case 0x10: STOP();                 break; // STOP // special ??? (old djnz disp)
				case 0x11: DE = pu16;              break; // LD  DE, nnnn
				case 0x12: mw8(DE, A);             break; // LD  (DE), A
				case 0x13: INC(DE);                break; // INC DE
				case 0x14: INC(D);                 break; // INC D
				case 0x15: DEC(D);                 break; // DEC D
				case 0x16: D = pu8;                break; // LD  D, nn
				case 0x17: RL(A);                  break; // RL  A
				case 0x18: JR(pu8);                break; // JR  disp
				case 0x19: ADDHL(DE);              break; // ADD HL, DE
				case 0x1A: A = mr8(DE);            break; // LD  A, (DE)
				case 0x1B: DEC(DE);                break; // DEC DE
				case 0x1C: INC(E);                 break; // INC E
				case 0x1D: DEC(E);                 break; // DEC E
				case 0x1E: E = pu8;                break; // LD  E, nn
				case 0x1F: RR(A);                  break; // RR  A
				case 0x20: JR(ps8, !ZF);           break; // JR  NZ, disp
				case 0x21: HL = pu16;              break; // LD  HL, nnnn
				case 0x22: mw8(HL, A); INC(HL);    break; // LDI (HL), A
				case 0x23: INC(HL);                break; // INC HL
				case 0x24: INC(H);                 break; // INC H
				case 0x25: DEC(H);                 break; // DEC H
				case 0x26: H = pu8;                break; // LD  H, nn
				case 0x27: DAA();                  break; // DAA
				case 0x28: JR(ps8, ZF);            break; // JR  Z, disp
				case 0x29: ADDHL(HL);              break; // ADD HL, HL
				case 0x2A: A = mr8(HL); INC(HL);   break; // LDI A, (HL)
				case 0x2B: DEC(HL);                break; // DEC HL
				case 0x2C: INC(L);                 break; // INC L
				case 0x2D: DEC(L);                 break; // DEC L
				case 0x2E: L = pu8;                break; // LD  L, nn
				case 0x2F: CPL();                  break; // CPL
				case 0x30: JR(ps8, !CF);           break; // JR  NC, disp
				case 0x31: SP = pu16;              break; // LD  SP, nnnn
				case 0x32: mw8(HL, A);             break; // LDD (HL), A // special (old remapped ld (nnnn), A)
				case 0x33: INC(SP);                break; // INC SP
				case 0x34: INC_MEM(HL);            break; // INC (HL)
				case 0x35: DEC_MEM(HL);            break; // DEC (HL)
				case 0x36: mw8(HL, pu8);           break; // LD  (HL), nn
				case 0x37: SCF();                  break; // SCF
				case 0x38: JR(pu8, CF);            break; // JR  c, disp
				case 0x39: ADDHL(SP);              break; // ADD HL, SP
				case 0x3A: A = mr8(HL); DEC(HL);   break; // LDD A, (HL)
				case 0x3B: DEC(SP);                break; // DEC SP
				case 0x3C: INC(A);                 break; // INC A
				case 0x3D: DEC(A);                 break; // DEC A
				case 0x3E: A = pu8;                break; // LD  A, nn
				case 0x3F: CCF();                  break; // CCF

				// LD
				case 0x40: B = B;                  break; // LD  B, B
				case 0x41: B = C;                  break; // LD  B, C
				case 0x42: B = D;                  break; // LD  B, D
				case 0x43: B = E;                  break; // LD  B, E
				case 0x44: B = H;                  break; // LD  B, H
				case 0x45: B = L;                  break; // LD  B, L
				case 0x46: B = mr8(HL);            break; // LD  B, (HL)
				case 0x47: B = A;                  break; // LD  B, A

				case 0x48: C = B;                  break; // LD  C, B
				case 0x49: C = C;                  break; // LD  C, C
				case 0x4A: C = D;                  break; // LD  C, D
				case 0x4B: C = E;                  break; // LD  C, E
				case 0x4C: C = H;                  break; // LD  C, H
				case 0x4D: C = L;                  break; // LD  C, L
				case 0x4E: C = mr8(HL);            break; // LD  C, (HL)
				case 0x4F: C = A;                  break; // LD  C, A

				case 0x50: D = B;                  break; // LD  D, B
				case 0x51: D = C;                  break; // LD  D, C
				case 0x52: D = D;                  break; // LD  D, D
				case 0x53: D = E;                  break; // LD  D, E
				case 0x54: D = H;                  break; // LD  D, H
				case 0x55: D = L;                  break; // LD  D, L
				case 0x56: D = mr8(HL);            break; // LD  D, (HL)
				case 0x57: D = A;                  break; // LD  D, A

				case 0x58: E = B;                  break; // LD  E, B
				case 0x59: E = C;                  break; // LD  E, C
				case 0x5A: E = D;                  break; // LD  E, D
				case 0x5B: E = E;                  break; // LD  E, E
				case 0x5C: E = H;                  break; // LD  E, H
				case 0x5D: E = L;                  break; // LD  E, L
				case 0x5E: E = mr8(HL);            break; // LD  E, (HL)
				case 0x5F: E = A;                  break; // LD  E, A

				case 0x60: H = B;                  break; // LD  H, B
				case 0x61: H = C;                  break; // LD  H, C
				case 0x62: H = D;                  break; // LD  H, D
				case 0x63: H = E;                  break; // LD  H, E
				case 0x64: H = H;                  break; // LD  H, H
				case 0x65: H = L;                  break; // LD  H, L
				case 0x66: H = mr8(HL);            break; // LD  H, (HL)
				case 0x67: H = A;                  break; // LD  H, A

				case 0x68: L = B;                  break; // LD  L, B
				case 0x69: L = C;                  break; // LD  L, C
				case 0x6A: L = D;                  break; // LD  L, D
				case 0x6B: L = E;                  break; // LD  L, E
				case 0x6C: L = H;                  break; // LD  L, H
				case 0x6D: L = L;                  break; // LD  L, L
				case 0x6E: L = mr8(HL);            break; // LD  L, (HL)
				case 0x6F: L = A;                  break; // LD  L, A

				case 0x70: mw8(HL, B);             break; // LD  (HL), B
				case 0x71: mw8(HL, C);             break; // LD  (HL), C
				case 0x72: mw8(HL, D);             break; // LD  (HL), D
				case 0x73: mw8(HL, E);             break; // LD  (HL), E
				case 0x74: mw8(HL, H);             break; // LD  (HL), H
				case 0x75: mw8(HL, L);             break; // LD  (HL), L
				case 0x76: HALT();                 break; // HALT
				case 0x77: mw8(HL, A);             break; // LD  (HL), A

				case 0x78: A = B;                  break; // LD  A, B
				case 0x79: A = C;                  break; // LD  A, C
				case 0x7A: A = D;                  break; // LD  A, D
				case 0x7B: A = E;                  break; // LD  A, E
				case 0x7C: A = H;                  break; // LD  A, H
				case 0x7D: A = L;                  break; // LD  A, L
				case 0x7E: A = mr8(HL);            break; // LD  A, (HL)
				case 0x7F: A = A;                  break; // LD  A, A

				case 0x80: ADD(B);              break; // ADD A, B
				case 0x81: ADD(C);              break; // ADD A, C
				case 0x82: ADD(D);              break; // ADD A, D
				case 0x83: ADD(E);              break; // ADD A, E
				case 0x84: ADD(H);              break; // ADD A, H
				case 0x85: ADD(L);              break; // ADD A, L
				case 0x86: ADD(mr8(HL));        break; // ADD A, (HL)
				case 0x87: ADD(A);              break; // ADD A, A

				case 0x88: ADC(B);              break; // ADC A, B
				case 0x89: ADC(C);              break; // ADC A, C
				case 0x8A: ADC(D);              break; // ADC A, D
				case 0x8B: ADC(E);              break; // ADC A, E
				case 0x8C: ADC(H);              break; // ADC A, H
				case 0x8D: ADC(L);              break; // ADC A, L
				case 0x8E: ADC(mr8(HL));        break; // ADC A, (HL)
				case 0x8F: ADC(A);              break; // ADC A, A

				case 0x90: SUB(B);              break; // SUB A, B
				case 0x91: SUB(C);              break; // SUB A, C
				case 0x92: SUB(D);              break; // SUB A, D
				case 0x93: SUB(E);              break; // SUB A, E
				case 0x94: SUB(H);              break; // SUB A, H
				case 0x95: SUB(L);              break; // SUB A, L
				case 0x96: SUB(mr8(HL));        break; // SUB A, (HL)
				case 0x97: SUB(A);              break; // SUB A, A

				case 0x98: SBC(B);              break; // SBC A, B
				case 0x99: SBC(C);              break; // SBC A, C
				case 0x9A: SBC(D);              break; // SBC A, D
				case 0x9B: SBC(E);              break; // SBC A, E
				case 0x9C: SBC(H);              break; // SBC A, H
				case 0x9D: SBC(L);              break; // SBC A, L
				case 0x9E: SBC(mr8(HL));        break; // SBC A, (HL)
				case 0x9F: SBC(A);              break; // SBC A, A

				case 0xA0: AND(B);              break; // AND A, B
				case 0xA1: AND(C);              break; // AND A, C
				case 0xA2: AND(D);              break; // AND A, D
				case 0xA3: AND(E);              break; // AND A, E
				case 0xA4: AND(H);              break; // AND A, H
				case 0xA5: AND(L);              break; // AND A, L
				case 0xA6: AND(mr8(HL));        break; // AND A, (HL)
				case 0xA7: AND(A);              break; // AND A, A

				case 0xA8: XOR(B);              break; // XOR A, B
				case 0xA9: XOR(C);              break; // XOR A, C
				case 0xAA: XOR(D);              break; // XOR A, D
				case 0xAB: XOR(E);              break; // XOR A, E
				case 0xAC: XOR(H);              break; // XOR A, H
				case 0xAD: XOR(L);              break; // XOR A, L
				case 0xAE: XOR(mr8(HL));        break; // XOR A, (HL)
				case 0xAF: XOR(A);              break; // XOR A, A

				case 0xB0: OR (B);              break; // OR  A, B
				case 0xB1: OR (C);              break; // OR  A, C
				case 0xB2: OR (D);              break; // OR  A, D
				case 0xB3: OR (E);              break; // OR  A, E
				case 0xB4: OR (H);              break; // OR  A, H
				case 0xB5: OR (L);              break; // OR  A, L
				case 0xB6: OR (mr8(HL));        break; // OR  A, (HL)
				case 0xB7: OR (A);              break; // OR  A, A

				case 0xB8: CP (B);              break; // CP  A, B
				case 0xB9: CP (C);              break; // CP  A, C
				case 0xBA: CP (D);              break; // CP  A, D
				case 0xBB: CP (E);              break; // CP  A, E
				case 0xBC: CP (H);              break; // CP  A, H
				case 0xBD: CP (L);              break; // CP  A, L
				case 0xBE: CP (mr8(HL));        break; // CP  A, (HL)
				case 0xBF: CP (A);              break; // CP  A, A

				case 0xC0: RET(!ZF);            break; // RET NZ
				case 0xC1: POP(BC);             break; // POP BC
				case 0xC2: JP(pu16, !ZF);       break; // JP  nz, nnnn
				case 0xC3: /*JP(pu16);*/            break; // JP  nnnn
				//case 0xC3: JP(pu16);            break; // JP  nnnn

/*
Case 0xC4     ' CALL NZ,nnnn
zcall pw, 1 - zf
Case 0xC5     ' PUSH BC
push b
push c
Case 0xC6     ' ADD  A,nn
add pb
Case 0xC7     ' RST  00H
rst 0
Case 0xC8     ' RET  Z
ret zf
Case 0xC9 'RET
ret
Case 0xCA     ' JP     'Z,nnnn
jp pw, zf

*/

				default: {
					// DEPRECATED
					u8 r1 = (op >> 0) & 0b111, r2 = (op >> 3) & 0b111;

					u8 r13 = (op >> 0) & 0b0111, r23 = (op >> 3) & 0b0111;
					u8 r14 = (op >> 0) & 0b1111, r22 = (op >> 4) & 0b0011;

					if (op == 0xCB) { // MULTIBYTE
						u8 op2 = pu8;
						u8 r8 = getr8(op2 & 0b111);
						u8 bit = ((op2 >> 3) & 0b111);

						switch (op2 >> 6) {
							case 0b00:
								switch ((op2 >> 3) & 0b111) {
									case 0b000: version(trace) TRACE(format("RLC  r%d", r8)); RLC (&r8); break;
									case 0b001: version(trace) TRACE(format("RRC  r%d", r8)); RRC (&r8); break;
									case 0b010: version(trace) TRACE(format("RL   r%d", r8)); RL  (&r8); break;
									case 0b011: version(trace) TRACE(format("RR   r%d", r8)); RR  (&r8); break;
									case 0b100: version(trace) TRACE(format("SLA  r%d", r8)); SLA (&r8); break;
									case 0b101: version(trace) TRACE(format("SRA  r%d", r8)); SRA (&r8); break;
									case 0b110: version(trace) TRACE(format("SWAP r%d", r8)); SWAP(&r8); break;
									case 0b111: version(trace) TRACE(format("SRL  r%d", r8)); SRL (&r8); break;
								}
							break;
							case 0b01: version(trace) TRACE(format("BIT %d, r%d", bit, r8)); BIT(bit, &r8); break;
							case 0b10: version(trace) TRACE(format("RES %d, r%d", bit, r8)); RES(bit, &r8); break;
							case 0b11: version(trace) TRACE(format("SET %d, r%d", bit, r8)); SET(bit, &r8); break;
						}

						setr8(op2 & 0b111, r8);

						//vbcycles += opcycles_cb[op2];
					} else {
						// Los dos bits mas significativos del primer byte indican el tipo de instrucción
						switch (op >> 6 & 0b11) {
							case 0b00: {
								switch (r13) {
									case 0b000:
										switch (r23) {
											case 0b000: version(trace) TRACE("NOP"); NOP();   break;
											case 0b001: version(trace) TRACE(format("LD [%04X] <- SP[%04X]", pu16, SP)); mem.w16(pu16, SP); break;
											case 0b010: version(trace) TRACE("STOP"); STOP();  break;
											case 0b011: version(trace) TRACE(format("JR %d", ps8)); JR(ps8); break;
											case 0b100: version(trace) TRACE(format("JR NZ, %d", ps8)); if (!ZF) JR(ps8); break;
											case 0b101: version(trace) TRACE(format("JR Z, %d", ps8)); if ( ZF) JR(ps8); break;
											case 0b110: version(trace) TRACE(format("JR NC, %d", ps8)); if (!CF) JR(ps8); break;
											case 0b111: version(trace) TRACE(format("JR C, %d", ps8)); if ( CF) JR(ps8); break;
										}
									break;
									case 0b001: case 0b011: {
										u8 r16 = (op >> 4) & 0b11;
										switch (op & 0b1111) {
											case 0b0001: version(trace) TRACE(format("LD r%d, %04X", r16, pu16)); setr16(r16, pu16); break;
											case 0b0011: version(trace) TRACE(format("INC r%d", r16));     { u16 v = getr16(r16); INC(&v);   setr16(r16, v); } break;
											case 0b1001: version(trace) TRACE(format("ADD HL, r%d", r16)); ADDHL(getr16(r16)); break;
											case 0b1011: version(trace) TRACE(format("DEC r%d", r16));     { u16 v = getr16(r16); DEC(&v);   setr16(r16, v); } break;
										}
									} break;
									case 0b010: { // A <- (r16), (r16) <- A
										u16 v16 = (r2 & 0b100) ? HL : getr16(r22 & 0b11);
										if (!(r2 & 0b1)) {
											version(trace) TRACE(format("LD [%04X], A", v16));
											mw8(v16, A);
										} else {
											version(trace) TRACE(format("LD A, [%04X]", v16));
											A = mem.r8(v16);
										}
										if (r2 & 0b100) { if (!(r23 & 0b10)) { version(trace) TRACE(format("INC HL")); INC(&HL); } else { TRACE(format("DEC HL")); DEC(&HL); } }
									} break;
									case 0b100: version(trace) TRACE(format("INC r%d", r2)); { u8 v = getr8(r2); INC(&v); setr8(r2, v); } break; // INC
									case 0b101: version(trace) TRACE(format("DEC r%d", r2)); { u8 v = getr8(r2); DEC(&v); setr8(r2, v); }  break; // DEC
									case 0b110: version(trace) TRACE(format("LD r%d, %02X", r2, pu8)); setr8(r2, pu8);  break; // LD, nn
									case 0b111:
										switch (r2) {
											case 0b000: version(trace) TRACE(format("RLCA")); RLC(&A); break;
											case 0b001: version(trace) TRACE(format("RRCA")); RRC(&A); break;
											case 0b010: version(trace) TRACE(format("RLA"));  RL (&A); break;
											case 0b011: version(trace) TRACE(format("RRA"));  RR (&A); break;
											case 0b100: version(trace) TRACE(format("DAA"));  DAA();   break;
											case 0b101: version(trace) TRACE(format("CPL"));  CPL();   break;
											case 0b110: version(trace) TRACE(format("SCF"));  SCF();   break;
											case 0b111: version(trace) TRACE(format("CCF"));  CCF();   break;
										}
									break;
								}
							} break;
							case 0b01: { // LD REG, REG -- REG <- REG
								if (op == 0x76) { // HALT (LD (HL), (HL))
									version(trace) {
										TRACE(format("HALT"));
										writefln("HALT");
									}
									//HALT();
								} else {
									version(trace) TRACE(format("LD r%d, r%d | v:%02X", r2, r1, getr8(r1)));
									setr8(r2, getr8(r1));
								}
							} break;
							case 0b10: { // OP A, REG
								switch (r2) {
									case 0b000: version(trace) TRACE(format("ADD r%d", r2)); ADD(getr8(r1)); break;
									case 0b001: version(trace) TRACE(format("ADC r%d", r2)); ADC(getr8(r1)); break;
									case 0b010: version(trace) TRACE(format("SUB r%d", r2)); SUB(getr8(r1)); break;
									case 0b011: version(trace) TRACE(format("SBC r%d", r2)); SBC(getr8(r1)); break;
									case 0b100: version(trace) TRACE(format("AND r%d", r2)); AND(getr8(r1)); break;
									case 0b101: version(trace) TRACE(format("XOR r%d", r2)); XOR(getr8(r1)); break;
									case 0b110: version(trace) TRACE(format("OR  r%d", r2)); OR (getr8(r1)); break;
									case 0b111: version(trace) TRACE(format("CP  r%d", r2)); CP (getr8(r1)); break;
								}
							} break;
							case 0b11: {
								switch (r13) {
									case 0b000:
										if ((r23 & 0b100) == 0) {
											if (getflag(r23 & 0b11)) RET();
										} else {
											switch (r23 & 0b11) {
												case 0b00: version(trace) TRACE(format("LD [0xFF00+$%02X], A", pu8)); mw8(0xFF00 | pu8, A);  break; // LD ($FF00 + nn), A // special (old ret po)
												case 0b01: version(trace) TRACE(format("ADD SP, %d", ps8)); ADDSP(ps8); break; // ADD SP, dd // special (old ret pe) (nocash extended as shortint)
												case 0b10: version(trace) TRACE(format("LD A, [0xFF00+$%02X]", pu8)); A = mem.r8(0xFF00 | pu8); break; // LD A, ($FF00 + nn) // special (old ret p)
												case 0b11: // TODO: SET FLAGS
													version(trace) TRACE(format("LD HL, SP + %d", ps8));
													HL = SP + ps8;
												break;
											}
										}
									break;
									case 0b001:
										if ((r23 & 0b001) == 0) {
											version(trace) TRACE(format("POP r%d", r22));
											//TRACE(format("POP r : %04X", getr16(r22)));
											setr16pp(r22, POP());
											//TRACE(format("POP r : %04X", getr16(r22)));
										} else {
											switch (r22) {
												case 0b00: version(trace) TRACE("RET"); RET();   break;
												case 0b01: version(trace) TRACE("RETI"); RETI();  break;
												case 0b10: version(trace) TRACE("JP HL"); JP(HL);  break;
												case 0b11: version(trace) TRACE("LD SP, HL"); SP = HL; break;
											}
										}
									break;
									case 0b010:
										if ((r23 & 0b100) == 0) {
											version(trace) TRACE(format("JP (%02b) $%04X", r23 & 0b11, pu16));
											if (getflag(r23 & 0b11)) JP(pu16);
										} else {
											switch (r23 & 0b11) {
												case 0b00: version(trace) TRACE(format("LD [0xFF00+C], A"     )); mw8(0xFF00 | C, A); break;
												case 0b01: version(trace) TRACE(format("LD [$%04X], A",   pu16)); mw8(pu16, A); break;
												case 0b10: version(trace) TRACE(format("LD A, [0xFF00+C]"     )); A = mem.r8(0xFF00 | C); break;
												case 0b11: version(trace) TRACE(format("LD A, [$%04X]",   pu16)); A = mem.r8(pu16); break;
											}
										}
									break;
									case 0b011:
										switch (r23) {
											case 0b000: version(trace) TRACE(format("JP $%04X",      pu16)); JP(pu16); break; // C3
											case 0b001: throw(new Exception("F.ERROR reached '0xCB'")); break; // CB
											case 0b010: throw(new Exception(format("INVALID OP (%02X)", op))); break; // D3
											case 0b011: throw(new Exception(format("INVALID OP (%02X)", op))); break; // DB
											case 0b100: throw(new Exception(format("INVALID OP (%02X)", op))); break; // E3
											case 0b101: throw(new Exception(format("INVALID OP (%02X)", op))); break; // EB
											case 0b110: IME = false; break; // F3 (DI)
											case 0b111: IME = true;  break; // FB (EI)
										}
									break;
									case 0b100:
										if ((r23 & 0b100) == 0) {
											if (getflag(r23 & 0b11)) {
												version(trace) TRACE(format("CALL $%04X", pu16));
												CALL(pu16);
											}
										} else {
											throw(new Exception(format("INVALID OP (%02X)", op))); // E4, EC, F4, FC
										}
									break;
									case 0b101:
										if ((r23 & 0b001) == 0) {
											version(trace) TRACE(format("PUSH r%d", r22));
											PUSH(getr16pp(r22));
										} else {
											switch (r22) {
												case 0b00:
													version(trace) TRACE(format("CALL $%04X", pu16));
													CALL(pu16);
												break;
												case 0b01: throw(new Exception(format("INVALID OP (%02X)", op))); break;
												case 0b10: throw(new Exception(format("INVALID OP (%02X)", op))); break;
												case 0b11: throw(new Exception(format("INVALID OP (%02X)", op))); break;
											}
										}
									break;
									case 0b110: // ALU (C6, CE, D6, DE, E6, EE, F6, FE)
										switch (r23) {
											case 0b000: version(trace) TRACE(format("ADD %02X", pu8)); ADD(pu8); break;
											case 0b001: version(trace) TRACE(format("ADC %02X", pu8)); ADC(pu8); break;
											case 0b010: version(trace) TRACE(format("SUB %02X", pu8)); SUB(pu8); break;
											case 0b011: version(trace) TRACE(format("SBC %02X", pu8)); SBC(pu8); break;
											case 0b100: version(trace) TRACE(format("AND %02X", pu8)); AND(pu8); break;
											case 0b101: version(trace) TRACE(format("XOR %02X", pu8)); XOR(pu8); break;
											case 0b110: version(trace) TRACE(format("OR  %02X", pu8)); OR (pu8); break;
											case 0b111: version(trace) TRACE(format("CP  %02X", pu8)); CP (pu8); break;
										}
									break;
									case 0b111: // RST (C7, CF, D7, DF, E7, EF, F7, FF)
										RST(r23);
									break;
								}
							} break;
						} // switch
					}
					break;
				} // switch
			}
		} // while
	} // function

// --- DESENSAMBLADO ----------------------------------------------------------

	char[] disasm(u16 PC) {
		u8* ptr = &mem.MEM[PC];
		return disasm(ptr, PC);
	}

	static char[] disasm(inout u8* addr, u16 PC = 0) {
		bool sign = false;
		char[] fmt;

		// Obtenemos el opcode
		u8 op = *(addr++);

		// Si el opcode es 0xCB
		if (op == 0xCB) {
			op = *(addr++);
			fmt = opdisasm_cb[op >> 3];
			if (fmt == "-") return "-";
			return format("%s %s", fmt, opdisasm_cb_regs[op & 0b111]);
		}

		// Si es un opcode normal
		fmt = opdisasm[op];
		int cb = opargs[op];
		if (cb == 0) return fmt;
		int v; if (cb == 1) v = *cast(u8*)addr; else v = *cast(u16*)addr;
		for (int n = 0; n < fmt.length; n++) if (fmt[n] == '*') { sign = true; break; }
		addr += cb;
		fmt = replace(fmt, "#", format("%%s" "$" "%%0" "%d" "X", cb * 2));
		fmt = replace(fmt, "*", format("%%s" "$" "%%0" "%d" "X", cb * 2));

		if (sign) {
			if (cb == 1) {
				//writefln("%d", PC + cb + cast(s8)v + 1);
				return format(fmt, "", PC + cb + cast(s8)v + 1);
			} else {
				return format(fmt, "", PC + cb + cast(s16)v + 1);
			}
		} else {
			//return format(fmt, (sign && v < 0) ? "-" : "", (v < 0) ? -v : v);
			return format(fmt, "", v);
		}
	}

	static void disasm(ubyte[] data, u16 PC = 0x0000) {
		u8* addr = data.ptr, dest = data.ptr + data.length;
		while (addr < dest) {
			u8* baddr = addr;
			writef("%04X: ", (addr - data.ptr) + PC);
			writef("%s [", disasm(addr, PC + (addr - data.ptr)));
			foreach (c; data[baddr - data.ptr..addr - data.ptr]) writef("%02X", c);
			writefln("]");
		}
	}

// --- NUEVAS INSTRUCCIONES ---------------------------------------------------

	void INC(ref u16 r) { r++; }
	void INC(ref u8  r) { r++; NF = false; ZF = (r == 0); HF = ((r & 0b1111) == 0b0000); }
	void INC_MEM(u16 addr) {
		u8 v = mr8(addr) - 1;
		mw8(addr, v);
		NF = false;
		ZF = (v == 0);
		HF = ((v & 0b1111) == 0b0000);
	}

	void DEC(ref u16 r) { r--; }
	void DEC(ref u8  r) { r--; NF = true ; ZF = (r == 0); HF = ((r & 0b1111) == 0b1111); }
	void DEC_MEM(u16 addr) {
		u8 v = mr8(addr) - 1;
		mw8(addr, v);
		NF = true;
		ZF = (v == 0);
		HF = ((v & 0b1111) == 0b1111);
	}

	void RLC (ref u8 r) { CF = (r & 0b10000000) != 0; r = (r << 1) | CF; ZF = (r == 0); HF = false; NF = false; } // Rotate Left
	void RRC (ref u8 r) { CF = (r & 0b00000001) != 0; r = (r >> 1) | (CF << 7); ZF = (r == 0); HF = false; NF = false; } // Rotate Right

	void RL  (ref u8 r) { CF = (r & 0b10000000) != 0; r = (r << 1) | ((r >> 7) & 0b00000001); HF = false; NF = false; } // Rotate Left thru carry
	void RR  (ref u8 r) { CF = (r & 0b00000001) != 0; r = (r >> 7) | ((r << 7) & 0b10000000); HF = false; NF = false; } // Roate Right thru carry

	void SLA (ref u8 r) { CF = (r & 0b10000000) != 0; r = (r << 1); ZF = (r == 0); HF = false; NF = false; } // Shift Left
	void SRA (ref u8 r) { CF = (r & 0b00000001) != 0; r = (r >> 1) | 0b10000000; ZF = (r == 0); HF = false; NF = false; } // Shift Right
	void SRL (ref u8 r) { CF = (r & 0b00000001) != 0; r = (r >> 1); ZF = (r == 0); HF = false; NF = false; } // Shift Right Logical

	void SWAP(ref u8 r) { r = ((r >> 4) & 0b1111) | ((r << 4) & 0b11110000); ZF = (r == 0); NF = false; HF = false; CF = false; } // SWAP NIBLES

	void POP(ref u16 r) { r = mem.r16(SP); SP += 2; }

// --- INSTRUCCIONES ----------------------------------------------------------
	void HALT() {
		//writefln("--HALT");
		//throw(new Exception(format("HALT NOT IMPLEMENTED")));
	}

	void STOP() {
		//writefln("--STOP|");
		//throw(new Exception(format("STOP NOT IMPLEMENTED")));
		//exit(-1);
	}

	void NOP() { }
	void AND(u8 v) { A &= v; ZF = (A == 0); NF = false; HF = true ; CF = false; } // Logical AND
	void OR (u8 v) { A |= v; ZF = (A == 0); NF = false; HF = false; CF = false; } // Logical OR
	void XOR(u8 v) { A ^= v; ZF = (A == 0); NF = false; HF = false; CF = false; } // Logical XOR
	void CP (u8 v) { NF = true; ZF = (A == v); CF = (A < v); HF = (A & 0b1111) < (v & 0b1111); } // ComPare with A

	void INC(u16* r) { (*r)++; }
	void INC(u8*  r) { (*r)++; NF = false; ZF = (*r == 0); HF = ((*r & 0b1111) == 0b0000); }

	void DEC(u16* r) { (*r)--; }
	void DEC(u8*  r) { (*r)--; NF = true; ZF = (*r == 0); HF = ((*r & 0b1111) == 0b1111); }

	void ADD(u8  v) { CF = (cast(u16)A + cast(u16)v > 0xFF); HF = (cast(u16)(A & 0xF) + cast(u16)(v & 0xF) > 0xF); A += v; NF = false; ZF = (A == 0); }
	void ADC(u8  v) { CF = ((cast(u16)A + cast(u16)v + cast(u16)CF) > 0xFF); HF = ((cast(u16)(A & 0xF) + cast(u16)(v & 0xF) + CF) > 0xF); A += v + CF; NF = false; ZF = (A == 0); }

	void SUB(u8  v) { CF = ((cast(u16)A) < ((cast(u16)A) - v)); HF = (((cast(u16)A) & 0x0F) < (((cast(u16)A) - v) & 0x0F)); A -= v; ZF = (A == 0); NF = true; }
	void SBC(u8  v) { CF = ((cast(u16)A) < ((cast(u16)A) - v - CF)); HF = (((cast(u16)A) & 0x0F) < (((cast(u16)A) - v - CF) & 0x0F)); A -= v; ZF = (A == 0); NF = true; }

	void ADDHL(u8  v) { HL += v; }
	void ADDHL(u16 v) { HL += v; }

	void ADDSP(s8  v) { ADDSP(cast(s16)v); }
	void ADDSP(s16 v) { CF = (SP + v < SP); NF = (SP ^ v ^ (SP + v) & 0x1000) > 0; SP += v; ZF = false; NF = false; }

	void RLC (u8 *r) { CF = (*r & 0b10000000) != 0; *r = (*r << 1) | CF; ZF = (*r == 0); HF = false; NF = false; } // Rotate Left
	void RRC (u8 *r) { CF = (*r & 0b00000001) != 0; *r = (*r >> 1) | (CF << 7); ZF = (*r == 0); HF = false; NF = false; } // Rotate Right

	void RL  (u8 *r) { CF = (*r & 0b10000000) != 0; *r = (*r << 1) | ((*r >> 7) & 0b00000001); HF = false; NF = false; } // Rotate Left thru carry
	void RR  (u8 *r) { CF = (*r & 0b00000001) != 0; *r = (*r >> 7) | ((*r << 7) & 0b10000000); HF = false; NF = false; } // Roate Right thru carry

	void SLA (u8 *r) { CF = (*r & 0b10000000) != 0; *r = (*r << 1); ZF = (*r == 0); HF = false; NF = false; } // Shift Left
	void SRA (u8 *r) { CF = (*r & 0b00000001) != 0; *r = (*r >> 1) | 0b10000000; ZF = (*r == 0); HF = false; NF = false; } // Shift Right
	void SRL (u8 *r) { CF = (*r & 0b00000001) != 0; *r = (*r >> 1); ZF = (*r == 0); HF = false; NF = false; } // Shift Right Logical

	void SWAP(u8 *r) { *r = ((*r >> 4) & 0b1111) | ((*r << 4) & 0b11110000); ZF = (*r == 0); NF = false; HF = false; CF = false; } // SWAP NIBLES

	// Operaciones con bit
	void BIT(u8 bit, u8 *r) { ZF = (*r & (1 << bit)) == 0; NF = false; HF = true; }
	static void RES(u8 bit, u8 *r) { *r &= ~(1 << bit); }
	static void SET(u8 bit, u8 *r) { *r |=  (1 << bit); }

	void PUSH(u16 v) { SP -= 2; mem.w16(SP, v); }
	u16  POP() { SP += 2; return mem.r16(SP - 2); }

	void DAA() {
		if (HF) {
			if ((A & 0b00001111) >= (HF | 0b00001010)) { A -= 0b00000110; }
			if ((A & 0b11110000) >= (CF | 0b10100000)) { A -= 0b01100000; CF = true; }
		} else {
			if ((A & 0b00001111) >= (HF | 0b00001010)) { A += 0b00000110; }
			if ((A & 0b11110000) >= (CF | 0b10100000)) { A += 0b01100000; CF = true; }
		}

		ZF = (A == 0);
		HF = false;
	} // Demical adjust register A

	void CPL () { A = ~A; HF = true; NF = true; } // Logical NOT
	void SCF () { CF = true; NF = false; HF = false; } // Set Carry Flag
	void CCF () { CF = !CF; NF = false; HF = false; } // Change Carry Flag

	void RET (bool cond) { if (cond) PC = POP(); } // RETURN

	void RET () { PC = POP(); } // RETURN
	void RETI() { RET(); IME = true; } // RETURN INTERRUPT

	void JR(s8  disp) { PC += disp; } // JUMP LOCAL TO
	void JR(s8 disp, bool cond) { if (cond) PC += disp; } // JUMP LOCAL TO

	void JP(u16 addr) { PC = addr; } // JUMP TO
	void JP(u16 addr, bool cond) { if (cond) PC = addr; } // JUMP TO

	void DI() { IME = false; } // DISABLE INTERRUPTS
	void EI() { IME = true ; } // ENABLE INTERRUPTS

	void CALL(u16 addr) { PUSH(PC); JP(addr); } // CALL
	void RST(u8 v) { CALL(v << 3); } // RESTART AT

	void TRACE(char[] s) {
		static Stream f;
		if (!showinst) return;
		if (!f) f = new File("trace.txt", FileMode.OutNew);
		writefln("%s", s);
		f.writefln("%04X: %s", CPC, s);
		RegDump(f);
	}
}

Console console;

static this() {
	version (trace) {
	} else {
		console = new Console();
		//console.clear();
		//console.refresh();
	}
}

static ~this() {
	//console.clear();
	//console.refresh();
}
