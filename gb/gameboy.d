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

	void RLC(u8*  r) { CF = ((*r >>  7) != 0); *r = (*r << 1) | (CF <<  0); ZF = (*r == 0); HF = false; NF = false; }
	void RLC(u16* r) { CF = ((*r >> 15) != 0); *r = (*r << 1) | (CF <<  0); ZF = (*r == 0); HF = false; NF = false; }
	void RRC(u8*  r) { CF = ((*r &   1) != 0); *r = (*r >> 1) | (CF <<  7); ZF = (*r == 0); HF = false; NF = false; }
	void RRC(u16* r) { CF = ((*r &   1) != 0); *r = (*r >> 1) | (CF << 15); ZF = (*r == 0); HF = false; NF = false; }

	void RL(u8*  r) { }
	void RL(u16* r) { }
	void RR(u8*  r) { }
	void RR(u16* r) { }

	void SLA(u8*  r) { }
	void SLA(u16* r) { }
	void SRA(u8*  r) { }
	void SRA(u16* r) { }

	void SWAP(u8*  R) {
		*R = (*R >> 4) | (*R << 4);
		ZF = (*R == 0);
		NF = false;
		HF = false;
		CF = false;
	}

	u16 SWAP(u16 R) {
		SWAP(cast(u8*)&R);
		return R;
	}

	void SRL(u8*  r) { }
	void SRL(u16* r) { }

	void BIT(u8*  r) { }
	void BIT(u16* r) { }

	void RES(u8*  r) { }
	void RES(u16* r) { }
	void SET(u8*  r) { }
	void SET(u16* r) { }

	void ADD(ref u8 R) { // Add
		HF = (((A & 0xF) + (R & 0xF)) >> 4) != 0;
		NF = false;
		ZF = (R == 0);
		R  = (A + R) & 0xFF;
		CF = ((R & 0x80) != 0);
	}

	void DEC(ref u8 R) { // Decrementar
		HF = ((R - 1) & 0xF) < (R & 0xF);
		R--; ZF = (R == 0);
		NF = true;
	}

	void INC(ref u8 R) { // Incrementar
		R++;
		HF = ((R & 0xF) == 0);
		ZF = (R == 0);
		NF = false;
	}

	u16 INC(u16 V) { // Incrementar
		V++;
		//HF = ((R & 0xF) == 0);
		//ZF = (R == 0);
		//NF = false;
		return V;
	}

	void CP(u8 V) { // Compare with A
		CF = (A < V); // Carry Flag
		HF = (A & 0xF) < (V & 0xF); // Half-Carry Flag
		ZF = (A == V); // Zero Flag
		NF = true; // Add-Sub flag
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

		u8 *get_reg8(int r) {
			switch (r) {
				case 0: return &B; case 1: return &C; case 2: return &D; case 3: return &E;
				case 4: return &H; case 5: return &L; case 7: return &A;
				default: throw(new Exception("Unexpected error"));
			}
		}

		u8  pu8 () { return *cast(u8 *)APC; }
		s8  ps8 () { return *cast(s8 *)APC; }
		u16 pu16() { return *cast(u16*)APC; }
		s16 ps16() { return *cast(s16*)APC; }

		while (true) {
			/*if (PC == 0x0237) {
				dump();
				exit(-1);
			}*/

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

			if (op == 0xCB) {
				op = MEM[PC++];
				//reg_cb = get_reg(op & 0b111, hl);
				// Decodificación de la operación
				switch (op & 0b11111000) {
					///* RLC  */ case 0x00: //hl ? RLC (cast(u16*)reg_cb) : RLC (cast(u8*)reg_cb); break;
					///* RRC  */ case 0x08: //hl ? RRC (cast(u16*)reg_cb) : RRC (cast(u8*)reg_cb); break;
					///* RL   */ case 0x10: //hl ? RL  (cast(u16*)reg_cb) : RL  (cast(u8*)reg_cb); break;
					///* RR   */ case 0x18: //hl ? RR  (cast(u16*)reg_cb) : RR  (cast(u8*)reg_cb); break;
					///* SLA  */ case 0x20: //hl ? SLA (cast(u16*)reg_cb) : SLA (cast(u8*)reg_cb); break;
					///* SRA  */ case 0x28: //hl ? SRA (cast(u16*)reg_cb) : SRA (cast(u8*)reg_cb); break;
					case 0x30: // SWAP
						if ((op & 0b111) == 6) {
							HL = SWAP(HL);
						} else {
							SWAP(get_reg8(op & 0b111));
						}
					break;
					///* SRL  */ case 0x38: //hl ? SRL (cast(u16*)reg_cb) : SRL (cast(u8*)reg_cb); break;
					///* BIT  */ case 0x40: //hl ? BIT (cast(u16*)reg_cb) : BIT (cast(u8*)reg_cb); break;
					///* RES  */ case 0x80: //hl ? RES (cast(u16*)reg_cb) : RES (cast(u8*)reg_cb); break;
					///* SET  */ case 0xC0: //hl ? SET (cast(u16*)reg_cb) : SET (cast(u8*)reg_cb); break;
					default:
						writefln("             \x18_____________________________ Instruction not emulated");
						return;
					break;
				}

				addCycles(opcycles_cb[op]);
			} else {
				APC = &MEM[PC];
				PC += opargs[op];

				int RPC = PC;

				addCycles(opcycles[op]);

				// Localización del registro ["B", "C", "D", "E", "H", "L", "(HL)", "A"];
				switch (op) {
					case 0x00:            break; // NOP - NOt Operation
					case 0x01: BC = pu16; break; // LD BC, nnnn
					case 0x05: DEC(B);    break; // DEC B
					case 0x06: B = pu8;   break; // LD B, nn
					case 0x0B: BC = BC - 1;   break; // DEC BC
					case 0x0C: INC(C);    break; // INC C
					case 0x0D: DEC(C);    break; // DEC C
					case 0x0E: C = pu8;   break; // LD C, nn
					case 0x16: D = pu8;   break; // LD D, nn
					case 0x19: // ADD HL, DE
						CF = ((HL + DE) < HL);
						HF = ((HL & 0xFFF) + (DE & 0xFFF)) > 0xFFF;
						HL = HL + DE;
						NF = false;
					break;
					case 0x20: if (!ZF) PC = PC + ps8; break; // JR NZ, PC+nn

					case 0x23: HL = INC(HL); break; // INC HL
					case 0x2A: A  = r8 (MEM.ptr, HL); break; // LDI  A,(HL) ---- special (old ld hl,(nnnn))
					case 0x2F: A = 255 - A; HF = true; NF = true; break; // Logical NOT
					/*
					//case 0x28: case 0x29: case 0x2A: case 0x2B: case 0x2C: case 0x2D: case 0x2E: case 0x2F: // SRA R
						if ((op & 0b111) == 6) {
							CF = (HL & 1) != 0;
							HL = HL >> 1;
						} else {
							u8* R = get_reg8(op & 0b111);
							CF = (*R & 1) != 0;
							*R = *R >> 1;
						}
						ZF = (*get_reg8(op & 0b111) == 0);
						HF = false;
						NF = false;
					break;
					*/
					case 0x21: HL = pu16; break; // LD HL, nnnn
					case 0x31: SP = pu16; break; // LD sp, nnnn
					case 0x32: w8(MEM.ptr, pu16, A); break; // LDD (nnnnn), A
					case 0x36: HL = pu8; break; // LD (HL), nn
					case 0x3E: A = pu8;  break; // LD A, nn
					case 0x47: B = A;    break; // LD B, A
					case 0x4F: C = A;    break; // LD C, A
					case 0x56: D = r8(MEM.ptr, HL); break; // LD D, HL
					case 0x57: D = A;    break; // LD D, A
					case 0x5E: E = r8(MEM.ptr, HL); break; // LD E, (HL)
					case 0x5F: E = A;    break; // LD E, A
					case 0x78: A = B;    break; // LD A, B
					case 0x79: A = C;    break; // LD A, C
					case 0x87: ADD(A);   break; // ADD A, A
					case 0xA0: case 0xA1: case 0xA2: case 0xA3: case 0xA4: case 0xA5: case 0xA6: case 0xA7: // AND R
						A &= ((op & 0b111) == 6) ? HL : *get_reg8(op & 0b111);
						ZF = (A == 0);
						CF = false;
						NF = false;
						HF = true;
					break;
					case 0xA8: case 0xA9: case 0xAA: case 0xAB: case 0xAC: case 0xAD: case 0xAE: case 0xAF: // XOR R
						A ^= ((op & 0b111) == 6) ? HL : *get_reg8(op & 0b111);
						ZF = (A == 0);
						CF = false;
						NF = false;
						HF = false;
					break;
					case 0xB0: case 0xB1: case 0xB2: case 0xB3: case 0xB4: case 0xB5: case 0xB6: case 0xB7: // OR R
						A |= ((op & 0b111) == 6) ? HL : *get_reg8(op & 0b111);
						ZF = (A == 0);
						CF = false;
						NF = false;
						HF = false;
					break;
					case 0xC3: PC = pu16; break;
					case 0xC9: // RET
						PC = *cast(u16 *)(MEM.ptr + SP);
						SP += 2;
					break;
					case 0xCD: // CALL nnnn
						pushStack16(PC);
						PC = pu16;
					break;
					case 0xD5: pushStack16(DE); break; // PUSH DE
					case 0xE0: // LD ($FF00+nn),A
						w8(MEM.ptr, 0xFF00 | pu8, A);
					break;
					case 0xE1: // POP HL
						HL = popStack16();
					break;
					case 0xE2: // LD ($FF00+C),A  ---- special (old jp po,nnnn)
						w8(MEM.ptr, 0xFF00 | C, A);
					break;
					case 0xE6: // AND nn
						A &= pu8;
						ZF = (A == 0);
						NF = false;
						CF = false;
						HF = true;
					break;
					case 0xE9: PC = HL; break; // JP HL
					case 0xEA: w8(MEM.ptr, pu16, A); break; // LD (nnnn), A  ---- special (old jp pe,nnnn)
					case 0xEF: // RST $28
						/*
						Jump Vectors in First ROM Bank
						The following addresses are supposed to be used as jump vectors:

						0000,0008,0010,0018,0020,0028,0030,0038   for RST commands
						0040,0048,0050,0058,0060                  for Interrupts
						*/
						CALL(0x28);
					break;
					case 0xF0: // LD A,($FF00+nn)
						A = r8(MEM.ptr, 0xFF00 | pu8);
					break;
					case 0xF3: IME = false; break; // IME=0 | Disable Interrupts
					case 0xFB: IME = true ; break; // IME=1 | Enable Interrupts
					case 0xFE: CP(pu8);     break; // CP nn | Compare with A
					case 0xFF: CALL(0x38); break; // RST $38

u8* addrr8(u8 r) {
	switch (r & 0b111) {
		case 0b000: return &B;
		case 0b001: return &C;
		case 0b010: return &D;
		case 0b011: return &E;
		case 0b100: return &H;
		case 0b101: return &L;
		case 0b110: return MEM + HL;
		case 0b111: return &A;
	}
}

u8 getr8(u8 r) { return *addrr8(r); }
void setr8(u8 r, u8 v) { *addrr8(r) = v; }

u16* addrr16(u8 r) {
	switch (r & 0b11) {
		case 0b000: return &BC;
		case 0b001: return &DE;
		case 0b010: return &HL;
		case 0b011: return &SP;
	}
}

u16 getr16(u8 r) { return *addrr16(r); }
void setr16(u8 r, u16 v) { *addrr16(r) = v; }

bool getflag(u8 r) {
	switch (r & 0b11) {
		case 0b000: return !ZF;
		case 0b001: return  ZF;
		case 0b010: return !CF;
		case 0b011: return  CF;
	}
}

// DEPRECATED
u8 r1 = (op >> 0) & 0b111, r2 = (op >> 3) & 0b111;

u8 r13 = (op >> 0) & 0b0111, r23 = (op >> 3) & 0b0111;
u8 r24 = (op >> 0) & 0b1111, r22 = (op >> 4) & 0b0011;

switch (op >> 6 & 0b11) {
	case 0b00: {
		switch (r13) {
			case 0b000:
				switch (r23) {
					case 0b000: NOP();   break;
					case 0b001: w16(r16, SP); break;
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
					case 0b1001: ADDHL(getrr16(r16)); break;
					case 0b1011: DEC(addrr16(r16)); break;
				}
			} break;
			case 0b010: { // A <- (r16), (r16) <- A
				u16 v16 = (r2 & 0b100) ? HL : getr16(r2 & 0b11);
				if (r2 & 0b1) A = r8(v16); else w8(v16, A);
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
			stderr.writefln("HALT");
		} else {
			setr8(r2, getr8(r1);
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
		} else {
			switch (r1) {
				case 0b000:
					if (r2 & 1) {
						switch (r2 >> 1) {
							case 0b00: w8(0xFF00 | pu8, A);  break; // LD ($FF00 + nn), A // special (old ret po)
							case 0b01: ADDSP(ps8);           break; // ADD SP, dd // special (old ret pe) (nocash extended as shortint)
							case 0b10: A = r8(0xFF00 | pu8); break; // LD A, ($FF00 + nn) // special (old ret p)
							case 0b11:
								HL = SP + ps8;
								// TODO: SET FLAGS
							break;
						}
					} else {
						if (getflag()) RET();
					}
				break;
				case 0b001:
					if (r2 & 1) {
						POP16(addrr16(r2 >> 1));
					} else {
					}
				break;
				case 0b010: break;
				case 0b011: break;
				case 0b100: break;
				case 0b101: break;
				case 0b110: break;
				case 0b111: RST(r2 << 3); break;
				default:
				break;
			}

			/*switch (op) {
				case 0xC0: if (!ZF) RET();         break;  // RET NZ
				case 0xC1: BC = pop16();           break;  // POP BC
				case 0xC2: if (!ZF) JP(pu16);      break;  // JP NZ, nnnn
				case 0xC3: PC = pu16;              break;  // JP nnnn
				case 0xC4: if (!ZF) CALL(pu16);    break;  // CALL NZ, nnnn
				case 0xC5: push16(BC);             break;  // PUSH BC
				case 0xC6: ADD(pu8);               break;  // ADD A, nn
				case 0xC7: RST(0);                 break;  // ADD A, nn
			}*/
		}
	} break;
}


/*
Case &HC6     ' ADD  A,nn
add pb

Case &HC9 'RET
ret
Case &HCA     ' JP     'Z,nnnn
jp pw, zf
Case &HCC     ' CALL Z,nnnn
zcall pw, zf
Case &HCD     ' CALL nnnn
zcall pw
Case &HCE     ' ADC  A,nn
adc pb

Case &HD1     ' POP  DE
pop E
pop D
Case &HD2     ' JP     'NC,nnnn
jp pw, 1 - cf
Case &HD3     ' -     '     '     '     '     '  ---- ??? (old out (nn),a)
'Stop
Case &HD4     ' CALL NC,nnnn
zcall pw, 1 - cf
Case &HD5     ' PUSH DE
push D
push E
Case &HD6     ' SUB  nn
zsub pb

Case &HD9     ' RETI     '     '     '     '  ---- remapped (old exx)
reti
Case &HDA     ' JP     'C,nnnn
jp pw, cf
Case &HDB     ' -     '     '     '     '     '  ---- ??? (old in a,(nn))
'Stop
Case &HDC     ' CALL C,nnnn
zcall pw, cf
Case &HDD     ' -     '     '     '     '     '  ---- ??? (old ix-commands)
'Stop
Case &HDE     ' SBC  A,nn     '  (nocash added, this opcode does existed, e.g. used by kwirk)
sbc pb

Case &HE1     ' POP  HL
pop L
pop H
Case &HE2     ' LD     '($FF00+C),A  ---- special (old jp po,nnnn)
WriteM 65280 Or c, A
Case &HE3     ' -     '     '     '     '     '  ---- ??? (old ex (sp),hl)
'Stop
Case &HE4     ' -     '     '     '     '     '  ---- ??? (old call po,nnnn)
'Stop
Case &HE5     ' PUSH HL
push H
push L
Case &HE6     ' AND  nn
zand pb

Case &HE9 'JP(HL)
jp H * 256 Or L
Case &HEA     ' LD     '(nnnn),A     '  ---- special (old jp pe,nnnn)
WriteM pw, A
Case &HEB     ' -     '     '     '     '     '  ---- ??? (old ex de,hl)
'Stop
Case &HEC     ' -     '     '     '     '     '  ---- ??? (old call pe,nnnn)
'Stop
Case &HED     ' -     '     '     '     '     '  ---- ??? (old ed-commands)
'Stop
Case &HEE     ' XOR  nn
zxor pb

Case &HF1     ' POP  AF
pop temp
setF CByte(temp)
pop A
Case &HF2     ' LD     'A,(C)     '     '  ---- special (old jp p,nnnn)
A = readM(65280 Or c)
Case &HF3 'DI
ime_stat = 2
Case &HF4     ' -     '     '     '     '     '  ---- ??? (old call p,nnnn)
'Stop
Case &HF5     ' PUSH AF
push A
push getF
Case &HF6     ' OR     'nn
zor pb

Case &HF9     ' LD     'SP,HL
SP = H * 256 Or L
Case &HFA     ' LD     'A,(nnnn)     '  ---- special (old jp m,nnnn)
A = readM(pw)
Case &HFB 'EI
ime_stat = 1
Case &HFC     ' -     '     '     '     '     '  ---- ??? (old call m,nnnn)
'Stop
Case &HFD     ' -     '     '     '     '     '  ---- ??? (old iy-commands)
'Stop
Case &HFE     ' CP     'nn
cp pb
*/
					default:
						writefln("             \x18_____________________________ Instruction not emulated");
						return;
					break;
				}

				version(trace) {
					if (showinst && PC != RPC) {
						writefln("-----------------------------------");
					}
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
}

int main(char[][] args) {
	GameBoy gb = new GameBoy;

	gb.loadRom("TETRIS.GB");
	gb.init();
	gb.interpret();

	return 0;
}