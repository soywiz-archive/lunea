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

import lunea.Lunea;
import SDL_mixer, std.string;

const int LOOP_INFINITE = -1;

class Sample {
	Mix_Chunk *sample;

	this() {
		sample = null;
	}

	static Sample fromFile(string fileName) {
		Sample sample = new Sample;
		sample.sample = Mix_LoadWAV(std.string.toStringz(fileName));
		//sample.sample = Mix_LoadWAV_RW(SDL_RWFromFile(std.string.toStringz(fileName), "rb"), 1);
		if (!sample.sample) throw(new Exception("Can't load Audio file: '" ~ fileName ~ "'"));
		return sample;
	}

	~this() {
		if (sample !is null) Mix_FreeChunk(sample);
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
	}
}

class Music {
	Mix_Music *music;

	this() {
		music = null;
	}

	~this() {
		if (music !is null) Mix_FreeMusic(music);
	}

	static Music fromFile(string fileName) {
		Music music = new Music;

		if (fileName.length) {
			music.music = Mix_LoadMUS(std.string.toStringz(fileName));
			if (music.music is null) throw(new Exception("Can't Load Music: '" ~ std.string.toString(Mix_GetError()) ~ "'"));
		}

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
}

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

	void play(Music music, int loops = 1, int fadems = 0, double position = 0.0) {
		if (music is null) return;
		music.play(loops, fadems, position);
	}
}