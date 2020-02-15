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

#line 1 "test.lun"
 
        
      
	 


real sig(real v) { return (v < 0) ? -1 : 1; }

Font font1;

class Test : Process  {
	Text mtext;

	void main()  {
		with (mtext = new Text("Test", 0, 0, Text.Align.left, Text.Align.top, Color.white, font1)) {
			relative = this;
			group.z = this;
		}
		
		return cast(void)(this.paction = &right);
	}
	
	void right()  {
		while (x < 640 - mtext.width) { x += 5; frame(); }
		return cast(void)(this.paction = &left);
	}

	void left()  {
		while (x > 0) { x -= 5; frame(); }
		return cast(void)(this.paction = &right);
	}
}

class Sample : Process  {
	int maxv = 10;
	
	void main()  {
		Text t = new Text("Hola", 20, 20, Text.Align.left, Text.Align.top, Color.red, font1);
		t.group.z = this;
		t.relative = this;
		
		real vx = 0, vy = 0;

        while (!key[_esc]) {
			if (key[_left ] && vx > -maxv) vx -= 2;
			if (key[_right] && vx <  maxv) vx += 2;
			if (key[_up   ] && vy > -maxv) vy -= 2;
			if (key[_down ] && vy <  maxv) vy += 2;
		
			if (vx != 0) vx -= sig(vx);
			if (vy != 0) vy -= sig(vy);
			
			x += vx;
			y += vy;

			frame();
		}
	}
}

class MainProcess : Process {
    void main()  {
		font1 = new Font("arial.ttf", 50);
		
		Sample sample = new Sample();
		
		with (new Test()) {
			x = 400;
			y = 300;
		}
		
		bool stopped = false;
		
        while (!key[_esc]) {
			if (key.released[_o]) {
				foreach (char[] s; pmanager.dumpS()) {
					writefln(s);
				}
			}
			
			if (key.pressed[_p]) {
				if (stopped) {
					this.flags += Flags.execute | Flags.tree;
				} else {
					this.flags -= Flags.execute | Flags.tree;
					this.flags += Flags.execute;					
				}
				
				stopped = !stopped;
			}
			
			if (key[_q]) sample.z =  100;
			if (key[_a]) sample.z = -100;
		
			frame();
		}
			
		exit();
    }
}

#line 1 "C:\Users\soywiz\projects\lunea\bin\..\lib\lunea\default\text.lun"
class Text : Process  {
	enum Align {
		left   = 0,
		top    = 0,
		center = 1,
		middle = 1,
		right  = 2,
		bottom = 2
	}

	Font font;
	char[] text;
	Color color;
	Align halign;
	Align valign;
	int shadow, border;
	
	real width() {
		if (!font) return 0;
		return font.width(text);
	}

	this(char[] text = "", real x = 0, real y = 0, Align halign = Align.left, Align valign = Align.top, Color color = Color.white, Font font = null) {
		if (font is null) font = debugFont;
		this.font  = font;
		this.text  = text;
		this.color = color;
		this.x = x;
		this.y = y;
		this.halign = halign;
		this.valign = valign;
		this.shadow = 0;
	}

	void draw()  {
		if (font is null) return;

		real rx = __x, ry = __y;

		switch (halign) {
			case Align.center: rx -= font.width(text) / 2; break;
			case Align.right: rx -= font.width(text); break;
			default: break;
		}

		switch (valign) {
			case Align.middle: ry -= font.height / 2; break;
			case Align.bottom: ry -= font.height; break;
			default: break;
		}

		if (shadow > 0) {
			Color scolor = new Color(0, 0, 0, 1 / cast(real)shadow);
			for (int n = shadow - 1; n > 0; n--) font.draw(text, rx + n, ry + n, scolor);
		}

		if (border > 0) {
			for (int y = -1; y <= 1; y++) {
				for (int x = -1; x <= 1; x++) {
					font.draw(text, rx + x, ry + y, Color.black);
				}
			}
		}

		font.draw(text, rx, ry, color);
	}
void main() { while(true)frame(); } }

#line 0 "unknown"
void __resource_loader() {
	title = "Untitled";
}

