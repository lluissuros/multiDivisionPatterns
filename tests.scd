//some unit tests.

(
var testObj1 = (amps: [1,1], beatDiv: 2);
var testObj2 = (amps: [1,1,1], beatDiv: 3);
f[\assertTrue].(
	f[\patternMerger].(testObj1, testObj2),
	(amps: [1,0,1,1,1,0], beatDiv:6)
);

testObj1 = (amps: [0,1], beatDiv: 2);
testObj2 = (amps: [0,1,1], beatDiv: 3);
f[\assertTrue].(
	f[\patternMerger].(testObj1, testObj2),
	(amps: [0,0,1,1,1,0], beatDiv:6)
);

testObj1 = (amps: [1,1,1,1], beatDiv: 2);
testObj2 = (amps: [1,1,1], beatDiv: 3);
f[\assertTrue].(
	f[\patternMerger].(testObj1, testObj2),
	(amps: [1,0,1,1,1,0,1,0,1,1,1,0], beatDiv:6)
);

testObj1 = (amps: [1,1,1,1], beatDiv: 4);
testObj2 = (amps: [1,1,1], beatDiv: 3);
f[\assertTrue].(
	f[\patternMerger].(testObj1, testObj2),
	(amps: [1,0,0,1,1,0,1,0,1,1,0,0], beatDiv:12)
);

testObj1 = (amps: [1,1,1,0], beatDiv: 2);
testObj2 = (amps: [1,1,1], beatDiv: 3);
f[\assertTrue].(
	f[\patternMerger].(testObj1, testObj2),
	(amps: [1,0,1,1,1,0,1,0,1,0,1,0] , beatDiv:6)
);

testObj1 = (amps: [1,1], beatDiv: 2);
testObj2 = (amps: [1,1,1,1,1], beatDiv: 5);
f[\assertTrue].(
	f[\patternMerger].(testObj1, testObj2),
	(amps: [1,0,1,0,1,1,1,0,1,0], beatDiv:10)
);


testObj1 = (amps: [1,1], beatDiv: 2);
testObj2 = (amps: [1,1,1,1,1,1], beatDiv: 3);
f[\assertTrue].(
	f[\patternMerger].(testObj1, testObj2),
	(amps: [1,0,1,1,1,0,1,0,1,1,1,0], beatDiv:6)
);

//BUG!
testObj1 = (amps: [0,0], beatDiv: 2);
testObj2 = (amps: [0,1], beatDiv: 2);
f[\assertTrue].(
	f[\patternMerger].(testObj1, testObj2),
	(amps: [0,0,1,0], beatDiv:4)
);

)