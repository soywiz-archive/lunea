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

public alias char[] string;

static class String {
	static char charAt(string s, int index) { return s[index]; }

	static string substr(string s, int start, int length) { if (length < 0) length = s.length + length; return s[start..s.length - length]; }
	static string substr(string s, int start) { return s[start..s.length]; }

	static string concat(string s1, string s2) { return s1 ~ s2; }

	static string toLowerCase(string s) { return std.string.tolower(s); }
	static string toUpperCase(string s) { return std.string.toupper(s); }

	static string copyValueOf(string data, int offset = 0, int count = 0) { return data[offset..count]; }

	static string trim   (string s) { return std.string.strip (s); }
	static string ltrim  (string s) { return std.string.stripl(s); }
	static string rtrim  (string s) { return std.string.stripr(s); }

	static string valueOf(bool   v) { return v ? "true" : "false"; }
	static string valueOf(char   v) { return std.string.toString(v); }
	static string valueOf(string v) { return v; }
	static string valueOf(int    v) { return std.string.toString(v); }
	static string valueOf(uint   v) { return std.string.toString(v); }
	static string valueOf(real   v) { return std.string.toString(v); }
	static string valueOf(ireal  v) { return std.string.toString(v); }
	static string valueOf(Object v) { return v.toString(); }

	static int    indexOf(string s1, string s2, int fromIndex = 0) { int to = s1.length - s2.length; for (int n = fromIndex; n <= to; n++) if (s1[n..n + s2.length] == s2) return n; return -1; }
	static int    lastIndexOf(string s1, string s2, int fromIndex = -1) { if (fromIndex == -1) fromIndex = s2.length - 1; if (fromIndex + s2.length > s1.length) fromIndex = s1.length -  s2.length; for (int n = fromIndex; n >= 0; n--) if (s1[n..n + s2.length] == s2) return n; return -1; }

	static int    length(string s) { return s.length; }
}

void echo  (string s) { for (int n = 0; n < s.length; n++) std.c.stdio.fputc(s[n], stdout); }
void echoln(string s) { echo(s ~ "\n"); }
