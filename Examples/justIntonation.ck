SinOsc sin => dac;

440.0 => float rootFreq;

[1.0/1.0,
 9.0/8.0,
 5.0/4.0,
 4.0/3.0,
 3.0/2.0,
 5.0/3.0,
 15.0/8.0,
 2.0/1.0] @=> float ptolemyRatios[];

for (0 => int i; i < ptolemyRatios.size(); i++) {
    rootFreq * ptolemyRatios[i] => sin.freq;
    0.1::second => now;
}
