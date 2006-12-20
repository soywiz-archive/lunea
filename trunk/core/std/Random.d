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
 *  $Id: Random.d,v 1.3 2006/02/16 16:32:41 soywiz Exp $
 *
 *	Mersenne Twister random number generator
 *	Based on code by Makoto Matsumoto, Takuji Nishimura, Shawn Cokus,
 *	Matthe Bellew, and Isaku Wada
 *	Andrew C. Edwards  v0.1  30 September 2003  edwardsac@ieee.org
 *
 *	Before using, initialize the state by using init_genrand(seed)
 *	or init_by_array(init_key, key_length).
 *
 *	Copyright (C) 1997 - 2002, Makoto Matsumoto and Takuji Nishimura,
 *	Copyright (C) 2003, Andrew C. Edwards
 *	All rights reserved.
 *
 *	Redistribution and use in source and binary forms, with or without
 *	modification, are permitted provided that the following conditions
 *	are met:
 *
 *	1. Redistributions of source code must retain the above copyright
 *	notice, this list of conditions and the following disclaimer.
 *
 *	2. Redistributions in binary form must reproduce the above copyright
 *	notice, this list of conditions and the following disclaimer in the
 *	documentation and/or other materials provided with the distribution.
 *
 *	3. The names of its contributors may not be used to endorse or promote
 *	products derived from this software without specific prior written
 *	permission.
 *
 *	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *	"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *	LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 *	A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 *	CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *	EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *	PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *	PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *	LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *	NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *	The original code included the following notice:
 *
 *	Any feedback is very welcome.
 *	http://www.math.keio.ac.jp/matumoto/emt.html
 *	email: matumoto@math.keio.ac.jp
 *
 *	Please CC: edwardsac@ieee.org on all correspondence
 *
 *	Modified by Kenta Cho.
 */

module lunea.std.Random;

private import std.date;

public class Random {
	public this() {
		init_genrand(getUTCtime());
	}

	public this(long n) {
		init_genrand(n);
	}

	int get(int min, int max) {
		if (min > max) { int temp; temp = max; max = min; min = temp; }
		return (min + nextInt(max - min + 1));
	}

	real getReal(real min, real max) {
		if (min > max) { real temp; temp = max; max = min; min = temp; }
		return cast(real)nextFloat(cast(float)max - cast(float)min) + cast(float)min;
	}

	public void setSeed(long n) {
		init_genrand(n);
	}

	public uint nextInt32() {
		return genrand_int32();
	}

	public int nextInt(int n) {
		if (n == 0) return 0;
		return genrand_int32() % n;
	}

	public int nextSignedInt(int n) {
		if (n == 0) return 0;
		return genrand_int32() % (n * 2) - n;
	}

	public float nextFloat(float n) {
		return genrand_real1() * n;
	}

	public float nextSignedFloat(float n) {
		return genrand_real1() * (n * 2) - n;
	}

	const int  N        = 624;
	const int  M        = 397;
	const uint MATRIX_A = 0x9908b0dfUL;
	const uint UMASK    = 0x80000000UL;
	const uint LMASK    = 0x7fffffffUL;
	uint MIXBITS(uint u, uint v) { return (u & UMASK) | (v & LMASK); }
	uint TWIST  (uint u, uint v) { return (MIXBITS(u,v) >> 1) ^ (v&1 ? MATRIX_A : 0); }

	uint state[N];
	int  left  = 1;
	int  initf = 0;
	uint *next;

	void init_genrand(uint s) {
		state[0] = s & 0xffffffffUL;
		for (int j = 1; j < N; j++) {
			state[j] = (1812433253UL * (state[j - 1] ^ (state[j - 1] >> 30)) + j);
			state[j] &= 0xffffffffUL;
		}
		initf = left = 1;
	}

	void init_by_array(uint init_key[], uint key_length) {
		int i, j, k;
		init_genrand(19650218UL);
		i = j = 1;
		k = (N > key_length ? N : key_length);

		for (; k; k--) {
			state[i] = (state[i] ^ ((state[i - 1] ^ (state[i - 1] >> 30)) * 1664525UL)) + init_key[j] + j;
			state[i] &= 0xffffffffUL;
			i++; j++;
			if (i >= N) { state[0] = state[N - 1]; i = 1; }
			if (j >= key_length) j = 0;
		}

		for (k = N - 1; k; k--) {
			state[i] = (state[i] ^ ((state[i - 1] ^ (state[i - 1] >> 30)) * 1566083941UL)) - i;
			state[i] &= 0xffffffffUL;
			i++;
			if (i >= N) { state[0] = state[N - 1]; i = 1; }
		}

		state[0] = 0x80000000UL;
		initf = left = 1;
	}

	void next_state() {
		uint *p = state.ptr;

		if (initf == 0) init_genrand(5489UL);

		left = N;
		next = state.ptr;

		for (int j = N - M + 1; --j; p++) *p = p[M    ] ^ TWIST(p[0], p[1]);
		for (int j = M        ; --j; p++) *p = p[M - N] ^ TWIST(p[0], p[1]);

		*p = p[M - N] ^ TWIST(p[0], state[0]);
	}

	uint genrand_int32() {
		uint y;

		if (--left == 0) next_state();
		y = *next++;

		y ^= (y >> 11);
		y ^= (y <<  7) & 0x9d2c5680UL;
		y ^= (y << 15) & 0xefc60000UL;
		y ^= (y >> 18);

		return y;
	}

	long genrand_int31() {
		uint y;

		if (--left == 0) next_state();
		y = *next++;

		y ^= (y >> 11);
		y ^= (y <<  7) & 0x9d2c5680UL;
		y ^= (y << 15) & 0xefc60000UL;
		y ^= (y >> 18);

		return cast(long)(y>>1);
	}

	double genrand_real1() {
		uint y;

		if (--left == 0) next_state();
		y = *next++;

		y ^= (y >> 11);
		y ^= (y <<  7) & 0x9d2c5680UL;
		y ^= (y << 15) & 0xefc60000UL;
		y ^= (y >> 18);

		return cast(double)y * (1.0/4294967295.0);
	}

	double genrand_real2() {
		uint y;

		if (--left == 0) next_state();
		y = *next++;

		y ^= (y >> 11);
		y ^= (y << 7) & 0x9d2c5680UL;
		y ^= (y << 15) & 0xefc60000UL;
		y ^= (y >> 18);

		return cast(double)y * (1.0/4294967296.0);
	}

	double genrand_real3() {
		uint y;

		if (--left == 0) next_state();
		y = *next++;

		y ^= (y >> 11);
		y ^= (y <<  7) & 0x9d2c5680UL;
		y ^= (y << 15) & 0xefc60000UL;
		y ^= (y >> 18);

		return (cast(double)y + 0.5) * (1.0/4294967296.0);
	}

	double genrand_res53() {
		uint a = genrand_int32() >> 5, b = genrand_int32() >> 6;
		return (a * 67108864.0+b) * (1.0/9007199254740992.0);
	}
}

Random random;

static this() {
	random = new Random();
}