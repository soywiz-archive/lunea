module gameboy.memory;

import std.stdio, std.string, std.stream, std.c.stdlib, std.zlib;
import gameboy.common;

bool MEM_TRACED[0x10000];

void MEMTRACE(int addr, char[] s, bool critical = false) {
	//if (MEM_TRACED[addr]) return;
	//return;

	if (addr == 0xFF44) return;
	// HRAM
	if (addr >= 0xFF80) return;

	if (addr >= 0xFF00 || critical) {
		writefln("%s", s);
	} else {
		//writefln("%s", s);
	}

	/*if (addr >= 0xFE00 && addr <= 0xFE9F) {
		writefln("%s", s);
	}

	if (addr >= 0x8000 && addr <= 0x9FFF) {
		writefln("%s", s);
	}*/

	// FE00-FE9F   Sprite Attribute Table (OAM)
}

u8* addr8(u8 *MEM, u16 addr) {
	return &MEM[addr];
}

// Lectura de 8 bits en memoria
u8 r8(u8 *MEM, u16 addr) {
	scope(exit) {
		MEMTRACE(addr, "----------");
		MEM_TRACED[addr] = true;
	}

	MEMTRACE(addr, "----------");

	MEMTRACE(addr, format("READ %04X -> %02X", addr, MEM[addr]));

	if (addr == 0xFF00) {
		return 0b11101111;
	}

	return MEM[addr];
}

// Lectura de 16 bits en memoria
u16 r16(u8 *MEM, u16 addr) {
	scope(exit) {
		MEMTRACE(addr, "----------");
		MEM_TRACED[addr] = true;
	}

	MEMTRACE(addr, "----------");

	MEMTRACE(addr, format("READ %04X -> %02X", addr, MEM[addr]));

	return *cast(u16*)&MEM[addr];
}

// Escritura de 8 bits en memoria
void w16(u8 *MEM, u16 addr, u16 v) {
	scope(exit) {
		MEMTRACE(addr, "----------");
		MEM_TRACED[addr] = true;
	}

	MEMTRACE(addr, "----------");
	MEMTRACE(addr, format("WRITE %04X <- %04X", addr, v));

	*cast(u16 *)(MEM + addr) = v;
}

// Escritura de 8 bits en memoria
void w8(u8 *MEM, u16 addr, u8 v) {
	scope(exit) {
		MEMTRACE(addr, "----------");
		MEM_TRACED[addr] = true;
	}

	MEMTRACE(addr, "----------");

	MEMTRACE(addr, format("WRITE %04X <- %02X (%08b)", addr, v, v));

	switch (addr >> 12) {
		// ROM0
		case 0x0: case 0x1: case 0x2: case 0x3: // 0000-3FFF   16KB ROM Bank 00     (in cartridge, fixed at bank 00)
			MEMTRACE(addr, "WRITE BANK 0");
			if (addr == 0x2000) {
				MEMTRACE(addr, format("ROM SELECT NN TO -> %d", v), true);
			}
		break;
		// ROM1
		case 0x4: case 0x5: case 0x6: case 0x7: // 4000-7FFF   16KB ROM Bank 01..NN (in cartridge, switchable bank number)
			MEMTRACE(addr, "WRITE BANK NN");
		break;
		// CHR0
		case 0x8: case 0x9: // 8000-9FFF   8KB Video RAM (VRAM) (switchable bank 0-1 in CGB Mode)
			MEMTRACE(addr, "WRITE VRAM");
			// MAP0
			if (addr >= 0x9800) {
			}
		break;
		// EXT0
		case 0xA: case 0xB: // A000-BFFF   8KB External RAM     (in cartridge, switchable bank, if any)
			MEMTRACE(addr, "WRITE ERAM");
		break;
		// RAM0
		case 0xC: // C000-CFFF   4KB Work RAM Bank 0 (WRAM)
			MEMTRACE(addr, "WRITE WRAM 0");
		break;
		// RAM1
		case 0xD: // D000-DFFF   4KB Work RAM Bank 1 (WRAM)  (switchable bank 1-7 in CGB Mode)
			MEMTRACE(addr, "WRITE WRAM 1");
		break;
		// E000-FDFF   Same as C000-DDFF (ECHO)    (typically not used)
		// FE00-FE9F   Sprite Attribute Table (OAM)
		// FEA0-FEFF   Not Usable
		// FF00-FF7F   I/O Ports
		// FF80-FFFE   High RAM (HRAM)
		// FFFF        Interrupt Enable Register
		case 0xE: case 0xF:
			MEMTRACE(addr, "WRITE DMA");
			// ECHO
			if (addr < 0xFE00) { // E000-FDFF   Same as C000-DDFF (ECHO)    (typically not used)
				MEMTRACE(addr, "WRITE WRAM 0 (ECHO)");
			// OAM
			} else if (addr < 0xFEA0) { // FE00-FE9F   Sprite Attribute Table (OAM)
				// OAM (memory at FE00h-FE9Fh) is accessable during Mode 0-1
			// ----
			} else if (addr < 0xFF00) { // FEA0-FEFF   Not Usable
				// .....
			// I/O
			} else if (addr < 0xFF80) { // FF00-FF7F   I/O Ports
				// DMA (Direct Memory Access)
				switch (addr) {
				// INPUT (Joypad Input)
					case 0xFF00: // FF00 - P1/JOYP - Joypad (R/W)
						MEMTRACE(addr, "WRITE JOYPAD");
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
						MEMTRACE(addr, "WRITE SERIAL DATA");
						/*
						8 Bits of data to be read/written
						*/
					break;
					case 0xFF02: // FF02 - SC - Serial Transfer Control (R/W)
						MEMTRACE(addr, "WRITE SERIAL CTRL");
						/*
						Bit 7 - Transfer Start Flag (0=No Transfer, 1=Start)
						Bit 1 - Clock Speed (0=Normal, 1=Fast) ** CGB Mode Only **
						Bit 0 - Shift Clock (0=External Clock, 1=Internal Clock)
						*/
					break;
					case 0xFF04: //FF04 - DIV - Divider Register (R/W)
						MEMTRACE(addr, "WRITE DIVIDE REGISTER");
						/*
						This register is incremented at rate of 16384Hz (~16779Hz on SGB). In CGB Double Speed Mode it is incremented twice as fast, ie. at 32768Hz. Writing any value to this register resets it to 00h.
						*/
					break;
					case 0xFF05: //FF05 - TIMA - Timer counter (R/W)
						MEMTRACE(addr, "WRITE TIMER COUNTER");
						/*
						This timer is incremented by a clock frequency specified by the TAC register ($FF07). When the value overflows (gets bigger than FFh) then it will be reset to the value specified in TMA (FF06), and an interrupt will be requested, as described below.
						*/
					break;
					case 0xFF06: //FF06 - TMA - Timer Modulo (R/W)
						MEMTRACE(addr, "WRITE TIMER RELOAD");
						/*
						When the TIMA overflows, this data will be loaded.
						*/
					break;
					case 0xFF07: //FF07 - TAC - Timer Control (R/W)
						MEMTRACE(addr, "WRITE TMER CTRL");
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
					case 0xFF0F: // FF0F - IF - Interrupt Flag (R/W)
						MEMTRACE(addr, "WRITE INTERRUPT FLAG");
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
						MEMTRACE(addr, "WRITE SOUND CHANNEL");
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
						MEMTRACE(addr, "WRITE SOUND CHANNEL");
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
						MEMTRACE(addr, "WRITE SOUND CHANNEL");
						/*
						Bit 7-4 - Initial Volume of envelope (0-0Fh) (0=No Sound)
						Bit 3   - Envelope Direction (0=Decrease, 1=Increase)
						Bit 2-0 - Number of envelope sweep (n: 0-7)
								  (If zero, stop envelope operation.)

						Length of 1 step = n*(1/64) seconds
						*/
					case 0xFF13: // FF13 - NR13 - Channel 1 Frequency lo (Write Only)
						MEMTRACE(addr, "WRITE SOUND CHANNEL");
						/*
						Lower 8 bits of 11 bit frequency (x).
						Next 3 bit are in NR14 ($FF14)
						*/
					break;
					case 0xFF14: // FF14 - NR14 - Channel 1 Frequency hi (R/W)
						MEMTRACE(addr, "WRITE SOUND CHANNEL");
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
						MEMTRACE(addr, "WRITE SOUND TONE");
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
						MEMTRACE(addr, "WRITE SOUND TONE");
						/*
						Bit 7-4 - Initial Volume of envelope (0-0Fh) (0=No Sound)
						Bit 3   - Envelope Direction (0=Decrease, 1=Increase)
						Bit 2-0 - Number of envelope sweep (n: 0-7)
								 (If zero, stop envelope operation.)

						Length of 1 step = n*(1/64) seconds
						*/
					break;
					case 0xFF18: // FF18 - NR23 - Channel 2 Frequency lo data (W)
						MEMTRACE(addr, "WRITE SOUND TONE");
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
					case 0xFF19: // FF19 - NR24 - Channel 2 Frequency hi data (R/W)
						/*
						  Bit 7   - Initial (1=Restart Sound)     (Write Only)
						  Bit 6   - Counter/consecutive selection (Read/Write)
						            (1=Stop output when length in NR21 expires)
						  Bit 2-0 - Frequency's higher 3 bits (x) (Write Only)
							Frequency = 131072/(2048-x) Hz
						*/
					break;
				// SOUND (Sound Channel 3 - Wave Output)
					case 0xFF1A: // FF1A - NR30 - Channel 3 Sound on/off (R/W)
						MEMTRACE(addr, "WRITE SOUND WAVE");
						/*
						Bit 7 - Sound Channel 3 Off  (0=Stop, 1=Playback)  (Read/Write)
						*/
					break;
					case 0xFF1B: // FF1B - NR31 - Channel 3 Sound Length
						MEMTRACE(addr, "WRITE SOUND WAVE");
						/*
						Bit 7-0 - Sound length (t1: 0 - 255)

						Sound Length = (256-t1)*(1/256) seconds
						This value is used only if Bit 6 in NR34 is set.
						*/
					break;
					case 0xFF1C: // FF1C - NR32 - Channel 3 Select output level (R/W)
						MEMTRACE(addr, "WRITE SOUND WAVE");
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
						MEMTRACE(addr, "WRITE SOUND WAVE");
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
						MEMTRACE(addr, "WRITE SOUND WAVE");
						/*
						Contents - Waveform storage for arbitrary sound data

						This storage area holds 32 4-bit samples that are played back upper 4 bits first.
						*/
					break;
				// SOUND (Sound Channel 4 - Noise)
					case 0xFF20: // FF20 - NR41 - Channel 4 Sound Length (R/W)
						MEMTRACE(addr, "WRITE SOUND NOISE STEREO");
						/*
						Bit 5-0 - Sound length data (t1: 0-63)

						Sound Length = (64-t1)*(1/256) seconds
						The Length value is used only if Bit 6 in NR44 is set.
						*/
					break;
					case 0xFF21: // FF21 - NR42 - Channel 4 Volume Envelope (R/W)
						MEMTRACE(addr, "WRITE SOUND NOISE");
						/*
						Bit 7-4 - Initial Volume of envelope (0-0Fh) (0=No Sound)
						Bit 3   - Envelope Direction (0=Decrease, 1=Increase)
						Bit 2-0 - Number of envelope sweep (n: 0-7)
								  (If zero, stop envelope operation.)

						Length of 1 step = n*(1/64) seconds
						*/
					break;
					case 0xFF22: // FF22 - NR43 - Channel 4 Polynomial Counter (R/W)
						MEMTRACE(addr, "WRITE SOUND NOISE");
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
						MEMTRACE(addr, "WRITE SOUND NOISE");
						/*
						Bit 7   - Initial (1=Restart Sound)     (Write Only)
						Bit 6   - Counter/consecutive selection (Read/Write)
						(1=Stop output when length in NR41 expires)
						*/
					break;
				// SOUND (Sound Control Registers)
					case 0xFF24: // FF24 - NR50 - Channel control / ON-OFF / Volume (R/W)
						MEMTRACE(addr, "WRITE SOUND NOISE");
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
						MEMTRACE(addr, "WRITE SOUND NOISE");
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
						MEMTRACE(addr, "WRITE SOUND NOISE");
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
						MEMTRACE(addr, "WRITE LCD CTRL");
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
						MEMTRACE(addr, "WRITE LCDC STATUS");
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
						MEMTRACE(addr, format("WRITE LCD SCROLL Y (%02X)", MEM[addr]));
					break;
					case 0xFF43: // FF43 - SCX - Scroll X (R/W)
						MEMTRACE(addr, "WRITE LCD SCROLL X");
						/*
						Specifies the position in the 256x256 pixels BG map (32x32 tiles) which is to be
						displayed at the upper/left LCD display position. Values in range from 0-255 may be
						used for X/Y each, the video controller automatically wraps back to the upper (left)
						position in BG map when drawing exceeds the lower (right) border of the BG map area.
						*/
					break;

					case 0xFF44: // FF44 - LY - LCDC Y-Coordinate (R)
						MEMTRACE(addr, "WRITE LCDC YCOORD");
						/*
						The LY indicates the vertical line to which the present data is transferred to the LCD Driver. The LY can take on any value between 0 through 153. The values between 144 and 153 indicate the V-Blank period. Writing will reset the counter.
						*/
					break;
					case 0xFF45: // FF45 - LYC - LY Compare (R/W)
						MEMTRACE(addr, "WRITE LCDC YCOMP");
						/*
						The gameboy permanently compares the value of the LYC and LY registers. When both values are identical, the coincident bit in the STAT register becomes set, and (if enabled) a STAT interrupt is requested.
						*/
					break;
					case 0xFF46: // FF46 - DMA - DMA Transfer and Start Address (W)
						MEMTRACE(addr, "WRITE DMA");
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
						MEMTRACE(addr, "WRITE BG PAL");
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
						MEMTRACE(addr, "WRITE SPR0 PAL");
						/*
						This register assigns gray shades for sprite palette 0. It works exactly as BGP (FF47),
						except that the lower two bits aren't used because sprite data 00 is transparent.
						*/
					break;
					case 0xFF49: // FF49 - OBP1 - Object Palette 1 Data (R/W) - Non CGB Mode Only
						MEMTRACE(addr, "WRITE SPR1 PAL");
						/*
						This register assigns gray shades for sprite palette 1. It works exactly as BGP (FF47),
						except that the lower two bits aren't used because sprite data 00 is transparent.
						*/
					break;
					case 0xFF4A: // FF4A - WY - Window Y Position (R/W)
						MEMTRACE(addr, "WRITE WIN Y");
					break;
					case 0xFF4B: // FF4B - WX - Window X Position minus 7 (R/W)
						MEMTRACE(addr, "WRITE WIN X");
						/*
						Specifies the upper/left positions of the Window area. (The window is an
						alternate background area which can be displayed above of the normal background.
						OBJs (sprites) may be still displayed above or behinf the window, just as for normal BG.)
						The window becomes visible (if enabled) when positions are set in range WX=0..166,
						WY=0..143. A postion of WX=7, WY=0 locates the window at upper left, it is then completly
						covering normal background.
						*/
					break;
					default:
						if (addr >= 0xFF00 && addr <= 0xFF7F) {
							MEMTRACE(addr, format("WRITING I/O PORTS (%04X)", addr));
						} else if (addr >= 0xFF80) {
							MEMTRACE(addr, format("WRITING HRAM (%04X)", addr));
						} else {
							writefln("UNKNOWN ADDRESS $%04X", addr);
							exit(-1);
						}
					break;
				}
			} else if (addr < 0xFFFF) { // FF80-FFFE High RAM (HRAM)
				MEMTRACE(addr, "WRITE HRAM");
			} else { // FFFF Interrupt Enable Register
				MEMTRACE(addr, "WRITE INTERRUPT ENABLE");
				/*
				Bit 0: V-Blank  Interrupt Enable  (INT 40h)  (1=Enable)
				Bit 1: LCD STAT Interrupt Enable  (INT 48h)  (1=Enable)
				Bit 2: Timer    Interrupt Enable  (INT 50h)  (1=Enable)
				Bit 3: Serial   Interrupt Enable  (INT 58h)  (1=Enable)
				Bit 4: Joypad   Interrupt Enable  (INT 60h)  (1=Enable)
				*/
			}
		break;
	} // switch

	if (addr <= 0x8000) {
		//writefln("LOL");
		//MEM[addr] = v;
	} else {
		MEM[addr] = v;
	}
}
