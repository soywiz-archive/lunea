import gameboy.z80;
import gameboy.joypad;
import SDL;
import std.c.windows.windows;
import std.c.stdio, std.c.string;
import std.stdio, std.string, std.stream, std.c.stdlib, std.zlib, std.system;
extern(Windows) void Sleep(int);

extern (C) {
    char*   getenv  (char *);
    int     putenv  (char *);
}

class GBWinSDL : GameboyHostSystem {
	GameBoy gb;

	void Sleep1() {
		Sleep(1);
	}

	SDL_Surface* buffer;
	SDL_Surface* screen;

	void attach(GameBoy gb) {
		this.gb = gb;
	}

	this() {
		if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_AUDIO) < 0) throw(new Exception("Unable to initialize SDL"));

		putenv("SDL_VIDEO_WINDOW_POS=center");
		putenv("SDL_VIDEO_CENTERED=1");

		SDL_WM_SetCaption("GameBoy", null);
		if ((screen = SDL_SetVideoMode(160 * 2, 144 * 2, 32, SDL_HWSURFACE | SDL_DOUBLEBUF)) is null) throw(new Exception("Unable to create SDL_Screen"));

		buffer = SDL_CreateRGBSurface(SDL_SWSURFACE, 160, 144, 32, 0xFF000000, 0x00FF0000, 0x0000FF00, 0x000000FF);

		SDL_Cursor *cursor = SDL_GetCursor();
		cursor.wm_cursor.curs = cast(void *)LoadCursorA(null, IDC_ARROW);
		SDL_SetCursor(cursor);
	}

	~this() {
		SDL_Quit();
	}

	u32 getc(u8 r) {
		switch (r & 0b11) {
			case 0b00: return 0xFF9cb916; break;
			case 0b01: return 0xFF8caa14; break;
			case 0b10: return 0xFF306430; break;
			case 0b11: return 0xFF103f10; break;
		}
	}

	void UpdateScreen(int type, u8* LCDSCR) {
		static int updates = 0;
		static int last = 0;
		static double fps;

		updates++;
		if (updates % 10 == 0) {
			last = SDL_GetTicks();
		} else if (updates % 10 == 9) {
			fps = 10000 / cast(double)(SDL_GetTicks() - last);
			SDL_WM_SetCaption(toStringz(format("GameBoy %4.1f fps", fps)), null);
		}

		SDL_Rect drect, srect;
		drect.x = drect.y = 0;
		drect.w = 160 * 2;
		drect.h = 144 * 2;
		srect.x = srect.y = 0;
		srect.w = 160 * 1;
		srect.h = 144 * 1;

		switch (type) {
			default: case 0: {
				for (int y = 0; y < 144; y++) {
					for (int x = 0; x < 160; x+= 4) {
						u8 v = LCDSCR[(x >> 2) + y * 40];
						(cast(u32*)buffer.pixels)[x + 0 + y * 160] = getc((v >> 0) & 0b11);
						(cast(u32*)buffer.pixels)[x + 1 + y * 160] = getc((v >> 2) & 0b11);
						(cast(u32*)buffer.pixels)[x + 2 + y * 160] = getc((v >> 4) & 0b11);
						(cast(u32*)buffer.pixels)[x + 3 + y * 160] = getc((v >> 6) & 0b11);
					}
				}
			} break;
			case 1:
				memcpy(buffer.pixels, LCDSCR, 160 * 144 * 4);
			break;
		}

		//SDL_UpdateRect(buffer, 0, 0, 160, 144);
		//SDL_BlitSurface(buffer, &srect, screen, &drect);
		SDL_LockSurface(screen);
		u32* src = cast(u32*)buffer.pixels, dst = cast(u32*)screen.pixels;
		for (int y = 0; y < 144; y++) {
			for (int x = 0; x < 160; x++) {
				if (x * 2 >= screen.w) continue;
				if (y * 2 >= screen.h) continue;

				u32 c = src[x + y * 160];

				int pos = x * 2 + y * screen.w * 2;

				dst[pos + 1] = dst[pos] = c;
				dst[pos + 1 + screen.w] = dst[pos + screen.w] = c;
			}
		}
		SDL_UnlockSurface(screen);
		SDL_UpdateRect(screen, 0, 0, 160 * 2, 144 * 2);
	}

	void KeepAlive() {
		SDL_Event event;

		while (SDL_PollEvent(&event)) {
			switch (event.type) {
				case SDL_QUIT:
					exit(-1);
				break;
				case SDL_MOUSEBUTTONDOWN:
				case SDL_MOUSEBUTTONUP:
				break;
				case SDL_KEYDOWN:
				case SDL_KEYUP:
					if (event.key.keysym.sym == SDLK_ESCAPE) {
						exit(-1);
					}
					if (event.key.keysym.sym == SDLK_d) {
						gb.dump();
					}

					{
						bool set = true;;
						JoyPAD.Key key;
						switch (event.key.keysym.sym) {
							case SDLK_LEFT:   key = JoyPAD.Key.LEFT;   break;
							case SDLK_RIGHT:  key = JoyPAD.Key.RIGHT;  break;
							case SDLK_UP:     key = JoyPAD.Key.UP;     break;
							case SDLK_DOWN:   key = JoyPAD.Key.DOWN;   break;
							case SDLK_z:      key = JoyPAD.Key.A;      break;
							case SDLK_x:      key = JoyPAD.Key.B;      break;
							case SDLK_RETURN: key = JoyPAD.Key.START;  break;
							case SDLK_SPACE:  key = JoyPAD.Key.SELECT; break;
							default: set = false; break;
						}

						if (set) {
							if (event.type == SDL_KEYDOWN) {
								gb.pad.Press(key);
							} else {
								gb.pad.Release(key);
							}
						}
					}
				break;
				default:
				break;
			}
		}
	}
}

GameBoy gb;

int main(char[][] args) {
	gb = new GameBoy(new GBWinSDL);

	gb.loadRom("ROMS\\TETRIS.GB");
	gb.init();

	//gb.dump();
	//exit(-1);

	gb.interpret();

	return 0;
}