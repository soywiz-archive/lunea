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
 *  $Id: Uri.d,v 1.1 2006/01/03 23:54:33 soywiz Exp $
 */

module lunea.std.Uri;

private import lunea.std.String;

private import std.string, std.stdio;

// RFC 2396 - Uniform Resource Identifiers (URI): Generic Syntax
class Uri {
	char[] unit;
	char[] scheme;
	char[] authority;
	char[] path;
	char[] query;
	char[] fragment;

	bool   absolute;
	char   pathSeparator;

	this(Uri uri) {
		with (this) {
			unit      = uri.unit;
			scheme    = uri.scheme;
			authority = uri.authority;
			path      = uri.path;
			query     = uri.query;
			fragment  = uri.fragment;
			absolute  = uri.absolute;
			pathSeparator = uri.pathSeparator;
		}
	}

	this(char[] uri) {
		int p;

		pathSeparator = '/';
		if ((p = String.indexOf(uri, "://")) != -1) {
			absolute = true;

			scheme = uri[0..p];
			uri    = uri[p + 3..uri.length];

			if ((p = String.indexOf(uri, "/")) != -1) {
				authority = uri[0..p];
				uri       = uri[p..uri.length];
			}
		} else if ((p = String.indexOf(uri, ":")) != -1) {
			absolute = true;

			if (p == 1) {
				unit = uri[0..p];
				uri  = uri[p + 1..uri.length];
			}
		} else {
			absolute = false;
		}

		if ((p = String.indexOf(uri, "#")) != -1) {
			fragment = uri[p + 1..uri.length];
			uri      = uri[0..p];
		}

		if ((p = String.indexOf(uri, "?")) != -1) {
			query = uri[p + 1..uri.length];
			uri   = uri[0..p];
		}

		if (String.indexOf(uri, "\\") != -1) pathSeparator = '\\';
		path = replace(uri, "\\", "/");
	}

	void dump() {
		writefln("unit: " ~ unit);
		writefln("scheme: " ~ scheme);
		writefln("authority: " ~ authority);
		writefln("path: " ~ path);
		writefln("query: " ~ query);
		writefln("fragment: " ~ fragment);
	}

	char[] toString() {
		char[] retval;

		if (absolute) {
			if (unit.length) {
				retval ~= unit ~ ":";
				if (path.length && path[0] != '/') retval ~= pathSeparator;
			} else {
				if (scheme.length) retval ~= scheme ~ "://";
				if (authority.length) {
					retval ~= authority;
					if (path.length && path[0] != '/') retval ~= pathSeparator;
				}
			}
		}

		if (path.length    ) {
			retval ~= replace(path, "/", "\\");
		}
		if (query.length   ) retval ~= "?" ~ query;
		if (fragment.length) retval ~= "#" ~ fragment;

		return retval;
	}

	/*static char[] merge(char[] path1, char[] path2) {
		if (!path2.length) return path1;

		// Absolute path
		if ((find(path2, ":") != -1)) {
			return path2;
		}
		// Absolute path without unit
		else if (path2[0] == '\\') {
			int pos = void;
			if ((pos = find(path1, ":")) != -1) {
				return path1[0..pos + 1] ~ "\\" ~ simplify(path2);
			}
			return path2;
		}
		// Relative path
		else {
			return path1 ~ "\\" ~ path2;
		}
	}*/

	static char[] simplify(char[] path) {
		path = tolower(strip(replace(path, "\\", "/")));

		char[][] npath;
		bool first = true;

		foreach (char[] part; split(path, "/")) {
			part = strip(part);
			if (!first && !part.length) {
				first = false;
				continue;
			}

			first = false;

			if (part == ".") continue;
			if (part == "..") {
				if (npath.length) npath.length = npath.length - 1;
				continue;
			}

			npath ~= part;
		}

		return std.string.join(npath, "/");
	}

	static Uri simplify(Uri uri) {
		Uri nuri = new Uri(uri);
		nuri.path = simplify(nuri.path);
		return uri;
	}

	/*static bool compare(char[] rp1, char[] p1, char[] rp2, char[] p2) {
		char[] r1 = simplify(merge(rp1, p1));
		char[] r2 = simplify(merge(rp2, p2));

		return (r1 == r2);
	}*/

	static bool compare(Uri u1, Uri u2) {
		if (simplify(u1).path != simplify(u2).path) return false;
		if (u1.absolute != u2.absolute) return false;
		if (u1.unit != u2.unit) return false;
		if (u1.scheme != u2.scheme) return false;
		if (u1.authority != u2.authority) return false;
		if (u1.query != u2.query) return false;
		if (u1.fragment != u2.fragment) return false;

		return true;
	}

	int opEquals(Uri o) {
		return compare(this, o);
	}
}