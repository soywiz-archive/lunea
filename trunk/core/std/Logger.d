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
 *  $Id: Logger.d,v 1.2 2006/01/06 02:17:01 soywiz Exp $
 */

module lunea.std.Logger;

private import std.file;

static class Logger {
	static bool initialized = false;
	static char[] fname = "debug.txt";

	static void add(char[] line, int level = 0) {
		if (!initialized) {
			write(fname, line);
			initialized = true;
		} else {
			append(fname, "\r\n" ~ std.string.repeat("\t", level) ~ line);
		}
	}
}