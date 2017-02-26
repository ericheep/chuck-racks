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

fun void midiPitchBend(MidiMsg msg, int chan, float bend, float pitchBendRange) {
    /* Scales the midifloat to the midi pitch bend range
    most Ableton midi instruments use +/-6 semitones
    because we have to round to an integer, a smaller
    pitch range will result in more precise pitches.

    This pitch bend will always bend up, ignoring the lower
    8192 values of a midi pitch bend message. We will have to
    divide out pitch range by two to adjust.

    https://www.midikits.net/midi_analyser/pitch_bend.htm

    Parameters
    ----------
        chan ; int
            Which channel the message is sent to.
        bend; float
            Then amount of bend from 0.0 to 1.0 in semitones.
        pitchBendRange: float
            This should match bend range on the midi instrument,
            a lower range on both will result in a more precise
            measurement.
    */

    Math.round((bend/(pitchBendRange * 0.5)) * 8192)$int + 8192 => int midiBend;

    // 0x0e is the command 'nibble' for pitch bend,
    // the right half is the channel
    0xe0 | chan => msg.data1;

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
is devoted to pitch bend, which makes polyphony with pitch bend troublesome.

A future solution would be to output different parts on different
midi channels, but ChucK-rack's midi out is currently limited to outputting
to all of the channels on a midi instrument.
*/

MidiMsg msg;

440.0 => float rootFreq;
// implemented channel for furture examples
0 => int channel;

// ratios of a Ptolemy diatonic scale (common 7 limit scale)
[1.0/1.0, 9.0/8.0, 5.0/4.0, 4.0/3.0,
 3.0/2.0, 5.0/3.0, 15.0/8.0, 2.0/1.0] @=> float ptolemyRatios[];

// I - IV - ii - V7
[0, 2, 0, 4, 5, 3, 0, 3, 5, 1, 3, 4, 6, 7] @=> int sequence[];

6.0 => float pitchBendRange;
40::ms => dur midiOnDuration;

fun void midiFreqOut(MidiMsg msg, int chan, float midiFloat, int vel, float pitchBendRange) {
    // midi integer
    Math.floor(midiFloat)$int => int midiInteger;

    // midi remainder (bend amount)
    midiFloat - Math.floor(midiFloat) => float midiBend;

    midiNoteOn(msg, chan, midiInteger, vel);
    midiPitchBend(msg, chan, midiBend, pitchBendRange);
}

// play at a slow tempo
while (true) {
    for (0 => int i; i < sequence.size(); i++) {
        // creates our midi "float" value taken from our frequency ratios
        Std.ftom(rootFreq * ptolemyRatios[i]) => float midiFloat;
        midiFloat$int => int midiInteger;

        midiFreqOut(msg, channel, midiFloat, 127, pitchBendRange);

        Std.ftom(rootFreq * ptolemyRatios[0]) => midiFloat;
        midiFloat$int => midiInteger;

        midiFreqOut(msg, channel, midiFloat, 127, pitchBendRange);

        // sets up delayed messages to turn off the midi note and clear the pitch bend
        spork ~ delayedMidiClear(msg, channel, midiInteger, midiOnDuration);

        PluginHost.quarter() => now;
    }
}
