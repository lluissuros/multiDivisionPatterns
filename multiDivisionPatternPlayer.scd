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
	var hit = BrownNoise.ar(0.0025) * env * amp;

	var klank = Klank.ar(
        `[freqs, nil, rings],
        hit
    );

    Out.ar(out, Pan2.ar(klank , pan));
}).add;
)

Synth("moto-rev");
Synth(\klankHit);


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
	arg patternObj, tempo = TempoClock.default.tempo;
	var beatNum = patternObj.amps.size / patternObj.beatDiv;
	var dur = beatNum / (patternObj.amps.size * tempo);

	Pbind(
		\instrument, "moto-rev",
		\dur, dur,
		\amp, Pseq( patternObj.amps, inf));
};
)





//test
(
var patObj1 = f[\patternRandGenerator].(
	{5.rand.max(1)}.(),
	{6.rand.max(2)}.()).postln;

var patObj2 = f[\patternRandGenerator].(
	{5.rand.max(1)}.(),
	{6.rand.max(2)}.()).postln;

var patObj3 = f[\patternRandGenerator].(
	{5.rand.max(1)}.(),
	{8.rand.max(2)}.()).postln;

var merged = f[\patternMerger].(patObj1, patObj2).postln;
merged = f[\patternMerger].(patObj2, patObj3).postln;

//var patt = (amps: [ 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 0, 0 ] , beatDiv: 6);
e = f[\makePbindFromPatternObj].(merged, 1).play;
)
e.stop;



TempoClock.default.tempo = 1;



(
d = Dictionary.new;
d.add(\monkey -> 0).postln;
d.add(\robot -> 1).postln;    // Add robot as a key with a value of 1
d.add(\monkey -> 2).postln;    // Replaces the value for the key monkey with 2
)



