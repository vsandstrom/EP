s.options.memSize = 8192 * 16;
s.makeWindow;
s.boot;
s.reboot;
s.options.sampleRate = 48000;

Server.default.options.outDevice = "BlackHole 16ch";
Server.default.options.outDevice = "16A";
Server.default.options.outDevice = "UltraLite AVB";
Server.default.options.inDevice = "UltraLite AVB"; s.reboot;
Server.default.options.outDevice = "Built-in Output";

/* TODO:
-> [*] Add new texture to piece complementing sampler.
-> [*] Try DWG-synth.
-> [*] Set master tempo using TempoClock
-> [*] Try using several Routines for different components.
-> [ ] Use Routine.next to change state of \rate parameter.
-> [ ] Optimiz loop and conditions
-> [ ] Add amplitude triggered synth for percussive sounds, triggered by signals in either left or right channel, post pan.
	   Should change with the Balance2 pan argument. Perhaps 3 layers, in[0], in[1] and in[0 + 1]
*/

// SynthDef(\passThru, {
// 	Out.ar(\out.kr(0), SoundIn.ar([ \in.kr(6), \in.kr +1 ]), \vol.kr(0.2));
// }).add;
// Synth(\passThru[\in, 4]);

s.waitForBoot({

var buf = Buffer.read(s, "./samples/aferes_edit.wav");
var buf5 = Buffer.read(s, "./samples/piano1.wav");

~b0 = true;
~b1 = true;
~b2 = true;

~fourOrEight = 4;

Server.freeAll;	
t = TempoClock.new( 80/60 );
f = SixteenFaders.new;

	~freqWin = Nil;
	~steth = Nil;

	
	if (~freqWin == Nil && ~steth == Nil, 
		{
	~freqWin = Window.new(\scope, Rect(width: 650, height: 300, left: 1050, top: 750));
			~freq = FreqScopeView(~freqWin, ~freqWin.view.bounds, s,);
			~freq.active = true;
			~freq.inBus = [0, 1];
			~freqWin.onClose_({~freq.kill});
			~freqWin.front.alwaysOnTop = true;
			CmdPeriod.add({Window.closeAll});
			
	~stethWin = Window.new(\steth, Rect(width: 300, height: 300, left: 1650, top: 1750));
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



s.sync;

SynthDef(\knaster, {
	var dust, noise;

	dust = Dust.kr(15);
	noise = LFDNoise3.ar(14);
	Out.ar(0, noise * dust * \vol.kr(0).linlin(0, 1, 0, 0.02));
}).add;

SynthDef(\verb, {
	var in, verb;
	in = In.ar(0, 2);
	verb = NHHall.ar(in, \verbDecay.kr(1), 0.2, 1000, 0.3, 9000, 0.5, 1, 1 );
	
	Out.ar(0, verb);
}).add;

// Bad Values från perkussic synt

SynthDef(\puff, { 
	var env, sig, trig;
	var offset = 1;
	//var pitch = 233.08; // Bb

	env = EnvGen.kr(Env.perc(\atk.kr(0.01), \rel.kr(5)), \t_trig.kr(0), doneAction: 2);

	sig = PinkNoise.ar(0.1) + ( SinOsc.ar(\freq.kr(233.08) * 0.1 ));

	sig = sig + ( Ringz.ar(sig, offset * \freq.kr(233.08), decaytime: 3) * 0.25 );
	sig = sig + ( Ringz.ar(sig, offset * \freq.kr(233.08) * 3, decaytime: 3) * 0.2 );
	sig = sig + ( Ringz.ar(sig, offset * \freq.kr(233.08) * 9/8 * 2, decaytime: 3) * 0.04 );
	// sig = ( BLowPass.ar(sig) * 0.5) + ( sig * 0.32);
	
	sig = NHHall.ar(sig!2, 12, 0.5, 500);


	// sig = Compander.ar(sig, sig, )

	// DetectSilence.ar(sig, doneAction:2);
	Out.ar(\out.kr(0), sig * \vol.kr(0.1).linlin(0, 1, 0, 0.002) * env);
}).add;

SynthDef(\aferes, {
	var sig;

	sig = PlayBuf.ar(2, \buf.kr(0), \rate.kr(1.022) * BufRateScale.kr(\buf.kr), 1.0, 0.0, 1.0, 0);
	sig = BLowPass.ar(sig, \freq.kr(1200).linlin(0, 1, 40, 8000), 1, 1, 0);
	Out.ar(\out.kr(0), sig * \vol.kr(0));

}).add;


s.sync;

SynthDef(\stutter, {
	var play, env, dust, burst;

	env = EnvGen.kr(
		Env.new(
			[0,1,0],
			[0.8, 10],
			[4, 2.5]
		),
		\t_trig.kr(0)
	);

	dust = Dust.kr(\dustFreq.kr(2));
	env = env * dust + ( env * 0.25 );

	burst = EnvGen.kr(
		Env.new(
			[0,1,1,0],
			[0.1, 0.1],
			[-4, 0, 4]
		),
		dust
	);
	
	play = PlayBuf.ar(
		2,
		\buf.kr(0),
		rate: \rate.kr(0.5),
		startPos: \pos.kr(0) * BufFrames.kr(\buf.kr),
		loop: 1 
	);

	//Out.ar(0, play * burst * \vol.kr(0.5));
	Out.ar(\out.kr(0), Splay.ar([
		play * \vol.kr(0.3), 
		play * (burst * \burstVol.kr(0.2))
		])
	);
}).add;

	SynthDef(\phys, {
		var sig0, sig1, env;

		sig0 = DWGBowedTor.ar(
			\freq.kr(300).lag(1.5),
			force: \force.kr(1),
			gate: \t_gate.kr(0),
			release: \rel.kr(0.1)
		);
		sig0 = DWGSoundBoard.ar(sig0);
		sig0 = BPF.ar(sig0, \freq.kr * 1.33, rq: 3) + sig0;
		sig0 = BPF.ar(sig0, \freq.kr * 1.8, rq: 2.2) + sig0;
		sig0 = BPF.ar(sig0, \freq.kr * 2.2, rq: 1.5) + sig0;

		sig1 = DWGBowedTor.ar(
			\freq.kr + LFNoise2.kr(1.3, 0.005).lag(1.5),
			force: \force.kr,
			gate: \t_gate.kr,
			release: \rel.kr(0.1)
		);
		sig1 = DWGSoundBoard.ar(sig1);
		sig1 = BPF.ar(sig1, \freq.kr * 1.33, rq: 3) + sig1;
		sig1 = BPF.ar(sig1, \freq.kr * 1.8, rq: 2.2) + sig1;
		sig1 = BPF.ar(sig1, \freq.kr * 2.2, rq: 1.5) + sig1;

		Out.ar(\out.kr(0), Pan2.ar(sig0 + sig1,\pos.kr(0.0) + LFDNoise3.kr(8, 0.2)) * \vol.kr(0.01).linlin(0, 1, 0, 0.02) );

	}).add;


SynthDef(\fell, {
	var play, env;
	
	env = EnvGen.kr(
		Env.new([0,1,1,0],
			[\atk.kr(0.1),
			\rel.kr(0.1)],
			[-4, 0, 4]),
		\t_trig.kr(0),
		doneAction: Done.freeSelf
	);
	play = PlayBuf.ar(
		2,
		\buf.kr(0),
		rate:  \rate.kr(0.5),
		startPos: \pos.kr(0) * BufFrames.kr(\buf.kr ),
		loop: 1 
	);

	play = play * env;
	Out.ar(\out.kr(0), Balance2.ar(play[0], play[1], \pan.kr(0), env * \vol.kr(0.3).linlin(0, 1, 0, 0.45)));

}).add;
s.sync;


~verb = Synth(\verb, [\verbDecay, 2]);

	~bob = Routine({
		var pos = 0;
		var waitTime = 0.05;
		var atk = 0;
		var rel = 0;
		var bob = 0;
		var count = 0;
		var state = 0;
		var pan = 0;


		Synth(\aferes, [\buf, buf, \freq, f.faderAt(9).asMap, \vol, f.faderAt(10).asMap]);
		loop{ // getSynchronous returns a float, when get returns the bus index and type. 
			waitTime = f.faderAt(15).getSynchronous.linexp(0,1, 0.05, 0.8); // get current value from fader as float, change to exponential scale.
			( t.beatDur / 3 ).wait;
			// waitTime.wait;
			count = ( count + 1 );
			state = f.faderAt(15).getSynchronous;

			if(pan < 1.abs){pan = pan + 0.003}{1};
			pan.postln;
			//s.sync;
		
			atk = if((( waitTime / 2) - 0.1) < 0) {0.1} {(waitTime / 2) - 0.1};

			~s0 = Synth(\fell, [
				\buf, buf5, 
				\pos, f.faderAt(0).asMap, 
				\t_trig, 1, 
				\atk, f.faderAt(3).getSynchronous.lincurve(0,1, 0.025, 0.8, -2) * atk,
				\rel, f.faderAt(6).getSynchronous.lincurve(0,1, 0.025, 0.8, -2),
				\pan, pan,
				\vol, f.faderAt(12).asMap,
				\rate, if((count % 5) == 0 && ~b0 == true){1.5}{1}
			]); 
			waitTime = f.faderAt(15).getSynchronous.linexp(0,1, 0.05, 0.8); 
			( t.beatDur / 3 ).wait;
			state = f.faderAt(15).getSynchronous;
			// waitTime.wait;
			s.sync;

			~s1 = Synth(\fell, [
				\buf, buf5,
				\pos, f.faderAt(1).asMap, 
				\t_trig, 1,
				\atk, f.faderAt(4).getSynchronous.lincurve(0,1, 0.025, 0.8, -2) * atk,
				\rel, f.faderAt(7).getSynchronous.lincurve(0,1, 0.025, 0.8, -2),
				\pan, 0,
				\vol, f.faderAt(13).asMap,
				\rate, if((count % ~fourOrEight) == 0 && ~b1 == true){0.5}{1}
			]);
			waitTime = f.faderAt(15).getSynchronous.linexp(0,1, 0.05, 0.8); 
			( t.beatDur / 3 ).wait;
			state = f.faderAt(15).getSynchronous;
			//waitTime.wait;
			s.sync;

			~s2 = Synth(\fell, [
				\buf, buf5,
				\pos, f.faderAt(2).asMap,
				\t_trig, 1, 
				\atk, f.faderAt(5).getSynchronous.lincurve(0,1, 0.025, 0.8, -2) * atk,
				\rel, f.faderAt(8).getSynchronous.lincurve(0,1, 0.025, 0.8, -2),
				\pan, -1 * pan,
				\vol, f.faderAt(14).asMap,
				\rate, if((count % 6) == 3 && ~b2 == true){2}{1}
			]);
			s.sync;
		}.yield;
		loop{
			wait(1);
		}.yield
	});

	~laura = Routine.new({
		var count = 0;
		var cond = true;

		// other "reverse" way to write wait
		// wait( t.beatDur * 64 );
		'hello'.postln;
		fork{
			var count = 0;
			var pitch = 233.08; // Bb
			var beat = t.beatDur;
	 		loop{
				count = count + 1;

				Synth(\puff, [\freq, pitch * 0.5, \rel, 6, \vol, f.faderAt(15).asMap, \t_trig, 1]);
				Synth(\puff, [\freq, pitch * 3/2, \rel, 6, \vol, f.faderAt(15).asMap, \t_trig, 1]);
				if(( count % 3 ) == 0){ // Loop 1
				(beat * 6).wait;
			}{
				(beat * 2).wait;
			};
				Synth(\puff, [\freq, pitch * 3/2 * 0.25, \rel, 6, \vol, f.faderAt(15).asMap, \t_trig, 1]);
				Synth(\puff, [\freq, pitch * 3/2 * 3/2 * 0.5, \rel, 6, \vol, f.faderAt(15).asMap, \t_trig, 1]);
				(beat * 6).wait;
				Synth(\puff, [\freq, pitch * 5/4 * 0.25, \rel, 6, \vol, f.faderAt(15).asMap, \t_trig, 1]);
				Synth(\puff, [\freq, pitch * 5/4 * 3/2 * 0.5, \rel, 6, \vol, f.faderAt(15).asMap, \t_trig, 1]);
				if(( count % 3 ) == 1){
				(beat * 6).wait;
			}{
				(beat * 2).wait;
			};
				Synth(\puff, [\freq, pitch * 9/8 * 0.25, \rel, 6, \vol, f.faderAt(15).asMap, \t_trig, 1]);
				Synth(\puff, [\freq, pitch, \rel, 6, \vol, f.faderAt(15).asMap, \t_trig, 1]);
				if(( count % 3 ) == 0){ // Loop 1
				(beat * 6).wait;
			}{
				if(( count % 3 ) == 1){
				(beat * 6).wait;
			}{
				(beat * 2).wait;
			};
			};
				Synth(\puff, [\freq, pitch * 3/2 * 0.25, \rel, 6, \vol, f.faderAt(15).asMap, \t_trig, 1]);
				Synth(\puff, [\freq, pitch * 3/2 * 5/4 * 0.5, \rel, 6, \vol, f.faderAt(15).asMap, \t_trig, 1]);
				(beat * 6).wait;
				Synth(\puff, [\freq, pitch * 16/11 * 0.25, \rel, 6, \vol, f.faderAt(15).asMap, \t_trig, 1]);
				Synth(\puff, [\freq, pitch * 16/11 * 3/2, \rel, 6, \vol, f.faderAt(15).asMap, \t_trig, 1]);
				(beat * 6).wait;
				if(( count % 3 ) == 2){ // Loop 1
				(beat * 6).wait;
			}{
				if(( count % 3 ) == 1){
				(beat * 6).wait;
			}{
				(beat * 2).wait;
			};
			};
				Synth(\puff, [\freq, pitch * 3/2 * 5/4 * 0.25, \rel, 6, \vol, f.faderAt(15).asMap, \t_trig, 1]);
				Synth(\puff, [\freq, pitch * 3/2, \rel, 6, \vol, f.faderAt(15).asMap, \t_trig, 1]);
				if(( count % 3 ) == 0){ // Loop 1
				(beat * 6).wait;
			}{
				(beat * 2).wait;
			};
				Synth(\puff, [\freq, pitch * 3/2 * 3/2 * 0.25, \rel, 6, \vol, f.faderAt(15).asMap, \t_trig, 1]);
				Synth(\puff, [\freq, pitch * 5/4 * 0.5, \rel, 6, \vol, f.faderAt(15).asMap, \t_trig, 1]);
				(beat * 6).wait;

			// Gör ljud och sekvens här!
		}
	}});

	// PLAY
	// {PlayBuf.ar(2, buf5) * 0.3}.play;

)
});
	~b0 = true;
	~b1 = true;
	~b2 = true;

	~fourOrEight = 4;
	~fourOrEight = 8;

	~b0 = true;
	~b1 = false;
	~b2 = true;

	~b0 = false;
	~b1 = false;
	~b2 = true;
	
	~b0 = false;
	~b1 = false;
	~b2 = false;

	t.play(~bob);
	t.play(~laura);//  < ----------- KOMP AVSTÄNGT! tills vidare
