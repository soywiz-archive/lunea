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
 *  $Id: config.d,v 1.1 2006/01/03 23:54:34 soywiz Exp $
 */

module lunea.frontend.config;

import std.c.windows.windows;

const char[] feversion = "0.9c";
//const char[] fedate    = __DATE__;
const char[] fedate    = "2005-2006";

const char[] appPath;
const char[] curPath;

static this() {
	// set appPath
	char *pathbuf = new char[MAX_PATH];
	int len = GetModuleFileNameA(null, pathbuf, MAX_PATH); appPath = pathbuf[0 .. len];
	appPath = std.path.getDirName(appPath);
	// set curPath
	curPath = std.file.getcwd();
}