module gameboy.z80;

import std.stdio, std.string, std.stream, std.c.stdlib, std.zlib;
import gameboy.tables, gameboy.memory;

import gameboy.common;

/*macro print(arg) {
	writefln(__FILE__, __LINE__, arg);
}*/

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

extern(Windows) void Sleep(int);

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

	Stream rom; // Stream
	RomHeader *rh; // Header
	// Memoria
	u8 MEM[0x10000];
	bool MEM_TRACED[0x10000];

	// Registros
	union { u16 AF; struct { u8 A; u8 F; } }
	union { u16 BC; struct { u8 B; u8 C; } }
	union { u16 DE; struct { u8 D; u8 E; } }
	union { u16 HL; struct { u8 H; u8 L; } }
	u16 SP;  // Stack Pointer
	u16 PC;  // Program Counter
	u8  IME; // Interrupt Master Enable Flag (Write Only)

	static const u8 CFMASK = 0b00010000;
	bool CF() { return (F & CFMASK) != 0; }
	void CF(bool set) { if (set) F |= CFMASK; else F &= ~CFMASK; }

	static const u8 HFMASK = 0b00100000;
	bool HF() { return (F & HFMASK) != 0; }
	void HF(bool set) { if (set) F |= HFMASK; else F &= ~HFMASK; }

	static const u8 NFMASK = 0b01000000;
	bool NF() { return (F & NFMASK) != 0; }
	void NF(bool set) { if (set) F |= NFMASK; else F &= ~NFMASK; }

	static const u8 ZFMASK = 0b10000000;
	bool ZF() { return (F & ZFMASK) != 0; }
	void ZF(bool set) { if (set) F |= ZFMASK; else F &= ~ZFMASK; }

	//bool ZF, NF, HF, CF;         // Zero Flag, Add/Sub-Flag, Half Carry Flag, Carry Flag

	// Utilitarios
	int cycles;   // Cantidad de ciclos * 1000 ejecutados
	int vbcycles; // Cantidad de ciclos de reloj usado para las scanlines

	bool sgb = false; // Emulacion de Super GameBoy
	bool cgb = false; // Emulación de GameBoy Color

	// Añade ciclos para simular el retraso
	void addCycles(int n) {
		static const uint ccyc = 0x400000, msec = 1;

		cycles += (n * 4) * 1000;
		vbcycles += (n * 4);

		while (cycles >= ccyc) {
			Sleep(msec);
			cycles -= ccyc;
		}

		while (vbcycles >= 17564) {
			incScanLine();
			printf("%02X|", MEM[0xFF44]);
			vbcycles -= 17564;
		}
	}

	// Cargamos la rom
	void loadRom(char[] name) { loadRom(new File(name, FileMode.In)); }
	void loadRom(Stream s) {
		//s.readExact(MEM.ptr, 0x4000);
		s.readExact(MEM.ptr, 0x8000);
		rh = cast(RomHeader *)(MEM.ptr + 0x100);
		rom = s;

		//traceInstruction(0x020C, 20); exit(-1);
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

	/*
		Un VBLANK se ejecuta 59.7 veces por segundo en la GB y 61.1 en SGB
		Un scanline se ejecuta (59.7 / 154)
	*/
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
			interrupt(0x40);
		}
	}

	void interrupt(u8 type) {
		u8 *IE = &MEM[0xFFFF]; // FFFF - IE - Interrupt Enable (R/W)
		u8 *IF = &MEM[0xFF0F]; // FF0F - IF - Interrupt Flag (R/W)

		writefln("!!INTERRUPTION: %02X", type);

		IME = false;

		switch (type) {
			case 0x40: // V-Blank
				if (*IE & (1 << 0)) {
				}
			break;
			case 0x48: // LCD STAT
				if (*IE & (1 << 1)) {
				}
			break;
			case 0x50: // Timer
				if (*IE & (1 << 2)) {
				}
			break;
			case 0x58: // Serial
				if (*IE & (1 << 3)) {
				}
			break;
			case 0x60: // Joypad
				if (*IE & (1 << 4)) {
				}
			break;
		}

		IME = true;
	}

	void dump() {
		File save = new File("dump", FileMode.OutNew);
		save.writeExact(&A, (&IME - &A) + IME.sizeof);
		//save.write(cast(ubyte[])compress(MEM, 9));
		save.write(MEM);
		save.close();
	}

	void pushStack16(u16 v) {
		SP -= 2;
		w16(MEM.ptr, SP, v);
	}

	u16 popStack16() {
		u16 R = r16(MEM.ptr, SP);
		SP += 2;
		return R;
	}

	void CALL(u16 addr) {
		pushStack16(PC);
		PC = addr;
	}

	// Interpreta una sucesión de opcodes
	void interpret() {
		void *APC;
		u16 CPC;
		u8 op;
		void *reg_cb;
		bool hl;
		bool showinst;

		u8* addrr8(u8 r) {
			switch (r & 0b111) {
				case 0b000: return &B;
				case 0b001: return &C;
				case 0b010: return &D;
				case 0b011: return &E;
				case 0b100: return &H;
				case 0b101: return &L;
				case 0b110: return &MEM[HL];
				case 0b111: return &A;
			}
		}

		u16* addrr16(u8 r) {
			switch (r & 0b11) {
				case 0b000: return &BC;
				case 0b001: return &DE;
				case 0b010: return &HL;
				case 0b011: return &SP;
			}
		}

		bool getflag(u8 r) {
			switch (r & 0b11) {
				case 0b000: return !ZF;
				case 0b001: return  ZF;
				case 0b010: return !CF;
				case 0b011: return  CF;
			}
		}

		u8 getr8(u8 r) { return *addrr8(r); }
		void setr8(u8 r, u8 v) { *addrr8(r) = v; }
		u16 getr16(u8 r) { return *addrr16(r); }
		void setr16(u8 r, u16 v) { *addrr16(r) = v; }


		u8  pu8 () { return *cast(u8 *)APC; } s8  ps8 () { return *cast(s8 *)APC; }
		u16 pu16() { return *cast(u16*)APC; } s16 ps16() { return *cast(s16*)APC; }

		while (true) {
			CPC = PC;
			op = MEM[PC++];

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

			// Los dos bits mas significativos del primer byte indican el tipo de instrucción
			switch (op >> 6 & 0b11) {
				case 0b00: {
					switch (r13) {
						case 0b000:
							switch (r23) {
								case 0b000: NOP();   break;
								case 0b001: w16(MEM.ptr, pu16, SP); break;
								case 0b010: STOP();  break;
								case 0b011: JR(pu8); break;
								case 0b100: if (!ZF) JR(pu8); break;
								case 0b101: if ( ZF) JR(pu8); break;
								case 0b110: if (!CF) JR(pu8); break;
								case 0b111: if ( CF) JR(pu8); break;
							}
						break;
						case 0b001: case 0b011: {
							u8 r16 = (op >> 4) & 0b11;
							switch (op & 0b1111) {
								case 0b0001: setr16(r16, pu16); break;
								case 0b0011: INC(addrr16(r16)); break;
								case 0b1001: ADDHL(getr16(r16)); break;
								case 0b1011: DEC(addrr16(r16)); break;
							}
						} break;
						case 0b010: { // A <- (r16), (r16) <- A
							u16 v16 = (r2 & 0b100) ? HL : getr16(r2 & 0b11);
							if (r2 & 0b1) A = r8(MEM.ptr, v16); else w8(MEM.ptr, v16, A);
							if (r2 & 0b100) { if (r2 & 0b1) DEC(HL); else INC(HL); }
						} break;
						case 0b100: INC(addrr8(r2)); break; // INC
						case 0b101: DEC(addrr8(r2)); break; // DEC
						case 0b110: setr8(r2, pu8);  break; // LD, nn
						case 0b111:
							switch (r2) {
								case 0b000: RLCA(); break;
								case 0b001: RRCA(); break;
								case 0b010: RLA (); break;
								case 0b011: RRA (); break;
								case 0b100: DAA (); break;
								case 0b101: CPL (); break;
								case 0b110: SCF (); break;
								case 0b111: CCF (); break;
							}
						break;
					}
				} break;
				case 0b01: { // LD REG, REG -- REG <- REG
					if (op == 0x76) { // HALT (LD (HL), (HL))
						writefln("HALT");
					} else {
						setr8(r2, getr8(r1));
					}
				} break;
				case 0b10: { // OP A, REG
					switch (r2) {
						case 0b000: ADD(r1); break;
						case 0b001: ADC(r1); break;
						case 0b010: SUB(r1); break;
						case 0b011: SBC(r1); break;
						case 0b100: AND(r1); break;
						case 0b101: XOR(r1); break;
						case 0b110: OR (r1); break;
						case 0b111: CP (r1); break;
					}
				} break;
				case 0b11: {
					if (op == 0xCB) { // MULTIBYTE
						u8 op2 = MEM[PC++];
						u8* r8 = addrr8(op2 & 0b111);
						u8 bit = ((op2 >> 3) & 0b111);

						switch (op2 >> 6) {
							case 0b00:
								switch ((op2 >> 3) & 0b111) {
									case 0b000: RLC (r8); break;
									case 0b001: RRC (r8); break;
									case 0b010: RL  (r8); break;
									case 0b011: RR  (r8); break;
									case 0b100: SLA (r8); break;
									case 0b101: SRA (r8); break;
									case 0b110: SWAP(r8); break;
									case 0b111: SRL (r8); break;
								}
							break;
							case 0b01: BIT(bit, r8); break;
							case 0b10: RES(bit, r8); break;
							case 0b11: SET(bit, r8); break;
						}
					} else {
						switch (r14) {
							case 0b0000: if (getflag(r22)) RET(); break;
							case 0b1000:
								switch (r22) {
									case 0b00: w8(MEM.ptr, 0xFF00 | pu8, A);  break; // LD ($FF00 + nn), A // special (old ret po)
									case 0b01: ADDSP(ps8); break; // ADD SP, dd // special (old ret pe) (nocash extended as shortint)
									case 0b10: A = r8(MEM.ptr, 0xFF00 | pu8); break; // LD A, ($FF00 + nn) // special (old ret p)
									case 0b11: // TODO: SET FLAGS
										HL = SP + ps8;
									break;
								}
							break;
							case 0b0001: POP16(addrr16(r22)); break;
							case 0b1001:
								switch (r23) {
									case 0b001: RET(); break;
									case 0b011: RETI(); break;
									case 0b101: JP(HL); break;
									case 0b111: SP = HL; break;
								}
							break;
							case 0b0010: case 0b1010:
								switch (r23) {
									case 0b000: case 0b001: case 0b010: case 0b011:
										if (getflag(r22)) JP(pu16);
									break;
									case 0b100: w8(MEM.ptr, 0xFF00 | C, A); break;
									case 0b101: w8(MEM.ptr, pu16, A); break;
									case 0b110: A = r8(MEM.ptr, 0xFF00 | C); break;
									case 0b111: A = r8(MEM.ptr, pu16); break;
								}
							break;
							case 0b0011:
								JP(pu16);
							break;
							case 0b1011:
								switch (r23) {
									case 0b110: DI(); break; // DI
									case 0b111: EI(); break; // EI
								}
							break;
							case 0b0100: case 0b1100:
								if (!(r23 & 0b100)) {
									if (getflag(r22)) CALL(pu16);
								} else {
									// -
								}
							break;
							case 0b0101: case 0b1101:
								switch (r23) {
									case 0b000: PUSH16(BC); break;
									case 0b001: CALL(pu16); break;
									case 0b010: PUSH16(DE); break;
									case 0b011: break;
									case 0b100: PUSH16(HL); break;
									case 0b101: break;
									case 0b110: PUSH16(AF); break;
									case 0b111: break;
								}
							break;
							case 0b0110: case 0b1110: // ALU nn
								switch (r23) {
									case 0b000: ADD(pu8); break;
									case 0b001: ADC(pu8); break;
									case 0b010: SUB(pu8); break;
									case 0b011: SBC(pu8); break;
									case 0b100: AND(pu8); break;
									case 0b101: XOR(pu8); break;
									case 0b110: OR (pu8); break;
									case 0b111: CP (pu8); break;
								}
							break;
							case 0b0111: case 0b1111: RST(r2 << 3); break;
						}
					}
				} break;
			}

			version(trace) {
				if (showinst && PC != RPC) {
					writefln("-----------------------------------");
				}
			}
		}
	}

	// Inicializamos la emulación
	void init() {
		AF = 0x01B0;
		BC = 0x0013;
		DE = 0x00D8;
		HL = 0x014D;
		SP = 0xFFFE;
		PC = 0x0100;
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

	// INSTRUCCIONES
	void NOP() {
	}
}

int main(char[][] args) {
	GameBoy gb = new GameBoy;

	gb.loadRom("TETRIS.GB");
	gb.init();
	gb.interpret();

	return 0;
}