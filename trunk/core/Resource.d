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
 *  $Id: Resource.d,v 1.1 2006/01/03 23:54:33 soywiz Exp $
 */

module lunea.Resource;

import lunea.Util;

// A hash of strings associated to a resource id.
public ushort[string] __resource_list;

version (Windows) {
	pragma(lib, "kernel32.lib");
	import std.c.windows.windows;

	extern (Windows) {
		HGLOBAL LoadResource  (HMODULE hModule, HRSRC hResInfo);
		HRSRC   FindResourceA (HMODULE hModule, LPCTSTR lpName, LPCTSTR lpType);
		DWORD   SizeofResource(HMODULE hModule, HRSRC hResInfo);
	}

	alias FindResourceA FindResource;
}

static class Resources {
	version (Windows) {
		private static HRSRC getp(char[] name) {
			if ((name in __resource_list) is null) return null;
			return FindResource(null, cast(char *)__resource_list[name], cast(char *)0x0A);
		}
	}

	// Obtain a pointer to the resource
	public static void* get(string name) {
		version(Windows) {
			HRSRC hRsrc; if ((hRsrc = getp(name)) is null) return null;
			return LoadResource(null, hRsrc);
		} else {
			throw(new Exception("Resources not implemented yet on Linux"));
			return null;
		}
	}

	// Obtain the size of a resource
	public static int size(string name) {
		version (Windows) {
			HRSRC hRsrc; if ((hRsrc = getp(name)) is null) return 0;
			return SizeofResource(null, hRsrc);
		} else {
			throw(new Exception("Resources not implemented yet on Linux"));
			return 0;
		}
	}

	// Return if have the resource requested
	public static bool have(string name) {
		version (Windows) {
			return !((name in __resource_list) is null);
		} else {
			throw(new Exception("Resources not implemented yet on Linux"));
			return false;
		}
	}
}
