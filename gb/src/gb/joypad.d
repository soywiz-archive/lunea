module gameboy.joypad;

import gameboy.common;

import std.stream, std.stdio, std.c.stdlib, std.system;

class JoyPAD {
	enum Key {
		// Botones direccionales
		RIGHT, LEFT, UP, DOWN,
		// Botones de acción
		A, B, SELECT, START,
	}

	// Tipo de lectura
	enum Type {
		buttons,
		direction
	}

	const u8 maskButtons    = 0b00010000;
	const u8 maskDirections = 0b00100000;

	// Estados
	bool KP[8];
	Type rstat;

	// Leemos las teclas pulsadas actualmente
	u8 Read() {
		u8 r = 0b11000000;
		switch (rstat) {
			case Type.buttons:
				r |= maskButtons;
				r |= ((!KP[Key.A     ]) << 0);
				r |= ((!KP[Key.B     ]) << 1);
				r |= ((!KP[Key.SELECT]) << 2);
				r |= ((!KP[Key.START ]) << 3);
			break;
			case Type.direction:
				r |= maskDirections;
				r |= ((!KP[Key.RIGHT ]) << 0);
				r |= ((!KP[Key.LEFT  ]) << 1);
				r |= ((!KP[Key.UP    ]) << 2);
				r |= ((!KP[Key.DOWN  ]) << 3);
			break;
		}

		return r;
	}

	// Cambiamos el tipo de lectura de teclas
	void Write(u8 v) {
		if (v & maskDirections) {
			rstat = Type.direction;
		} else if (v & maskButtons) {
			rstat = Type.buttons;
		}
	}

	// Simulamos el pulsado de una tecla
	void Press(Key k) {
		KP[k] = true;
	}

	// Simulamos la liberación de una tecla
	void Release(Key k) {
		KP[k] = false;
	}

	/*
		FF00 - P1/JOYP - Joypad (R/W)
		The eight gameboy buttons/direction keys are arranged in form of a 2x4 matrix. Select either button or direction keys by writing to this register, then read-out bit 0-3.

		Bit 7 - Not used
		Bit 6 - Not used
		Bit 5 - P15 Select Button Joys      (0=Select)
		Bit 4 - P14 Select Direction Joys   (0=Select)
		Bit 3 - P13 Input Down  or Start    (0=Pressed) (Read Only)
		Bit 2 - P12 Input Up    or Select   (0=Pressed) (Read Only)
		Bit 1 - P11 Input Left  or Button B (0=Pressed) (Read Only)
		Bit 0 - P10 Input Right or Button A (0=Pressed) (Read Only)
	*/
}
