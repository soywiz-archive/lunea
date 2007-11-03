/*
 *  Lunea library (gl2d)
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
 *  $Id: Audio.d,v 1.3 2006/01/06 02:17:01 soywiz Exp $
 */

module lunea.driver.Audio;

private import lunea.Resource;

import lunea.Lunea;
import SDL_mixer, std.string;

const int LOOP_INFINITE = -1;

class Sample {
	Mix_Chunk *sample;

	this() {
		sample = null;
	}

	static Sample fromFile(char[] filename) {
		Sample sample = new Sample;
		sample.sample = Mix_LoadWAV(std.string.toStringz(filename));
		if (!sample.sample) throw(new Exception("Can't load Audio file: '" ~ filename ~ "'"));
		return sample;
	}

	static Sample fromResource(char[] filename) {
		if (!Resources.have(filename)) throw(new Exception("Can't load resource: " ~ filename ~ "'"));
		Sample sample = new Sample;
		sample.sample = Mix_LoadWAV_RW(SDL_RWFromMem(Resources.get(filename), Resources.size(filename)), -1);
		if (!sample.sample) throw(new Exception("Can't load Audio file: '" ~ filename ~ "'"));
		return sample;
	}

	~this() {
		if (sample !is null) Mix_FreeChunk(sample);
	}

	private real vvolume = 1.0;

	real volume(real v) {
		Mix_VolumeChunk(this.sample, cast(int)(vvolume = v * 128));
		return vvolume;
	}

	real volume() {
		return vvolume = ((cast(real)Mix_VolumeChunk(this.sample, -1)) / 128);
	}
}

class Channel {
	int channel;

	this(int channel) {
		this.channel = channel;
	}

	int play(Sample sample, int loops = 1, int fadems = 0, int ticks = LOOP_INFINITE) {
		//printf("Mix_FadeInChannelTimed(%d, %d, %d, %d, %d);\n", channel, sample.sample, loops, ms, ticks);
		int channel;

		if (fadems == 0) {
			if (ticks == LOOP_INFINITE) {
				channel = Mix_PlayChannel(channel, sample.sample, loops);
			} else {
				channel = Mix_PlayChannelTimed(channel, sample.sample, loops, ticks);
			}
		} else {
			if (ticks == LOOP_INFINITE) {
				channel = Mix_FadeInChannel(channel, sample.sample, loops, fadems);
			} else {
				channel = Mix_FadeInChannelTimed(channel, sample.sample, loops, fadems, ticks);
			}
		}

		if (channel < 0) throw(new Exception("Can't play the sample on channel " ~ std.string.toString(channel)));

		return channel;
	}

	void pause() {
		Mix_Pause(channel);
	}

	void resume() {
		Mix_Resume(channel);
	}

	void stop() {
		Mix_HaltChannel(channel);
	}

	void stopAfter(int ms) {
		Mix_ExpireChannel(channel, ms);
	}

	deprecated void halt() {
		stop();
	}

	void fadeOut(int ms) {
		Mix_FadeOutChannel(channel, ms);
	}

	bool playing() {
		return (Mix_Playing(channel) != 0);
	}

	bool playing(bit set) {
		set ? resume() : pause();
		return set;
	}
}

class Music {
	Mix_Music *music;
	char[] tempfile;

	this() {
		music = null;
	}

	~this() {
		if (music !is null) Mix_FreeMusic(music);
		if (tempfile) unlink(tempfile.ptr);
	}

	static Music fromFile(char[] filename) {
		Music music = new Music;

		if (filename.length) {
			music.music = Mix_LoadMUS(std.string.toStringz(filename));
			if (music.music is null) throw(new Exception("Can't Load Music: '" ~ std.string.toString(Mix_GetError()) ~ "'"));
		}

		return music;
	}

	static Music fromResource(char[] filename) {
		if (!Resources.have(filename)) throw(new Exception("Can't load resource: " ~ filename ~ "'"));

		Music music = new Music;

		char *tname = tempnam(null, "mus_");
		music.tempfile = std.string.toString(tname);

		//Resources.get(filename), Resources.size(filename)

		//char[] array;
		//array = new
		//array.ptr = Resources.get(filename);
		//array.length = Resources.size(filename);

		FILE *file = fopen(tname, "wb");
		fwrite(Resources.get(filename), 1, Resources.size(filename), file);
		//fwrite();
		fclose(file);

		//write(tname, array);

		if (filename.length) {
			music.music = Mix_LoadMUS(tname);
			if (music.music is null) throw(new Exception("Can't Load Music: '" ~ std.string.toString(Mix_GetError()) ~ "'"));
		}

		//unlink(toStringz(music.tempfile));

		//free(tname);

		return music;
	}

	void play(int loops = 1, int fadems = 0, double position = 0.0) {
		if (music is null) return;

		int result;

		if (position == 0.0) {
			if (fadems == 0) {
				result = Mix_PlayMusic(music, loops);
			} else {
				result = Mix_FadeInMusic(music, loops, fadems);
			}
		} else {
			result = Mix_FadeInMusicPos(music, loops, fadems, position);
		}

		volume = vvolume;

		if (result != 0) {
			throw(new Exception("Can't Play Music: '" ~ std.string.toString(Mix_GetError()) ~ "'"));
		}
	}

	void fadeOut(int ms) {
		Mix_FadeOutMusic(ms);
	}

	void stop() {
		Mix_HaltMusic();
	}

	deprecated void halt() {
		stop();
	}

	private static real vvolume = 1.0;

	static real volume(real v) {
		Mix_VolumeMusic(cast(int)((vvolume = v) * 128));
		return v;
	}

	static real volume() {
		return cast(real)(Mix_VolumeMusic(-1)) / 128;
	}
}

Audio audio;

class Audio {
	Channel[16] channels;
	Channel     freeChannel;
	Channel     allChannels;
	//Music       music;

	static this() {
		if (!(SDL_WasInit(SDL_INIT_EVERYTHING) & SDL_INIT_AUDIO)) {
			if (SDL_InitSubSystem(SDL_INIT_AUDIO) < 0) {
				throw new Exception("Unable to initialize SDL: " ~ std.string.toString(SDL_GetError()));
			}
		}
		audio = new Audio;
	}

	static ~this() {
		SDL_QuitSubSystem(SDL_INIT_AUDIO);
	}

	this() {
		//if (Mix_OpenAudio(MIX_DEFAULT_FREQUENCY, MIX_DEFAULT_FORMAT, 2, 1024) != 0) {
		if (Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 1024) != 0) {
			throw(new Exception("Can't Open Audio Mixer"));
		}

		for (int n = 0; n < 16; n++) channels[n] = new Channel(n);
		allChannels = freeChannel = new Channel(-1);
	}

	~this() {
		Mix_CloseAudio();
	}

	Channel play(Sample sample, int loops = 1, int ms = 0, int ticks = LOOP_INFINITE) {
		int channelNumber = freeChannel.play(sample, loops, ms, ticks);
		return channels[channelNumber];
	}

	void play(Music music, int loops = LOOP_INFINITE, int fadems = 0, double position = 0.0) {
		if (music is null) return;
		music.play(loops, fadems, position);
	}
}
