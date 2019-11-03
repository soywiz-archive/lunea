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
 *  $Id: PathFind.d,v 1.7 2006/04/24 17:36:13 soywiz Exp $
 */

module lunea.std.PathFind;

private import
	lunea.std.Math,
	lunea.std.String
;

private import
	std.stdio,
	std.math
;

//public alias PathFind.Point Point;

class PathFind {
	public int width, height;
	public bit[][] map;

	private Node[][] nodes;
	private NodeList opened;
	private int openedid = 1;
	private int closedid = 2;
	private int sx, sy;
	private int dx, dy;

	public void setSize(int width, int height) {
		this.width  = width;
		this.height = height;

		nodes.length = map.length = height;

		for (int y = 0; y < height; y++) {
			map[y].length = width;
			nodes[y].length = width;
			for (int x = 0; x < width; x++) {
				map[y][x] = false;
				nodes[y][x] = new Node(x, y);
			}
		}
	}

	public this(int width, int height) {
		setSize(width, height);
		opened = new NodeList;
	}

	public class Point {
		int x, y;

		this(int x, int y) {
			this.x = x;
			this.y = y;
		}

		char[] toString() {
			return "[" ~ String.valueOf(x) ~ ", " ~ String.valueOf(y) ~ "]";
		}
	}

	private class Node {
		int status;
		int x, y;
		uint f, g, h;
		Node parent;
		Node next;

		void reset() {
			this.status = 0;
			this.f = this.h = this.g = 0;
			this.parent = this.next = null;
		}

		this(int x, int y) {
			this.x = x;
			this.y = y;
			reset();
		}
	}

	private class NodeList {
		Node first = null;

		void add(Node node) {
			if (first is null) {
				first = node;
				return;
			}

			if (node.f <= first.f) {
				node.next = first;
				first = node;
				return;
			}

			Node current = first;

			while (current.next !is null) {
				if (node.f <= current.next.f) {
					node.next = current.next;
					current.next = node;
					return;
				}

				current = current.next;
			}

			current.next = node;
			return;
		}

		void remove(Node node) {
			Node current = first;

			if (node is first) {
				first = first.next;
				return;
			}

			while (current.next !is null) {
				if (current.next is node) {
					current.next = node.next;
					return;
				}
				current = current.next;
			}
		}

		void update(Node node) {
			remove(node);
			add(node);
		}

		void clean() {
			Node current = first;
			while (current !is null) {
				Node temp = current;
				current = temp.next;
				temp = null;
			}
			first = null;
		}

		int has() {
			return (first !is null);
		}
	}

	protected int heuristic(int x, int y) {
		return (abs(dx - x) + abs(dy - y)) * 10;
		//return cast(int)(hypot(cast(real)(dx - x), cast(real)(dy - y)) * 10);
	}

	/*public Point[] find(int _sx, int _sy, int _dx, int _dy, int flags = 0) {
		Point[] retlist;
		Node current;
		bool found = false;
		int cx, cy;

		for (int y = 0; y < height; y++) for (int x = 0; x < width; x++) nodes[y][x].reset();

		this.dx = _sx; this.dy = _sy;
		if (sx < 0 || sx >= width || sy < 0 || sy >= height) throw(new Exception("Out of bounds"));

		this.sx = _dx; this.sy = _dy;
		if (dx < 0 || dx >= width || dy < 0 || dy >= height) throw(new Exception("Out of bounds"));

		if (map[sy][sx]) throw(new Exception("Start position is blocked"));
		if (map[dy][dx]) throw(new Exception("Destination position is blocked"));

		opened.clean();
		current = nodes[sy][sx];
		opened.add(current);
		current.status = openedid;

		while (opened.has) {
			current = opened.first;
			opened.remove(current);

			if (current.x == dx && current.y == dy) { found = true; break; }

			next(current);

			current.status = closedid;
		}

		if (!found) throw(new Exception("Path not found"));

		while (current) {
			retlist ~= new Point(current.x, current.y);
			current = current.parent;
		}

		return retlist;
	}*/

	public Point[] find(int _dx, int _dy, int _sx, int _sy, int flags = 0) {
		Point[] retlist;
		Node current;
		bool found = false;
		int cx, cy;

		for (int y = 0; y < height; y++) for (int x = 0; x < width; x++) nodes[y][x].reset();

		this.dx = _sx; this.dy = _sy;
		if (sx < 0 || sx >= width || sy < 0 || sy >= height) return null;

		this.sx = _dx; this.sy = _dy;
		if (dx < 0 || dx >= width || dy < 0 || dy >= height) return null;

		if (map[sy][sx]) return null;
		if (map[dy][dx]) return null;

		opened.clean();
		current = nodes[sy][sx];
		opened.add(current);
		current.status = openedid;

		while (opened.has) {
			current = opened.first;
			opened.remove(current);

			if (current.x == dx && current.y == dy) { found = true; break; }

			next(current);

			current.status = closedid;
		}

		if (!found) return null;

		while (current) {
			retlist ~= new Point(current.x, current.y);
			current = current.parent;
		}

		int rll2 = retlist.length / 2;
		for (int n = 0, m = retlist.length - 1; n < rll2; n++, m--) {
			Point temp = retlist[n];
			retlist[n] = retlist[m];
			retlist[m] = temp;
		}

		return retlist;
	}

	protected void open(Node parent, int ix, int iy, int ig) {
		int x = parent.x + ix, y = parent.y + iy;

		if (!check(x, y)) return;

		Node current = nodes[y][x];
		if (current.status == closedid) return;

		uint g = parent.g + ig, h = heuristic(x, y);

		if (x == dx && y == dy) { g = 0; h = 0; }

		uint f = g + h;

		if (current.status != openedid) {
			current.status = openedid;
		} else {
			if (current.f < f) return;
			opened.remove(current);
		}

		current.parent = parent;
		current.f = f;
		current.g = g;
		current.h = h;
		opened.add(current);
	}

	private bool check(int x, int y) {
		if (x < 0 || x >= width ) return false;
		if (y < 0 || y >= height) return false;
		return !map[y][x];
	}

	private bool check(Node node, int dx, int dy) {
		return check(node.x + dx, node.y + dy);
	}

	private void next(Node current) {
		open(current, -1,  0, 10);
		open(current,  1,  0, 10);
		open(current,  0, -1, 10);
		open(current,  0,  1, 10);

		if (check(current, -1, 0) && check(current, 0, -1)) open(current, -1, -1, 14);
		if (check(current,  1, 0) && check(current, 0, -1)) open(current,  1, -1, 14);
		if (check(current, -1, 0) && check(current, 0,  1)) open(current, -1,  1, 14);
		if (check(current,  1, 0) && check(current, 0,  1)) open(current,  1,  1, 14);
	}
}