module gameboy.keypad;

import gameboy.common;

import std.stream, std.stdio, std.c.stdlib, std.system;

/*
	Bit 7 - Not used
	Bit 6 - Not used
	Bit 5 - P15 Select Button Keys      (0=Select)
	Bit 4 - P14 Select Direction Keys   (0=Select)
	Bit 3 - P13 Input Down  or Start    (0=Pressed) (Read Only)
	Bit 2 - P12 Input Up    or Select   (0=Pressed) (Read Only)
	Bit 1 - P11 Input Left  or Button B (0=Pressed) (Read Only)
	Bit 0 - P10 Input Right or Button A (0=Pressed) (Read Only)
*/

class KeyPAD {
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

	// Estados
	bool KP[8];
	Type rstat;

	// Guardamos el estado del LCD
	void save(Stream s) {
		u8 temp; for (int n = 0; n < 8; n++) { temp = KP[n]; s.write(temp); }
		temp = rstat; s.write(temp);
	}

	// Cargamos el estado del LCD
	void load(Stream s) {
		u8 temp; for (int n = 0; n < 8; n++) { s.read(temp); KP[n] = (temp != 0); }
		s.read(temp); rstat = cast(Type)temp;
	}

	// Leemos las teclas pulsadas actualmente
	u8 Read() {
		u8 r = 0b11000000;
		switch (rstat) {
			case Type.buttons:
				r |= 0b00100000;
				r |= ((!KP[Key.A     ]) << 0);
				r |= ((!KP[Key.B     ]) << 1);
				r |= ((!KP[Key.SELECT]) << 2);
				r |= ((!KP[Key.START ]) << 3);
			break;
			case Type.direction:
				r |= 0b00010000;
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
		if (v & 0b0010000) {
			rstat = Type.buttons;
		} else {
			rstat = Type.direction;
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
}
