module pdcurses;

import std.string;

extern(C) {
	alias ubyte chtype;

	struct WINDOW { /* definition of a window	*/

		int	_cury;  /* current pseudo-cursor	*/
		int	_curx;
		int	_maxy;  /* max window coordinates	*/
		int	_maxx;
		int	_begy;  /* origin on screen		*/
		int	_begx;
		int	_flags;  /* window properties		*/
		chtype	_attrs;		/* standard attributes and colors */
		chtype	_bkgd;		/* background, normally blank	*/
		bool	_clear;		/* causes clear at next refresh	*/
		bool	_leaveit;	/* leaves cursor where it is	*/
		bool	_scroll;	/* allows window scrolling	*/
		bool	_nodelay;	/* input character wait flag	*/
		bool	_immed;		/* immediate update flag	*/
		bool	_sync;		/* synchronise window ancestors	*/
		bool	_use_keypad;	/* flags keypad key mode active	*/
		chtype	**_y;		/* pointer to line pointer array   */
		int	*_firstch;	/* first changed character in line */
		int	*_lastch;	/* last changed character in line  */
		int	_tmarg;		/* top of scrolling region	*/
		int	_bmarg;		/* bottom of scrolling region	*/
		int	_delayms;	/* milliseconds of delay for getch() */
		int	_parx, _pary;	/* coords relative to parent (0,0) */
		WINDOW *_parent;	/* subwin's pointer to parent win  */
	} ;

	WINDOW *initscr();

	int	nodelay(WINDOW *, chtype);
	int	erase();
	int	noecho();
	int	werase(WINDOW *);
	int waddch(WINDOW *, chtype);
	int	addch(ubyte);
	int	flash();
	int	pechochar(WINDOW *, chtype);
	int	wclear(WINDOW *);
	int	clear();
	int	beep();
	int	refresh();
	int	move(int, int);
	int	mvaddstr(int, int, char *);
	int	wrefresh(WINDOW *);
	int	wmove(WINDOW *, int, int);
	int	wprintw(WINDOW *, char *, ...);
	int	wcolor_set(WINDOW *, short, void *);

	int has_key(int);
}

class Console {
	WINDOW *win;
	bool autorefresh;

	enum {
		KEY_UP = 0x103,
	}

	this(bool autorefresh = false) {
		this.win = initscr();
		this.autorefresh = autorefresh;
	}

	void color_set() {
	}

	void move(int y, int x) {
		wmove(this.win, y, x);
		if (autorefresh) refresh();
	}

	void addch(ubyte c) {
		waddch(this.win, c);
	}

	void print(char[] text) {
		wprintw(this.win, "%s", toStringz(text));
		if (autorefresh) refresh();
	}

	void clear() {
		wclear(this.win);
		if (autorefresh) refresh();
	}

	void refresh() {
		wrefresh(this.win);
	}
}
