import std.stdio, std.string, std.stream;

alias ubyte  u8;
alias ushort u16;
alias uint   u32;

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

class GameBoy {
	// 1 -> 4 cycles, 2 -> 8 cycles, 3 -> 12 cycles, 4 -> 16 cycles
	static ubyte opcycles[0x100] = [
		//////////////////////////////////////////////////////////
		/*  00  */ 1, 3, 2, 2, 1, 1, 2, 1, 5, 2, 2, 2, 1, 1, 2, 1,
		/*  10  */ 1, 3, 2, 2, 1, 1, 2, 1, 2, 2, 2, 2, 1, 1, 2, 1,
		/*  20  */ 2, 3, 2, 2, 1, 1, 2, 1, 2, 2, 2, 2, 1, 1, 2, 1,
		/*  30  */ 2, 3, 2, 2, 3, 3, 3, 1, 2, 2, 2, 2, 1, 1, 2, 1,
		/*  40  */ 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
		/*  50  */ 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
		/*  60  */ 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
		/*  70  */ 2, 2, 2, 2, 2, 2, 1, 2, 1, 1, 1, 1, 1, 1, 2, 1,
		/*  80  */ 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
		/*  90  */ 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
		/*  A0  */ 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
		/*  B0  */ 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1,
		/*  C0  */ 2, 3, 3, 4, 3, 4, 2, 4, 2, 4, 3, 2, 3, 6, 2, 4,
		/*  D0  */ 2, 3, 3, 3, 3, 4, 2, 4, 2, 4, 3, 0, 3, 0, 2, 4,
		/*  E0  */ 3, 3, 2, 0, 0, 4, 2, 4, 4, 1, 4, 0, 0, 0, 2, 4,
		/*  F0  */ 2, 3, 2, 1, 0, 4, 2, 4, 2, 2, 4, 1, 0, 0, 2, 4,
		//////////////////////////////////////////////////////////
	];

	// 1 -> 4 cycles, 2 -> 8 cycles, 3 -> 12 cycles, 4 -> 16 cycles
	static ubyte opcycles_cb[0x100] = [
		////////+//////////////////////////+////////////////////////
		////////+/           00            +           08          /
		////////+//////////////////////////+////////////////////////
		/*  00  */ 2, 2, 2, 2, 2, 2, 4, 2,   2, 2, 2, 2, 2, 2, 4, 2,
		/*  10  */ 2, 2, 2, 2, 2, 2, 4, 2,   2, 2, 2, 2, 2, 2, 4, 2,
		/*  20  */ 2, 2, 2, 2, 2, 2, 4, 2,   2, 2, 2, 2, 2, 2, 4, 2,
		/*  30  */ 2, 2, 2, 2, 2, 2, 4, 2,   2, 2, 2, 2, 2, 2, 4, 2,
		/*  40  */ 2, 2, 2, 2, 2, 2, 3, 2,   0, 0, 0, 0, 0, 0, 0, 0,
		/*  50  */ 0, 0, 0, 0, 0, 0, 0, 0,   0, 0, 0, 0, 0, 0, 0, 0,
		/*  60  */ 0, 0, 0, 0, 0, 0, 0, 0,   0, 0, 0, 0, 0, 0, 0, 0,
		/*  70  */ 0, 0, 0, 0, 0, 0, 0, 0,   0, 0, 0, 0, 0, 0, 0, 0,
		/*  80  */ 2, 2, 2, 2, 2, 2, 4, 2,   0, 0, 0, 0, 0, 0, 0, 0,
		/*  90  */ 0, 0, 0, 0, 0, 0, 0, 0,   0, 0, 0, 0, 0, 0, 0, 0,
		/*  A0  */ 0, 0, 0, 0, 0, 0, 0, 0,   0, 0, 0, 0, 0, 0, 0, 0,
		/*  B0  */ 0, 0, 0, 0, 0, 0, 0, 0,   0, 0, 0, 0, 0, 0, 0, 0,
		/*  C0  */ 2, 2, 2, 2, 2, 2, 4, 2,   0, 0, 0, 0, 0, 0, 0, 0,
		/*  D0  */ 0, 0, 0, 0, 0, 0, 0, 0,   0, 0, 0, 0, 0, 0, 0, 0,
		/*  E0  */ 0, 0, 0, 0, 0, 0, 0, 0,   0, 0, 0, 0, 0, 0, 0, 0,
		/*  F0  */ 0, 0, 0, 0, 0, 0, 0, 0,   0, 0, 0, 0, 0, 0, 0, 0,
		////////////////////////////////////////////////////////////
	];

	static ubyte opargs[0x100] = [
		//////////////////////////////////////////////////////////
		/*  00  */ 0, 2, 0, 0, 0, 0, 1, 0, 2, 0, 0, 0, 0, 0, 1, 0,
		/*  10  */ 0, 2, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0,
		/*  20  */ 1, 2, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0,
		/*  30  */ 1, 2, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0,
		/*  40  */ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		/*  50  */ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		/*  60  */ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		/*  70  */ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		/*  80  */ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		/*  90  */ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		/*  A0  */ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		/*  B0  */ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		/*  C0  */ 0, 0, 2, 2, 2, 0, 1, 0, 0, 0, 2, 0, 2, 2, 1, 0,
		/*  D0  */ 0, 0, 2, 0, 2, 0, 1, 0, 0, 0, 2, 0, 2, 0, 1, 0,
		/*  E0  */ 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 2, 0, 0, 0, 1, 0,
		/*  F0  */ 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 2, 0, 0, 0, 1, 0,
		//////////////////////////////////////////////////////////
	];

	// # -> unsigned | * -> signed
	static char[] opdisasm[0x100] = [
		//////////+/////////////////+//////////////+///////////////+//////////////+//////////////+//////////////+///////////////+//////////////+//////////////+//////////////+///////////////+////////////+/////////////+////////////+///////////////+/////////////
		//////////+        00       +      01      +       02      +      03      +      04      +      05      +       06      +      07      +      08      +      09      +      0A       +     0B     +     0C      +     0D     +      0E       +     0F    //
		//////////+/////////////////+//////////////+///////////////+//////////////+//////////////+//////////////+///////////////+//////////////+//////////////+//////////////+///////////////+////////////+/////////////+////////////+///////////////+/////////////
		/*   00   */   "NOP"        , "LD BC, #"   , "LD (BC), A"  , "INC BC"     , "INC B"      , "DEC B"      , "LD B, #"     , "RLC A"      , "LD #, SP"   , "ADD HL, BC" , "LD A, (BC)"  , "DEC BC"   , "INC C"     , "DEC C"    , "LD C, #"     , "RRC A"    ,
		/*   10   */   "STOP"       , "LD DE, #"   , "LD (DE), A"  , "INC DE"     , "INC D"      , "DEC D"      , "LD D, #"     , "RLA"        , "JR *"       , "ADD HL, DE" , "LD A, (DE)"  , "DEC DE"   , "INC E"     , "DEC E"    , "LD E, #"     , "RRA"      ,
		/*   20   */   "JR NZ, *"   , "LD HL, #"   , "LDI (HL), A" , "INC HL"     , "INC H"      , "DEC H"      , "LD H, #"     , "DAA"        , "JR Z, *"    , "ADD HL, HL" , "LDI A, (HL)" , "DEC HL"   , "INC L"     , "DEC L"    , "LD L, #"     , "CPL"      ,
		/*   30   */   "JR NC, *"   , "LD SP, #"   , "LDD (HL), A" , "INC SP"     , "INC (HL)"   , "DEC (HL)"   , "LD (HL), #"  , "SCF"        , "JR C, *"    , "ADD HL, SP" , "LDD A, (HL)" , "DEC SP"   , "INC A"     , "DEC A"    , "LD A, #"     , "CCF"      ,
		/*   40   */   "LD B, B"    , "LD B, C"    , "LD B, D"     , "LD B, E"    , "LD B, H"    , "LD B, L"    , "LD B, (HL)"  , "LD B, A"    , "LD C, B"    , "LD C, C"    , "LD C, D"     , "LD C, E"  , "LD C, H"   , "LD C, L"  , "LD C, (HL)"  , "LD C, A"  ,
		/*   50   */   "LD D, B"    , "LD D, C"    , "LD D, D"     , "LD D, E"    , "LD D, H"    , "LD D, L"    , "LD D, (HL)"  , "LD D, A"    , "LD E, B"    , "LD E, C"    , "LD E, D"     , "LD E, E"  , "LD E, H"   , "LD E, L"  , "LD E, (HL)"  , "LD E, A"  ,
		/*   60   */   "LD H, B"    , "LD H, C"    , "LD H, D"     , "LD H, E"    , "LD H, H"    , "LD H, L"    , "LD H, (HL)"  , "LD H, A"    , "LD L, B"    , "LD L, C"    , "LD L, D"     , "LD L, E"  , "LD L, H"   , "LD L, L"  , "LD L, (HL)"  , "LD L, A"  ,
		/*   70   */   "LD (HL), B" , "LD (HL), C" , "LD (HL), D"  , "LD (HL), E" , "LD (HL), H" , "LD (HL), L" , "HALT"        , "LD (HL), A" , "LD A, B"    , "LD A, C"    , "LD A, D"     , "LD A, E"  , "LD A, H"   , "LD A, L"  , "LD A, (HL)"  , "LD A, A"  ,
		/*   80   */   "ADD A, B"   , "ADD A, C"   , "ADD A, D"    , "ADD A, E"   , "ADD A, H"   , "ADD A, L"   , "ADD A, (HL)" , "ADD A, A"   , "ADC A, B"   , "ADC A, C"   , "ADC A, D"    , "ADC A, E" , "ADC A, H"  , "ADC A, L" , "ADC A, (HL)" , "ADC A, A" ,
		/*   90   */   "SUB A, B"   , "SUB A, C"   , "SUB A, D"    , "SUB A, E"   , "SUB A, H"   , "SUB A, L"   , "SUB A, (HL)" , "SUB A, A"   , "SBC A, B"   , "SBC A, C"   , "SBC A, D"    , "SBC A, E" , "SBC A, H"  , "SBC A, L" , "SBC A, (HL)" , "SBC A, A" ,
		/*   A0   */   "AND B"      , "AND C"      , "AND D"       , "AND E"      , "AND H"      , "AND L"      , "AND (HL)"    , "AND A"      , "XOR B"      , "XOR C"      , "XOR D"       , "XOR E"    , "XOR H"     , "XOR L"    , "XOR (HL)"    , "XOR A"    ,
		/*   B0   */   "OR B"       , "OR C"       , "OR D"        , "OR E"       , "OR H"       , "OR L"       , "OR (HL)"     , "OR A"       , "CP B"       , "CP C"       , "CP D"        , "CP E"     , "CP H"      , "CP L"     , "CP (HL)"     , "CP A"     ,
		/*   C0   */   "RET NZ"     , "POP BC"     , "JP NZ, #"    , "JP #"       , "CALL NZ, #" , "PUSH BC"    , "ADD A, #"    , "RST 00H"    , "RET Z"      , "RET"        , "JP Z, #"     , "CB"       , "CALL Z, #" , "CALL #"   , "ADC A, #"    , "RST 08H"  ,
		/*   D0   */   "RET NC"     , "POP DE"     , "JP NC, #"    , "-"          , "CALL NC, #" , "PUSH DE"    , "SUB #"       , "RST 10H"    , "RET C"      , "RETI"       , "JP C, #"     , "-"        , "CALL C, #" , "-"        , "SBC A, #"    , "RST 18H"  ,
		/*   E0   */   "LDH (#), A" , "POP HL"     , "LDH (C), A"  , "-"          , "-"          , "PUSH HL"    , "AND #"       , "RST 20H"    , "ADD SP, #"  , "JP HL"      , "LD (#), A"   , "-"        , "-",        , "-"        , "XOR #"       , "RST 28H"  ,
		/*   F0   */   "LDH A, (#)" , "POP AF"     , "-"           , "DI"         , "-"          , "PUSH AF"    , "OR #"        , "RST 30H"    , "LDHL SP, #" , "LD SP, HL"  , "LD A, (#)"   , "EI"       , "-"         , "-"        , "CP #"        , "RST 38H"  ,
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	];

	static char[] opdisasm_cb_regs[] = ["B", "C", "D", "E", "H", "L", "(HL)", "A"];

	static char[] opdisasm_cb[] = [
		////////+/////////+//////////
		////////+   00    +   08   //
		////////+/////////+//////////
		/*  00  */ "RLC"  ,  "RRC"  ,
		/*  10  */ "RL"   ,  "RR"   ,
		/*  20  */ "SLA"  ,  "SRA"  ,
		/*  30  */ "SWAP" ,  "SRL"  ,
		/*  40  */ "BIT"  ,  "-"    ,
		/*  50  */ "-"    ,  "-"    ,
		/*  60  */ "-"    ,  "-"    ,
		/*  70  */ "-"    ,  "-"    ,
		/*  80  */ "RES"  ,  "-"    ,
		/*  90  */ "-"    ,  "-"    ,
		/*  A0  */ "-"    ,  "-"    ,
		/*  B0  */ "-"    ,  "-"    ,
		/*  C0  */ "SET"  ,  "-"    ,
		/*  D0  */ "-"    ,  "-"    ,
		/*  E0  */ "-"    ,  "-"    ,
		/*  F0  */ "-"    ,  "-"    ,
		/////////////////////////////
	];

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

	// Stream
	Stream rom;
	// Header
	RomHeader *rh;
	// Memoria
	u8 MEM[0x10000];

	// Registros
	union { u16 AF; u8 A_F[2]; } // ACUM, FLAGS
	union { u16 BC; u8 B_C[2]; } // B, C
	union { u16 DE; u8 D_E[2]; } // D, E
	union { u16 HL; u8 H_L[2]; } // H, L
	u16 SP;                      // Stack Pointer
	u16 PC;                      // Program Counter
	bool CF;                     // Carry Flag

	// Utilitarios
	u32 cycles; // Cantidad de ciclos * 1000 ejecutados

	bool sgb = false; // Emulacion de Super GameBoy

	// Añade ciclos para simular el retraso
	void addCycles(int n) {
		cycles += (n * 4) * 1000;
	}

	// Realiza el retraso pertinente
	void sleep() {
		static const uint ccyc = 0x400000, msec = 1;
		if (cycles >= ccyc) {
			//Sleep(msec);
			cycles -= ccyc;
		}
	}

	// Cargamos la rom
	void loadRom(char[] name) { loadRom(new File(name, FileMode.In)); }
	void loadRom(Stream s) {
		s.readExact(MEM.ptr, 0x4000);
		rh = cast(RomHeader *)(MEM.ptr + 0x100);
		rom = s;
		disasm(MEM[0x100..0x104], 0x100);
	}

	// Interpreta una sucesión de opcodes
	void interpret() {
		while (true) {
			u8 op = MEM[PC++];

			if (op == 0xCB) {
				op = MEM[PC++];
				bool hl = false;
				void *reg_cb;

				// Localización del registro ["B", "C", "D", "E", "H", "L", "(HL)", "A"];
				switch (op & 0b111) {
					case 0: reg_cb = &B_C[0]; break;
					case 1: reg_cb = &B_C[1]; break;
					case 2: reg_cb = &D_E[0]; break;
					case 3: reg_cb = &D_E[1]; break;
					case 4: reg_cb = &H_L[0]; break;
					case 5: reg_cb = &H_L[1]; break;
					case 6: reg_cb = &HL;     hl = true; break;
					case 7: reg_cb = &A_F[0]; break;
					default: throw(new Exception("Unexpected error"));
				}

				// Decodificación de la operación
				switch (op & 0b11111000) {
					/* RLC  */ case 0x00:
						if (hl) {
							u16 *r = reg_cb;
							CF = (*r >> 15);
							*r = (*r << 1) | CF;
						} else {
							u8 *r = reg_cb;
							*r = (*r << 1) | CF;
						}
					break;
					/* RRC  */ case 0x08:
						if (hl) {
							u16 *r = reg_cb;
							CF = *r & 1;
							*r = (*r >> 1) | (CF << 15);
						} else {
							u8 *r = reg_cb;
							CF = *r & 1;
							*r = (*r >> 1) | (CF << 7);
						}
					break;
					/* RL   */ case 0x10: break;
					/* RR   */ case 0x18: break;
					/* SLA  */ case 0x20: break;
					/* SRA  */ case 0x28: break;
					/* SWAP */ case 0x30: break;
					/* SRL  */ case 0x38: break;
					/* BIT  */ case 0x40: break;
					/* RES  */ case 0x80: break;
					/* SER  */ case 0xC0: break;
				}

				addCycles(opcycles_cb[op]);
			} else {
				switch (op) {
				}

				addCycles(opcycles[op]);
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

	static void w8(u16 addr, u8 v) {
		switch (addr & 0xF000) {
			// 16KB ROM Bank 00     (in cartridge, fixed at bank 00)
			case 0x0: case 0x1: case 0x2: case 0x3:
			break;
			// 16KB ROM Bank 01..NN (in cartridge, switchable bank number)
			case 0x4: case 0x5: case 0x6: case 0x7:
			break;
			// 8000-9FFF   8KB Video RAM (VRAM) (switchable bank 0-1 in CGB Mode)
			case 0x8: case 0x9:
			break;
			// A000-BFFF   8KB External RAM     (in cartridge, switchable bank, if any)
			case 0xA: case 0xB:
			break;
			// C000-CFFF   4KB Work RAM Bank 0 (WRAM)
			case 0xC:
			break;
			// D000-DFFF   4KB Work RAM Bank 1 (WRAM)  (switchable bank 1-7 in CGB Mode)
			case 0xD:
			break;
			// E000-FDFF   Same as C000-DDFF (ECHO)    (typically not used)
			// FE00-FE9F   Sprite Attribute Table (OAM)
			// FEA0-FEFF   Not Usable
			// FF00-FF7F   I/O Ports
			// FF80-FFFE   High RAM (HRAM)
			// FFFF        Interrupt Enable Register
			case 0xE: case 0xF:
				if (addr < 0xFE00) {
				} else if (addr < 0xFE9F) {
				} else if (addr < 0xFEFF) {
				} else if (addr < 0xFF7F) {
				} else {
				}
			break;
		}
	}

	static char[] disasm(inout u8* addr) {
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
		for (int n = 0; n < fmt.length; n++) if (fmt[n] == '*') { fmt[n] = '#'; sign = true; break; }
		addr += cb; fmt = replace(fmt, "#", format("%%s" "$" "%%0" "%d" "X", cb * 2));

		return format(fmt, (sign && v < 0) ? "-" : "", v);
	}

	static void disasm(ubyte[] data, u16 offset = 0x0000) {
		u8* addr = data.ptr, dest = data.ptr + data.length;
		while (addr < dest) {
			writef("%04X: ", (addr - data.ptr) + offset);
			writefln("%s", disasm(addr));
		}
	}
}

int main(char[][] args) {
	GameBoy gb = new GameBoy;

	gb.loadRom("TETRIS.GB");

	return 0;
}