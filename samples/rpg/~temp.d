#line 0 "module"
module lunea.Program;

#line 0 "import"
public import lunea.Process, lunea.std.All, std.string, lunea.Lunea, lunea.driver.Main, std.stdio;

#line 0 "main"
int main(string[] args) {
	try {
		__resource_loader();
		return pmanager.start(args, new MainProcess);
	} catch (Exception e) {
		writefln(e.toString);
	}
	return -1;
}

#line 1 "src\config.lun"
 
	  
	 
    //debug:   true;
       
	   
        


#line 1 "src\main.lun"
 
	 
	 


Random random;
Map map;

alias PathFind.Point PPoint;

class MovingCharacter : Process  {
	real speed = 2.1;

	PPoint[] ppath;
	int ppos;

	this(Sprite sprite) {
		if (sprite !is null) this.sprite = sprite.clone();
		sprite.animation = "stop_down";
	}

	void main()  {
		bit moving, running;

		while (true) {
			char[] cani = sprite.animation;
			//running = key[_lshift] || key[_rshift];
			running = key[_shift];

			if (ppath.length && ppos < ppath.length) {
				int nx = ppath[ppos].x, ny = ppath[ppos].y;
				int cx = cast(int)(this.x / 32), cy = cast(int)(this.y / 32);
				printf("[%d, %d] --> [%d, %d]\n", cx, cy, nx, ny);
				if (nx < cx) key[_left] = true;
				if (nx > cx) key[_right] = true;
				if (ny < cy) key[_up] = true;
				if (ny > cy) key[_down] = true;
				if (cx == nx && cy == ny) ppos++;
			}

			if (key[_left] ) cani = "walk_left";
			if (key[_down] ) cani = "walk_down";
			if (key[_up]   ) cani = "walk_up";
			if (key[_right]) cani = "walk_right";

			sprite.animation = cani;

			moving = false;

			if (key[_up]   ) { y -= speed * (running + 1); moving = true; }
			if (key[_down] ) { y += speed * (running + 1); moving = true; }
			if (key[_left] ) { x -= speed * (running + 1); moving = true; }
			if (key[_right]) { x += speed * (running + 1); moving = true; }

			z = y;

			if (!moving) {
				if (key.released[_up]   ) sprite.animation = "stop_up";
				if (key.released[_down] ) sprite.animation = "stop_down";
				if (key.released[_left] ) sprite.animation = "stop_left";
				if (key.released[_right]) sprite.animation = "stop_right";
			}

			frame();
		}
	}

	void path()  {
		while (true) {
			real speed = 3;
			real running = 0;
			bool moving = false;

			if (!ppath.length || ppos >= ppath.length) {
				paction = &main;
				frame();
				break;
			}

			int nx = ppath[ppos].x, ny = ppath[ppos].y;
			int cx = cast(int)(this.x / 32), cy = cast(int)(this.y / 32);
			if (nx < cx) key[_left] = true;
			if (nx > cx) key[_right] = true;
			if (ny < cy) key[_up] = true;
			if (ny > cy) key[_down] = true;
			if (cx == nx && cy == ny) ppos++;

			if (key[_left] ) sprite.animation = "walk_left";
			if (key[_down] ) sprite.animation = "walk_down";
			if (key[_up]   ) sprite.animation = "walk_up";
			if (key[_right]) sprite.animation = "walk_right";

			if (key[_up]   ) { y -= speed * (running + 1); moving = true; }
			if (key[_down] ) { y += speed * (running + 1); moving = true; }
			if (key[_left] ) { x -= speed * (running + 1); moving = true; }
			if (key[_right]) { x += speed * (running + 1); moving = true; }

			z = y;

			if (!moving) {
				if (key.released[_up]   ) sprite.animation = "stop_up";
				if (key.released[_down] ) sprite.animation = "stop_down";
				if (key.released[_left] ) sprite.animation = "stop_left";
				if (key.released[_right]) sprite.animation = "stop_right";
			}

			frame();
		}
	}

	void goTo(int dx, int dy) {
		if (dx < 0 || dy < 0 || dx >= map.width || dy >= map.height) return;
		int sx = cast(int)(this.x / 32), sy = cast(int)(this.y / 32);
		ppath = map.pathfind.find(sx, sy, dy, dx);
		ppos = 0;
		paction = &path;
	}
}

class Character : Process  {
	real speed = 1;
	real zangle = 0;

	this(Sprite sprite) {
		if (sprite !is null) this.sprite = sprite.clone();
	}

	void main()  {
		while (true) frame();
	}

	void move_left()  {
		while (true) {
			x -= speed;
			if (x < 0) x = 300;
			zangle += 0.08;
			angle = (sin(zangle) * PI * 2) / 40;
			frame();
		}
	}

	void draw()  {
		super.draw();
		real cx = __x, cy = __y;

		Screen.drawFillBox(cx - 2, cy - 2, cx + 2, cy + 2, Color.black);
		Screen.drawBox(cx - 1, cy - 1, cx + 1, cy + 1, Color.white);
	}
}

class MainProcess : Process {
	MapLayer  ml;
	TileSet ctileset;

	this() {
		random = new Random;
	}

	void setMap() {
		map = new Map;
		with (ml = new MapLayer(40, 40)) {
			this.ctileset = tileset = new TileSet(Image.fromFile("tileset.png"), 32, 32, 2, 2, 2, 2);
			for (int y = 0; y < width; y++) {
				for (int x = 0; x < height; x++) {
					int[] list = [ 12, 12, 12, 12, 5, 5, 6, 6, 7 ];
					board[y][x] = cast(ubyte)(list[random.get(0, list.length - 1)]);
				}
			}
		}
		map.addLayer(ml);

		SmoothKeyScroll sks = new SmoothKeyScroll(0, 0, map.sw * map.tw, map.sh * map.th); map.relative = sks;
		sks.vxmax = sks.vymax = 0;
	}

	void main()  {
		fps = 200;

		setMap();

        Sprite marle = Sprite.fromFile("marle.xml");

		for (int n = 0; n < 100; n++) {
			with (new Character(marle)) {
				inner = ml;
				sprite.factor = random.getReal(1, 1.5);
				switch (random.get(0, 3)) {
					default:
					case 0: sprite.animation = "stop_up"; break;
					case 1: sprite.animation = "stop_left"; break;
					case 2: sprite.animation = "stop_right"; break;
					case 3: sprite.animation = "stop_down"; break;
				}
				x = random.get(0, 2000);
				z = y = random.get(0, 1000);
			}
		}

		MovingCharacter mc;

		with (mc = new MovingCharacter(marle)) {
			inner = ml;
			sprite.factor = 1.0;
			sprite.animation = "stop_down";
			x = 500;
			z = y = 400;
		}

		new UserMouse;

		GuiInit();

		Palette pal = new Palette(this.ctileset);

		{
			Window window = new Window;
			window.title = "Capas";
			window.width = window.minw = 84;
			window.height = window.minh = 86;
			{
				Button button[3];
				button[0] = new Button;
				button[0].inner = window;
				button[0].label = "Capa 1";
				button[0].y = 0;
				button[1] = new Button;
				button[1].inner = window;
				button[1].label = "Capa 2";
				button[1].y = 22;
				button[2] = new Button;
				button[2].inner = window;
				button[2].label = "Capa 3";
				button[2].y = 44;

				button[0].onClick ~= delegate void(Object caller) {
					button[0].pressed = true;
					button[1].pressed = false;
					button[2].pressed = false;
				};

				button[1].onClick ~= delegate void(Object caller) {
					button[0].pressed = false;
					button[1].pressed = true;
					button[2].pressed = false;
				};

				button[2].onClick ~= delegate void(Object caller) {
					button[0].pressed = false;
					button[1].pressed = false;
					button[2].pressed = true;
				};

				button[0].onClick.execute(this);
			}
		}

		while (!key[_esc]) {
			x = Mouse.x;
			y = Mouse.y;

			if (Mouse.released[0]) {
				if (key[_shift]) {
					mc.goTo(map.getY(y), map.getX(x));
				}
			}

			if (Mouse.left) {
				if (!key[_shift]) {
					map.layers[0].board[map.getY(y)][map.getX(x)] = cast(ubyte)pal.selected;
				}
			}

			if (key[_e]) {
				throw(new Exception("Excepción"));
				//x = Mouse.x / 0;
			}

			frame();
		}

		exit();
	}
}

#line 1 "src\map\map.lun"
class TileSet {
	Image tileset;
	Image[] tiles;
	int w, h;

	this(Image tileset, int w = 32, int h = 32, int bx = 0, int by = 0, int sx = 0, int sy = 0) {
		this.w = w; this.h = h;
		tiles = (this.tileset = tileset).split(w, h, bx, by, sx, sy);
	}

	void draw(int x, int y, ubyte type, real alpha = 1.0) {
		if (type >= tiles.length) return;
		tiles[type].fastDrawAlpha(x, y, alpha);
	}
}

class Map : Process  {
	PathFind pathfind;
	MapLayer[] layers;
	bit showgrid = false;
	int tw = 32, th = 32;
	int sw =  0, sh =  0;
	Color colorgrid;

	alias sw w;
	alias sh h;
	alias sw width;
	alias sh height;

	private void init() {
		//clip = new Rect(0, 0, Screen.width - 1, Screen.height - 1);
		colorgrid = new Color(0, 0, 0, 0.2);
	}

	this() {
		init();
	}

	void addLayer(MapLayer layer) {
		layers ~= layer;
		layer.group.priority = layer.group.z = this;
		layer.relative = this;

		if (layer is null) return;
		if (sw < layer.width ) sw = layer.width;
		if (sh < layer.height) sh = layer.height;

		if (layer.tileset is null) return;
		if (tw > layer.tileset.w) tw = layer.tileset.w;
		if (th > layer.tileset.h) th = layer.tileset.h;

		pathfind = new PathFind(sw, sh);
	}

	void main()  {
		while (true) frame();
	}

	void drawEnd()  {
		if (!showgrid) return;

		int ax = cast(int)(__x - x), ay = cast(int)(__y - y);

		//Screen.pushClip(clip);

		int dx = -(ax / tw), dy = -(ay / th);
		int rx = (ax % tw), ry = (ay % th);

		int mw = (clip.w / tw) + 3, mh = (clip.h / th) + 3;


		for (int y1 = 0; y1 < mh; y1++, dy++) {
			Screen.drawLine(0, y1 * th + ry, Screen.width - 1, y1 * th + ry, colorgrid);
		}

		for (int x1 = 0; x1 < mw; x1++, dx++) {
			Screen.drawLine(x1 * tw + rx, 0, x1 * tw + rx, Screen.height - 1, colorgrid);
		}

		//Screen.popClip();
	}

	int getX(real sx) {
		if (!layers || !layers.length) return -1;
		return layers[0].getX(sx);
	}

	int getY(real sy) {
		if (!layers || !layers.length) return -1;
		return layers[0].getY(sy);
	}
}

class MapLayer : Process  {
	TileSet tileset;
	ubyte[][] board;
	int width, height;

	void setSize(int width, int height) {
		this.width = width;
		this.height = height;

		board.length = height;
		for (int y = 0; y < height; y++) {
			board[y].length = width;
			for (int x = 0; x < width; x++) {
				board[y][x] = 0;
			}
		}
	}

	this(TileSet tileset, int width, int height) {
		setSize(width, height);
		this.tileset = tileset;
	}

	this(int width, int height) {
		setSize(width, height);
	}

	void main()  {
		while (true) frame();
	}

	void draw()  {
		if (!tileset) return;
		if (!clip) clip = new Rect(0, 0, Screen.width, Screen.height);

		int ax = cast(int)(__x - x), ay = cast(int)(__y - y);

		int dx = -(ax / tileset.w);
		int dy = -(ay / tileset.h);
		int rx = (ax % tileset.w);
		int ry = (ay % tileset.h);

		int mw = (clip.w / tileset.w) + 3;
		int mh = (clip.h / tileset.h) + 3;

		int dx1 = dx;
		for (int y1 = 0; y1 < mh; y1++, dy++) {
			dx = dx1;
			for (int x1 = 0; x1 < mw; x1++, dx++) {
				if (dx < 0 || dy < 0) continue;
				if (dx >= width || dy >= height) continue;

				tileset.draw(
					clip.x1 + x1 * 32 + rx,
					clip.y1 + y1 * 32 + ry,
					board[dy][dx],
					alpha
				);
			}
		}
	}

	int getX(real sx) {
		int ax = cast(int)(__x - x - sx);
		int dx = -(ax / tileset.w);
		return dx;
	}

	int getY(real sy) {
		int ay = cast(int)(__y - y - sy);
		int dy = -(ay / tileset.h);
		return dy;
	}

	void getXY(real sx, real sy, out int dx, out int dy) {
		dx = getX(sx);
		dy = getX(sy);
	}
}
#line 1 "src\misc.lun"
class Palette : Process  {
	Window window;
	TileSet tileset;
	int rollp = 0;
	int selected = 0;
	int s = 0;

	this(TileSet tileset) {
		this.tileset = tileset;
		with (window = new Window) {
			title = "Paleta";
			x = 0;
			y = 0;
			window.w = window.minw = 75;
			window.h = 400;
			this.inner = window;
		}
	}

	void main()  {
		while (true) {
			//printf("%d\n", Mouse.b[2]);
			if (Mouse.b[3]) s -= (key[_shift] * 3 + 1);
			if (Mouse.b[4]) s += (key[_shift] * 3 + 1);
			if (key[_kp_minus]) s--;
			if (key[_kp_plus]) s++;
			if (Mouse.pressed[0]) {
				Image ci = tileset.tiles[0];
				if (!ci) continue;

				int px = cast(int)(__x + window.width / 2 - ci.w / 2);
				int py = cast(int)(__y - rollp + 2);
				//n * (ci.h + 2)
				if (Mouse.x >= px && Mouse.x <= px + ci.w) {
					//printf("%d, %d\n", cast(int)Mouse.x, cast(int)Mouse.y);

					if (Mouse.y >= py && Mouse.y <= py + (ci.h + 2) * 10) {
						int pn = (Mouse.y - py) / (ci.h + 2);
						//printf("%d\n", pn);
						selected = pn + s;
					}
				}
				//printf("lol");
			}
			frame();
		}
	}

	void draw()  {
		for (int n = 0; n < 10; n++) {
			int px, py;
			if (n + s < 0) continue;
			if (n + s >= tileset.tiles.length) break;
			Image ci = tileset.tiles[n + s];
			if (!ci) continue;
			px = cast(int)(__x + window.width / 2 - ci.w / 2);
			py = cast(int)(__y + n * (tileset.tiles[0].h + 2) - rollp + 2);
			if (selected == n + s) {
				Screen.drawBox(px - 1, py - 1, px + ci.w, py + ci.h, Color.red);
			}
			ci.draw(px, py);
		}
	}
}

class UserMouse : Process  {
	this() {
		Mouse.hide();
		sprite = Sprite.fromFile("cursor.xml");
	}

	~this() {
		Mouse.show();
	}

	void main()  {
		bit pressed = false;
		real sx, sy;

		while (true) {
			z = 100000;
			x = Mouse.x;
			y = Mouse.y;

			frame();
		}
	}
}
#line 1 "C:\Users\soywiz\projects\lunea\bin\..\lib\lunea\camera\smooth.lun"
class SmoothKeyScroll : Process  {
	public real vx = 0, vy = 0;
	//private real rx = 0, ry = 0;

	public real vxmax = 20, vymax = 20;
	public real x1 = 0, y1 = 0, x2 = 0, y2 = 0;
	public real w = 0, h = 0;

	private void setst(real x1, real y1, real x2, real y2) {
		this.x1 = x1;
		this.y1 = y1;
		this.x2 = x2;
		this.y2 = y2;

		y = x = 0;
	}

	public this(real x1, real y1, real x2, real y2) {
		setst(x1, y1, x2, y2);
		this.w = Screen.width;
		this.h = Screen.height;
	}

	public this(real x1, real y1, real x2, real y2, real width, real height) {
		setst(x1, y1, x2, y2);
		this.w = width;
		this.h = height;
	}

	public void set(real x, real y) {
		this.x = -x;
		this.y = -y;
	}

	private void limit(inout real var, real min, real max) {
		if (min > max) {
			real temp = max;
			max = min;
			min = temp;
		}

		if (var < min) var = min;
		if (var > max) var = max;
	}

	void main()  {
		bit pressed = false;
		real msx, msy;
		real sx, sy;

		while (true) {
			if (Mouse.right) {
				if (!pressed) {
					msx = Mouse.x;
					msy = Mouse.y;
					sx = x;
					sy = y;
					pressed = true;
				} else {
					x = sx - (Mouse.x - msx) * 3;
					y = sy - (Mouse.y - msy) * 3;
					vx = vy = 0;
				}
			} else {
				pressed = false;

				if (key[_left])  vx += 2;
				if (key[_right]) vx -= 2;
				if (key[_up])    vy += 2;
				if (key[_down])  vy -= 2;

				if (vx != 0) vx += (vx < 0) ? 1 : -1;
				if (vy != 0) vy += (vy < 0) ? 1 : -1;

				if (abs(vx) >= vxmax) vx = (vx > 0) ? vxmax : -vxmax;
				if (abs(vy) >= vymax) vy = (vy > 0) ? vymax : -vymax;

				x += vx; y += vy;
			}

			limit(x, w - x2, -x1);
			limit(y, h - y2, -y1);

			frame();
		}
	}
}
#line 1 "C:\Users\soywiz\projects\lunea\bin\..\lib\lunea\gui\button.lun"
class Button : Process  {
	real width = 80, height = 20;
	char[] label;
	bit pressing = false;
	bit over = false;
	bit toggle = false;
	bit pressed = false;

	GuiEventHandler onClick;

	this() {
		onClick = new GuiEventHandler();
	}

	void main()  {
		while (true) {
			int px1 = cast(int)__x, py1 = cast(int)__y;
			int px2 = px1 + cast(int)width;
			int py2 = py1 + cast(int)height;

			over = false;
			if (Mouse.x >= px1 && Mouse.x <= px2) {
				if (Mouse.y >= py1 && Mouse.y <= py2) {
					if (Mouse.pressed[0]) {
						pressing = true;
						// Pressed
					}

					if (Mouse.b[0] && pressing) over = true;

					if (pressing && Mouse.released[0]) {
						if (toggle) pressed = !pressed;
						onClick.execute(this);
					}
				}
			}

			if (Mouse.released[0]) {
				pressing = false;
				// Released
			}
			frame();
		}
	}

	void draw()  {
		int px1 = cast(int)__x, py1 = cast(int)__y;
		int px2 = px1 + cast(int)width;
		int py2 = py1 + cast(int)height;

		if (pressing || pressed) {
			Screen.drawFillBox(px1, py1, px2, py2, gui.fgColor);
		} else {
			Screen.drawFillBox(px1, py1, px2, py2, gui.bgColor);
		}

		Screen.drawBox(px1, py1, px2, py2, gui.fgColor);
		guifont.draw(
			label,
			px1 + (px2 - px1) / 2 - guifont.width(label) / 2 - 1,
			py1 + (py2 - py1) / 2 - guifont.height / 2,
			Color.black
		);
	}
}
#line 1 "C:\Users\soywiz\projects\lunea\bin\..\lib\lunea\gui\debug.lun"
class Debug : Process  {
	bit cdebug = false;

	private char[][] cdump;
	private int ccstart = 0;
	real backfps;

	void main()  {
		bit stop = false;

		while (true) {
			if (!stop) {
				if (key[_f12]) {
					cdebug = !cdebug;

					if (cdebug) {
						this.flags -= Flags.execute | Flags.tree | Flags.childs;
					} else {
						this.flags += Flags.execute | Flags.tree | Flags.childs;
					}

					if (cdebug) {
						backfps = fps;
						fps = 24;
						cdump = pmanager.dumpS();
					} else {
						fps = backfps;
					}

					stop = true;
				} else if (cdebug) {
					if (key[_esc]) {
						cdebug = false;
						break;
					} else if (key[_up]) {
						ccstart--;
					} else if (key[_pgup]) {
						ccstart -= 5;
					} else if (key[_down]) {
						ccstart++;
					} else if (key[_pgdn]) {
						ccstart += 5;
					}
				}
			} else {
				if (!key[_f12]) stop = false;
			}
			frame();
		}

		exit();
	}

	void nodebug() { }

	override void draw      () { }
	override void drawBegin () { }
	override void drawEnd   () {
		if (!cdebug) return;

		Screen.drawFillBox(0, 0, Screen.width, Screen.height, Color.blackst);
		debugFont.draw("DEBUG", 11, 11, Color.black);
		debugFont.draw("DEBUG", 10, 10, Color.white);

		real px = 40, py = 50;
		if (ccstart < 0) ccstart = 0;
		if (ccstart > cdump.length - 1) ccstart = cdump.length - 1;

		for (int n = 0; n < cdump.length; n++) {
			if (n + ccstart >= cdump.length) break;

			char[] cline = cdump[n + ccstart];
			real ry = n * (debugFont.height + 3);

			if (py + ry > Screen.height - 50) break;

			debugFont.draw(cline, px + 1, py + ry + 1, Color.black);
			debugFont.draw(cline, px, py + ry, Color.white);
		}
	}
}
#line 1 "C:\Users\soywiz\projects\lunea\bin\..\lib\lunea\gui\guicore.lun"
Gui gui;
Font guifont;
Process guiover;
Process guifocused;
Process guifocusedc;

void GuiInit(Font font = null) {
	gui = new Gui(1000);
	if (font !is null) {
		guifont = font;
	} else {
		guifont = new Font("Arial", 14, false, true);
	}
}

class Gui : Process  {
	Color bgColor;
	Color fgColor;
	Color tbaColor;
	Color tbbColor;

	private int ct = 0;

	this(real z) {
		this.z = z;
		this.priority = -1000;
		bgColor  = Color.fromHex("C0C4DAE0");
		fgColor  = Color.fromHex("777FABFF");
		tbaColor = Color.fromHex("8EB3CFE0");
		tbbColor = Color.fromHex("DCDDE4E0");
	}

	private void pnext(Process p) {
		p.z = ct;
		p.priority = -ct;
		ct++;
		guifocused = p;
	}

	void attach(Process p) {
		pnext(p);
	}

	void bringFront(Process p) {
		pnext(p);
	}

	void executeBegin()  {
		//writefln("EXECUTE_BEGIN");
		guifocusedc = null;
		guiover = null;
	}

	void main()  {
		while (true) frame();
	}

	void executeEnd()  {
		if (guifocusedc !is null) {
			//writefln("EXECUTE_END");
			Mouse.b[0] = false;
			Mouse.pressed[0] = false;
			Mouse.released[0] = false;
		} else {
			if (Mouse.pressed[0]) guifocused = null;
		}
	}

	void draw()  {
		//Screen.drawLine(0, 0, Screen.width - 1, Screen.height - 1, Color.white);
	}
}

class GuiEventHandler {
	private void delegate(Object that)[] list;

	void opCatAssign(void delegate(Object that) d) {
		list ~= d;
	}

	void opAddAssign(void delegate(Object that) d) {
		list ~= d;
	}

	void execute(Process that) {
		foreach (void delegate(Object that) deleg; list) deleg(that);
	}
}
#line 1 "C:\Users\soywiz\projects\lunea\bin\..\lib\lunea\gui\window.lun"
class Window : Process  {
	private real __width, __height;
	char[] title;
	bit dragging = false;
	bit resizing = false;
	int resizingp = 0;
	real dpx, dpy;
	real drx, dry;
	real dmx, dmy;
	real stickydist = 8;
	bit hasfocus = false;
	real minw = 100, minh = 100;
	int lastpress = 0;

	alias width  w;
	alias height h;

	bool minimized = false;

	this() {
		this.group.z = gui;
		this.group.priority = gui;
		this.__width = 100;
		this.__height = 100;
		title = "Untitled";
		center();
		gui.attach(this);
		relativex = 2;
		relativey = 20;
	}

	public void width(real v) {
		__width = max(minw, v);
	}

	public void height(real v) {
		__height = max(minh, v);
	}

	public real width() {
		return __width;
	}

	public real height() {
		return __height;
	}

	static private bit near(real from, real to, real dist = 5) {
		dist = abs(dist);
		return (from >= to - dist && from <= to + dist);
	}

	private static void nearset(inout real from, real to, real dist = 5, real addv = 0) {
		if (near(from + addv, to, dist)) from = to - addv;
	}

	private static bit rintersect(real a1, real a2, real b1, real b2) {
		real temp;
		if (a1 > a2) { temp = a2; a2 = a1; a1 = temp; }
		if (b1 > b2) { temp = b2; b2 = b1; b1 = temp; }

		return (min(a2, b2) + 1) >= (max(a1, b1) - 1);
	}

	static private void nearboxset(inout real x1, inout real y1, real w1, real h1, real x2, real y2, real w2, real h2, real dist = 5) {
		bit setx = false, sety = false;

		// Horizontal
		if (near(x1 + w1, x2     , dist) && rintersect(y1, y1 + h1, y2, y2 + h2)) { setx = true; x1 = x2 - w1 - 1; }
		if (near(x1     , x2 + w2, dist) && rintersect(y1, y1 + h1, y2, y2 + h2)) { setx = true; x1 = x2 + w2 + 1; }

		// Vertical
		if (near(y1 + h1, y2     , dist) && rintersect(x1, x1 + w1, x2, x2 + w2)) { sety = true; y1 = y2 - h1 - 1; }
		if (near(y1     , y2 + h2, dist) && rintersect(x1, x1 + w1, x2, x2 + w2)) { sety = true; y1 = y2 + h2 + 1; }

		if (setx) {
			nearset(y1, y2, dist, h1 + 1);
			nearset(y1, y2 + h2, dist, h1);
		}

		if (sety) {
			nearset(x1, x2, dist, w1 + 1);
			nearset(x1, x2 + w2, dist, w1);
		}

		if (setx) {
			nearset(y1, y2, dist);
			nearset(y1, y2 + h2 + 1, dist);
		}

		if (sety) {
			nearset(x1, x2, dist);
			nearset(x1, x2 + w2 + 1, dist);
		}
	}

	static private void nearboxsetr(real minw, real minh, real x1, real y1, inout real w1, inout real h1, real x2, real y2, real w2, real h2, real dist = 5) {
		if (near(x1 + w1, x2, dist) && rintersect(y1, y1 + h1, y2, y2 + h2)) w1 = x2 - x1 - 1;
		if (near(x1 + w1, x2 + w2, dist) && rintersect(y1, y1 + h1, y2, y2 + h2)) w1 = x2 + w2 - x1;
		if (near(y1 + h1, y2, dist) && rintersect(x1, x1 + w1, x2, x2 + w2)) h1 = y2 - y1 - 1;
		if (near(y1 + h1, y2 + h2, dist) && rintersect(x1, x1 + w1, x2, x2 + w2)) h1 = y2 + h2 - y1;

		if (near(x1 + w1, Screen.width,  dist)) w1 = Screen.width - x1 - 1;
		if (near(y1 + h1, Screen.height, dist)) h1 = Screen.height - y1;

		w1 = max(minw, w1); h1 = max(minh, h1);
	}

	private void updatenear_position() {
		if (!this.group || !this.group.z) return;

		foreach (Process p; group.z.zList) {
			if (p is this) continue;
			if (this.classinfo !is p.classinfo) continue;
			Window wnd = cast(Window)p;
			nearboxset(x, y, width, height, wnd.x, wnd.y, wnd.width, wnd.height, stickydist);
		}
	}

	private void updatenear_resize() {
		if (!this.group || !this.group.z) return;

		foreach (Process p; group.z.zList) {
			if (p is this) continue;
			if (this.classinfo !is p.classinfo) continue;
			Window wnd = cast(Window)p;
			nearboxsetr(minw, minh, x, y, __width, __height, wnd.x, wnd.y, wnd.width, wnd.height, stickydist);
		}
	}

	public void pxy(real x, real y) {
		px(x); py(y);
		updatenear_position();
	}

	public void px(real x) {
		nearset(x, 0, stickydist, 0);
		nearset(x, Screen.width, stickydist, width + 1);
		this.x = max(-width + 20, x);
	}

	public void py(real y) {
		nearset(y, 0, stickydist, 0);
		nearset(y, Screen.height, stickydist, height + 1);
		this.y = max(-5, y);
	}

	public real px() {
		return y;
	}

	public real py() {
		return y;
	}

	public void center() {
		x = Screen.width  / 2 - (__width  / 2);
		y = Screen.height / 2 - (__height / 2);
	}

	void main()  {
		while (true) {
			int px1 = cast(int)__x, py1 = cast(int)__y;
			int px2 = px1 + cast(int)__width;
			int py2 = py1 + cast(int)__height;

			if (lastpress > 0) lastpress--;

			if (Mouse.x >= px1 && Mouse.x <= px2) {
				if (Mouse.y >= py1 && Mouse.y <= py2) {
					guiover = this;

					if (Mouse.y >= py1 && Mouse.y <= py1 + 18) {
						if (Mouse.pressed[0] && !guifocusedc) {
							// Start drag
							if (guifocused !is this) {
								//writefln("Focus: " ~ this.toString);
							}
							//writefln("Drag start");
							dragging = true;
							dpx = x; dpy = y;
							dmx = Mouse.x; dmy = Mouse.y;
							gui.bringFront(this);
							guifocusedc = this;

							if (lastpress > 0) {
								minimized = !minimized;
							}

							if (lastpress == 0) {
								lastpress = 20;
							}
						}
					} else if (Mouse.pressed[0]) {
						if (!guifocusedc) {
							if (guifocused !is this) {
								//writefln("Focus: " ~ this.toString);
							}
							gui.bringFront(this);
							guifocusedc = this;
						}
					}

					if (Mouse.pressed[0] && !guifocusedc || guifocusedc is this) {
						resizingp = 0;

						if (Mouse.x >= px2 - 3 && Mouse.x <= px2 && Mouse.y >= py1 + 18) {
							resizing   = true;
							resizingp |= 1 << 0;
						}

						if (Mouse.y >= py2 - 3 && Mouse.y <= py2) {
							resizing   = true;
							resizingp |= 1 << 1;
						}

						if ((Mouse.x >= px2 - 8 && Mouse.x <= px2) && (Mouse.y >= py2 - 8 && Mouse.y <= py2)) {
							resizing   = true;
							resizingp |= (1 << 0) | (1 << 1);
						}

						/*if (Mouse.x >= px1 && Mouse.x <= px1 + 3) {
							resizing   = true;
							resizingp |= 1 << 2;
						}

						if (Mouse.y >= py1 && Mouse.y <= py1 + 3) {
							resizing   = true;
							resizingp |= 1 << 3;
							dragging = false;
						}*/

						if (resizing) {
							//writefln("Resize start");
							drx = width;
							dry = height;
							dpx = x;
							dpy = y;
							dmx = Mouse.x; dmy = Mouse.y;
						}
					}

					if (Mouse.pressed[0]) {
						hasfocus = true;
					}
				}
			}

			if (resizing) {
				if (Mouse.x - dmx != 0 || Mouse.y - dmy != 0) {
					if (resizingp & (1 << 0)) width  = drx + Mouse.x - dmx;
					if (resizingp & (1 << 1)) height = dry + Mouse.y - dmy;
					/*if (resizingp & (1 << 2)) {
						px(dpx + Mouse.x - dmx);
						updatenear_position();
						width = drx - (x - dpx);
						if (width <= drx) px(dpx);
					}
					if (resizingp & (1 << 3)) {
						py(dpy + Mouse.y - dmy);
						updatenear_position();
						height = dry - (y - dpy);
						if (height <= dry) py(dpy);
					}*/

					updatenear_resize();
				}

				if (Mouse.released[0]) {
					//writefln("Resize end");
					resizing = false;
				}

				guifocusedc = this;
			}

			if (dragging) {
				pxy(dpx + Mouse.x - dmx, dpy + Mouse.y - dmy);

				if (Mouse.released[0]) {
					//writefln("Drag end");
					dragging = false;
				}

				guifocusedc = this;
			}

			if (Mouse.released[0]) {
				hasfocus = false;
			}

			if (hasfocus) {
				guifocusedc = this;
			}

			frame();
		}
	}

	void draw()  {
		int px1 = cast(int)__x, py1 = cast(int)__y;
		int px2 = px1 + cast(int)__width;
		int py2 = py1 + cast(int)__height;

		if (minimized) {
			py2 = py1 + 20;
		}

		Screen.drawFillBox(px1, py1, px2, py2, gui.bgColor);
		Screen.drawBox(px1, py1, px2, py2, gui.fgColor);
		if (guifocused is this) {
			Screen.drawFillBox(px1 + 2, py1 + 2, px2 - 2, py1 + 18, gui.tbaColor);
			guifont.draw(title, px1 + 6, py1 + 5, Color.black);
		} else {
			Screen.drawFillBox(px1 + 2, py1 + 2, px2 - 2, py1 + 18, gui.tbbColor);
		}
		guifont.draw(title, px1 + 5, py1 + 4, Color.white);
	}

	void drawBegin()  {
		/*
		if (minimized) {
			Screen.pushClip(new Rect(x + 1, y + 20, width - 1, 0), true);
		} else {
			Screen.pushClip(new Rect(x + 1, y + 20, width - 1, height - 1), true);
		}
		*/
		if (minimized) {
			Screen.pushClip(new Rect(x, y, width + 1, 20 + 1), true);
		} else {
			Screen.pushClip(new Rect(x, y, width + 1, height + 1), true);
		}
	}

	void drawEnd()  {
		Screen.popClip();
	}
}

#line 0 "unknown"
void __resource_loader() {
	title = "rpgtest";
}

