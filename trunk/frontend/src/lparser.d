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
 *  $Id: lparser.d,v 1.5 2006/02/16 18:39:12 soywiz Exp $
 */

module lunea.frontend.lparser;

private import std.stdio, std.string;

private import
	lunea.frontend.ltoken,
	lunea.frontend.util;

class LuneaParser {
	private string[]       configKeys, configValues;
	public  string[]       interactionsType, interactionsValue1, interactionsValue2, interactionsFunctions;
	public  string[string] config;
	public  bit[string]    imports;
	public  bit[string]    parsed;
	public  string[]       resources;
	public  string[]       libraries;
	public  string         result;
	public  bool           hasProgram = false;

	private void pushConfig(string name, string value) {
		configKeys   ~= name;
		configValues ~= value;
	}

	private void pushImport(string name) {
		imports[name] = true;
	}

	private void pushLibrary(string name) {
		libraries ~= name;
	}

	private void pushResource(string name) {
		resources ~= name;
	}

	public this() {
		config["title"]           = "Untitled";
		config["driver"]          = "default";
		config["icon"]            = "";
		config["companyname"]     = "";
		config["comments"]        = "No comments";
		config["filedescription"] = "No comments";
		config["fileversion"]     = "1, 0, 0, 0";
		config["internalname"]    = "unnamed";
		config["legalcopyright"]  = "";
		config["legaltrademarks"] = "";
		config["productname"]     = "unnamed";
		config["productversion"]  = "1, 0, 0, 0";
		config["console"]         = "true";
		config["output"]          = "output";
		config["debug"]           = "false";
		config["compress"]        = "false";
		config["temp"]            = "false";

		imports["std.string"]     = true;
		imports["std.stdio"]      = true;
	}

	public void parseFile(string filename, string code) {
		int opn0 = 0, opn1 = 0, opn2 = 0;
		auto lt = new LTokenizer(code);
		LToken token, token2, token3;
		bool action_main = true;
		char[] action_main_name;

		if ((filename in parsed) !is null) return;
		parsed[filename] = true;

		void throwfe(char[] str) {
			char[] adds = filename;
			if (lt.current) adds ~= "(" ~ std.string.toString(lt.current.line) ~ ")";
			throw(new Exception(adds ~ ": " ~ str));
		}

		try {
			while ((token = lt.current) !is null) {
				switch (token.value) {
					case "(":
						opn0++;
					break;
					case ")":
						if (opn0 <= 0) throw(new Exception("Error: " ~ __FILE__ ~ "(" ~ std.string.toString(__LINE__) ~ ")"));
						opn0--;
					break;
					case "[":
						opn1++;
					break;
					case "]":
						if (opn1 <= 0) throw(new Exception("Error: " ~ __FILE__ ~ "(" ~ std.string.toString(__LINE__) ~ ")"));
						opn1--;
					break;
					case "{":
						opn2++;
					break;
					case "}":
						if (opn2 <= 0) throw(new Exception("Error: " ~ __FILE__ ~ "(" ~ std.string.toString(__LINE__) ~ ")"));
						opn2--;
					break;
					case "config":
						if (opn2 != 0) break;

						token.value = "";

						if (lt.next.value != "{") throw(new Exception("Se esperaba { despues del bloque config"));
						lt.current.value = "";
						lt.next();

						while ((token = lt.current) !is null) {
							switch (token.value) {
								case "}":
									token.value = "";
									goto config_continue1;
								default:
									if (token.type != LToken.ttype.identifier) throw(new Exception("Se esperaba un identificador dentro del bloque config"));
									string cv = lt.next.value;
									if (cv != ":" && cv != "=") throw(new Exception("Se esperaba : despues de identificador en bloque config"));
									lt.current.value = "";
									token2 = lt.next;
									switch (token2.type) {
										case LToken.ttype.string:
										case LToken.ttype.number:
										case LToken.ttype.identifier:
										break;
										default:
											throw(new Exception("Se esperaba una cadena despues de :"));
										break;
									}
									if (lt.next.value != ";") throw(new Exception("Se esperaba ; para separar identificadores"));
									lt.current.value = "";
									pushConfig(token.value, token2.rvalue);
									token.value = token2.value = "";
								break;
							}
							lt.current.value = "";
							lt.next();
						}

						throw(new Exception("No se cerro el } del bloque Config"));

						config_continue1:
					break;
					case "program":
						if (opn2 != 0) break;

						if (!action_main) throw(new Exception("El proceso '" ~ action_main_name ~ "' no define un action main { }"));

						hasProgram = true;
						token.value = "class MainProcess : Process";

						action_main = false; action_main_name = "program";
					break;
					case "process":
						if (opn2 != 0) break;

						if (!action_main) throw(new Exception("El proceso '" ~ action_main_name ~ "' no define un action main { }"));

						token2 = lt.next;
						if (token2.type != LToken.ttype.identifier) throw(new Exception("Se esperaba un identificador despues de process"));

						token.value = "class " ~ token2.value ~ " : Process";

						action_main = false; action_main_name = token2.value;

						token2.value = "";
					break;
					case "action":
						if (opn2 >= 2) {
							if (lt.next.value != "(") throw(new Exception("Se esperaba ("));
							lt.current.value = "";

							token2 = lt.next;
							if (token2.type != LToken.ttype.identifier) throw(new Exception("Se esperaba un identificador despues de program"));

							if (lt.next.value != ")") throw(new Exception("Se esperaba )"));
							lt.current.value = "";

							if (lt.next.value != ";") throw(new Exception("Se esperaba ;"));
							lt.current.value = "";

							token.value = "return cast(void)(this.paction = &" ~ token2.value ~ ");";
							token2.value = "";
						} else if (opn2 == 1) {
							token2 = lt.next;
							if (token2.type != LToken.ttype.identifier) throw(new Exception("Se esperaba un identificador despues de program"));

							if (token2.value == "main") {
								action_main = true;
							}

							token.value = "void " ~ token2.value ~ "()";
							token2.value = "";
						}
					break;
					// collision(Type1, Type2)
					case "collision":
						if (opn2 == 0) {
							char[] type1, type2;
							char[] name1, name2;

							if (lt.next.value != "(") throw(new Exception("Se esperaba ("));
							lt.current.value = "";

							if (lt.next.type != LToken.ttype.identifier) throw(new Exception("Se esperaba un identificador despues de collision"));
							type1 = lt.current.value;
							lt.current.value = "";

							if (lt.next.type != LToken.ttype.identifier) throw(new Exception("Se esperaba un identificador despues de collision"));
							name1 = lt.current.value;
							lt.current.value = "";

							if (lt.next.value != ",") throw(new Exception("Se esperaba ,"));
							lt.current.value = "";

							if (lt.next.type != LToken.ttype.identifier) throw(new Exception("Se esperaba un identificador despues de collision"));
							type2 = lt.current.value;
							lt.current.value = "";

							if (lt.next.type != LToken.ttype.identifier) throw(new Exception("Se esperaba un identificador despues de collision"));
							name2 = lt.current.value;
							lt.current.value = "";

							if (lt.next.value != ")") throw(new Exception("Se esperaba )"));
							lt.current.value = "";

							if (lt.next.value != "{") throw(new Exception("Se esperaba {"));
							lt.current.value = "";

							opn2++;

							interactionsType      ~= "collision";
							interactionsValue1    ~= type1;
							interactionsValue2    ~= type2;
							interactionsFunctions ~= "collision_" ~ type1 ~ "_" ~ type2;

							token.value = "bool collision_" ~ type1 ~ "_" ~ type2 ~ "(Process _p1, Process _p2) { " ~ type1 ~ " " ~ name1 ~ " = cast(" ~ type1 ~ ")_p1; " ~ type2 ~ " " ~ name2 ~ " = cast(" ~ type2 ~ ")_p2;";
						}
					break;
					default:
					break;
				}

				lt.next();
			}
		} catch (Exception e) {
			throwfe(e.toString);
		}

		if (!action_main) throwfe("El proceso '" ~ action_main_name ~ "' no define un action main { }");

		char[] rfilename = filename;
		if (rfilename.length > 2 && rfilename[0..2] == ".\\") {
			rfilename = filename[2..rfilename.length];
		}
		result ~= "#""line 1 \"" ~ rfilename ~ "\"\n" ~ lt.value ~ "\n";
	}

	public void parseFinish() {
		processConfig();
		preppendFinal();
		appendFinal();
	}

	public void processConfig() {
		//resources.length = 0;
		libraries.length = 0;

		for (int n = 0; n < configValues.length; n++) {
			switch (configKeys[n]) {
				case
				"title", "driver", "icon", "comments", "companyname",
				"filedescription", "fileversion", "internalname",
				"legalcopyright", "legaltrademarks", "productname",
				"productversion", "console", "output", "compress",
				"debug", "temp":

					config[configKeys[n]] = configValues[n];
				break;
				case "resource": pushResource(configValues[n]); break;
				case "library":  pushLibrary (configValues[n]); break;
				case "import":   pushImport  (configValues[n]); break;
				default:
					throw(new Exception("El parametro de configuracion '" ~ configKeys[n] ~ "' es invalido"));
				break;
			}
		}
	}

	private void preppendFinal() {
		string prep;

		pushImport("lunea.Lunea");
		pushImport("lunea.Process");
		//pushImport("lunea.Interactions");
		pushImport("lunea.driver.Main");
		pushImport("lunea.std.All");

		prep ~=
			"#""line 0 \"module\"\n"
			"module lunea.Program;\n\n"
			"#""line 0 \"import\"\n"
		;

		//foreach (string name, bool b; imports) prep ~= "public import " ~ name ~ ";";
		if (imports.length) prep ~= "import " ~ join(imports.keys, ", ") ~ ";\n\n";

		prep ~=
			"#""line 0 \"main\"\n"
			"int main(string[] args) {\n"
			"\ttry {\n"
			"\t\t__resource_loader();\n"
			"\t\treturn pmanager.start(args, new MainProcess);\n"
			"\t} catch (Exception e) {\n"
			"\t\twritefln(e.toString);\n"
			"\t}\n"
			"\treturn -1;\n"
			"}\n\n"
		;

		result = prep ~ result;
	}

	private void appendFinal() {
		result ~= "\n#""line 0 \"unknown\"\n";
	}
}