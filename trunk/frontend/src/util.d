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
 *  $Id: util.d,v 1.1 2006/01/03 23:54:34 soywiz Exp $
 */

module lunea.frontend.util;

private import std.string, std.file, std.path, std.stdio, std.process;
private import
	lunea.frontend.ini,
	lunea.frontend.config
;

alias char[] string;

char[][] list(char[] path, char[] pattern = "*", bit file = true, bit dir = false, bit tree = false) {
	char[][] retval;

	foreach (char[] cfile; std.file.listdir(path)) {
		char[] fullPath = path ~ "\\" ~ cfile;

		if (isdir(fullPath)) {
			if (dir && std.path.fnmatch(cfile, pattern)) retval ~= fullPath;
			if (tree) retval ~= list(fullPath, pattern, file, dir, tree);
		} else {
			if (file && std.path.fnmatch(cfile, pattern)) retval ~= fullPath;
		}
	}

	return retval;
}


string[] getSrcDFiles(string path, bit tree = false) {
	return list(path, "*.d", true, false, tree);
}

char[] mergePaths(char[] path1, char[] path2) {
	if (!path2.length) return path1;

	// Absolute path
	if ((find(path2, ":") != -1)) {
		return path2;
	}
	// Absolute path without unit
	else if (path2[0] == '\\') {
		int pos = void;
		if ((pos = find(path1, ":")) != -1) {
			return path1[0..pos + 1] ~ "\\" ~ simplifyPath(path2);
		}
		return path2;
	}
	// Relative path
	else {
		return path1 ~ "\\" ~ path2;
	}
}

char[] simplifyPath(char[] path) {
	path = tolower(strip(replace(path, "/", "\\")));

	char[][] npath;
	bit first = true;

	foreach (char[] part; split(path, "\\")) {
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

	return std.string.join(npath, "\\");
}

bit comparePaths(char[] rp1, char[] p1, char[] rp2, char[] p2) {
	char[] r1 = simplifyPath(mergePaths(rp1, p1));
	char[] r2 = simplifyPath(mergePaths(rp2, p2));

	return (r1 == r2);
}

char[] findDmdDirectory() {
	char[] cwdir;
	char[][] resultTest;
	char[] retval = "";

	cwdir = getcwd();
	chdir(appPath);

	try {
		SimpleIni ini = new SimpleIni("lunea.ini");

		resultTest ~= ini.get("paths", "dmd");
	} catch (Exception e) {
	}

	resultTest ~= "\\..\\..\\dmd\\bin";
	resultTest ~= "\\dmd\\bin";

	foreach (char[] result; resultTest) {
		result = mergePaths(appPath, result);
		if (exists(result ~ "\\dmd.exe")) { retval = result; break; }
	}

	chdir(cwdir);

	if (!retval.length) throw(new Exception("No se pudo localizar DMD.exe. Edite el fichero lunea.ini (DMD path)"));

	return retval;
}

char[] findDmcDirectory() {
	char[] cwdir;
	char[][] resultTest;
	char[] retval = "";

	cwdir = getcwd();
	chdir(appPath);

	try {
		SimpleIni ini = new SimpleIni("lunea.ini");

		resultTest ~= ini.get("paths", "dmc");
	} catch (Exception e) {
	}

	resultTest ~= "\\..\\..\\dm\\bin";
	resultTest ~= "\\dm\\bin";

	foreach (char[] result; resultTest) {
		result = mergePaths(appPath, result);
		if (exists(result ~ "\\rcc.exe")) { retval = result; break; }
	}

	chdir(cwdir);

	if (!retval.length) throw(new Exception("No se pudo localizar RCC.exe. Edite el fichero lunea.ini (DMC path)"));

	return retval;
}

void updateDmdScIni(char[] path) {
	char[] inif = path ~ "\\sc.ini";
	char[] lib;

	if (!exists(inif)) throw(new Exception("No se encuentra el fichero '" ~ inif ~ "'"));

	SimpleIni ini = new SimpleIni(inif);

	lib = ini.get("environment", "lib");

	if (!lib.length) throw(new Exception("No se encuentra (o esta vacio) el parametro LIB en el apartado [Enviroment] del fichero '" ~ inif ~ "'"));

	foreach (char[] libpath; split(lib, ";")) {
		libpath = tolower(strip(libpath));
		if (!libpath.length) continue;
		if (libpath[0] == '"') libpath = libpath[1..libpath.length - 1];
		libpath = replace(libpath, "%@p%", path);

		if (comparePaths(path, libpath, appPath, "..\\lib")) {
			// Perfecto! ya esta incluida la libreria
			return;
		}
	}

	// Parece que no esta incluida la libreria

	char[] toadd = ";\"" ~ simplifyPath(appPath ~ "\\..\\lib") ~ "\"";

	char[] data = cast(char[])read(inif);
	char[] led  = "\n";

	char[][] dataw;

	if (find(data, "\r\n") != -1) led = "\r\n";

	foreach (char[] linei; split(data, led))	{
		char[] line = tolower(strip(linei));
		if (line[0..3] == "lib") {
			if (find(line, "=") != -1) {
				dataw ~= linei ~ toadd;
				continue;
			}
		}
		dataw ~= linei;
	}

	write(inif, std.string.join(dataw, led));

	//echoln(toadd);
}

string addslashes(string s) {
	string tohex(ubyte c) {
		string ret;
		ret ~= std.string.hexdigits[c / 16];
		ret ~= std.string.hexdigits[c % 16];
		return ret;
	}

	string rs;

	for (int n = 0; n < s.length; n++) {
		switch (s[n]) {
			case '"' : rs ~= "\\\""; break;
			case '\\': rs ~= "\\\\"; break;
			case '\n': rs ~= "\\n";  break;
			case '\r': rs ~= "\\r";  break;
			case '\t': rs ~= "\\t";  break;
			default:
				if (s[n] < ' ') {
					rs ~= "\\x" ~ tohex(s[n]);
				} else {
					rs ~= s[n];
				}
			break;
		}
	}

	return rs;
}

string[] expandPatterns(string basedir, string[] rpattern) {
	bit[string] repeat;
	string[] resr;

	for (int n = 0; n < rpattern.length; n++) {
		string   rfile   = std.string.tr(rpattern[n], "/", "\\");

		string   pathw   = std.path.getDirName(rfile);
		string   path    = std.string.tr(pathw, "\\", "/");
		string   pattern = std.path.getBaseName(rfile);

		if (!std.string.count(pattern, "*") && !std.string.count(pattern, "?") && !std.string.count(pattern, "[")) {
			string file = path ~ (path.length ? "/" : "") ~ pattern;

			repeat[file] = true;
			resr ~= file;
		} else {
			string[] files   = std.file.listdir(basedir ~ "\\" ~ pathw);

			for (int m = 0; m < files.length; m++) {
				string file = path ~ (path.length ? "/" : "") ~ files[m];
				if (!std.path.fnmatch(files[m], pattern)) continue;
				if ((file in repeat) is null) {
					repeat[file] = true;
					resr ~= file;
				}
			}
		}
	}

	return resr;
}

void removeife(string file) {
	if (std.file.exists(file)) std.file.remove(file);
}

alias std.string.strip   trim;
alias std.string.tolower strtolower;

void echo  (string s) { for (int n = 0; n < s.length; n++) std.c.stdio.fputc(s[n], stdout); }
void echoln(string s) { echo(s ~ "\n"); }

alias std.string.toString cstr;