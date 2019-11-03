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
 *  $Id: ProcessThread.d,v 1.4 2006/04/24 17:36:13 soywiz Exp $
 */

module lunea.ProcessThread;

//private import std.gc;

// Based on yaneSDK4D (http://www.sun-inet.or.jp/~yaneurao/dlang/english.html)
abstract class ProcessThread {
	private byte*  __register_esp;
	private byte*  __register_esp_start;
	private bool   __suspended;
	private bool   __ended;
	private bool   __changed;
	private bool   __first = true;
	private byte[] __stack;
	private int    __stack_size;

	// main action of process
	public abstract void main();

	public  this() { paction = &main; }
	public ~this() { }

	public void frame() { __suspended = true; __switch_thread(); }

	// paction
	public void delegate () paction() { return __function; }
	public void paction(void delegate () sfunction) {
		__changed  = !__first;
		__first    = __ended = __suspended = false;
		__function = sfunction;
	}

	private void delegate() __function;

	public  void __execute() {
		if (__ended) return;
		__suspended ? __resume() : __start(__function);
	}
	private void __resume() {
		try {
			if (!__suspended) return;
			__suspended = false;
			__switch_thread();
		} catch (Exception e) {
			throw(e);
		}
	}

	private void __start(void delegate() sfunction, int ssize = 0) {
		if (ssize) __stack_size = ssize;
		if (!__stack_size) __stack_size = 0x1000;

		if (__stack.length < __stack_size) __stack = new byte[__stack_size];
		__register_esp = &__stack[0] + __stack_size;

		__changed = __ended = __suspended = false;

		__register_esp_start = __register_esp;
		__function = sfunction;

		__ms_push(cast(uint)(&__start_do)); // RET POINTER
		__ms_push(0); // dword ptr FS:[0]
		__ms_push(0); // EDI
		__ms_push(0); // ESI
		__ms_push(0); // EBP
		__ms_push(0); // EBX

		try {
			__switch_thread();
		} catch (Exception e) {
			throw(e);
		}
	}

	private static void __start_do(ProcessThread process) {
		try {
			process.__function();
			if (!process.__changed) process.__ended = true;
			process.__switch_thread();
		} catch (Exception e) {
			throw(e);
		}
	}

	private void __ms_push(uint u) { *cast(uint *)(__register_esp -= 4) = u; }

	private void __switch_thread() {
		asm {
			naked;

			push EBX;
			push EBP;
			push ESI;
			push EDI;

			push dword ptr FS:[0];

			xchg ESP, [EAX + 8]; // EAX (pointer to object) + 8 (first field [__register_esp])

			pop dword ptr FS:[0];

			pop  EDI;
			pop  ESI;
			pop  EBP;
			pop  EBX;

			ret;
		}
	}

	abstract protected void __attach();
	abstract protected void __detach();

	protected bool __finished() { return __ended; }
}