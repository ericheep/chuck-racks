// Eric Heep
// February 23rd, 2017
// justIntonationSynced.ck

MidiMsg msg;

440.0 => float rootFreq;

// outlines a Ptolemy diatonic scale
[1.0/1.0,
 9.0/8.0,
 5.0/4.0,
 4.0/3.0,
 3.0/2.0,
 5.0/3.0,
 15.0/8.0,
 2.0/1.0] @=> float ptolemyRatios[];

fun void midiNoteOn() {

    // PluginHost.sendMidi(msg)
}

for (0 => int i; i < ptolemyRatios.size(); i++) {
    Std.ftom(rootFreq * ptolemyRatios[i]) => float midiFreq;
    <<< midiFreq >>>;
    0.1::second => now;
}


