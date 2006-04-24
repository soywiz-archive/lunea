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
 *  $Id: Animation.d,v 1.6 2006/01/22 22:44:02 soywiz Exp $
 */

module lunea.driver.Animation;

import lunea.driver.Image;

import lunea.std.All;

private import std.file, std.stdio, std.string, std.conv;

class Frame {
	public real duration;
	public ZImage[] images;

	void draw(real x, real y) {
		foreach (ZImage zimage; images) zimage.draw(x, y);
	}

	void draw(real x, real y, real alpha, real angle = 0, real size = 1.0, real red = 1.0, real green = 1.0, real blue = 1.0) {
		foreach (ZImage zimage; images) zimage.draw(x, y, alpha, angle, size, red, green, blue);
	}

	void opCatAssign(ZImage image) {
		this.images ~= image;
	}
}

enum {
	VM_UNKNOWN,
	VM_TIME,
	VM_FRAME,
	VM_POSITION,
	VM_USER
}

class Animation {
	public char[]  name;
	public int     method;
	public Frame[] frames;
	public real    maxDuration;

	this(char[] name, char[] method) {
		this.name = name;
		switch (std.string.tolower(std.string.strip(method))) {
			default:
			case "time"    : this.method = VM_TIME    ; break;
			case "frame"   : this.method = VM_FRAME   ; break;
			case "position": this.method = VM_POSITION; break;
			case "user"    : this.method = VM_USER    ; break;
		}
		maxDuration = 1;
	}

	Frame getFrame(real duration) {
		real cduration = 0;
		Frame cframe;

		if (frames.length) cframe = frames[0];

		foreach (Frame frame; frames) {
			cduration += frame.duration;
			if (cduration < duration) continue;
			cframe = frame; break;
		}

		return cframe;
	}

	Frame update(inout real duration, real increment) {
		if (maxDuration > 0) {
			duration = (duration + increment) % maxDuration;
		} else {
			duration = 0;
		}

		return getFrame(duration);
	}

	void opCatAssign(Frame frame) {
		if (frame is null) return;
		frames ~= frame;
		maxDuration += frame.duration;
	}
}

class SpriteType {
	Image image;
	Image[char[]] images;
	Animation[char[]] animations;

	this(Xml xml) {
		void addZImageToFrame(inout Frame frame, char[] id, real x = 0, real y = 0, real alpha = 1, real size = 1, real angle = 0, real red = 1, real green = 1, real blue = 1) {
			if ((id in images) is null) return;

			frame ~= new ZImage(
				images[id],
				x, y,
				size, angle, alpha,
				red, green, blue,
				BLEND_NORMAL
			);
		}

		real greal(char[] data, real defval = 0) {
			data = std.string.tolower(std.string.strip(data));
			if (data.length) return std.conv.toReal(data);
			return defval;
		}

		int gint(char[] data, int defval = 0) {
			data = std.string.tolower(std.string.strip(data));
			if (data.length) return std.conv.toInt(data);
			return defval;
		}

		void parseClips(Xml xml) {
			foreach (Xml sxml; xml.xpath("/clip")) {
				char[] id = sxml.getAttributeFiltered("id");
				char[] x  = sxml.getAttributeFiltered("x");
				char[] y  = sxml.getAttributeFiltered("y");
				char[] w  = sxml.getAttributeFiltered("width");
				char[] h  = sxml.getAttributeFiltered("height");
				char[] cx = sxml.getAttributeFiltered("centerx");
				char[] cy = sxml.getAttributeFiltered("centery");

				Image image = Image.fromImage(
					image,
					gint(x ), gint(y ),
					gint(w ), gint(h ),
					gint(cx), gint(cy)
				);

				if (id.length == 0) throw(new Exception("Clip without id"));
				if (id in images  ) throw(new Exception("The id of clip is already choosen"));

				images[id] = image;
			}
		}

		void parseImages(Xml xml, inout Frame frame) {
			foreach (Xml ixml; xml.xpath("/image")) {
				char[] cid   = ixml.getAttributeFiltered("clipid");
				char[] x     = ixml.getAttributeFiltered("x");
				char[] y     = ixml.getAttributeFiltered("y");
				char[] alpha = ixml.getAttributeFiltered("alpha");
				char[] size  = ixml.getAttributeFiltered("size");
				char[] angle = ixml.getAttributeFiltered("angle");
				char[] red   = ixml.getAttributeFiltered("r");
				char[] green = ixml.getAttributeFiltered("g");
				char[] blue  = ixml.getAttributeFiltered("b");

				addZImageToFrame(
					frame, cid,
					greal(x, 0), greal(y, 0),
					greal(alpha, 1), greal(size, 1), greal(angle, 0),
					greal(red, 1), greal(green, 1), greal(blue, 1)
				);
			}
		}

		void parseFrame(Xml fxml, inout Animation view, real factor = 1.0) {
			char[] duration = fxml.getAttributeFiltered("duration");

			char[] cid   = fxml.getAttributeFiltered("clipid");
			char[] x     = fxml.getAttributeFiltered("x");
			char[] y     = fxml.getAttributeFiltered("y");
			char[] alpha = fxml.getAttributeFiltered("alpha");
			char[] size  = fxml.getAttributeFiltered("size");
			char[] angle = fxml.getAttributeFiltered("angle");
			char[] red   = fxml.getAttributeFiltered("red");
			char[] green = fxml.getAttributeFiltered("green");
			char[] blue  = fxml.getAttributeFiltered("blue");

			Frame frame = new Frame;
			frame.duration = greal(duration, 1) * factor;

			if (cid.length) {
				addZImageToFrame(
					frame, cid,
					greal(x, 0), greal(y, 0),
					greal(alpha, 1), greal(size, 1), greal(angle, 0),
					greal(red, 1), greal(green, 1), greal(blue, 1)
				);
			}

			parseImages(fxml, frame);

			view ~= frame;
		}

		void parseRepeat(Xml xml, inout Animation view, bool isanimation = true, real factor = 1.0) {
			int times;

			times = isanimation ? 1 : gint(xml.getAttributeFiltered("times"), 0);

			for (; times > 0; times--) {
				foreach (Xml rxml; xml.children) {
					if (rxml is null) continue;
					switch (rxml.name) {
						case "repeat": parseRepeat(rxml, view, false, factor); break;
						case "frame":  parseFrame (rxml, view, factor); break;
					}
				}
			}
		}

		void parseAnimations(Xml xml) {
			foreach (Xml vxml; xml.xpath("/animation")) {
				char[] name   = vxml.getAttributeFiltered("name");
				char[] method = vxml.getAttributeFiltered("method");
				char[] factor = vxml.getAttributeFiltered("factor");

				Animation view = new Animation(name, method);

				parseRepeat(vxml, view, true, greal(factor, 1.0));

				animations[view.name] = view;
			}
		}

		void parseSprite(Xml xml) {
			parseClips(xml);
			parseAnimations(xml);
		}

		if (xml.name != "sprite") throw(new Exception("The XML must be an sprite descriptor"));
		char[] nimage = xml["image"];
		if (!nimage.length) return;
		this.image = Image.fromFile(nimage);

		parseSprite(xml);
	}

	this(char[] data) {
		this(new Xml(data));
	}

	static SpriteType fromFile(char[] file) {
		return new SpriteType(cast(char[])std.file.read(file));
	}
}

class Sprite {
	public  real factor;

	private SpriteType spritetype;
	private Animation _animation;
	private Frame frame;
	private real pos;

	this(SpriteType spritetype, real factor = 1.0) {
		this.spritetype  = spritetype;
		this.factor      = factor;
		this.pos         = 0;
		this.animation   = "default";
	}

	Sprite clone() {
		return new Sprite(spritetype, factor);
	}

	this(char[] xml, real factor = 1.0) {
		this(new SpriteType(xml), factor);
	}

	this(Sprite sprite, real factor = 1.0) {
		this(sprite.spritetype, factor);
	}

	static Sprite fromFile(char[] file, real factor = 1.0) {
		return new Sprite(SpriteType.fromFile(file), factor);
	}

	void set(char[] name) {
		if (spritetype is null) return;
		name = std.string.tolower(std.string.strip(name));

		if (name in spritetype.animations) _animation = spritetype.animations[name];

		if (_animation is null) {
			Animation[] vl = spritetype.animations.values;
			if (vl.length) _animation = vl[0];
		}
	}

	char[] animation() {
		if (_animation is null) return "";
		return _animation.name;
	}

	char[] animation(char[] name) {
		set(name);
		return animation();
	}

	void update(real incv) {
		if (_animation is null) return;
		frame = _animation.update(this.pos, incv * factor);
	}

	void update(real incpos, real incframe, real inctime) {
		if (_animation is null) return;
		switch (_animation.method) {
			default:
			case VM_TIME    : frame = _animation.update(this.pos, inctime  * factor); break;
			case VM_FRAME   : frame = _animation.update(this.pos, incframe * factor); break;
			case VM_POSITION: frame = _animation.update(this.pos, incpos   * factor); break;
			case VM_USER    : break;
		}
	}

	void draw(real x, real y) {
		if (frame is null) return;
		frame.draw(x, y);
	}

	void draw(real x, real y, real alpha, real angle = 0, real size = 1.0, real red = 1.0, real green = 1.0, real blue = 1.0) {
		if (frame is null) return;
		frame.draw(x, y, alpha, angle, size, red, green, blue);
	}
}