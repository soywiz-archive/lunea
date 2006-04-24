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
 *  $Id: main.d,v 1.5 2006/02/26 19:00:59 soywiz Exp $
 */

module lunea.frontend.main;

private import std.string, std.file, std.path, std.stdio, std.process, std.zip;

public import
	lunea.frontend.ltoken,
	lunea.frontend.lparser,
	lunea.frontend.util,
	lunea.frontend.config,
	lunea.frontend.compile
;

void showHeader() {
	char[] corev = "unknown", corevp = appPath ~ "/../core/VERSION";
	char[] driversp = appPath ~ "/../core/drivers";
	char[][] drivers;
	if (exists(corevp)) corev = cast(char[])read(corevp);


	echoln("Lunea Preprocessor " ~ feversion ~ " (using Digital Mars compiler)");
	echoln("Copyright (c) " ~ fedate ~ " by Carlos Ballesteros Velasco");
	if (exists(driversp)) {
		foreach (char[] file; std.file.listdir(driversp)) {
			char[] cfile, cver;
			cver = "unknown";
			if (file == "CVS") continue;
			if (!isdir(driversp ~ "/" ~ file)) continue;
			if (exists(cfile = driversp ~ "/" ~ file ~ "/VERSION")) {
				cver = cast(char[])read(cfile);
			}
			drivers ~= file ~ "(" ~ cver ~ ")";
		}
	}

	echo("Core(" ~ corev ~ "); Drivers: " ~ std.string.join(drivers, ", ") ~ "\n");

	echoln("");
}

int main(string[] args) {
	LuneaParser parser = new LuneaParser;
	ushort fcount = 0;

	showHeader();
	compileInit();

	foreach (char[] cfile; list("src", "*.lun", true, false, true)) {
		parser.parseFile(cfile, cast(char[])read(cfile)); fcount++;
	}

	if (fcount == 0) {
		foreach (char[] cfile; list(".", "*.lun", true, false, false)) {
			parser.parseFile(cfile, cast(char[])read(cfile)); fcount++;
		}
	}

	if (fcount != 0) {
		parser.processConfig();
		foreach (char[] library; parser.libraries) {
			char[] file;
			if (exists(file = appPath ~ "\\..\\lib\\lunea\\" ~ library)) {
				foreach (char[] cfile; list(file, "*.lun", true, false, true)) {
					parser.parseFile(cfile, cast(char[])read(cfile));
				}
				continue;
			}

			if (!exists(file = "lib\\" ~ library ~ ".zip")) {
				if (!exists(file = appPath ~ "\\..\\lib\\lunea\\" ~ library ~ ".zip")) {
					throw(new Exception("No se pudo cargar la libreria '" ~ library ~ "'"));
					continue;
				}
			}
			//echoln(":" ~ file);
			ZipArchive za = new ZipArchive(read(file));
			foreach (ArchiveMember am; za.directory) {
				if (!std.path.fnmatch(am.name, "*.lun")) continue;
				parser.parseFile(file ~ "#" ~ am.name, cast(char[])za.expand(am)); fcount++;
			}
		}
	}

	if (!fcount) throw(new Exception("No hay ficheros de Lunea (*.lun) en el directorio '.\\src' para compilar."));
	if (!parser.hasProgram) throw(new Exception("No se ha definido el bloque program { }"));

	parser.parseFinish();

	string[] resources2 = expandPatterns("res", parser.resources);
	string[] resources;

	foreach (char[] cres; resources2) {
		bool cadd = true;
		foreach (char[] mres; resources) {
			if (cres == mres) { cadd = false; break; }
		}
		if (cadd) resources ~= cres;
	}

	if (!compileResources(parser.config, resources)) return -1;
	if (!compileProgram  (parser,        resources)) return -1;

	writef("\nImports:\n");
	foreach (char[] key, bit value; parser.imports) {
		echo("\t" ~ key ~ "\n");
	}

	writef("\nConfiguracion:\n");
	foreach (char[] key, char[] value; parser.config) {
		echo("\t" ~ toupper(key) ~ ": '");
		echo(value ~ "'\n");
	}

	if (resources.length) {
		writef("\nRecursos:\n");
		foreach (char[] value; resources) {
			echo("\t" ~ value ~ "\n");
		}
	}

	if (parser.libraries.length) {
		writef("\nLibrerias:\n");
		foreach (char[] value; parser.libraries) {
			echo("\t" ~ value ~ "\n");
		}
	}

	return 0;
}