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
 *  $Id: Process.d,v 1.13 2006/02/16 16:32:39 soywiz Exp $
 */

module lunea.Process;

private import lunea.ProcessThread;
private import lunea.driver.Main;
private import std.math, std.stdio;
private import lunea.Lunea;

enum Flags {
	// Behaviour
	execute = 1 << 0x0, visible = 1 << 0x1, alive   = 1 << 0x2,
	// Flipping
	xflip   = 1 << 0x3, yflip   = 1 << 0x4, zflip   = 1 << 0x5,
	// Tree
	tree    = 1 << 0xa, childs  = 1 << 0xb,
}

class CFlags {
	protected Process parent;

	public ushort _flags = Flags.execute | Flags.visible | Flags.alive;

	bool execute() { return (_flags & Flags.execute) != 0; }
	bool visible() { return (_flags & Flags.visible) != 0; }
	bool alive  () { return (_flags & Flags.alive)   != 0; }

	void opAddAssign(ushort cflags) {
		if (!(cflags & Flags.childs)) {
			_flags |= (cflags & ~Flags.tree);
		} else {
			cflags  = cflags & ~Flags.childs;
		}

		assert(parent);

		if (!(cflags & Flags.tree)) return;

		Process cp = parent.son;
		while (cp) {
			cp.flags += cflags;
			cp = cp.smallbro;
		}
	}

	void opSubAssign(ushort cflags) {
		if (!(cflags & Flags.childs)) {
			_flags &= ~(cflags & ~Flags.tree);
		} else {
			cflags  = cflags & ~Flags.childs;
		}

		assert(parent);

		if (!(cflags & Flags.tree)) return;

		Process cp = parent.son;
		while (cp) { cp.flags -= cflags; cp = cp.smallbro; }
	}

	this(CFlags cflags) { this.parent = cflags.parent; this._flags = cflags._flags; }
	this(Process pparent) { this.parent = pparent; }
	int opCast() {
		return _flags;
	}
}

class CGroup {
	private Process father;

	private Process _z = null;
	private Process _e = null;

	public  ushort zp;
	public  ushort ep;

	this(Process father) { this.father = father; }

	public void removeFromZ() {
		if (_z is null) return;

		for (int n = 0; n < father.zList.length; n++) {
			Process p = father.zList[n];
			p.group.z = this._z;
		}

		int length = _z.zList.length - 1;
		for (int n = zp; n < length; n++) {
			_z.zList[n] = _z.zList[n + 1];
			_z.zList[n].group.zp = n;
		}
		_z.zList.length = _z.zList.length - 1;
	}

	public void removeFromE() {
		if (_e is null) return;

		for (int n = 0; n < father.eList.length; n++) {
			Process p = father.eList[n];
			p.group.priority = this._e;
		}

		int length = _e.eList.length - 1;
		for (int n = ep; n < length; n++) {
			_e.eList[n] = _e.eList[n + 1];
			_e.eList[n].group.ep = n;
		}
		_e.eList.length = _e.eList.length - 1;
	}

	public Process z() { return _z; }
	public Process z(Process p) {
		if (p is null) p = pmanager;

		removeFromZ();

		_z = p;

		if (p !is null) {
			p.zList ~= this.father;
			p.resortZ();
		}

		return p;
	}

	public Process priority() { return _e; }
	public Process priority(Process p) {
		if (p is null) p = pmanager;

		removeFromE();

		_e = p;

		if (p !is null) {
			p.eList ~= this.father;
			p.resortE();
		}

		return p;
	}
}

abstract class ProcessCounter : ProcessThread {
	public  int        id = -1;
	private static int nextid = 0;

	public  this() { id = nextid++; __attach(); }
	public ~this() { __detach(); }

	protected abstract void __attach();
	protected abstract void __detach();
}

enum Collision {
	inner = 0, // Circulo interior
	outer = 1, // Circulo exterior
	box   = 2, // Caja
	pixel = 3, // Pixel perfect
}

abstract class Process : ProcessCounter {
	public Process    father, son, bigbro, smallbro;
	public Process    relative;
	public real       z = 0;
	public real       priority = 0;

	public CFlags     flags;
	public CGroup     group;

	public Process[]  zList;
	public Process[]  eList;

	public Collision  collisionType = Collision.inner;

	public Process inner(Process father) {
		return (this.relative = this.group.priority = this.group.z = father);
	}

	override public this() {
		flags = new CFlags(this);
		group = new CGroup(this);
		super();
	}

	public ~this() {
		pmanager -= this;

		this.group.removeFromZ();
		this.group.removeFromE();

		delete flags; flags = null;
		delete group; group = null;
	}

	protected void __attach  () { pmanager.attach(this); }
	protected void __detach  () { pmanager.detach(this); }

	public    char[] type    () { return this.classinfo.name; }
	public    char[] toString() { return "(" ~ std.string.toString(id) ~ ", " ~ type ~ ")"; }

	void _draw() {
		// TODO: we must execute draw after or before?
		draw();

		drawBegin();
		resortZ();
		for (int n = 0; n < zList.length; n++) {
			Process p = zList[n];

			if (!p.flags.visible) continue;

			if (p.zList.length) {
				p._draw();
			} else {
				//p.drawBegin(); // ?
				p.draw();
				//p.drawEnd(); // ?
			}
		}
		drawEnd();
	}

	void _execute() {
		__execute();

		executeBegin();
		resortE();
		for (int n = 0; n < eList.length; n++) {
			Process p = eList[n];

			if (!p.flags.execute) continue;

			if (!p.flags.alive) {
				try { delete p; } catch (Exception e) { }
				n--;
				continue;
			}

			cprocess = p;

			if (p.eList.length) {
				p._execute();
			} else {
				//p.executeBegin(); // ?
				p.__execute();
				//p.executeEnd(); // ?
			}

			if (p.__finished) p.flags -= Flags.alive;
		}
		executeEnd();
	}

	void resortZ() {
		// Ordenar Z
		for (int n = 0; n < zList.length; n++) {
			int m = n;
			while (m > 0) {
				if (zList[m].z >= zList[m - 1].z) break;
				Process temp = zList[m - 1];
				zList[m - 1] = zList[m];
				zList[m]     = temp;
				m--;
			}
			//zList[n].group.zp = n;
		}

		for (int n = 0; n < zList.length; n++) zList[n].group.zp = n;
	}

	void resortE() {
		// Ordenar priority
		for (int n = 0; n < eList.length; n++) {
			int m = n;
			while (m > 0) {
				if (eList[m].priority >= eList[m - 1].priority) break;

				Process temp = eList[m - 1];
				eList[m - 1] = eList[m];
				eList[m]     = temp;
				m--;
			}
			//eList[n].group.ep = n;
		}

		for (int n = 0; n < eList.length; n++) eList[n].group.ep = n;
	}

	// PROCESS
	public real  x = 0, y = 0;
	public real  angle = 0;
	public real  alpha = 1.0;
	public real  size  = 1.0;
	public Image graph;
	public Sprite sprite;
	public Rect  clip;
	public uint  tint = 0x00ffffff;

	public real  relativex = 0, relativey = 0;

	private real  __bx = 0, __by = 0;

	real __x() {
		if (relative is null || relative is this) return x;
		return x + relative.__x + relative.relativex;
	}

	real __y() {
		if (relative is null || relative is this) return y;
		return y + relative.__y + relative.relativey;
	}

	real __x(real v) {
		if (relative is null || relative is this) return v;
		return v + relative.__x + relative.relativex;
	}

	real __y(real v) {
		if (relative is null || relative is this) return v;
		return v + relative.__y + relative.relativey;
	}

	// DRAW
	void draw() {
		if (sprite !is null) {
			if (tint != 0x00ffffff) {
				sprite.draw(__x, __y, alpha, angle, size, (cast(real)((tint & 0xff) >> 0) / 0xff), (cast(real)((tint & 0xff00) >> 8) / 0xff), (cast(real)((tint & 0xff0000) >> 16) / 0xff));
			} else {
				sprite.draw(__x, __y, alpha, angle, size);
			}
			sprite.update(sqrt(abs(__bx - x) + abs(__by - y)), 1, fps_interval);
			__bx = x; __by = y;
			return;
		}

		if (graph is null) return;

		if (tint != 0x00ffffff) {
			graph.draw(__x, __y, alpha, angle, size, (cast(real)((tint & 0xff) >> 0) / 0xff), (cast(real)((tint & 0xff00) >> 8) / 0xff), (cast(real)((tint & 0xff0000) >> 16) / 0xff));
		} else {
			graph.draw(__x, __y, alpha, angle, size);
		}
	}

	void drawBegin() {
		if (clip is null) return;
		Screen.pushClip(clip, true);
	}

	void drawEnd() {
		if (clip is null) return;
		Screen.popClip();
	}

	void executeBegin() {
	}

	void executeEnd() {
	}

	char[][] dumpSZ(int level = 0) {
		char[][] retval;

		if (!zList.length) {
			retval ~= std.string.repeat("\t", level) ~ "-[" ~ std.string.toString(z) ~ "] " ~ toString;
		} else {
			retval ~= std.string.repeat("\t", level) ~ "-[" ~ std.string.toString(z) ~ "] " ~ toString ~ " {";
			for (int n = 0; n < zList.length; n++) {
				foreach (char[] s; zList[n].dumpSZ(level + 1)) retval ~= s;
			}
			retval ~= std.string.repeat("\t", level) ~ "}";
		}

		return retval;
	}

	char[][] dumpSE(int level = 0) {
		char[][] retval;

		if (!eList.length) {
			retval ~= std.string.repeat("\t", level) ~ "-[" ~ std.string.toString(priority) ~ "] " ~ toString;
		} else {
			retval ~= std.string.repeat("\t", level) ~ "-[" ~ std.string.toString(priority) ~ "] " ~ toString ~ " {";
			for (int n = 0; n < eList.length; n++) {
				foreach (char[] s; eList[n].dumpSE(level + 1)) retval ~= s;
			}
			retval ~= std.string.repeat("\t", level) ~ "}";
		}

		return retval;
	}

	void opAddAssign(ushort cflags) { flags += cflags; }
	void opSubAssign(ushort cflags) { flags -= cflags; }

	// TODO
	// collision methods
	Process collision(char[] type) {
		if ((type in pmanager.cnlist) is null) return null;
		foreach (Process cp; pmanager.cnlist[type]) if (pcollision(cp)) return cp;
		return null;
	}

	Process collision(ClassInfo type) {
		return collision(type.name);
	}

	/*Process collision(Object object) {
		return collision(object.type.name);
	}*/

	Process collision(Process[] p) {
		foreach (Process cp; p) if (pcollision(cp)) return cp;
		return null;
	}

	Process[] getCollisionArray(char[] type) {
		Process[] retval;
		if ((type in pmanager.cnlist) is null) return retval;
		foreach (Process cp; pmanager.cnlist[type]) if (pcollision(cp)) retval ~= cp;
		return retval;
	}

	Process[] getCollisionArray(Process[] p) {
		Process[] retval;
		foreach (Process cp; p) if (pcollision(cp)) retval ~= cp;
		return retval;
	}

	// FIX;TODO
	bool pcollision(Process that) {
		if (interactions.hasInteraction("collision", this, that)) {
			return cast(bool)interactions.interact("collision", this, that);
		}

		switch (collisionType) {
			default:
			case Collision.inner:
				if (!this.graph || !that.graph) return false;
				int dist  = cast(int)(hypot(this.x - that.x, this.y - that.y));
				int size1 = cast(int)(SQRT2 * (this.graph.w + this.graph.h) / 6);
				int size2 = cast(int)(SQRT2 * (this.graph.w + this.graph.h) / 6);
				if (dist <= size1 + size2) return true;
				return false;
			break;
		}
	}
}

class ProcessManager : Process {
	public Process[]    list;
	public int[Process] listp;

	public Process[][char[]]    cnlist;
	public int[Process][char[]] cnlistp;

	void main() { }

	void nodebug() { }

	override public  this() { cprocess = this; }
	override public ~this() {
		for (int n = 0; n < list.length; n++) {
			if (!list[n]) continue;
			listp.remove(list[n]);
			try { delete list[n]; } catch (Exception) { }
		}
		list.length = 0;
	}

	override void __attach() { }
	override void __detach() { }

	override void executeBegin() { }
	override void executeEnd  () { }

	int start(char[][] args, Process mprc) {
		LuneaDriver.onStart();

		arguments = args;
		mprocess  = mprc;
		cprocess  = this;

		while (length && luneaRunning) {
			try {
				LuneaDriver.onBeforeExecute();

				try {
					_execute();
					_draw();
				} catch (Exception e) {
					writefln("Exception: " ~ e.toString);
				}

				LuneaDriver.onAfterExecute();
			} catch (Exception e) {
				writefln("Fatal Error: " ~ e.toString);
				break;
			}
		}

		LuneaDriver.onExit();

		return 0;
	}

	void attach(Process p) {
		if (p is null) return;
		if (p is this) return;

		p.father = cprocess;

		if (cprocess) {
			p.smallbro = cprocess.son;
			if (cprocess.son) cprocess.son.bigbro = p;
			cprocess.son = p;
		}

		if (p.father) {
			p.group.priority = p.father.group.priority;
			p.group.z        = p.father.group.z;
		} else {
			p.group.priority = p.group.z = this;
		}

		this += p;
	}

	void detach(Process p) {
		if (p is null) return;
		if (p is this) return;

		//p.son.father = p.father;
		if (p.father && p.father.son == p) p.father.son = p.smallbro;
		if (p.smallbro) p.smallbro.bigbro = p.bigbro;
		if (p.bigbro)   p.bigbro.smallbro = p.smallbro;

		p.group.removeFromZ();
		p.group.removeFromE();

		this -= p;
	}

	void opSubAssign(Process p) {
		if (p is null) return;
		if ((p in listp) is null) return;

		for (int n = listp[p] + 1; n < list.length; n++) list[n - 1] = list[n];
		list.length = list.length - 1;
		listp.remove(p);

		char[] ptype = p.type;
		if ((ptype in cnlistp) is null) return;
		int[Process] clistp = cnlistp[ptype];
		Process[]    *clist  = &cnlist[ptype];

		if ((p in clistp) is null) return;

		for (int n = clistp[p] + 1; n < clist.length; n++) clist[n - 1] = clist[n];
		clist.length = clist.length - 1;

		clistp.remove(p);
	}

	void opAddAssign(Process p) {
		listp[p] = list.length;
		list ~= p;

		char[] ptype = p.type;
		if ((ptype in cnlist) is null) cnlist[ptype].length = 0;
		cnlistp[ptype][p] = cnlist[ptype].length;
		cnlist[ptype] ~= p;
	}

	char[][] dumpS() {
		char[][] retval;

		retval ~= "DUMP {";
			retval ~= "\tDUMP(ALL) {";
				for (int n = 0; n < list.length; n++) {
					retval ~= "\t\t- " ~ list[n].toString;
				}
			retval ~= "\t}";
			retval ~= "\tDUMP(Z) {";
				foreach (char[] s; dumpSZ(2)) retval ~= s;
			retval ~= "\t}";
			retval ~= "\tDUMP(E) {";
				foreach (char[] s; dumpSE(2)) retval ~= s;
			retval ~= "\t}";
			retval ~= "\tDUMP(TYPE) {";
				foreach (char[] key, Process[] pl; cnlist) {
					foreach (Process p; pl) {
						retval ~= "\t\t- " ~ std.string.toString(cast(int)cast(int *)p);
					}
				}
			retval ~= "\t}";
			retval ~= "\tDUMP(TYPE2) {";
				foreach (char[] key, int[Process] pl; cnlistp) {
					foreach (Process p, int key2; pl) {
						retval ~= "\t\t- " ~ std.string.toString(cast(int)cast(int *)p);
					}
				}
			retval ~= "\t}";
/*
	public Process[][char[]]    cnlist;
	public int[Process][char[]] cnlistp;
*/
		retval ~= "}";

		return retval;
	}

	uint length() { return list.length; }
}

alias bool function(Process, Process) InteractionCallback;

class Interactions {
	InteractionCallback[ClassInfo][ClassInfo][char[]] list;

	void add(char[] type, ClassInfo i1, ClassInfo i2, InteractionCallback func) {
		list[type][i1][i2] = func;
	}

	bool hasInteraction(char[] type, Process p1, Process p2) {
		if (p1 is null || p2 is null) return false;
		if ((type in list) is null) return false;
		if ((p1.classinfo in list[type]) !is null && (p2.classinfo in list[type][p1.classinfo]) !is null) return true;
		if ((p2.classinfo in list[type]) !is null && (p1.classinfo in list[type][p2.classinfo]) !is null) return true;
		return false;
	}

	int interact(char[] type, Process p1, Process p2) {
		InteractionCallback func;
		if ((p1.classinfo in list[type]) !is null && (func = list[type][p1.classinfo][p2.classinfo]) !is null) return func(p1, p2);
		if ((p2.classinfo in list[type]) !is null && (func = list[type][p2.classinfo][p1.classinfo]) !is null) return func(p2, p1);
		return 0;
	}
}

void exit() { luneaRunning = false; }

ProcessManager pmanager;
Process        mprocess;
Process        cprocess;
Interactions   interactions;

static this() {
	pmanager = new ProcessManager;
	interactions = new Interactions();
}

static ~this() {
	//foreach (char[] line; pmanager.dumpS()) Logger.add(line, 0);
	delete pmanager; pmanager = null;
}
