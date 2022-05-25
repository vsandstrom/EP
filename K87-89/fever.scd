s.waitForBoot({	
	s.dumpOSC(0);

	a = Group.new;
	b = Group.new;
	f = SixteenFaders.new;
	s.sync;


	// Stop patterns if running

	~voice1.stop; 
	~voice2.stop; 
	~voice3.stop; 
	~seq.stop;

	// UTILITY and MIDI:

	for (0, 2, {
		
		MIDIClient.init;
		s.sync;
	});
	
	s.sync;


	// UNCOMMENT AND USE MOTU FOR MIDI CLOCK OUT!!!

	~clock = TempoClock.new(67/60);
	// ~midiclock = MIDIClockOut.new("UltraLite AVB", "MIDI Out", ~clock);
	~clock.tempo = 310 / 60;

	// creates FreqScope and Stethoscope if not existing
	~freqWin = Nil;
	~steth = Nil;

	
	if (~freqWin == Nil && ~steth == Nil, 
		{
~freqWin = Window.new(\scope, Rect(width: 650, height: 300, left: 1050, top: 750));
			~freq = FreqScopeView(~freqWin, ~freqWin.view.bounds, s);
			~freq.active = true;
			~freq.inBus = [0, 1];
			~freqWin.onClose_({~freq.kill});
			~freqWin.front.alwaysOnTop = true;
			CmdPeriod.add({Window.closeAll});
			
			~steth = Stethoscope.new(s, 4);
			~steth.window.alwaysOnTop = true;
	
		} 
	);

	if (s.options.outDevice != "UltraLite AVB") {
		s.options.outDevice = "UltraLite AVB";
		s.options.inDevice = "UltraLite AVB";
		"REBOOT: WRONG AUDIO DEVICE".postln;
		s.reboot;
	};


	// DECLARE PatternProxys

	~v0 = PatternProxy.new;
	~v1 = PatternProxy.new;
	~v2 = PatternProxy.new;
	~v3 = PatternProxy.new;
	~v4 = PatternProxy.new;

	~d0 = PatternProxy.new;
	~d1 = PatternProxy.new;
	~d2 = PatternProxy.new;
	~d3 = PatternProxy.new;
	~d4 = PatternProxy.new;

	// Changing pattern using PatternProxy, a new instance has one property: "source". To alter after initialization, use
	// keyword .source;

	// PART ONE:
	// --------------------------------------------------------------
	
	~v0.source = Pseq(
		[
			 35, 38, 
			 40, 35, 38, 36, 
			 35, 28, 23, 
			 28, 
			 33, 35, 30, 31,
			 33, 35, 33, 31,
			 30, 28, 26, 24,
			 23
		 ] + 36, 2
	 ); // Melodi

	~d0.source = Pseq(
		[
			 4, 4,
			 2, 2, 2, 2,
			 2, 4, 2,
			 10, 2, 2,
			 4, 2,
			 2, 4, 2,
			 2, 2, 2, 2,
			 4, 16
		 ] * 2, 2
	 );

	~v1.source = Pseq(
		[
			28, 31, 33, 31, \rest, 19, 19, 
			23, 26, 23, 24, 26, 23, 21, 
			\rest
		] + 36, 2
	); // Topp

	~d1.source = Pseq(
		[
			4, 4, 4, 6, 2, 4, 8, 
			4, 4, 4, 4, 4, 4, 
			16, 16
		] * 2, 2
	);

	~v2.source = Pseq(
		[
			[19, 26], [16, 23], [12, 19], [9, 16], [7, 14],
			[4, 11], 0, -3, [7, 14], [4, 19], 0, -3,
			7, 4, 0, -3, 7, 4, 0, 9,
			[7, 26], [4, 23], [12, 19], [9, 16], [7, 14],
			[4, 11], 0, -3, [7, 14], [4, 19], 0, -3,
			7, 4, 0, -3, 7
		] + 36, 1
	); // Bottom

	 ~d2.source = Pseq(
		[
			4, 4, 4, 4, 
			4, 4, 4, 4, 
			4, 4, 4, 4, 
			4, 4, 4, 4, 
			4, 4, 4, 4, 
			4, 4, 4, 4, 
			4, 4, 4, 4, 
			4, 4, 4, 4, 
			4, 4, 4, 4,
			16
		] * 2, 1
	);

	~v3.source = Pseq([ \rest, 18, \rest ] + 36, 2); // Aux stämma
	~d3.source = Pseq([ 24, 4, 52] * 2, 2); // Aux stämma
	~v4.source = Pseq([\rest, 16, \rest, 16, 8] + 36, 2); // Bas
	~d4.source = Pseq([24, 8, 8, 32, 8] * 2, 2); // Bas
	 
	// CALL SYNTHDEFS

	Fever.new;

	// synthdef prototypes

	SynthDef(\drop, {
		var sig, env, line0, line1;
		line0 = Line.kr(150, 0, 1.3) * \lineVol.kr(1);
		line1 = Line.kr(130, 0, 1.3) * \lineVol.kr(1);
		env = EnvGen.kr(Env.new([ 0,1,0 ],[ \atk.kr(0.16), \rel.kr(6) ], [4, -4]), \t_trig.kr(0));
		sig = [ LFTri.ar(\freq.kr(50) + line0) * SinOsc.kr(line0.linexp(0,150, 1, 100)), LFTri.ar(\freq.kr(50) + line1) *SinOsc.kr(line1.linexp(0,150, 1, 100))];
		Out.ar(\out.kr(0), sig * env * 0.2);
		Out.ar(\out.kr + 1, sig * env * 0.2);
	}).add;

	// Synth(\drop, [\t_trig, 1, \lineVol, 1, \degree, 12]);
	// Synth(\drop, [\t_trig, 1, \lineVol, 0, \degree, 12]);
	// )
	// Synth(\drop, [\t_trig, 1, \lineVol, 0, \degree, 12, \atk, 0.1, \rel, 0.5]);
	// Synth(\drop, [\t_trig, 1, \lineVol, 0, \degree, 7]);

	s.sync;

	// // --------------------------------------------------------------


	// CREATE SYNTH INSTANCES:


	{ReplaceOut.ar(0, 
		Compander(LeakDC.ar(In.ar(0, 2)), In.ar(0, 2), 0.75, 1, 1/4))
	}.play;
	~verb = Synth.new(\verb, [\verbVol, f.faderAt(3).asMap, \verbFold, f.faderAt(2).asMap], addAction: \addToTail);
	s.sync;

	
	// PATTERNs
	
	// LEAD

	~seq = Pbind.new(
		\instrument, \lead,
		\dur, ~d0,
		\freq, ~v0,
		\atk, Pwhite(0.4, 1.2, inf),
		// Make more interesting envelope curves with fixed times per note.
		\rel, ~d0 + 2,
		\vol, f.faderAt(1).asMap,
		\carFold, f.faderAt(0).asMap,
		\modAmount, 0,
		\modFreq, Pseq( [~v0 + Prand([24, 32, (28 * 2)], inf)], inf),
		\t_trig, 1,
		\addAction, \addToHead
	).play(quant: 1); 

	// --------------------------------------------------------------
	
	// VOICE 1
	~voice1 = Pbind.new(
		\instrument, \fold,
		\freq, ~v1,
		\dur, ~d1,
		\fold, f.faderAt(4).asMap,
		\vol, f.faderAt(5).asMap,
		\atk, Pwhite(0.4, 1.2, inf),
		\rel, ~d1 + 2,
		\addAction, \addToHead
	).play(quant: 1);
	
	// --------------------------------------------------------------

	// VOICE 2
	~voice2 = Pbind.new(
		\instrument, \fold,
		\freq, ~v2,
		\dur, ~d2,
		\fold, f.faderAt(6).asMap,
		\vol, f.faderAt(7).asMap,
		\atk, Pwhite(0.4, 1.2, inf),
		\rel, ~d2 + 2,
		\addAction, \addToHead
	).play(quant: 1);
	
	// --------------------------------------------------------------

	~voice3 = Pbind.new(
		\instrument, \fold,
		\freq, ~v3,
		\dur, ~d3,
		\fold, f.faderAt(4).asMap,
		\vol, f.faderAt(5).asMap,
		\atk, 1.2, 
		\rel, ~d3 + 3,
		\addAction, \addToHead
	).play(quant: 1);
	
	// --------------------------------------------------------------

	~voice4 = Pbind.new(
		\instrument, \fold,
		\freq, ~v4,
		\dur, ~d4,
		\fold, f.faderAt(6).asMap,
		\vol, f.faderAt(7).asMap,
		\atk, 1.2,
		\rel, ~d4 + 2,
		\addAction, \addToHead
	).play(quant: 1);
	
	// --------------------------------------------------------------

	s.sync;

	ServerMeter(s, 16,16);
});
