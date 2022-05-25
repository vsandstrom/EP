// TUNING Pitch : 65.41

s.waitForBoot({ 
	
	// Sending MIDIClock to external device

	if (s.options.outDevice != "UltraLite AVB") {
		s.options.outDevice = "UltraLite AVB";
		s.options.inDevice = "UltraLite AVB";
		"REBOOT: WRONG AUDIO DEVICE".postln;
		s.reboot;
	};

	(
	2.do({
		MIDIClient.init;  //  Run twice for SC to find MOTU
	});
	~clock = TempoClock.new(67/60);
	~midiclock = MIDIClockOut.new("UltraLite AVB", "MIDI Out", ~clock);
	~clock.tempo = 80 / 60;
	);

	 ~freqWin = Nil;
	 ~steth = Nil;

	// creates FreqScope and Stethoscope if not existing
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

	(
	2.do({
		MIDIClient.init;  //  Run twice for SC to find MOTU
	});
	~clock = TempoClock.new(67/60);
	~midiclock = MIDIClockOut.new("UltraLite AVB", "MIDI Out", ~clock);
	~clock.tempo = 80 / 60;
	); 

	f = SixteenFaders.new;

	SynthDef(\passThru, {
		var sig = SoundIn.ar([\in.kr(0), \in.kr+1], mul: \passThruVol.kr(0.6));
		Out.ar(\out.kr(0), sig);
		Out.ar(\out.kr + 2, sig);
	}).add;

	SynthDef.new(\verb, {
		arg modamount = 0.05, dens = 12, outratio;
		var in, sig, mix, dust, fade;
		
		// Change mix ratio with ONE argument
		// var dryvol = outratio - (outratio % 1);
		// var wetvol = outratio % 1;

		//dust = Dust.kr(dens);

		dust = LFNoise2.kr(dens.linlin(0,1, 0, 25));

		in = In.ar(\in.kr(4), 2); // Analog In 1/2 on Device is 4/5 in SuperCollider
		// in = SoundIn.ar([in, in+1]);

		sig = NHHall.ar(in, rt60: \decay.kr(14), stereo: \stereo.kr(0.5), 
		lowFreq: 80, hiFreq: 10000, earlyDiffusion: 0.3, 
		lateDiffusion: 0.3, modRate: dust, modDepth: modamount);

		fade = XLine.ar();

		Out.ar(\out.kr(0), sig * \dry.kr(0.55) + sig * \wet.kr(0.4));

	}).add;

	SynthDef(\cvNoise, {
		var noise;

		noise = LFDNoise3.ar(\noiseFreq.kr(12), \noiseVol.kr(1).linlin(0,1,0,0.35));

		Out.ar(\out.kr(2), noise);
	}).add;

	SynthDef(\slurLFO, {
		var sig, noise, noise2, freq;

		freq = Demand.kr(Trig.kr(Dust.kr(3.7)), Trig.kr( Dust.kr(2.3) ), demandUGens: Dwrand.new( [ 0.2, 0.75, 2.2, 3.5, 8 ], [ 1, 3, 2, 1, 5 ].normalizeSum, inf ));

		noise = LFNoise2.kr( freq.lag(2.5) );

		noise2 = LFDNoise3.kr( LFNoise2.kr(21) );

		sig = SinOsc.ar(noise + noise2);

		Out.ar(\out.kr(4), sig * \lfoVol.kr(1).linlin(0,1,0,0.2));
	}).add;
	
	SynthDef.new(\grain, {
		arg in = 0, out = 4, dens, rand = 1.2, randAmount = 0.4, dur = 1,
		grainVol = 0.4, modamount = 0.2;
		var sig1, sig2, dust, pan, verb;

		dust = Dust.kr(dens.linlin(0, 1, 8, 80));
		pan = LFNoise2.kr(rand, randAmount);

		sig1 = GrainIn.ar(2, trigger: dust, dur: dur.linexp(0, 1, 0.01, 0.5), in:
		SoundIn.ar(in), pan:
		pan, maxGrains: 20);
		
		sig2 = GrainIn.ar(2, trigger: dust, dur: dur.linexp(0, 1, 0.01, 0.5), in:
		SoundIn.ar(in+1), pan:
		pan, maxGrains: 20);

		verb = NHHall.ar([ sig1, sig2 ], rt60: \decay.kr(14), stereo: \stereo.kr(0.5), 
		lowFreq: 80, hiFreq: 10000, earlyDiffusion: 0.3, 
		lateDiffusion: 0.3, modRate: dust, modDepth: modamount);


		Out.ar(out, Splay.ar([sig1, sig2])*grainVol.linlin(0, 1, 0, 0.4));
		Out.ar(out+2, verb*grainVol.linlin(0, 1, 0, 0.4));
	}).add;

	s.sync;

	if (s.options.inDevice == "UltraLite AVB", ( // Only create passThru if using UltraLite AVB
	~passThru = Synth.new(\passThru, [\in, 4, \passThruVol, f.faderAt(8).asMap]);
	~noise0 = Synth.new(\cvNoise, [\out, 2, \noiseVol, f.faderAt(7).asMap]);
	~noise1 = Synth.new(\cvNoise, [\out, 3, \noiseVol, f.faderAt(7).asMap]);
	~lfo = Synth.new(\slurLFO, [\out, 4, \lfoVol, f.faderAt(7).asMap]);
	));

	//	~passThru = Synth.new(\passThru, [\in, 4, \passThruVol, f.faderAt(9).asMap]);
	~grain = Synth.new(\grain, [\in, 4, \out, 0, \grainVol, f.faderAt(4).asMap, \dur, f.faderAt(5).asMap, \dens, f.faderAt(6).asMap]);
	~verb = Synth.new(\verb, [\in, 0, \out, 0, \modamount, f.faderAt(0).asMap, \dens, f.faderAt(1).asMap, \decay, 4, \dry, f.faderAt(2).asMap, \wet, ~sixteenVal3.asMap], addAction: \addToTail);
	~midiclock.play;


});


// END PIECE!
~midiclock.stop;

// ANALOG 1/2 is bus 4 in SuperCollider

 ~passThru = Synth.new(\passThru);
~verb = Synth.new(\verb, [\in, 4, \out, 0, \decay, 2]);
~grain = Synth.new(\grain, [\in, 4, \out, 4, \dur, 0.2]);
~noise = Synth.new(\cvNoise, [\noiseVol, 1, \out, 4]);
~lfo = Synth.new(\slurLFO, [\out, 4]);

~noise.set(\out, 2)

~verb.set(\modamount, 0.05, \dens, 0.8, \decay, 4, \dry, 0.8, \wet, 0.4);
~grain.set(\dur, 0.2, \grainVol, 0.01, \dens, 20);
~grain.free;
// ~grain.set(\in, 2, \dur, 0.02, \grainVol, 0.2, \out, 3, \rand, 5, \randAmount, 1);
ServerMeter.new(s, 9,8);
Server.killAll;
