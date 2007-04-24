import std.stdio, std.string, std.stream, std.c.stdlib;

alias ubyte  u8;
alias ushort u16;
alias uint   u32;

alias byte  s8;
alias short s16;
alias int   s32;

/*macro print(arg) {
	writefln(__FILE__, __LINE__, arg);
}*/

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
	bool MEM_TRACED[0x10000];

	// Registros
	u8 A; u8 F;
	u16 AF() { return *cast(u16*)&A; }
	void AF(u16 v) { *cast(u16*)&A = v; }

	u8 B; u8 C;
	u16 BC() { return *cast(u16*)&B; }
	void BC(u16 v) { *cast(u16*)&B = v; }

	u8 D; u8 E;
	u16 DE() { return *cast(u16*)&D; }
	void DE(u16 v) { *cast(u16*)&D = v; }

	u8 H; u8 L;
	u16 HL() { return *cast(u16*)&H; }
	void HL(u16 v) { *cast(u16*)&H = v; }

	u16 SP;                      // Stack Pointer
	u16 PC;                      // Program Counter
	bool ZF, NF, HF, CF;         // Zero Flag, Add/Sub-Flag, Half Carry Flag, Carry Flag
	bool IME;                    // Interrupt Master Enable Flag (Write Only)

	// Utilitarios
	int cycles; // Cantidad de ciclos * 1000 ejecutados

	bool sgb = false; // Emulacion de Super GameBoy

	// Añade ciclos para simular el retraso
	void addCycles(int n) {
		cycles += (n * 4) * 1000;
	}

	// Realiza el retraso pertinente
	void sleep() {
		static const uint ccyc = 0x400000, msec = 1;
		while (cycles >= ccyc) {
			Sleep(msec);
			cycles -= ccyc;
		}
	}

	// Cargamos la rom
	void loadRom(char[] name) { loadRom(new File(name, FileMode.In)); }
	void loadRom(Stream s) {
		s.readExact(MEM.ptr, 0x4000);
		rh = cast(RomHeader *)(MEM.ptr + 0x100);
		rom = s;

		//traceInstruction(0x020C, 20); exit(-1);
	}

	void RLC(u8*  r) { CF = ((*r >>  7) != 0); *r = (*r << 1) | CF; ZF = (*r == 0); HF = NF = false; }
	void RLC(u16* r) { CF = ((*r >> 15) != 0); *r = (*r << 1) | CF; ZF = (*r == 0); HF = NF = false; }
	void RRC(u8*  r) { CF = ((*r &   1) != 0); *r = (*r >> 1) | (CF << 7); ZF = (*r == 0); HF = NF = false; }
	void RRC(u16* r) { CF = ((*r &   1) != 0); *r = (*r >> 1) | (CF << 15); ZF = (*r == 0); HF = NF = false; }

	void RL(u8*  r) { }
	void RL(u16* r) { }
	void RR(u8*  r) { }
	void RR(u16* r) { }

	void SLA(u8*  r) { }
	void SLA(u16* r) { }
	void SRA(u8*  r) { }
	void SRA(u16* r) { }

	void SWAP(u8*  r) { }
	void SWAP(u16* r) { }

	void SRL(u8*  r) { }
	void SRL(u16* r) { }

	void BIT(u8*  r) { }
	void BIT(u16* r) { }

	void RES(u8*  r) { }
	void RES(u16* r) { }
	void SET(u8*  r) { }
	void SET(u16* r) { }

	void DEC(ref u8 R) { // Decrementar
		HF = ((R - 1) & 0xF) < (R & 0xF);
		R--; ZF = (R == 0);
		NF = true;
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
			writef("%s [", disasm(addr));
			for (u8* p = MEM.ptr + PC; p < addr; p++) writef("%02X", *p);
			writefln("]");
			PC = addr - MEM.ptr;
			count--;
		}
	}

	void interrupt(u8 type) {
		u8 *IE = &MEM[0xFFFF]; // FFFF - IE - Interrupt Enable (R/W)
		u8 *IF = &MEM[0xFF0F]; // FF0F - IF - Interrupt Flag (R/W)

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

	// Interpreta una sucesión de opcodes
	void interpret() {
		void *APC;
		u16 CPC;
		u8 op;
		void *reg_cb;
		bool hl;
		int ticks = 1024;

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
			CPC = PC;
			op = MEM[PC++];
			if (ticks-- <= 0) {
				ticks = ticks.init;
				sleep();
			}

			//writefln("%d", ticks);

			// Trazamos la instrucción si corresponde
			version(trace) {
				if (!MEM_TRACED[CPC]) {
					traceInstruction(CPC);
					MEM_TRACED[CPC] = true;
				}
			}

			if (op == 0xCB) {
				op = MEM[PC++];
				//reg_cb = get_reg(op & 0b111, hl);
				// Decodificación de la operación
				switch (op & 0b11111000) {
					/* RLC  */ case 0x00: //hl ? RLC (cast(u16*)reg_cb) : RLC (cast(u8*)reg_cb); break;
					/* RRC  */ case 0x08: //hl ? RRC (cast(u16*)reg_cb) : RRC (cast(u8*)reg_cb); break;
					/* RL   */ case 0x10: //hl ? RL  (cast(u16*)reg_cb) : RL  (cast(u8*)reg_cb); break;
					/* RR   */ case 0x18: //hl ? RR  (cast(u16*)reg_cb) : RR  (cast(u8*)reg_cb); break;
					/* SLA  */ case 0x20: //hl ? SLA (cast(u16*)reg_cb) : SLA (cast(u8*)reg_cb); break;
					/* SRA  */ case 0x28: //hl ? SRA (cast(u16*)reg_cb) : SRA (cast(u8*)reg_cb); break;
					/* SWAP */ case 0x30: //hl ? SWAP(cast(u16*)reg_cb) : SWAP(cast(u8*)reg_cb); break;
					/* SRL  */ case 0x38: //hl ? SRL (cast(u16*)reg_cb) : SRL (cast(u8*)reg_cb); break;
					/* BIT  */ case 0x40: //hl ? BIT (cast(u16*)reg_cb) : BIT (cast(u8*)reg_cb); break;
					/* RES  */ case 0x80: //hl ? RES (cast(u16*)reg_cb) : RES (cast(u8*)reg_cb); break;
					/* SET  */ case 0xC0: //hl ? SET (cast(u16*)reg_cb) : SET (cast(u8*)reg_cb); break;
				}

				addCycles(opcycles_cb[op]);
			} else {
				APC = &MEM[PC];
				PC += opargs[op];

				addCycles(opcycles[op]);

				// Localización del registro ["B", "C", "D", "E", "H", "L", "(HL)", "A"];
				switch (op) {
					case 0x00: break; // NOt Operation
					case 0x05: DEC(B); break;
					case 0x06: B = pu8; break;
					case 0x0D: DEC(C); break;
					case 0x0E: C = pu8; break; // NOt Operation
					case 0x20:
						if (!ZF) PC = PC + ps8;
					break;
					case 0x21: HL = pu16; break;
					case 0x32: w8(pu16, A); break;
					case 0x3E:
						A = pu8;
					break;
					case 0xA0: case 0xA1: case 0xA2: case 0xA3: case 0xA4: case 0xA5: case 0xA6: case 0xA7: // AND
						A &= ((op & 0b111) == 6) ? HL : *get_reg8(op & 0b111);
						ZF = (A == 0);
						CF = NF = false;
						HF = true;
					break;
					case 0xA8: case 0xA9: case 0xAA: case 0xAB: case 0xAC: case 0xAD: case 0xAE: case 0xAF: // XOR
						A ^= ((op & 0b111) == 6) ? HL : *get_reg8(op & 0b111);
						ZF = (A == 0);
						CF = HF = NF = false;
					break;
					case 0xB0: // OR
						A |= ((op & 0b111) == 6) ? HL : *get_reg8(op & 0b111);
						ZF = (A == 0);
						CF = HF = NF = false;
					break;
					case 0xC3: PC = pu16; break;
					case 0xE0: // LD ($FF00+nn),A
						w8(0xFF00 | pu8, A);
					break;
					case 0xF0: // LD A,($FF00+nn)
						A = r8(0xFF00 | pu8);
					break;
					case 0xF3: IME = false; break; // IME=0 | Disable Interrupts
					case 0xFB: IME = true ; break; // IME=1 | Enable Interrupts
					case 0xFE: CP(pu8);     break; // CP nn | Compare with A
/*setC A < val
setH (A And 15) < (val And 15)
setZ A = val
nf = 1*/
					default:
						writefln("             \x18_____________________________ Instruction not emulated");
						return;
					break;
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

	u8 r8(u16 addr) {
		scope(exit) MEM_TRACED[addr] = true;

		if (!MEM_TRACED[addr]) {
			writefln("READ %04X -> %02X", addr, MEM[addr]);
		}

		return MEM[addr];
	}

	void w8(u16 addr, u8 v) {
		scope(exit) MEM_TRACED[addr] = true;

		if (!MEM_TRACED[addr]) {
			writefln("WRITE %04X <- %02X", addr, v);
		}

		switch (addr >> 12) {
			case 0x0: case 0x1: case 0x2: case 0x3: // 0000-3FFF   16KB ROM Bank 00     (in cartridge, fixed at bank 00)
				if (!MEM_TRACED[addr]) writefln("WRITE BANK 0");
			break;
			case 0x4: case 0x5: case 0x6: case 0x7: // 4000-7FFF   16KB ROM Bank 01..NN (in cartridge, switchable bank number)
				if (!MEM_TRACED[addr]) writefln("WRITE BANK NN");
			break;
			case 0x8: case 0x9: // 8000-9FFF   8KB Video RAM (VRAM) (switchable bank 0-1 in CGB Mode)
				if (!MEM_TRACED[addr]) writefln("WRITE VRAM");
			break;
			case 0xA: case 0xB: // A000-BFFF   8KB External RAM     (in cartridge, switchable bank, if any)
				if (!MEM_TRACED[addr]) writefln("WRITE ERAM");
			break;
			case 0xC: // C000-CFFF   4KB Work RAM Bank 0 (WRAM)
				if (!MEM_TRACED[addr]) writefln("WRITE WRAM 0");
			break;
			case 0xD: // D000-DFFF   4KB Work RAM Bank 1 (WRAM)  (switchable bank 1-7 in CGB Mode)
				if (!MEM_TRACED[addr]) writefln("WRITE WRAM 1");
			break;
			// E000-FDFF   Same as C000-DDFF (ECHO)    (typically not used)
			// FE00-FE9F   Sprite Attribute Table (OAM)
			// FEA0-FEFF   Not Usable
			// FF00-FF7F   I/O Ports
			// FF80-FFFE   High RAM (HRAM)
			// FFFF        Interrupt Enable Register
			case 0xE: case 0xF:
				if (!MEM_TRACED[addr]) writefln("WRITE DMA");
				if (addr < 0xFE00) { // E000-FDFF   Same as C000-DDFF (ECHO)    (typically not used)
				} else if (addr < 0xFEA0) { // FE00-FE9F   Sprite Attribute Table (OAM)
					// OAM (memory at FE00h-FE9Fh) is accessable during Mode 0-1
				} else if (addr < 0xFF00) { // FEA0-FEFF   Not Usable
				} else if (addr < 0xFF80) { // FF00-FF7F   I/O Ports
					// DMA (Direct Memory Access)
					switch (addr) {
					// INPUT (Joypad Input)
						case 0xFF00: // FF00 - P1/JOYP - Joypad (R/W)
							/*
							The eight gameboy buttons/direction keys are arranged in form of a 2x4 matrix. Select either button or direction keys by writing to this register, then read-out bit 0-3.

							Bit 7 - Not used
							Bit 6 - Not used
							Bit 5 - P15 Select Button Keys      (0=Select)
							Bit 4 - P14 Select Direction Keys   (0=Select)
							Bit 3 - P13 Input Down  or Start    (0=Pressed) (Read Only)
							Bit 2 - P12 Input Up    or Select   (0=Pressed) (Read Only)
							Bit 1 - P11 Input Left  or Button B (0=Pressed) (Read Only)
							Bit 0 - P10 Input Right or Button A (0=Pressed) (Read Only)
							*/
						break;
					// SERIAL (Serial Data Transfer (Link Cable))
						case 0xFF01: // FF01 - SB - Serial transfer data (R/W)
							/*
							8 Bits of data to be read/written
							*/
						break;
						case 0xFF02: // FF02 - SC - Serial Transfer Control (R/W)
							/*
							Bit 7 - Transfer Start Flag (0=No Transfer, 1=Start)
							Bit 1 - Clock Speed (0=Normal, 1=Fast) ** CGB Mode Only **
							Bit 0 - Shift Clock (0=External Clock, 1=Internal Clock)
							*/
						break;
						case 0xFF04: //FF04 - DIV - Divider Register (R/W)
							/*
							This register is incremented at rate of 16384Hz (~16779Hz on SGB). In CGB Double Speed Mode it is incremented twice as fast, ie. at 32768Hz. Writing any value to this register resets it to 00h.
							*/
						break;
						case 0xFF05: //FF05 - TIMA - Timer counter (R/W)
							/*
							This timer is incremented by a clock frequency specified by the TAC register ($FF07). When the value overflows (gets bigger than FFh) then it will be reset to the value specified in TMA (FF06), and an interrupt will be requested, as described below.
							*/
						break;
						case 0xFF06: //FF06 - TMA - Timer Modulo (R/W)
							/*
							When the TIMA overflows, this data will be loaded.
							*/
						break;
						case 0xFF07: //FF07 - TAC - Timer Control (R/W)
							/*
							Bit 2    - Timer Stop  (0=Stop, 1=Start)
							Bits 1-0 - Input Clock Select
							  00:   4096 Hz    (~4194 Hz SGB)
							  01: 262144 Hz  (~268400 Hz SGB)
							  10:  65536 Hz   (~67110 Hz SGB)
							  11:  16384 Hz   (~16780 Hz SGB)
							*/
						break;
					// INTERRUPTS
						case 0xFFFF: // FFFF - IE - Interrupt Enable (R/W)
							/*
							Bit 0: V-Blank  Interrupt Enable  (INT 40h)  (1=Enable)
							Bit 1: LCD STAT Interrupt Enable  (INT 48h)  (1=Enable)
							Bit 2: Timer    Interrupt Enable  (INT 50h)  (1=Enable)
							Bit 3: Serial   Interrupt Enable  (INT 58h)  (1=Enable)
							Bit 4: Joypad   Interrupt Enable  (INT 60h)  (1=Enable)
							*/
						break;
						case 0xFF0F: // FF0F - IF - Interrupt Flag (R/W)
							/*
							Bit 0: V-Blank  Interrupt Request (INT 40h)  (1=Request)
							Bit 1: LCD STAT Interrupt Request (INT 48h)  (1=Request)
							Bit 2: Timer    Interrupt Request (INT 50h)  (1=Request)
							Bit 3: Serial   Interrupt Request (INT 58h)  (1=Request)
							Bit 4: Joypad   Interrupt Request (INT 60h)  (1=Request)
							*/
						break;
					// SOUND (Sound Channel 1 - Tone & Sweep)
						case 0xFF10: // FF10 - NR10 - Channel 1 Sweep register (R/W)
							/*
							Bit 6-4 - Sweep Time
							Bit 3   - Sweep Increase/Decrease
								0: Addition    (frequency increases)
								1: Subtraction (frequency decreases)
							Bit 2-0 - Number of sweep shift (n: 0-7)

							Sweep Time:

								000: sweep off - no freq change
								001: 7.8 ms  (1/128Hz)
								010: 15.6 ms (2/128Hz)
								011: 23.4 ms (3/128Hz)
								100: 31.3 ms (4/128Hz)
								101: 39.1 ms (5/128Hz)
								110: 46.9 ms (6/128Hz)
								111: 54.7 ms (7/128Hz)

							The change of frequency (NR13,NR14) at each shift is calculated by the following formula where X(0) is initial freq & X(t-1) is last freq:

							X(t) = X(t-1) +/- X(t-1)/2^n
							*/
						break;
						case 0xFF11: // FF11 - NR11 - Channel 1 Sound length/Wave pattern duty (R/W)
							/*
							Bit 7-6 - Wave Pattern Duty (Read/Write)
							Bit 5-0 - Sound length data (Write Only) (t1: 0-63)

							Wave Duty:

							00: 12.5% ( _-------_-------_------- )
							01: 25%   ( __------__------__------ )
							10: 50%   ( ____----____----____---- ) (normal)
							11: 75%   ( ______--______--______-- )

							Sound Length = (64-t1)*(1/256) seconds
							The Length value is used only if Bit 6 in NR14 is set.
							*/
						break;
						case 0xFF12: // FF12 - NR12 - Channel 1 Volume Envelope (R/W)
							/*
							Bit 7-4 - Initial Volume of envelope (0-0Fh) (0=No Sound)
							Bit 3   - Envelope Direction (0=Decrease, 1=Increase)
							Bit 2-0 - Number of envelope sweep (n: 0-7)
							          (If zero, stop envelope operation.)

							Length of 1 step = n*(1/64) seconds
							*/
						case 0xFF13: // FF13 - NR13 - Channel 1 Frequency lo (Write Only)
							/*
							Lower 8 bits of 11 bit frequency (x).
							Next 3 bit are in NR14 ($FF14)
							*/
						break;
						case 0xFF14: // FF14 - NR14 - Channel 1 Frequency hi (R/W)
							/*
							Bit 7   - Initial (1=Restart Sound)     (Write Only)
							Bit 6   - Counter/consecutive selection (Read/Write)
							          (1=Stop output when length in NR11 expires)
							Bit 2-0 - Frequency's higher 3 bits (x) (Write Only)

							Frequency = 131072/(2048-x) Hz
							*/
						break;
					// SOUND (Sound Channel 2 - Tone)
						case 0xFF16: // FF16 - NR21 - Channel 2 Sound Length/Wave Pattern Duty (R/W)
							/*
							Bit 7-6 - Wave Pattern Duty (Read/Write)
							Bit 5-0 - Sound length data (Write Only) (t1: 0-63)

							Wave Duty:

							00: 12.5% ( _-------_-------_------- )
							01: 25%   ( __------__------__------ )
							10: 50%   ( ____----____----____---- ) (normal)
							11: 75%   ( ______--______--______-- )

							Sound Length = (64-t1)*(1/256) seconds
							The Length value is used only if Bit 6 in NR24 is set.
							*/
						break;
						case 0xFF17: // FF17 - NR22 - Channel 2 Volume Envelope (R/W)
							/*
							Bit 7-4 - Initial Volume of envelope (0-0Fh) (0=No Sound)
							Bit 3   - Envelope Direction (0=Decrease, 1=Increase)
							Bit 2-0 - Number of envelope sweep (n: 0-7)
							         (If zero, stop envelope operation.)

							Length of 1 step = n*(1/64) seconds
							*/
						break;
						case 0xFF18: // FF18 - NR23 - Channel 2 Frequency lo data (W)
							/*
							Frequency's lower 8 bits of 11 bit data (x).
							Next 3 bits are in NR24 ($FF19).

							// FF19 - NR24 - Channel 2 Frequency hi data (R/W)

							Bit 7   - Initial (1=Restart Sound)     (Write Only)
							Bit 6   - Counter/consecutive selection (Read/Write)
							    (1=Stop output when length in NR21 expires)
							Bit 2-0 - Frequency's higher 3 bits (x) (Write Only)

							Frequency = 131072/(2048-x) Hz
							*/
						break;
					// SOUND (Sound Channel 3 - Wave Output)
						case 0xFF1A: // FF1A - NR30 - Channel 3 Sound on/off (R/W)
							/*
							Bit 7 - Sound Channel 3 Off  (0=Stop, 1=Playback)  (Read/Write)
							*/
						break;
						case 0xFF1B: // FF1B - NR31 - Channel 3 Sound Length
							/*
							Bit 7-0 - Sound length (t1: 0 - 255)

							Sound Length = (256-t1)*(1/256) seconds
							This value is used only if Bit 6 in NR34 is set.
							*/
						break;
						case 0xFF1C: // FF1C - NR32 - Channel 3 Select output level (R/W)
							/*
							Bit 6-5 - Select output level (Read/Write)

							Possible Output levels are:

							0: Mute (No sound)
							1: 100% Volume (Produce Wave Pattern RAM Data as it is)
							2:  50% Volume (Produce Wave Pattern RAM data shifted once to the right)
							3:  25% Volume (Produce Wave Pattern RAM data shifted twice to the right)
							*/
						break;
						case 0xFF1D: // FF1D - NR33 - Channel 3 Frequency's lower data (W)
							/*
							Lower 8 bits of an 11 bit frequency (x).

							FF1E - NR34 - Channel 3 Frequency's higher data (R/W)

							Bit 7   - Initial (1=Restart Sound)     (Write Only)
							Bit 6   - Counter/consecutive selection (Read/Write)
							         (1=Stop output when length in NR31 expires)
							Bit 2-0 - Frequency's higher 3 bits (x) (Write Only)

							Frequency = 4194304/(64*(2048-x)) Hz = 65536/(2048-x) Hz
							*/
						break;
						case 0xFF30: case 0xFF31: case 0xFF32: case 0xFF33: case 0xFF34: case 0xFF35: case 0xFF36: // FF30-FF3F - Wave Pattern RAM
						case 0xFF37: case 0xFF38: case 0xFF39: case 0xFF3A: case 0xFF3B: case 0xFF3C: case 0xFF3D: case 0xFF3E: case 0xFF3F:
							/*
							Contents - Waveform storage for arbitrary sound data

							This storage area holds 32 4-bit samples that are played back upper 4 bits first.
							*/
						break;
					// SOUND (Sound Channel 4 - Noise)
						case 0xFF20: // FF20 - NR41 - Channel 4 Sound Length (R/W)
							/*
							Bit 5-0 - Sound length data (t1: 0-63)

							Sound Length = (64-t1)*(1/256) seconds
							The Length value is used only if Bit 6 in NR44 is set.
							*/
						break;
						case 0xFF21: // FF21 - NR42 - Channel 4 Volume Envelope (R/W)
							/*
							Bit 7-4 - Initial Volume of envelope (0-0Fh) (0=No Sound)
							Bit 3   - Envelope Direction (0=Decrease, 1=Increase)
							Bit 2-0 - Number of envelope sweep (n: 0-7)
							          (If zero, stop envelope operation.)

							Length of 1 step = n*(1/64) seconds
							*/
						break;
						case 0xFF22: // FF22 - NR43 - Channel 4 Polynomial Counter (R/W)
							/*
							The amplitude is randomly switched between high and low at the given frequency. A higher frequency will make the noise to appear 'softer'.
							When Bit 3 is set, the output will become more regular, and some frequencies will sound more like Tone than Noise.

							Bit 7-4 - Shift Clock Frequency (s)
							Bit 3   - Counter Step/Width (0=15 bits, 1=7 bits)
							Bit 2-0 - Dividing Ratio of Frequencies (r)

							Frequency = 524288 Hz / r / 2^(s+1) ;For r=0 assume r=0.5 instead
							*/
						break;
						case 0xFF23: // FF23 - NR44 - Channel 4 Counter/consecutive; Inital (R/W)
							/*
							Bit 7   - Initial (1=Restart Sound)     (Write Only)
							Bit 6   - Counter/consecutive selection (Read/Write)
							(1=Stop output when length in NR41 expires)
							*/
						break;
					// SOUND (Sound Control Registers)
						case 0xFF24: // FF24 - NR50 - Channel control / ON-OFF / Volume (R/W)
							/*
							The volume bits specify the "Master Volume" for Left/Right sound output.

							Bit 7   - Output Vin to SO2 terminal (1=Enable)
							Bit 6-4 - SO2 output level (volume)  (0-7)
							Bit 3   - Output Vin to SO1 terminal (1=Enable)
							Bit 2-0 - SO1 output level (volume)  (0-7)

							The Vin signal is received from the game cartridge bus, allowing external hardware in the cartridge to supply a fifth sound channel, additionally to the gameboys internal four channels. As far as I know this feature isn't used by any existing games.
							*/
						break;
						case 0xFF25: // FF25 - NR51 - Selection of Sound output terminal (R/W)
							/*
							Bit 7 - Output sound 4 to SO2 terminal
							Bit 6 - Output sound 3 to SO2 terminal
							Bit 5 - Output sound 2 to SO2 terminal
							Bit 4 - Output sound 1 to SO2 terminal
							Bit 3 - Output sound 4 to SO1 terminal
							Bit 2 - Output sound 3 to SO1 terminal
							Bit 1 - Output sound 2 to SO1 terminal
							Bit 0 - Output sound 1 to SO1 terminal
							*/
						break;
						case 0xFF26: // FF26 - NR52 - Sound on/off
							/*
							If your GB programs don't use sound then write 00h to this register to save 16% or more on GB power consumption. Disabeling the sound controller by clearing Bit 7 destroys the contents of all sound registers. Also, it is not possible to access any sound registers (execpt FF26) while the sound controller is disabled.

							Bit 7 - All sound on/off  (0: stop all sound circuits) (Read/Write)
							Bit 3 - Sound 4 ON flag (Read Only)
							Bit 2 - Sound 3 ON flag (Read Only)
							Bit 1 - Sound 2 ON flag (Read Only)
							Bit 0 - Sound 1 ON flag (Read Only)

							Bits 0-3 of this register are read only status bits, writing to these bits does NOT enable/disable sound. The flags get set when sound output is restarted by setting the Initial flag (Bit 7 in NR14-NR44), the flag remains set until the sound length has expired (if enabled). A volume envelopes which has decreased to zero volume will NOT cause the sound flag to go off.
							*/
						break;
					// LCD
						case 0xFF40: // FF40 - LCDC - LCD Control (R/W)
							/*
							Bit 7 - LCD Display Enable             (0=Off, 1=On)
							Bit 6 - Window Tile Map Display Select (0=9800-9BFF, 1=9C00-9FFF)
							Bit 5 - Window Display Enable          (0=Off, 1=On)
							Bit 4 - BG & Window Tile Data Select   (0=8800-97FF, 1=8000-8FFF)
							Bit 3 - BG Tile Map Display Select     (0=9800-9BFF, 1=9C00-9FFF)
							Bit 2 - OBJ (Sprite) Size              (0=8x8, 1=8x16)
							Bit 1 - OBJ (Sprite) Display Enable    (0=Off, 1=On)
							Bit 0 - BG Display (for CGB see below) (0=Off, 1=On)
							*/
						break;
						case 0xFF41: // FF41 - STAT - LCDC Status (R/W)
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
						break;
						case 0xFF42: // FF42 - SCY - Scroll Y (R/W)
						break;
						case 0xFF43: // FF43 - SCX - Scroll X (R/W)
							/*
							Specifies the position in the 256x256 pixels BG map (32x32 tiles) which is to be
							displayed at the upper/left LCD display position. Values in range from 0-255 may be
							used for X/Y each, the video controller automatically wraps back to the upper (left)
							position in BG map when drawing exceeds the lower (right) border of the BG map area.
							*/
						break;

						case 0xFF44: // FF44 - LY - LCDC Y-Coordinate (R)
							/*
							The LY indicates the vertical line to which the present data is transferred to the LCD Driver. The LY can take on any value between 0 through 153. The values between 144 and 153 indicate the V-Blank period. Writing will reset the counter.
							*/
						break;
						case 0xFF45: // FF45 - LYC - LY Compare (R/W)
							/*
							The gameboy permanently compares the value of the LYC and LY registers. When both values are identical, the coincident bit in the STAT register becomes set, and (if enabled) a STAT interrupt is requested.
							*/
						break;
						case 0xFF46: // FF46 - DMA - DMA Transfer and Start Address (W)
							/*
							Writing to this register launches a DMA transfer from ROM or RAM to OAM memory (sprite attribute table). The written value specifies the transfer source address divided by 100h, ie. source & destination are:

								Source:      XX00-XX9F   ;XX in range from 00-F1h
								Destination: FE00-FE9F

							It takes 160 microseconds until the transfer has completed (80 microseconds in CGB Double Speed Mode), during this time the CPU can access only HRAM (memory at FF80-FFFE). For this reason, the programmer must copy a short procedure into HRAM, and use this procedure to start the transfer from inside HRAM, and wait until the transfer has finished:

								ld  (0FF46h),a ;start DMA transfer, a=start address/100h
								ld  a,28h      ;delay...
								wait:           ;total 5x40 cycles, approx 200ms
								dec a          ;1 cycle
								jr  nz,wait    ;4 cycles

							Most programs are executing this procedure from inside of their VBlank procedure, but it is possible to execute it during display redraw also, allowing to display more than 40 sprites on the screen (ie. for example 40 sprites in upper half, and other 40 sprites in lower half of the screen).
							*/
						break;
						case 0xFF47: // FF47 - BGP - BG Palette Data (R/W) - Non CGB Mode Only
							/*
							This register assigns gray shades to the color numbers of the BG and Window tiles.

								Bit 7-6 - Shade for Color Number 3
								Bit 5-4 - Shade for Color Number 2
								Bit 3-2 - Shade for Color Number 1
								Bit 1-0 - Shade for Color Number 0

							The four possible gray shades are:

								0  White
								1  Light gray
								2  Dark gray
								3  Black

							In CGB Mode the Color Palettes are taken from CGB Palette Memory instead.
							*/
						break;
						case 0xFF48: // FF48 - OBP0 - Object Palette 0 Data (R/W) - Non CGB Mode Only
							/*
							This register assigns gray shades for sprite palette 0. It works exactly as BGP (FF47),
							except that the lower two bits aren't used because sprite data 00 is transparent.
							*/
						break;
						case 0xFF49: // FF49 - OBP1 - Object Palette 1 Data (R/W) - Non CGB Mode Only
							/*
							This register assigns gray shades for sprite palette 1. It works exactly as BGP (FF47),
							except that the lower two bits aren't used because sprite data 00 is transparent.
							*/
						break;
						case 0xFF4A: // FF4A - WY - Window Y Position (R/W)
						break;
						case 0xFF4B: // FF4B - WX - Window X Position minus 7 (R/W)
							/*
							Specifies the upper/left positions of the Window area. (The window is an
							alternate background area which can be displayed above of the normal background.
							OBJs (sprites) may be still displayed above or behinf the window, just as for normal BG.)
							The window becomes visible (if enabled) when positions are set in range WX=0..166,
							WY=0..143. A postion of WX=7, WY=0 locates the window at upper left, it is then completly
							covering normal background.
							*/
						break;
					}
				} else if (addr < 0xFFFF) { // FF80-FFFE High RAM (HRAM)
				} else { // FFFF Interrupt Enable Register
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