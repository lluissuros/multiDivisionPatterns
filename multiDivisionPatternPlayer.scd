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

    Out.ar(out, Pan2.ar(klank * env * 0.1 , pan));
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

    Out.ar(out, Pan2.ar(sin * env  * amp * 0.3 , pan));
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
		if(index % patternObj2.beatDiv == 0
			&& (patternObj1.amps.wrapAt(index/patternObj2.beatDiv) > 0))
		{
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
	  freqs =400,
	  tempo = TempoClock.default.tempo;
	var beatNum = patternObj.amps.size / patternObj.beatDiv;
	var dur = beatNum / (patternObj.amps.size * tempo);
	var types = patternObj.amps.collect({ |amp|
		if( amp > 0 ){\note}{\rest}
	});

	var counterFreq = 0;
	var freqsToPlay = patternObj.amps.collect({ |amp|
		var freq;
		if( amp > 0 ){
			freq = freqs.asArray.wrapAt(counterFreq);
			counterFreq = counterFreq + 1;
		}{ freq = \rest; };
		freq;
	});

	Pbind(
		\instrument, \klankHit,
		\dur, dur,
		\freq, Pseq( freqsToPlay, inf),
		\pan, pan,
		\amp, Pseq( patternObj.amps, inf),
	    \type, Pseq( types, inf));
};
)


//proto play
(
var pans = [-1, 1];
var degrees = Scale.kumoi.degrees;
var freqs = [
	(60 + {degrees.choose}.dup( 7.rand.max(1) )).midicps,
	(60 + {degrees.choose}.dup( 7.rand.max(1) )).midicps];

var multiDivPbinds = Array.newClear(2).collect({
	|el, index|
	var patObj1 = f[\patternRandGenerator].(
		{5.rand.max(1)}.(),
		{7.rand.max(2)}.()).postln;

	var patObj2 = f[\patternRandGenerator].(
		{5.rand.max(1)}.(),
		{7.rand.max(2)}.()).postln;

	var patObj3 = f[\patternRandGenerator].(
		{5.rand.max(1)}.(),
		{7.rand.max(2)}.()).postln;

	var merged = f[\patternMerger].(
		f[\patternMerger].(patObj1, patObj2),
		patObj3);
	f[\makePbindFromPatternObj].(merged, pans.[index], freqs[index]);
});

~multiDivPlayers.do({ |stream|
	stream.stop;
});

~multiDivPlayers = multiDivPbinds.collect({ |pbind|
	pbind.play;
});

"NEW RYTHM". postln;
)


Scale.directory

//automatic pattern changer
(
Tdef(\patternCreator, {
	inf.do{
		var pans = [-1, 1];
		var degrees = Scale.kumoi.degrees; //chinese, nairuz, gong
		var freqs = [
			(60 + {degrees.choose}.dup( 7.rand.max(1) )).midicps,
			(60 + {degrees.choose}.dup( 7.rand.max(1) )).midicps];

		var multiDivPbinds = Array.newClear(2).collect({
			|el, index|

			var patObj1 = f[\patternRandGenerator].(
				[2].choose,
				2);

			var patObj2 = f[\patternRandGenerator].(
				[2].choose,
				3);

			var patObj3 = f[\patternRandGenerator].(
				[2].choose,
				[5].choose);

			var merged = f[\patternMerger].(
				f[\patternMerger].(patObj1, patObj2),
				patObj3);

			merged.postln;
			merged.amps.size.postln;

			f[\makePbindFromPatternObj].(merged, pans.[index], freqs[index]);
		});

		~multiDivPlayers.do({ |stream|
			stream.stop;
		});

		~multiDivPlayers = multiDivPbinds.collect({ |pbind|
			pbind.play;
		});

		//TODO: maybe 'remember' the past ~multiDiv in an Array, and interpolate them, not always playing a new one.

		"NEW RYTHM". postln;
		[4].choose.wait;
	}
});
)

Scale.directory

//version 2
(
Tdef(\patternCreator, {
	var degrees = Scale.chinese.degrees; //chinese, nairuz, gong
	var baseFreqs = 60 + [
		degrees[0],
		degrees.wrapAt(2),
		degrees[0],
		degrees.wrapAt(5)];
	var pans = [-1, 1];
	var counterFreq = 0;

	inf.do{
		var baseFreq = baseFreqs.wrapAt(counterFreq).postln;
		var makeArp = { ({degrees.choose}.dup( 7.rand.max(2))).mirror1 };
		var freqs = [
			(baseFreq + makeArp.().postln ).midicps,
			(baseFreq + makeArp.().postln ).midicps];

		var multiDivPbinds = Array.newClear(2).collect({
			|el, index|

			var patObj1 = f[\patternRandGenerator].(
				[2].choose,
				5);

			var patObj2 = f[\patternRandGenerator].(
				[2].choose,
				3);

			var merged = f[\patternMerger].(patObj1, patObj2);


			f[\makePbindFromPatternObj].(merged, pans.[index], freqs[index]);
		});

		~multiDivPlayers.do({ |stream|
			stream.stop;
		});

		~multiDivPlayers = multiDivPbinds.collect({ |pbind|
			pbind.play;
		});

		//TODO: maybe 'remember' the past ~multiDiv in an Array, and interpolate them, not always playing a new one.

		"NEW RYTHM". postln;
		counterFreq = counterFreq + 1;
		[4].choose.wait;
	}
});
)
Tdef(\patternCreator).play;
Tdef(\patternCreator).stop;


~multiDivPlayers.do({ |strm| strm.stop });
~multiDivPlayers.do({ |strm| strm.play });


// I LIKE THOSE
( 'amps': [ 0, 0, 0, 1, 0, 1, 1, 0, 0 ], 'beatDiv': 3 )
( 'amps': [ 0, 1 ], 'beatDiv': 2 )
( 'amps': [ 1, 0.5, 0, 0, 1, 0 ], 'beatDiv': 2 )
( 'amps': [ 0.5, 0, 0, 0.5, 1, 0, 1, 1, 0.5, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0.5, 0.8, 0, 0.5, 0, 1 ], 'beatDiv': 6 )
( 'amps': [ 0.5, 0, 1, 0, 0, 0.5 ], 'beatDiv': 2 )
( 'amps': [ 0, 1, 0, 0.8, 0, 1, 0, 0, 0.5 ], 'beatDiv': 3 )

