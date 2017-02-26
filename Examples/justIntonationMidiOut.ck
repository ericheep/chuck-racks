// Eric Heep
// February 25rd, 2017
// justIntonationMidiOut.ck


fun void delayedMidiClear(MidiMsg msg, int chan, int num, dur delay) {
    delay => now;

    // note off
    0x80 | chan => msg.data1;
    num => msg.data2;
    0 => msg.data3;
    PluginHost.sendMidi(msg);

    // pitch bend clear
    0x0e | chan => msg.data1;
    0 => msg.data2;
    8192 => msg.data3;
    PluginHost.sendMidi(msg);
}

fun void midiNoteOn(MidiMsg msg, int chan, int num, int vel) {
    0x90 | chan => msg.data1;
    num => msg.data2;
    vel => msg.data3;
    PluginHost.sendMidi(msg);
}

fun void midiPitchBend(MidiMsg msg, int channel, float bend, float pitchRange) {
    /* Scales the midifloat to the midi pitch bend range
    most Ableton midi instruments use +/-6 semitones
    because we have to round to an integer, a smaller
    pitch range will result in more precise pitches.

    This pitch bend will always bend up, ignoring the lower
    8192 values of a midi pitch bend message.

    https://www.midikits.net/midi_analyser/pitch_bend.htm

    Parameters
    ----------
        channel ; int
            Which channel the message is sent to.
        bend; float
            Then amount of bend from 0.0 to 1.0 in semitones.
        pitchRange: float
            This should match bend range on the midi instrument,
            a lower range on both will result in a more precise
            measurement.
    */

    Math.round((bend/pitchRange) * 8192)$int + 8192 => int midiBend;

    // 0x0e is the command 'nibble' for pitch bend,
    // the right half is the channel
    0xe0 | channel => msg.data1;

    // the midiBend var is split over 14 bits in the two
    // subsequent messages, with the last bit set to zero
    // (which gives reason to use a mask of 01111111 or 127
    midiBend & 127 => msg.data2;
    (midiBend >> 8) & 127 => msg.data3;

    PluginHost.sendMidi(msg);
}

/* A way to accurately utilize the midi pitch bend message
as a means to produce precise frequences with midi instruments

The major drawback with pitch bend, is that an entire midi channel
is devoted to pitch bend, which makes polyphony difficult. The
solution here is to create many instances of the same midi instrument
to imitate polyphony (although it is really just several different
monophonic instruments playing simultaneously).
*/

MidiMsg msg;

440.0 => float rootFreq;

// ratios of a Ptolemy diatonic scale (common 7 limit scale)
[1.0/1.0, 9.0/8.0, 5.0/4.0, 4.0/3.0,
 3.0/2.0, 5.0/3.0, 15.0/8.0, 2.0/1.0] @=> float ptolemyRatios[];

[0, 0] @=> int channelOne[];
[4, 5] @=> int channelTwo[];
[7, 9] @=> int channelThree[];

6.0 => float PITCH_BEND_RANGE;
40::ms => dur midiOnDuration;

fun void note(int channel, int idx) {
    // creates our midi "float" value taken from our frequency ratios
    Std.ftom(rootFreq * ptolemyRatios[idx]) => float midiFloat;

    // midi integer
    Math.floor(midiFloat)$int => int midiNote;

    // midi remainder (bend amount)
    midiFloat - Math.floor(midiFloat) => float midiBend;

    // channel, midiN, velocity, pitch bend, pitch bend range
    midiNoteOn(msg, channel, midiNote, 127);
    midiPitchBend(msg, channel, midiBend, PITCH_BEND_RANGE);

    // sets up delayed messages to turn off the midi note and clear the pitch bend
    spork ~ delayedMidiClear(msg, channel, midiNote, midiOnDuration);
}

while (true) {
    for (0 => int i; i < 2; i++) {
        note(0, channelOne[i]);
        note(1, channelTwo[i]);
        note(2, channelThree[i]);

        PluginHost.sixteenth() * 4 => now;
    }
}
