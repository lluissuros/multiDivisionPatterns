/*
make a pattern creator
start with divisions of 2s and 3s
return an array with 0 and 1 whereas it should be a beat or not
later, this array could be an object, with other params such as amp or freq
Create a player that plays the array
Make the pattern creator handle also 5s, 7s, and so on
*/

(
// some sytnh to test
SynthDef("moto-rev", { arg out=0, amp = 1;
    var x = RLPF.ar(LFPulse.ar(SinOsc.kr(0.2, 0, 10, 21), [0,0.1], 0.1),
        100, 0.1).clip2(0.4);
	var env = EnvGen.kr(Env.perc(0.001, 2), doneAction: 2);
    Out.ar(out, x * amp * env);
}).add;

SynthDef(\klankHit,{
	|out = 0,
	freq = 65,
	maxffreq = 6000.0,
	ringLength = 3,
	atk = 0.1,
	sus = 0,
	rel = 1,
	pan = 0,
	amp = 0.5|

	var freqs =  ({LinRand(0, maxffreq).round(freq) + freq}).dup(12);
	var rings =  {Rand(0.1, ringLength)}.dup(12);

	var env = EnvGen.kr(Env.linen(atk, sus, rel, 1, \welch), doneAction:2);
	var hit = BrownNoise.ar(0.0025) * amp;

	var klank = Klank.ar(
        `[freqs, nil, rings],
        hit
    );

    Out.ar(out, Pan2.ar(klank * env , pan));
}).add;


SynthDef(\sinHit,{
	|out = 0,
	freq = 400,
	atk = 0.01,
	sus = 0,
	rel = 0.1,
	pan = 0,
	amp = 1|

	var env = EnvGen.kr(Env.perc(atk, rel), doneAction:2);
	var sin = SinOsc.ar(freq);

    Out.ar(out, Pan2.ar(sin * env  * amp , pan));
}).add;
)



Synth("moto-rev");
Synth(\klankHit);
Synth(\sinHit);


/*
todos:
-pattern should be random and 2s and 3s divided
-handle tempo from outside (taking TempoClock?)
*/



/*DATA MODEL:
I need an object containing:
-The pattern as an array of amps.
-number of beats in the pattern
-the beat division in the pattern
-(opt, later) The pattern durations in an array of durations

patternObject = (
  amps: Array,
  beatDiv: Int,
  beatNum: Int
)

*/



(
/*CREATE FUNCTIONS*/
f = f ? ();

// used for testing
f.assertTrue =  {
	arg actual, expected;
	if (actual != expected){
		("test failed, expected " + actual + " to be "+ expected).die() }
	{true}
};

f.ampBelowThreholdToZero = {
	arg pattern, minAmp;
	pattern.collect( {|amp| if( amp>=minAmp ){amp}{0} } );
};

f.patternRandGenerator = {
	arg
	patternLength = {3.rand.max(1)}.(),
	patternBeatDiv = {4.rand.max(2)}.(),
	minAmp = 0.5;

	var emptyResult = Array.fill(patternLength * patternBeatDiv, 0);
	var amps = emptyResult.collect( {[0,0.5,0.8,1].wchoose([0.5, 0.1, 0.1, 0.3])} ).normalize;
	var patternObj = (
		amps: f[\ampBelowThreholdToZero].(amps, minAmp),
		beatDiv: patternBeatDiv);
	patternObj;
};


// TODO: should ta dke as much patterns as we want
f.patternMerger = {
	arg
	  patternObj1, // = (amps: Array, beatDiv: Int)
	  patternObj2;

	//TODO: resultsize now is brute force, but could be optimized
	var resultSize = patternObj1.amps.size * patternObj2.amps.size;
	var emptyAmps = Array.fill(resultSize, {0});

	var amps = emptyAmps.collect({
		|i, index|
		if(index % patternObj2.beatDiv == 0) {
			patternObj1.amps.wrapAt(index/patternObj2.beatDiv);
		}{
			if(index % patternObj1.beatDiv == 0) {
				patternObj2.amps.wrapAt(index/patternObj1.beatDiv);
			}{0};
		};
	});

	(amps: amps, beatDiv: patternObj1.beatDiv * patternObj2.beatDiv);
	//TODO: check if two halfs, 3rds or whatever are equal and simplyfy
};



f.makePbindFromPatternObj = {
	arg
	  patternObj,
	  pan = 0,
	  freq=400,
	  tempo = TempoClock.default.tempo;
	var beatNum = patternObj.amps.size / patternObj.beatDiv;
	var dur = beatNum / (patternObj.amps.size * tempo);
	var types = patternObj.amps.collect({ |amp|
		if( amp > 0 ){\note}{\rest}
	});

	Pbind(
		\instrument, \sinHit,
		\dur, dur,
		\freq, Pseq( freq.asArray, inf),
		\pan, pan,
		\amp, Pseq( patternObj.amps, inf),
	    \type, Pseq( types, inf));
};
)



//proto play
(
var patObj1R = f[\patternRandGenerator].(
	{5.rand.max(1)}.(),
	{11.rand.max(2)}.()).postln;

var patObj2R = f[\patternRandGenerator].(
	{5.rand.max(1)}.(),
	{11.rand.max(2)}.()).postln;

var patObj3R = f[\patternRandGenerator].(
	{5.rand.max(1)}.(),
	{11.rand.max(2)}.()).postln;

var patObj1L = f[\patternRandGenerator].(
	{5.rand.max(1)}.(),
	{11.rand.max(2)}.()).postln;

var patObj2L = f[\patternRandGenerator].(
	{5.rand.max(1)}.(),
	{11.rand.max(2)}.()).postln;

var patObj3L = f[\patternRandGenerator].(
	{5.rand.max(1)}.(),
	{11.rand.max(2)}.()).postln;

var mergedR = f[\patternMerger].(
	f[\patternMerger].(patObj1R, patObj2R),
	patObj3R);

var mergedL = f[\patternMerger].(
	f[\patternMerger].(patObj1L, patObj2L),
	patObj3R);

e.stop;
g.stop;


e = f[\makePbindFromPatternObj].(mergedR, 1).play;
g = f[\makePbindFromPatternObj].(mergedL, -1).play;
)



e.stop;
e.play;

g.stop;
g.play;



TempoClock.default.tempo = 1;



(
d = Dictionary.new;
d.add(\monkey -> 0).postln;
d.add(\robot -> 1).postln;    // Add robot as a key with a value of 1
d.add(\monkey -> 2).postln;    // Replaces the value for the key monkey with 2
)



