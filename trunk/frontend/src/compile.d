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
 *  $Id: compile.d,v 1.5 2006/04/24 17:34:44 soywiz Exp $
 */

module lunea.frontend.compile;

private import std.stdio, std.file, std.path, std.string, std.process;

private import
	lunea.frontend.lparser,
	lunea.frontend.util,
	lunea.frontend.config;

char[] dmcpath, dmdpath;

void compileInit() {
	try {
		dmdpath = findDmdDirectory();
		dmcpath = findDmcDirectory();
		updateDmdScIni(dmdpath);
	} catch (Exception e) {
		system(appPath ~ "\\start.html");
	}
}

bool compileResources(string[string] config, string[] resources) {
	writef("Compilando recursos...");

	bool retval = true;
	bool vdebug = (trim(strtolower(config["debug"])) != "false");
	string resource;

	// Deshabilitado el debug (temporalmente)
	vdebug = false;

	resource ~= "#include <windows.h>\n\n";

	if (config["icon"].length && std.file.exists("res\\" ~ config["icon"])) {
		resource ~= "icon ICON DISCARDABLE \"" ~ addslashes("res\\" ~ config["icon"]) ~ "\"\n";
	}

	for (int n = 0; n < resources.length; n++) {
		string filename = std.string.tr(resources[n], "/", "\\");
		resource ~= std.string.toString(101 + n) ~ " RCDATA	 PRELOAD \"" ~ addslashes("res\\" ~ filename) ~ "\"\n";
	}

	resource ~= (
		"\n"
		"VS_VERSION_INFO VERSIONINFO\n"
		"FILEVERSION 1,0,0,1\n"
		"PRODUCTVERSION 1,0,0,1\n"
		"FILEFLAGSMASK 0x17L\n"
		"FILEFLAGS 0x" ~ (vdebug ? "1" : "0") ~ "L\n"
		"FILEOS 0x4L\n"
		"FILETYPE 0x1L\n"
		"FILESUBTYPE 0x0L\n"
		"BEGIN\n"
		"\tBLOCK \"StringFileInfo\"\n"
		"\tBEGIN\n"
		"\t\tBLOCK \"0c0a04b0\"\n"
		"\t\tBEGIN\n"
		"\t\t\tVALUE \"Comments\",         \"" ~ addslashes(config["comments"])        ~ "\"\n"
		"\t\t\tVALUE \"CompanyName\",      \"" ~ addslashes(config["companyname"])     ~ "\"\n"
		"\t\t\tVALUE \"FileDescription\",  \"" ~ addslashes(config["filedescription"]) ~ "\"\n"
		"\t\t\tVALUE \"FileVersion\",      \"" ~ addslashes(config["fileversion"])     ~ "\"\n"
		"\t\t\tVALUE \"InternalName\",     \"" ~ addslashes(config["internalname"])    ~ "\"\n"
		"\t\t\tVALUE \"LegalCopyright\",   \"" ~ addslashes(config["legalcopyright"])  ~ "\"\n"
		"\t\t\tVALUE \"LegalTrademarks\",  \"" ~ addslashes(config["legaltrademarks"]) ~ "\"\n"
		"\t\t\tVALUE \"OriginalFilename\", \"" ~ addslashes(config["output"])          ~ "\"\n"
		"\t\t\tVALUE \"ProductName\",      \"" ~ addslashes(config["productname"])     ~ "\"\n"
		"\t\t\tVALUE \"ProductVersion\",   \"" ~ addslashes(config["productversion"])  ~ "\"\n"
		"\t\tEND\n"
		"\tEND\n"
		"\tBLOCK \"VarFileInfo\"\n"
		"\tBEGIN\n"
		"\t\tVALUE \"Translation\", 0xc0a, 1200\n"
		"\tEND\n"
		"END\n"
	);

	string tempf  = "~outputrc.txt";
	string temprc = "~temp";
	string path;

	if (find(dmcpath, ":") == -1 || (dmcpath.length > 0 && dmcpath[0] == '\\')) {
		path = appPath ~ "\\" ~ dmcpath;
	} else {
		path = dmcpath;
	}

	string rcc = path ~ "\\rcc.exe";

	if (!std.file.exists(rcc)) {
		writefln("Error");

		writefln("\tNo se pudo encontrar el programa RCC.exe en '" ~ rcc ~ "'");

		return false;
	}

	write(temprc ~ ".rc", resource);

	if (system(rcc ~ " " ~ temprc ~ ".rc -32 > " ~ tempf) != 0) {
		writefln("Error");

		if (!std.file.exists(tempf)) goto cr_end;

		string[] lines = split(cast(string)std.file.read(tempf), "\n");

		for (int n = 0; n < lines.length; n++) {
			string line = trim(lines[n]);
			if (n < lines.length && trim(lines[n + 1]) == "^") { n++; continue; }
			if (!line.length) continue;
			writefln("\t" ~ lines[n]);
		}

		retval = false;
	} else {
		writefln("Ok");
	}

	cr_end:

	removeife(temprc ~ ".rc");
	removeife(tempf);

	return retval;
}

bool compileProgram(LuneaParser parser, string[] resources) {
	string[string] config = parser.config;
	string         data   = parser.result;

	bool vdebug = (trim(strtolower(config["debug"])) != "false");
	bool vtemp = (trim(strtolower(config["temp"])) != "false");

	writef("Compilando programa...");

	string resourcestr;

	resourcestr ~= "void __resource_loader() {\n";
	resourcestr ~= "\ttitle = \"" ~ addslashes(config["title"]) ~ "\";\n";

	for (int n = 0; n < resources.length; n++) {
		//__resource_list["name"] = 101;
		resourcestr ~= "\tlunea.Resource.__resource_list[\"" ~ addslashes(resources[n]) ~ "\"] = " ~ std.string.toString(101 + n) ~ ";\n";
	}

	for (int n = 0; n < parser.interactionsType.length; n++) {
		string type   = parser.interactionsType[n];
		string value1 = parser.interactionsValue1[n];
		string value2 = parser.interactionsValue2[n];
		string func = parser.interactionsFunctions[n];

		resourcestr ~= "\tinteractions.add(\"" ~ type ~ "\", " ~ value1 ~ ".classinfo, " ~ value2 ~ ".classinfo, &" ~ func ~ ");\n";
	}

	resourcestr ~= "}\n\n";

	data ~= resourcestr;

	bool   retval   = true;
	string ppath    = appPath;
	string tempdf   = "~temp.d";
	string tempf    = "~output.txt";
	string fileName = std.string.split(config["output"], ".")[0];

	if (!std.file.exists(ppath ~ "\\..\\core\\drivers\\" ~ config["driver"])) {
		writefln("Error");

		writefln("\tEl driver '" ~ config["driver"] ~ "' no existe");

		return false;
	}

	string parameters;

	parameters ~= tempdf;

	foreach (string dfile; getSrcDFiles(simplifyPath(ppath ~ "\\..\\core"), false) ~ getSrcDFiles(simplifyPath(ppath ~ "\\..\\core\\drivers\\" ~ config["driver"]), true) ~ getSrcDFiles(simplifyPath(ppath ~ "\\..\\core\\std"), true)) {
		//dfile = simplifyPath(dfile);
		parameters ~= " \"" ~ dfile ~ "\"";
	}

	parameters ~= " ~temp.res";
	parameters ~= " -of\"" ~ fileName ~ "\"";
	parameters ~= " -release";
	parameters ~= " -O";
	parameters ~= " -d";
	//parameters ~= " -w";

	string link = "";

	if (config["console"].length) {
		if (trim(strtolower(config["console"])) == "false") {
			link ~= "/exet:nt/su:windows:4.0";
		}
	}

	if (link.length) parameters ~= " -L" ~ link;

	parameters ~= " -quiet > " ~ tempf;

	string path;

	if (find(dmdpath, ":") == -1 || (dmdpath.length > 0 && dmdpath[0] == '\\')) {
		path = appPath ~ "\\" ~ dmdpath;
	} else {
		path = dmdpath;
	}

	string dmd = path ~ "\\dmd.exe";

	if (!std.file.exists(dmd)) {
		writefln("Error");

		writefln("\tNo se pudo encontrar el comando dmd en '" ~ dmd ~ "'");

		return false;
	}

	//echo(data); return 0;

	write(tempdf, data);

	if (vdebug) parameters = "-profile -cov " ~ parameters;

	if (system(dmd ~ " " ~ parameters) != 0) {
		writefln("Error");

		if (!std.file.exists(tempf)) goto cp_end;

		string[] lines = split(cast(string)std.file.read(tempf), "\n");

		for (int n = 0; n < lines.length; n++) {
			string line = trim(lines[n]);
			if (n < lines.length && trim(lines[n + 1]) == "^") { n++; continue; }
			if (!line.length) continue;
			writefln("\t" ~ line);
		}

		retval = false;
	} else {
		writefln("Ok");
	}

	string[] files = std.file.listdir(std.file.getcwd());
	for (int n = 0; n < files.length; n++) {
		if (!std.path.fnmatch(files[n], "*.obj")) continue;
		std.file.remove(files[n]);
	}

	if (retval) {
		char[] upx = appPath ~ "\\upx.exe";
		if (config["compress"] != "false") {
			writef("Comprimiendo ejecutable...");
			if (exists(upx)) {
				if (system(upx ~ " --force " ~ fileName ~ ".exe > " ~ tempf) == 0) {
					writefln("Ok");
				} else {
					writefln("Error");
				}
			} else {
				writefln("UPX Not Found");
			}
		}
	}

	cp_end:

	if (!vtemp) removeife(tempdf);
	removeife(tempf);
	removeife("~temp.res");
	removeife(fileName ~ ".map");

	return retval;
}
