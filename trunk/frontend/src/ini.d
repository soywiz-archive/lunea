/*
 *  Lunea preprocessor
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
 *  $Id: ini.d,v 1.1 2006/01/03 23:54:34 soywiz Exp $
 */

module lunea.frontend.ini;

private import std.file, std.string, std.stdio;

class SimpleIni {
	private char[][] lines;

	char[][char[]][char[]] sections;

	void parse() {
		char[] section = "";

		foreach (char[] line; lines) {
			line = strip(line);

			// void
			if (!line.length) continue;
			// comments
			if (line[0] == ';' || line[0] == '#') continue;
			// secction
			if (line[0] == '[') {
				section = tolower(strip(line[1..line.length - 1]));
				continue;
			}

			int pos = void;
			if ((pos = find(line, "=")) == -1) continue;

			char[] name   = tolower(strip(line[0..pos]));
			char[] value  = strip(line[pos + 1..line.length]);

			sections[section][name] = value;
		}
	}

	char[] get(char[] section, char[] name) {
		name    = tolower(strip(name));
		section = tolower(strip(section));

		if ((section in sections)          is null) return "";
		if ((name    in sections[section]) is null) return "";
		return sections[section][name];
	}

	this(char[] file) {
		if (!exists(file)) throw(new Exception("File '" ~ file ~ "' doesn't exists"));
		char[] data = cast(char[])std.file.read(file);
		lines = split(data, "\n");
		parse();
	}
}