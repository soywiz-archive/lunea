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
 *  $Id: File.d,v 1.5 2006/01/15 03:38:59 soywiz Exp $
 */

module lunea.std.File;

private import
	lunea.std.String,
	lunea.std.Uri
;

private import std.string, std.stdio, std.file, std.c.stdio;

class File {
	FILE *fd;
	Uri uri;

	void open(char[] uris, char[] mode) {
		uri = new Uri(uris);
		switch (String.toLowerCase(uri.scheme)) {
			case "http":
				throw(new Exception("HTTP protocol not implemented yet"));
			break;
			case "ftp":
				throw(new Exception("FTP protocol not implemented yet"));
			break;
			default:
				throw(new Exception(String.toUpperCase(uri.scheme) ~ " protocol unknown"));
			break;
			case "": {
				char[] fname = uri.toString;

				if (!exists(fname) || (fd = fopen(toStringz(fname), toStringz(mode))) is null) {
					throw(new Exception("File '" ~ fname ~ "' can't open with mode '" ~ mode ~ "'"));
				}
			} break;
		}
	}

	void close() {
		if (fd !is null) fclose(fd);
	}

	char[] fread(int length) {
		char[] retval;
		return retval;
	}

	this(char[] uri, char[] flags) {
		open(uri, flags);
	}

	static bool exists(char[] uris) {
		return std.file.exists(uris) != 0;
	}

	static void rename(char[] uri1, char[] uri2) {
		std.file.rename(uri1, uri2);
	}

	static void copy(char[] uri1, char[] uri2) {
		std.file.copy(uri1, uri2);
	}

	static void remove(char[] uris) {
		std.file.remove(uris);
	}

	static bool isFile(char[] uris) {
		return std.file.isfile(uris) != 0;
	}

	static bool isDirectory(char[] uris) {
		return std.file.isdir(uris) != 0;
	}
}