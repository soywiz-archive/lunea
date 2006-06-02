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
 *  $Id: ltoken.d,v 1.3 2006/01/07 13:00:40 soywiz Exp $
 */

module lunea.frontend.ltoken;

private import std.file, std.stdio, std.c.stdio, std.string, std.ctype, std.conv;

private import lunea.frontend.util;

class LToken {
	bool ignore;

	enum ttype {
		operator,
		identifier,
		string,
		number,
		ignored,
	};

	ttype type;

	bool identifier = false;
	bool numeric = false;
	int line;
	char[] value;

	this(char[] value, int line, bool ignore = false, ttype type = ttype.operator) {
		this.value  = value;
		this.ignore = ignore;
		this.line   = line;
		this.type   = type;
	}

	char[] rvalue() {
		if (type != ttype.string) return value;
		// FIXME
		//if (value[0] == '"' || value[0] == '\'') return value[1..value.length - 1];

		char[] retval;
		int p = 0;
		while (p < value.length) {
			if (value[p] == '"' || value[p] == '\'') {
				char cvalue = value[p];
				p++;
				while (p < value.length) {
					char c = value[p];
					if (c == '\\') {
						c = value[++p];
						switch (c) {
							case 'n': c = '\n'; break;
							case 'r': c = '\r'; break;
							case 't': c = '\t'; break;
							case '0':
								// FIXME
							break;
							default:
								// FIXME
							break;
						}
					} else if (c == cvalue) {
						break;
					}
					retval ~= c; p++;
				}
			}
			p++;
		}

		return retval;
	}
}

class LTokenizer {
	char[] code;
	LToken[] tokens;
	int ptoken;
	int lastline;

	this(char[] code) {
		this.code = code;
		parse();
		reset();
	}

	static LTokenizer fromFile(char[] fname) {
		return new LTokenizer(cast(char[])std.file.read(fname));
	}

	void dump() {
		foreach (LToken token; tokens) {
			echo(token.value);
		}
	}

	char[] value() {
		char[] retval;
		foreach (LToken token; tokens) retval ~= token.value;
		return retval;
	}

	void reset() {
		ptoken = -1;
		next();
	}

	LToken first() {
		reset();
		return current();
	}

	LToken next() {
		while (true) {
			ptoken++;
			if (ptoken >= tokens.length) return null;
			if (tokens[ptoken].ignore) continue;
			return tokens[ptoken];
		}
	}

	LToken current() {
		if (ptoken < 0 || ptoken >= tokens.length) return null;
		return tokens[ptoken];
	}

	void parse() {
		int line = 1, cline;
		int p = 0, p1;

		void push(LToken.ttype type = LToken.ttype.operator) {
			tokens ~= new LToken(code[p1..p], cline, false, type);
		}

		void pushIgnore() {
			tokens ~= new LToken(code[p1..p], cline, true, LToken.ttype.ignored);
		}

		try {
			// To avoid problems
			code ~= "\xff\xff\xff\xff\xff\xff\xff\xff";

			while (p < code.length) {
				cline = line;
				p1 = p;
				//writefln(code[p] ~ code[p + 1]);
				switch (code[p]) {
					case ' ', '\n', '\r', '\v', '\t', '\f':
						while (p < code.length) {
							switch (code[p]) {
								case '\n': line++; break;
								case ' ', '\r', '\v', '\t', '\f': break;
								default: goto parseln1;
							}
							p++;
						}
						parseln1:
						pushIgnore();
						//writefln("-->" ~ code[p]);
					break;
					case '/':
						switch (code[++p]) {
							case '=':
								p++;
								push();
							break;
							case '/':
								p++;
								while (p < code.length) {
									if (code[p++] == '\n') {
										line++;
										break;
									}
								}
								pushIgnore();
							break;
							case '+': {
								int nest = 0;
								++p;
								while (p < code.length) {
									if (code[p] == '\n') line++;

									if (code[p] == '+') {
										++p;
										if (code[p] == '/') {
											++p;
											--nest;
											if (nest < 0) break;
										}
									} else if (code[p] == '/') {
										++p;
										if (code[p] == '+') {
											++p;
											++nest;
										}
									} else ++p;
								}
								pushIgnore();
							} break;
							case '*':
								++p;
								while (p < code.length) {
									if (code[p] == '\n') ++line;

									if (code[p] == '*') {
										++p;
										if (code[p] == '/') {
											++p;
											break;
										}
									} else ++p;
								}

								pushIgnore();
							break;
							default:
								push();
							break;
						}
					break;
					case '.':
						if (code[++p] == '.') if (code[++p] == '.') p++;

						push();
					break;
					case '&':
						p++;
						if (code[p] == '=') {
							p++;
						} else if (code[p] == '&') {
							p++;
						}

						push();
					break;
					case '|':
						++p;
						if (code[p] == '=') {
							p++;
						} else if (code[p] == '|') {
							p++;
						}

						push();
					break;
					case '-':
						p++;
						if (code[p] == '=') {
							p++;
						} else if (code[p] == '-') {
							p++;
						}

						push();
					break;
					case '+':
						p++;
						if (code[p] == '=') {
							p++;
						} else if (code[p] == '+') {
							p++;
						}

						push();
					break;
					case '<':
						p++;
						if (code[p] == '=') {
							p++;
						} else if (code[p] == '<') {
							if (code[++p] == '=') p++;
						} else if (code[p] == '>') {
							if (code[++p] == '=') p++;
						}

						push();
					break;
					case '>':
						p++;
						if (code[p] == '=') {
							p++;
						} else if (code[p] == '>') {
							if (code[++p] == '=') {
								p++;
							} else if (code[p] == '>') {
								if (code[++p] == '=') p++;
							}
						}
						push();
					break;
					case '!':
						p++;
						if (code[p] == '=') {
							if (code[++p] == '=') p++;
						} else if (code[p] == '<') {
							p++;
							if (code[p] == '>') {
								if (code[++p] == '=') p++;
							} else if (code[p] == '=') {
								p++;
							}
						} else if (code[p] == '>') {
							if (code[++p] == '=') p++;
						}

						push();
					break;
					case '*', '%', '^', '~':
						if (code[++p] == '=') p++;
						push();
					break;
					case '[':
						if (code[++p] == ']') p++;
						push();
					break;
					case '(', ')', ']', '{', '}', ':', ';', '?':
						p++;
						push();
					break;
					case '=':
						if (code[++p] == '=') if (code[++p] == '=') p++;

						push();
					break;
					case '\'': {
						++p;
						while (p < code.length) {
							if (code[p] == '\\') {
								++p;
							} else if (code[p] == '\'') {
								++p;
								break;
							}
							++p;
						}

						push(LToken.ttype.string);
					} break;
					case '\"': {
						++p;
						while (p < code.length) {
							if (code[p] == '\\') {
								++p;
							} else if (code[p] == '\"') {
								++p;
								break;
							}
							++p;
						}

						push(LToken.ttype.string);
					} break;

					/*
					case 'r':
						if (code[++p] != '\"') goto case_ident;
					break;
					case '`':
						tokenPrependData = file[pFrom .. p]; pFrom = p;
						t.value = TOKstring;
						t.ustring = wysiwygString(file[p]);
						tokenData = file[pFrom .. p]; return t.value;
						return t.value;

					case 'x':
						tokenPrependData = file[pFrom .. p]; pFrom = p;
						// HEX string?
						++p;
						if (file[p] != '\"') {
							start = p - 1;
							goto case_ident;
						}
						t.value = TOKstring;
						t.ustring = hexString();
						tokenData = file[pFrom .. p]; return t.value;
						return t.value;

					*/

					// Identifier start with _ or a-z,A-Z:
					case 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l',
						 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x',
						 'y', 'z':
					case 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L',
						 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
						 'Y', 'Z', '_':

						case_ident:

						// Extract the identifier:
						while (p < code.length) {
							if (!isalnum(code[p]) && !(code[p] == '_')) break;
							p++;
						}

						push(LToken.ttype.identifier);
					break;
					// Numeric literal:
					case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9': {
						// TODO
						int pos = 0;
						int base = 10;
						bool s0  = false, done = false;

						while (p < code.length) {
							// Starts with 0
							if (pos == 0 && code[p] == '0') {
								s0 = true; base = 8;
							} else {
								done = false;

								if (pos == 1 && s0) {
									switch (code[p]) {
										case '.':
											if (code[p + 1] == '.') {
												//p--;
												goto numeric_done;
											}
										break;
										case 'x', 'X':
											done = true;
											base = 16;
											// hexadecimal
										break;
										case 'b', 'B':
											done = true;
											base = 2;
											// binary
										break;
										case 'i', 'f', 'F':
											// finished (real)
											goto numeric_done;
										break;
										case '0', '1', '2', '3', '4', '5', '6', '7':
											done = true;
											base = 8;
											// octal
										break;
										default:
										break;
									}
								}

								if (!done) {
									switch (code[p]) {
										case '_': break;
										case '.':
											if (code[p + 1] == '.') {
												//p--;
												goto numeric_done;
											}

											if (s0) goto numeric_done;
										break;
										case 'i', 'f', 'F':
										if (!s0) { p++; goto numeric_done; }
										case 'a', 'A', 'b', 'B', 'c', 'C', 'd', 'D', 'e', 'E':
										if (base < 16) goto numeric_done;
										case '8', '9':
										if (base < 10) goto numeric_done;
										case '2', '3', '4', '5', '6', '7':
										if (base < 8) goto numeric_done;
										case '0', '1':
										if (base < 2) goto numeric_done;
										break;
										default:
											goto numeric_done;
										break;
									}
								}
							}

							p++; pos++;
						}

						numeric_done:

						push(LToken.ttype.number);

						//throw(new Exception("TODO"));
					} break;

					case '\xff': p++; break;

					default:
						p++;

						//throw(new Exception("Unknown secuence (" ~ std.string.toString(cast(int)code[p]) ~ ")"));

						push();
					break;
				}
			}
		} catch (Exception e) {
			writefln("Exception: " ~ e.toString());
		}

		lastline = line;
	}
}
