module gameboy.z80;

public import gameboy.common;

import gameboy.tables, gameboy.memory;
import std.stdio, std.string, std.stream, std.c.stdlib, std.zlib, std.system;

//version = trace_all;
version = trace;

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
*/

interface GameboyHostSystem {
	void Sleep1();
	void UpdateScreen(int type, u8* LCDSCR);
	void KeepAlive();
}

class GameBoy {
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

	GameboyHostSystem ghs;
	Stream rom; // Stream
	RomHeader *rh; // Header
	// Memoria
	u8 MEM[0x10000];
	bool MEM_TRACED[0x10000];

	this(GameboyHostSystem ghs) {
		this.ghs = ghs;
	}

	// Registros
	static if (endian == Endian.BigEndian) {
		union { u16 AF; struct { u8 A; u8 F; } }
		union { u16 BC; struct { u8 B; u8 C; } }
		union { u16 DE; struct { u8 D; u8 E; } }
		union { u16 HL; struct { u8 H; u8 L; } }
	} else {
		union { u16 AF; struct { u8 F; u8 A; } }
		union { u16 BC; struct { u8 C; u8 B; } }
		union { u16 DE; struct { u8 E; u8 D; } }
		union { u16 HL; struct { u8 L; u8 H; } }
	}
	u16 SP;  // Stack Pointer
	u16 PC;  // Program Counter
	u8  IME; // Interrupt Master Enable Flag (Write Only)
	bool jump;

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

	void RegDump() {
		writefln(
			"AF:%04X " "BC:%04X "
			"DE:%04X " "HL:%04X "
			"| SP:%04X " "| PC:%04X " "| IME:%02X | "
			"Z%d " "N%d "
			"H%d " "C%d ",
			AF, BC, DE, HL,
			SP, PC, IME,
			ZF, NF, HF, CF
		);
		writefln("STACK {");
			for (int n = SP - 12; n <= SP + 18; n += 2) {
				if (n < 0xFFFE) {
					writefln("  %04X: %04X", n, r16(MEM.ptr, n));
				}
			}
		writefln("}");
	}

	// Utilitarios
	int cycles;   // Cantidad de ciclos * 1000 ejecutados
	int vbcycles; // Cantidad de ciclos de reloj usado para las scanlines
	//u64 mmsec;    // Microsegundos

	bool sgb = false; // Emulacion de Super GameBoy
	bool cgb = false; // Emulación de GameBoy Color

	// Añade ciclos para simular el retraso
	void addCycles(int n) {
		static const uint ccyc = 0x400000, slcyc = (ccyc / cast(int)(59.73 * 144)), msec = 1;

		cycles += (n << 2) * 1000;
		vbcycles += (n << 2);
		//mmsec = (n * 0x400000) / 1000000;

		/*while (mmsec >= 1000) {
			Sleep(1);
			mmsec -= 1000;
		}*/

		ghs.KeepAlive();

		while (cycles >= ccyc) {
			ghs.Sleep1();
			cycles -= ccyc;
		}

		while (vbcycles >= slcyc) {
			incScanLine();
			//printf("%02X|", MEM[0xFF44]);
			vbcycles -= slcyc;
		}
	}

	// Cargamos la rom
	void loadRom(char[] name) { loadRom(new File(name, FileMode.In)); }
	void loadRom(Stream s) {
		rom = s;
		rom.position = 0;
		rom.readExact(&MEM[0], 0x4000);
		switchBank2(1);
		rh = cast(RomHeader *)(&MEM[0x100]);
	}

	void switchBank2(u8 bank) {
		rom.position = 0x4000 * bank;
		rom.readExact(&MEM[0x4000], 0x4000);
	}

	// Inicializamos la emulación
	void init() {
		AF = 0x01B0; BC = 0x0013;
		DE = 0x00D8; HL = 0x014D;
		SP = 0xFFFE; PC = 0x0100;
		MEM[0xFF05] = 0x00; // TIMA
		MEM[0xFF06] = 0x00; // TMA
		MEM[0xFF07] = 0x00; // TAC
		MEM[0xFF10] = 0x80; // NR10
		MEM[0xFF11] = 0xBF; // NR11
		MEM[0xFF12] = 0xF3; // NR12
		MEM[0xFF14] = 0xBF; // NR14
		MEM[0xFF16] = 0x3F; // NR21
		MEM[0xFF17] = 0x00; // NR22
		MEM[0xFF19] = 0xBF; // NR24
		MEM[0xFF1A] = 0x7F; // NR30
		MEM[0xFF1B] = 0xFF; // NR31
		MEM[0xFF1C] = 0x9F; // NR32
		MEM[0xFF1E] = 0xBF; // NR33
		MEM[0xFF20] = 0xFF; // NR41
		MEM[0xFF21] = 0x00; // NR42
		MEM[0xFF22] = 0x00; // NR43
		MEM[0xFF23] = 0xBF; // NR30
		MEM[0xFF24] = 0x77; // NR50
		MEM[0xFF25] = 0xF3; // NR51
		MEM[0xFF26] = sgb ? 0xF0 : 0xF1; // NR52
		MEM[0xFF40] = 0x91; // LCDC
		MEM[0xFF42] = 0x00; // SCY
		MEM[0xFF43] = 0x00; // SCX
		MEM[0xFF45] = 0x00; // LYC
		MEM[0xFF47] = 0xFC; // BGP
		MEM[0xFF48] = 0xFF; // OBP0
		MEM[0xFF49] = 0xFF; // OBP1
		MEM[0xFF4A] = 0x00; // WY
		MEM[0xFF4B] = 0x00; // WX
		MEM[0xFFFF] = 0x00; // IE
	}

	void traceInstruction(int PC, int count = 1) {
		while (count > 0) {
			u8* addr = MEM.ptr + PC;
			writef("TRACE: ");
			writef("%04X: ", PC);
			char[] casm = disasm(addr, PC);
			writef("%s", casm);
			for (int n = 0; n < 0x0E - cast(int)casm.length; n++) writef(" ");
			writef("[");
			for (u8* p = MEM.ptr + PC; p < addr; p++) writef("%02X", *p);
			writefln("]");
			PC = addr - MEM.ptr;
			count--;
		}
	}

	// Un VBLANK se ejecuta 59.7 veces por segundo en la GB y 61.1 en SGB
	// Un scanline se ejecuta (59.7 / 154)
	void incScanLine() {
		u8* scanline = &MEM[0xFF44];
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
			ghs.UpdateScreen(0, MEM.ptr);
			interrupt(0x40);
		}
	}

	void interrupt(u8 type) {
		u8 *IE = &MEM[0xFFFF]; // FFFF - IE - Interrupt Enable (R/W)
		u8 *IF = &MEM[0xFF0F]; // FF0F - IF - Interrupt Flag (R/W)

		//writefln("!!INTERRUPTION: %02X", type);

		if (!IME) return;

		IME = false;

		switch (type) {
			case 0x40: // V-Blank
				if (*IE & (1 << 0)) {
					SET(0, IF);
				}
			break;
			case 0x48: // LCD STAT
				if (*IE & (1 << 1)) {
					SET(1, IF);
				}
			break;
			case 0x50: // Timer
				if (*IE & (1 << 2)) {
					SET(2, IF);
				}
			break;
			case 0x58: // Serial
				if (*IE & (1 << 3)) {
					SET(3, IF);
				}
			break;
			case 0x60: // Joypad
				if (*IE & (1 << 4)) {
					SET(4, IF);
				}
			break;
		} // switch

		IME = true;
	}

	void dump() {
		File save = new File("dump", FileMode.OutNew);
		save.writeExact(&A, (&IME - &A) + IME.sizeof);
		//save.write(cast(ubyte[])compress(MEM, 9));
		save.write(MEM);
		save.close();
	}

	bool showinst;
	// Interpreta una sucesión de opcodes
	void interpret() {
		void *APC;
		u16 CPC;
		u8 op;
		void *reg_cb;
		bool hl;

		u8 getr8 (u8 r) {
			switch (r & 0b111) {
				case 0b000: return B; case 0b001: return C;
				case 0b010: return D; case 0b011: return E;
				case 0b100: return H; case 0b101: return L;
				case 0b110: return r8(MEM.ptr, HL); case 0b111: return A;
			}
		}

		void setr8 (u8 r, u8  v) {
			switch (r & 0b111) {
				case 0b000: B = v; return; case 0b001: C = v; return;
				case 0b010: D = v; return; case 0b011: E = v; return;
				case 0b100: H = v; return; case 0b101: L = v; return;
				case 0b110: w8(MEM.ptr, HL, v); return; case 0b111: A = v; return;
			}
		}


		u16* addrr16(u8 r) {
			switch (r & 0b11) {
				case 0b000: return &BC; case 0b001: return &DE;
				case 0b010: return &HL; case 0b011: return &SP;
			}
		}

		bool getflag(u8 r) {
			switch (r & 0b11) {
				case 0b000: return !ZF; case 0b001: return ZF;
				case 0b010: return !CF; case 0b011: return CF;
			}
		}

		u16  getr16(u8 r       ) { return *addrr16(r); }
		void setr16(u8 r, u16 v) { *addrr16(r) = v;    }

		// Leer parámetros
		u8  pu8 () { return *cast(u8 *)APC; } s8  ps8 () { return *cast(s8 *)APC; }
		u16 pu16() { return *cast(u16*)APC; } s16 ps16() { return *cast(s16*)APC; }

		// Bucle principal
		while (true) {
			CPC = PC;
			jump = false;

			/*
			if (PC == 0x2A0) { RegDump(); }
			if (PC == 0x2A3) { RegDump(); }
			if (PC == 0x2A6) { RegDump(); }
			if (PC == 0x2BA) { RegDump(); }
			if (PC == 0x2C4) { RegDump(); }
			if (PC == 0x29D7) { RegDump(); }
			if (PC == 0x29D9) { RegDump(); }
			if (PC == 0x29E0) { RegDump(); }
				*/
			//if (PC == 0x02CD) { RegDump(); exit(-1); }
			//if (PC == 0x028) { RegDump(); exit(-1); }

			//if (PC >= 0x028 && PC < 0x033) { RegDump(); }

			//if (PC == 0x0369) { RegDump(); }
			//if (PC == 0x2820) { RegDump(); }
			//if (PC >= 0x2820 && PC < 0x282A) { RegDump(); }
			//if (PC == 0x282A) { RegDump(); exit(-1); }
			//if (PC == 0x02F8) { RegDump(); exit(-1); }
			//if (PC == 0x02B4) { RegDump(); exit(-1); }

			//if (PC == 0x2838) { RegDump(); exit(-1); }

			//if (PC == 0x036C) { RegDump(); exit(-1); }
			//if (PC == 0x36F) { RegDump(); exit(-1); }

			// Decodificamos la instrucción
			op = MEM[PC++];

			APC = &MEM[PC];

			// Trazamos la instrucción si corresponde
			version(trace) {
				version(trace_all) {
					traceInstruction(CPC);
				} else {
					showinst = false;
					if (!MEM_TRACED[CPC]) {
						traceInstruction(CPC);
						MEM_TRACED[CPC] = true;
						showinst = true;
					}
				}
			}

			// DEPRECATED
			u8 r1 = (op >> 0) & 0b111, r2 = (op >> 3) & 0b111;

			u8 r13 = (op >> 0) & 0b0111, r23 = (op >> 3) & 0b0111;
			u8 r14 = (op >> 0) & 0b1111, r22 = (op >> 4) & 0b0011;

			if (op == 0xCB) { // MULTIBYTE
				u8 op2 = MEM[PC++];
				u8 r8 = getr8(op2 & 0b111);
				u8 bit = ((op2 >> 3) & 0b111);

				switch (op2 >> 6) {
					case 0b00:
						switch ((op2 >> 3) & 0b111) {
							case 0b000: TRACE(format("RLC  r%d", r8)); RLC (&r8); break;
							case 0b001: TRACE(format("RRC  r%d", r8)); RRC (&r8); break;
							case 0b010: TRACE(format("RL   r%d", r8)); RL  (&r8); break;
							case 0b011: TRACE(format("RR   r%d", r8)); RR  (&r8); break;
							case 0b100: TRACE(format("SLA  r%d", r8)); SLA (&r8); break;
							case 0b101: TRACE(format("SRA  r%d", r8)); SRA (&r8); break;
							case 0b110: TRACE(format("SWAP r%d", r8)); SWAP(&r8); break;
							case 0b111: TRACE(format("SRL  r%d", r8)); SRL (&r8); break;
						}
					break;
					case 0b01: TRACE(format("BIT %d, r%d", bit, r8)); BIT(bit, &r8); break;
					case 0b10: TRACE(format("RES %d, r%d", bit, r8)); RES(bit, &r8); break;
					case 0b11: TRACE(format("SET %d, r%d", bit, r8)); SET(bit, &r8); break;
				}

				setr8(op2 & 0b111, r8);

				addCycles(opcycles_cb[op2]);

				PC += opargs[op];
			} else {
				PC += opargs[op];

				// Los dos bits mas significativos del primer byte indican el tipo de instrucción
				switch (op >> 6 & 0b11) {
					case 0b00: {
						switch (r13) {
							case 0b000:
								switch (r23) {
									case 0b000: TRACE("NOP"); NOP();   break;
									case 0b001: TRACE(format("LD [%04X] <- SP[%04X]", pu16, SP)); w16(MEM.ptr, pu16, SP); break;
									case 0b010: TRACE("STOP"); STOP();  break;
									case 0b011: TRACE(format("JR %d", ps8)); JR(ps8); break;
									case 0b100: TRACE(format("JR NZ, %d", ps8)); if (!ZF) JR(ps8); break;
									case 0b101: TRACE(format("JR Z, %d", ps8)); if ( ZF) JR(ps8); break;
									case 0b110: TRACE(format("JR NC, %d", ps8)); if (!CF) JR(ps8); break;
									case 0b111: TRACE(format("JR C, %d", ps8)); if ( CF) JR(ps8); break;
								}
							break;
							case 0b001: case 0b011: {
								u8 r16 = (op >> 4) & 0b11;
								switch (op & 0b1111) {
									case 0b0001: TRACE(format("LD r%d, %04X", r16, pu16)); setr16(r16, pu16); break;
									case 0b0011: TRACE(format("INC r%d", r16));     { u16 v = getr16(r16); INC(&v);   setr16(r16, v); } break;
									case 0b1001: TRACE(format("ADD HL, r%d", r16)); ADDHL(getr16(r16)); break;
									case 0b1011: TRACE(format("DEC r%d", r16));     { u16 v = getr16(r16); DEC(&v);   setr16(r16, v); } break;
								}
							} break;
							case 0b010: { // A <- (r16), (r16) <- A
								u16 v16 = (r2 & 0b100) ? HL : getr16(r2 & 0b11);
								if (r2 & 0b1) {
									TRACE(format("LD A, [%04X]", v16));
									A = r8(MEM.ptr, v16);
								} else {
									TRACE(format("LD [%04X], A", v16));
									w8(MEM.ptr, v16, A);
								}
								if (r2 & 0b100) { if (r2 & 0b1) { TRACE(format("INC HL")); INC(&HL); } else { TRACE(format("DEC HL")); DEC(&HL); } }
							} break;
							case 0b100: TRACE(format("INC r%d", r2)); { u8 v = getr8(r2); INC(&v); setr8(r2, v); } break; // INC
							case 0b101: TRACE(format("DEC r%d", r2)); { u8 v = getr8(r2); DEC(&v); setr8(r2, v); }  break; // DEC
							case 0b110: TRACE(format("LD r%d, %02X", r2, pu8)); setr8(r2, pu8);  break; // LD, nn
							case 0b111:
								switch (r2) {
									case 0b000: TRACE(format("RLCA")); RLC(&A); break;
									case 0b001: TRACE(format("RRCA")); RRC(&A); break;
									case 0b010: TRACE(format("RLA"));  RL (&A); break;
									case 0b011: TRACE(format("RRA"));  RR (&A); break;
									case 0b100: TRACE(format("DAA"));  DAA();   break;
									case 0b101: TRACE(format("CPL"));  CPL();   break;
									case 0b110: TRACE(format("SCF"));  SCF();   break;
									case 0b111: TRACE(format("CCF"));  CCF();   break;
								}
							break;
						}
					} break;
					case 0b01: { // LD REG, REG -- REG <- REG
						if (op == 0x76) { // HALT (LD (HL), (HL))
							TRACE(format("HALT"));
							writefln("HALT");
							HALT();
						} else {
							TRACE(format("LD r%d, r%d | v:%02X", r2, r1, getr8(r1)));
							setr8(r2, getr8(r1));
						}
					} break;
					case 0b10: { // OP A, REG
						switch (r2) {
							case 0b000: TRACE(format("ADD r%d", r2)); ADD(getr8(r1)); break;
							case 0b001: TRACE(format("ADC r%d", r2)); ADC(getr8(r1)); break;
							case 0b010: TRACE(format("SUB r%d", r2)); SUB(getr8(r1)); break;
							case 0b011: TRACE(format("SBC r%d", r2)); SBC(getr8(r1)); break;
							case 0b100: TRACE(format("AND r%d", r2)); AND(getr8(r1)); break;
							case 0b101: TRACE(format("XOR r%d", r2)); XOR(getr8(r1)); break;
							case 0b110: TRACE(format("OR  r%d", r2)); OR (getr8(r1)); break;
							case 0b111: TRACE(format("CP  r%d", r2)); CP (getr8(r1)); break;
						}
					} break;
					case 0b11: {
						switch (r13) {
							case 0b000:
								if ((r23 & 0b100) == 0) {
									if (getflag(r23 & 0b11)) RET();
								} else {
									switch (r23 & 0b11) {
										case 0b00: TRACE(format("LD [0xFF00+$%02X], A", pu8)); w8(MEM.ptr, 0xFF00 | pu8, A);  break; // LD ($FF00 + nn), A // special (old ret po)
										case 0b01: TRACE(format("ADD SP, %d", ps8)); ADDSP(ps8); break; // ADD SP, dd // special (old ret pe) (nocash extended as shortint)
										case 0b10: TRACE(format("LD A, [0xFF00+$%02X]", pu8)); A = r8(MEM.ptr, 0xFF00 | pu8); break; // LD A, ($FF00 + nn) // special (old ret p)
										case 0b11: // TODO: SET FLAGS
											TRACE(format("LD HL, SP + %d", ps8));
											HL = SP + ps8;
										break;
									}
								}
							break;
							case 0b001:
								if ((r23 & 0b001) == 0) {
									TRACE(format("POP r%d", r22));
									//TRACE(format("POP r : %04X", getr16(r22)));
									setr16(r22, POP16());
									//TRACE(format("POP r : %04X", getr16(r22)));
								} else {
									switch (r22) {
										case 0b00: TRACE("RET"); RET();   break;
										case 0b01: TRACE("RETI"); RETI();  break;
										case 0b10: TRACE("JP HL"); JP(HL);  break;
										case 0b11: TRACE("LD SP, HL"); SP = HL; break;
									}
								}
							break;
							case 0b010:
								if ((r23 & 0b100) == 0) {
									if (getflag(r23 & 0b11)) JP(pu16);
								} else {
									switch (r23 & 0b11) {
										case 0b00: TRACE(format("LD [0xFF00+C], A")); w8(MEM.ptr, 0xFF00 | C, A); break;
										case 0b01: TRACE(format("LD [$%04X], A", pu16)); w8(MEM.ptr, pu16, A); break;
										case 0b10: TRACE(format("LD A, [0xFF00+C]")); A = r8(MEM.ptr, 0xFF00 | C); break;
										case 0b11: TRACE(format("LD A, [$%04X]", pu16)); A = r8(MEM.ptr, pu16); break;
									}
								}
							break;
							case 0b011:
								switch (r23) {
									case 0b000: TRACE(format("JP $%04X", pu16)); JP(pu16); break; // C3
									case 0b001: writefln("FATAL ERROR reached '0xCB'"); exit(-1); break; // CB
									case 0b010: writefln("INVALID OP (%02X)", op); exit(-1); break; // D3
									case 0b011: writefln("INVALID OP (%02X)", op); exit(-1); break; // DB
									case 0b100: writefln("INVALID OP (%02X)", op); exit(-1); break; // E3
									case 0b101: writefln("INVALID OP (%02X)", op); exit(-1); break; // EB
									case 0b110: IME = false; break; // F3 (DI)
									case 0b111: IME = true;  break; // FB (EI)
								}
							break;
							case 0b100:
								if ((r23 & 0b100) == 0) {
									if (getflag(r23 & 0b11)) CALL(pu16);
								} else {
									writefln("INVALID OP (%02X)", op); exit(-1); // E4, EC, F4, FC
								}
							break;
							case 0b101:
								if ((r23 & 0b001) == 0) {
									PUSH16(getr16(r22));
								} else {
									switch (r22) {
										case 0b00: CALL(pu16); break;
										case 0b01: writefln("INVALID OP (%02X)", op); exit(-1); break;
										case 0b10: writefln("INVALID OP (%02X)", op); exit(-1); break;
										case 0b11: writefln("INVALID OP (%02X)", op); exit(-1); break;
									}
								}
							break;
							case 0b110: // ALU (C6, CE, D6, DE, E6, EE, F6, FE)
								switch (r23) {
									case 0b000: TRACE(format("ADD %02X", pu8)); ADD(pu8); break;
									case 0b001: TRACE(format("ADC %02X", pu8)); ADC(pu8); break;
									case 0b010: TRACE(format("SUB %02X", pu8)); SUB(pu8); break;
									case 0b011: TRACE(format("SBC %02X", pu8)); SBC(pu8); break;
									case 0b100: TRACE(format("AND %02X", pu8)); AND(pu8); break;
									case 0b101: TRACE(format("XOR %02X", pu8)); XOR(pu8); break;
									case 0b110: TRACE(format("OR  %02X", pu8)); OR (pu8); break;
									case 0b111: TRACE(format("CP  %02X", pu8)); CP (pu8); break;
								}
							break;
							case 0b111: // RST (C7, CF, D7, DF, E7, EF, F7, FF)
								RST(r23);
							break;
						}
					} break;
				} // switch

				addCycles(opcycles[op]);
			} // else

			if (jump && showinst) {
				writefln("--------------------------------------------------\n");
			}

			/*if (showinst) {
				RegDump();
				writefln();
			}*/
		} // while
	} // function

// --- DESENSAMBLADO ----------------------------------------------------------

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
				return format(fmt, "", PC + cb + cast(s8)v + 1);
			} else {
				return format(fmt, "", PC + cb + cast(s16)v + 1);
			}
		} else {
			//return format(fmt, (sign && v < 0) ? "-" : "", (v < 0) ? -v : v);
			return format(fmt, "", v);
		}
	}

	static void disasm(ubyte[] data, u16 offset = 0x0000) {
		u8* addr = data.ptr, dest = data.ptr + data.length;
		while (addr < dest) {
			u8* baddr = addr;
			writef("%04X: ", (addr - data.ptr) + offset);
			writef("%s [", disasm(addr));
			foreach (c; data[baddr - data.ptr..addr - data.ptr]) writef("%02X", c);
			writefln("]");
		}
	}

// --- INSTRUCCIONES ----------------------------------------------------------
	void NOP() { }
	void AND(u8 v) { A &= v; ZF = (A == 0); NF = false; HF = true ; CF = false; } // Logical AND
	void OR (u8 v) { A |= v; ZF = (A == 0); NF = false; HF = false; CF = false; } // Logical OR
	void XOR(u8 v) { A ^= v; ZF = (A == 0); NF = false; HF = false; CF = false; } // Logical XOR
	void CP (u8 v) {
		NF = true;
		ZF = (A == v);
		CF = (A < v);
		HF = (A & 0b1111) < (v & 0b1111);
	} // ComPare with A

	void HALT() {
		exit(-1);
	}

	void STOP() {
		exit(-1);
	}

	void INC(u16* r) { (*r)++; }
	void INC(u8*  r) {
		(*r)++; NF = false; ZF = (*r == 0);
		HF = ((*r & 0b1111) == 0b0000);
	}

	void DEC(u16* r) { (*r)--; }
	void DEC(u8*  r) {
		(*r)--; NF = true; ZF = (*r == 0);
		HF = ((*r & 0b1111) == 0b1111);
	}

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
	void RL  (u8 *r) { exit(-1); } // Rotate Left thru carry
	void RR  (u8 *r) { exit(-1); } // Roate Right thru carry
	void SLA (u8 *r) { CF = (*r & 0b10000000) != 0; *r <<= 1; ZF = (*r == 0); HF = false; NF = false; } // Shift Left
	void SRA (u8 *r) { exit(-1); } // Shift Right

	void SWAP(u8 *r) {
		*r = ((*r >> 4) & 0b1111) | ((*r << 4) & 0b11110000);
		ZF = (*r == 0);
		NF = false;
		HF = false;
		CF = false;
	} // SWAP NIBLES
	void SRL (u8 *r) { }

	void BIT(u8 bit, u8 *r) { ZF = (*r & (1 << bit)) == 0; NF = false; HF = true; }
	void RES(u8 bit, u8 *r) { *r &= ~(1 << bit); }
	void SET(u8 bit, u8 *r) { *r |=  (1 << bit); }

	void PUSH16(u16 v) { SP -= 2; *cast(u16*)(&MEM[SP]) = v; }
	void POP16(u16 *r) { *r = *cast(u16*)(&MEM[SP]); SP += 2; }

	u16 POP16() { u16 rv = *cast(u16*)(&MEM[SP]); SP += 2; return rv; }

	void DAA () {
		exit(-1);
	} // Demical adjust register A

	void CPL () { A = ~A; HF = true; NF = true; } // Logical NOT
	void SCF () { exit(-1); }
	void CCF () { exit(-1); }

	void RET () { POP16(&PC); } // RETURN
	void RETI() { RET(); IME = true; } // RETURN INTERRUPT

	void JR(s8 disp) { PC += disp; } // JUMP LOCAL TO
	void JP(u16 addr) { PC = addr; jump = true; } // JUMP TO

	void DI() { IME = false; } // DISABLE INTERRUPTS
	void EI() { IME = true ; } // ENABLE INTERRUPTS

	void CALL(u16 addr) { PUSH16(PC); JP(addr); } // CALL
	void RST(u8 v) { CALL(v << 3); } // RESTART AT

	void TRACE(char[] s) {
		if (showinst) writefln("%s", s);
	}
}
