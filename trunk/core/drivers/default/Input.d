/*
 *  Lunea library (gl2d)
 *  Copyright (C) 2005  Carlos Ballesteros Velasco
 *
 *  This file is part of Lunea.
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 *  $Id: Input.d,v 1.5 2006/02/16 23:13:26 soywiz Exp $
 */

module lunea.driver.Input;

import SDL, SDL_keyboard, SDL_mouse;

import lunea.Lunea;
import std.c.windows.windows;

static class Input {
	static void update() {
		KeyboardTemp.buffer = "";

		SDL_Event event;

		for (int n = 0; n < 5; n++) MouseTemp.pressed[n] = MouseTemp.released[n] = false;
		for (int n = 0; n < SDLK_LAST; n++) KeyboardTemp.pressed[n] = KeyboardTemp.released[n] = false;

		while (SDL_PollEvent(&event)) {
			switch (event.type) {
				case SDL_QUIT:
					luneaRunning = false;
				break;
				case SDL_MOUSEBUTTONDOWN:
				case SDL_MOUSEBUTTONUP:
					bool bset = (event.type == SDL_MOUSEBUTTONDOWN);
					int idx;

					switch (event.button.button) {
						case SDL_BUTTON_LEFT:      idx = 0; break;
						case SDL_BUTTON_RIGHT:     idx = 1; break;
						default:
						case SDL_BUTTON_MIDDLE:    idx = 2; break;
						case SDL_BUTTON_WHEELUP:   idx = 3; break;
						case SDL_BUTTON_WHEELDOWN: idx = 4; break;
					}

					if (event.type == SDL_MOUSEBUTTONDOWN) {
						if (event.button.button == SDL_BUTTON_WHEELUP) {
							MouseTemp.z++;
						} else if (event.button.button == SDL_BUTTON_WHEELDOWN) {
							MouseTemp.z--;
						}
					}

					//printf("%d:%d\n", idx, bset);

					MouseTemp.b[idx] = bset;
					if (bset) {
						MouseTemp.pressed[idx] = true;
					} else {
						MouseTemp.released[idx] = true;
					}

				break;
				case SDL_KEYDOWN:
				case SDL_KEYUP:
					bool bset = (event.type == SDL_KEYDOWN);
					int idx = event.key.keysym.sym;

					KeyboardTemp[idx] = bset;

					if (bset) {
						KeyboardTemp.pressed[idx] = true;
					} else {
						KeyboardTemp.released[idx] = true;
					}
				break;
				default:
				break;
			}
		}

		//printf("%s", std.string.toStringz(keyboard.buffer));

		SDL_GetMouseState(&MouseTemp.x, &MouseTemp.y);

		MouseTemp.b[3] = MouseTemp.released[3];
		MouseTemp.b[4] = MouseTemp.released[4];

		KeyboardTemp[_shift] = KeyboardTemp[_lshift] || KeyboardTemp[_rshift];

		Mouse.copy(MouseTemp);
		Keyboard.copy(KeyboardTemp);
	}
}

class CKeyboard {
	public bool keys[SDLK_LAST];
	public bool pressed[SDLK_LAST];
	public bool released[SDLK_LAST];
	public string buffer;

	this() {
		SDL_EnableUNICODE(1);
		SDL_EnableKeyRepeat(SDL_DEFAULT_REPEAT_DELAY, SDL_DEFAULT_REPEAT_INTERVAL);
	}

	void setInterval(int delay, int interval) {
		SDL_EnableKeyRepeat(delay, interval);
	}

	bool opIndex(int index) {
		return keys[index];
	}

	bool opIndexAssign(bool value, int index) {
		return keys[index] = value;
	}

	void copy(CKeyboard that) {
		this.buffer = that.buffer;
		this.keys    [0..SDLK_LAST] = that.keys    [0..SDLK_LAST];
		this.pressed [0..SDLK_LAST] = that.pressed [0..SDLK_LAST];
		this.released[0..SDLK_LAST] = that.released[0..SDLK_LAST];
	}
}

extern(Windows) HCURSOR LoadCursorFromFileA(LPCTSTR lpFileName);

class CMouse {
	public int x, y, z;
	public bit[5] b;
	public bit[5] pressed;
	public bit[5] released;

	public bool left () { return b[0]; }
	public bool right() { return b[1]; }

	public void hide() { SDL_ShowCursor(false); }
	public void show() { SDL_ShowCursor(true ); }
	public void set(int x, int y) { SDL_WarpMouse(this.x = x, this.y = y); }

	void copy(CMouse that) {
		this.x = that.x;
		this.y = that.y;
		this.z = that.z;
		this.b[0..5] = that.b[0..5];
		this.pressed [0..5] = that.pressed [0..5];
		this.released[0..5] = that.released[0..5];
	}

	void setCursor() {
		SDL_Cursor *cursor = SDL_GetCursor();
		cursor.wm_cursor.curs = cast(void *)LoadCursorA(null, IDC_ARROW);
		//cursor.wm_cursor.curs = cast(void *)LoadCursorFromFileA("res\\icon.ico");
		SDL_SetCursor(cursor);
	}
}

public  CMouse    Mouse;
public  CKeyboard Keyboard;

private CMouse    MouseTemp;
private CKeyboard KeyboardTemp;

static this() {
	Mouse    = new CMouse;
	Keyboard = new CKeyboard;

	MouseTemp    = new CMouse;
	KeyboardTemp = new CKeyboard;
}

public alias Keyboard key;

enum {
	_esc     = SDLK_ESCAPE,

	_f1      = SDLK_F1,
	_f2      = SDLK_F2,
	_f3      = SDLK_F3,
	_f4      = SDLK_F4,
	_f5      = SDLK_F5,
	_f6      = SDLK_F6,
	_f7      = SDLK_F8,
	_f8      = SDLK_F8,
	_f9      = SDLK_F9,
	_f10     = SDLK_F10,
	_f11     = SDLK_F11,
	_f12     = SDLK_F12,

	_up      = SDLK_UP,
	_down    = SDLK_DOWN,
	_left    = SDLK_LEFT,
	_right   = SDLK_RIGHT,

	//_enter   = SDLK_KP_ENTER,
	_space   = SDLK_SPACE,

	_0       = SDLK_0,
	_1       = SDLK_1,
	_2       = SDLK_2,
	_3       = SDLK_3,
	_4       = SDLK_4,
	_5       = SDLK_5,
	_6       = SDLK_6,
	_7       = SDLK_7,
	_8       = SDLK_8,
	_9       = SDLK_9,

	_a       = SDLK_a,
	_b       = SDLK_b,
	_c       = SDLK_c,
	_d       = SDLK_d,
	_e       = SDLK_e,
	_f       = SDLK_f,
	_g       = SDLK_g,
	_h       = SDLK_h,
	_i       = SDLK_i,
	_j       = SDLK_j,
	_k       = SDLK_k,
	_l       = SDLK_l,
	_m       = SDLK_m,
	_n       = SDLK_n,
	_o       = SDLK_o,
	_p       = SDLK_p,
	_q       = SDLK_q,
	_r       = SDLK_r,
	_s       = SDLK_s,
	_t       = SDLK_t,
	_u       = SDLK_u,
	_v       = SDLK_v,
	_w       = SDLK_w,
	_x       = SDLK_x,
	_y       = SDLK_y,
	_z       = SDLK_z,

	_ins     = SDLK_INSERT,
	_home    = SDLK_HOME,
	_end     = SDLK_END,
	_pgup    = SDLK_PAGEUP,
	_pgdn    = SDLK_PAGEDOWN,

	_shift   = SDLK_COMPOSE,
	_lshift  = SDLK_LSHIFT,
	_rshift  = SDLK_RSHIFT,

	_kp0     = SDLK_KP0,
	_kp1     = SDLK_KP1,
	_kp2     = SDLK_KP2,
	_kp3     = SDLK_KP3,
	_kp4     = SDLK_KP4,
	_kp5     = SDLK_KP5,
	_kp6     = SDLK_KP6,
	_kp7     = SDLK_KP7,
	_kp8     = SDLK_KP8,
	_kp9     = SDLK_KP9,
	_kp_period = SDLK_KP_PERIOD,
	_kp_divide = SDLK_KP_DIVIDE,
	_kp_multiply = SDLK_KP_MULTIPLY,
	_kp_minus = SDLK_KP_MINUS,
	_kp_plus = SDLK_KP_PLUS,
	_kp_enter = SDLK_KP_ENTER,
	_kp_equals = SDLK_KP_EQUALS,
}