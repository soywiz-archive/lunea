/*
 *  Lunea library
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
 *  $Id: String.d,v 1.4 2006/02/16 16:32:41 soywiz Exp $
 */

module lunea.std.String;

private import std.string, std.c.stdio;

//public alias char[] string;

static class String {
	static char charAt(char[] s, int index) { return s[index]; }

	static char[] substr(char[] s, int start, int l) { if (l < 0) l = s.length + l; return s[start..s.length - l]; }
	static char[] substr(char[] s, int start) { return s[start..s.length]; }

	static char[] concat(char[] s1, char[] s2) { return s1 ~ s2; }

	static char[] toLowerCase(char[] s) { return std.string.tolower(s); }
	static char[] toUpperCase(char[] s) { return std.string.toupper(s); }

	static char[] copyValueOf(char[] data, int offset = 0, int count = 0) { return data[offset..count]; }

	static char[] trim   (string s) { return std.string.strip (s); }
	static char[] ltrim  (string s) { return std.string.stripl(s); }
	static char[] rtrim  (string s) { return std.string.stripr(s); }

	static char[] valueOf(bool   v) { return v ? "true" : "false"; }
	static char[] valueOf(char   v) { return std.string.toString(v); }
	static char[] valueOf(string v) { return v; }
	static char[] valueOf(int    v) { return std.string.toString(v); }
	static char[] valueOf(uint   v) { return std.string.toString(v); }
	static char[] valueOf(real   v) { return std.string.toString(v); }
	static char[] valueOf(ireal  v) { return std.string.toString(v); }
	static char[] valueOf(Object v) { return v.toString(); }

	static int    indexOf(char[] s1, char[] s2, int fromIndex = 0) { int to = s1.length - s2.length; for (int n = fromIndex; n <= to; n++) if (s1[n..n + s2.length] == s2) return n; return -1; }
	static int    lastIndexOf(char[] s1, char[] s2, int fromIndex = -1) { if (fromIndex == -1) fromIndex = s2.length - 1; if (fromIndex + s2.length > s1.length) fromIndex = s1.length -  s2.length; for (int n = fromIndex; n >= 0; n--) if (s1[n..n + s2.length] == s2) return n; return -1; }

	static int    length(char[] s) { return s.length; }
}

void echo  (char[] s) { for (int n = 0; n < s.length; n++) std.c.stdio.fputc(s[n], stdout); }
void echoln(char[] s) { echo(s ~ "\n"); }
