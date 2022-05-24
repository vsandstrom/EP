Koltrast{
	var <>buf;
	*new { | buf |
		^super.newCopyArgs( buf ).init;
	}
	init {
		
		// ---------------------------------------------

		SynthDef(\playback, {
			var sig, cursor, noise, fade;

			noise = LFDNoise3.kr(\noiseFreq.kr(8), \noiseAmount.kr(0.002));
			fade = XLine.kr( 0.01, 1, \fadeTime.kr(2));
			sig = PlayBuf.ar(
				2, 
				buf,
				BufRateScale.kr(buf) * \rate.kr(1) + noise,
				trigger: \t_trig.kr(1),
				startPos: 800000);

			DetectSilence.ar(sig, doneAction: 2);
			cursor = Phasor.kr(
				\t_trig.kr,
				BufRateScale.kr(buf) * \rate.kr,
				0,
				BufFrames.kr(buf).linlin(0,BufFrames.kr(buf), 0,1)
				);

			Out.ar(\out.kr(0), (sig*\vol.kr(0.8) * fade));
			Out.ar( 55, (sig*\vol.kr * fade));
			
		}).add;
		
		// ---------------------------------------------

		SynthDef(\demandSynth2, {
			var fund = 69;
			var trigger, in, sig, env, fade, verb, fadeOut;

			in = A2K.kr(In.ar(\in.kr(55), 2) * 4);
			// in = DelayN.ar(In.ar(\in.kr(55), 2), 0.2, 0.2);
			fade = Line.kr( 0, 1, \fadeTime.kr(2));
			trigger = Trig.kr( InRange.kr( Amplitude.kr(A2K.kr(in.lag(1) * 4), 0.2, 0.5), \loTresh.kr(0.01), 0.8 ).lag(0.01));
			// env = EnvGen.kr(Env.perc(\atk.kr(0.1).linexp(0, 1, 0.01, 0.7), \rel.kr(1).linexp(0, 1, 0.01, 2.5)), gate: trigger);
			env = EnvGen.kr(
				Env( 
					[ 0, 0.01, 1, 0 ],
					[
						0.05,
						\atk.kr(0.1).linexp(0, 1, 0.01, 0.3),
						\rel.kr(1).linexp(0, 1, 0.01, 0.39) 
					], curve: -4), trigger);

			sig = DPW3Tri.ar( Demand.kr(trigger, 0, demandUGens: Dseq( [ 
					[ fund, (fund*3) / 2], // Db, Ab
					[ (fund*5) / 4, (fund*5) / 3], // F, Bb
					[ (fund*15) / 8, (fund*9) / 8], // C, Eb
					[ (fund*3) / 2, (fund*45) / 32],  // Ab, G
					[ (fund*15) / 16, (fund*5) / 4]
					// [ 69.295657744218, 103.82617439499 ], 
					// [ 87.307057858251, 233.08188075904 ], 
					// [ 130.8127826503, 155.56349186104 ], 
					// [ 103.82617439499, 195.99771799087 ] 
				] * 2, inf) * Dwrand([1, 2, 0.75], [0.6,0.2, 0.1], inf)).lag(0.1));

			sig = sig * fade * EnvFollow.kr( in ).lag(0.7) * \vol.kr(0.7) ;
			sig = HPF.ar(sig, \hpf.kr(440));
			fadeOut = Line.kr(1,0,\fadeTime.kr);
			verb = NHHall.ar(sig, \verbTime.kr(4).linlin(0, 1, 0, 12), 0.5, 800, 0.5, 2000, 0.2, 0.2, 0.3);

			Out.ar( \out.kr(0), 0.8 * env * sig!2.tanh + ( verb * \verbVol.kr(0.3).linexp(0, 1, 0.01, 0.6)));  
		
		}).add;

		// ---------------------------------------------

		SynthDef(\verb, {
			var in, verb;

			in = In.ar(\in.kr(0), 2);
			verb = NHHall.ar( 
				in * EnvFollow.kr( in ),
				\verbTime.kr(7).linlin(0, 1, 0, 14)
			) * \verbVol.kr(0.35);

			Out.kr(\out.kr(0), verb);

		}).add;

		//------------------------------------------------------------

		SynthDef(\pingedBurst, {
			var fund = 69;
			var trigger, in, filter, freq, fade, fadeOut, oct, dust, transEnv;

			in = A2K.kr(In.ar(\in.kr(0), 2) );
			fade = Line.kr( 0, 1, \fadeTime.kr(2) );
			trigger = Trig.kr( InRange.kr( in.lag(1), \loThresh.kr(0.01, 0.8 ) ) );
			dust = Dust.kr(\dens.kr(20), EnvGen.kr(Env.new([0, 1, 0], [0.2, 0.5]), trigger));
			oct = Demand.kr(trigger, 0, Dwrand.new([1,2,4,6], [3, 2, 2,1].normalizeSum, inf));

			freq = Demand.kr(dust, 0, Dseq.new([
					[ fund, (fund*3) / 2], // Db, Ab
					[ (fund*5) / 4, ( (fund*5) / 3 )*2], // F, Bb [ (fund*15) / 8, (fund*9) / 8], // C, Eb
					[ (fund*3) / 2, (fund*45) / 32]  // Ab, G
					// [ 69.295657744218, 103.82617439499 ], 
					// [ 87.307057858251, 233.08188075904 ], 
					// [ 130.8127826503, 155.56349186104 ], 
					// [ 103.82617439499, 195.99771799087 ] 
				]* oct, inf));

			filter = Ringz.ar(K2A.ar(trigger), freq, \decay.kr(12));
			transEnv = Phasor.kr(trigger);

			Out.ar( \out.kr(0), filter * fade * transEnv * \filterVol.kr(0.3) );

		}).add;

		//------------------------------------------------------------
SynthDef(\caust, {
			var sig, sig1, sig2, env, noise, dist, rand;

			rand = LFNoise2.kr(15);
			sig1 = VarSaw.ar(
				\freq.kr(300).lag(1.5) + ( LFNoise2.kr(12 + rand) * 2 ),
				0,
				0.5 + ( LFNoise2.kr(0.4) * \saw.kr(0.2)));

			sig2 = VarSaw.ar(
				\freq.kr(300).lag(1.5) + (LFNoise2.kr(12 + rand) * 2),
				0,
				0.5 + ( LFNoise2.kr(0.4) * \saw.kr(0.2)));

			sig = sig1 + sig2;

			dist = RLPFD.ar(
				InsideOut.ar(sig, 0.2), 
				\cutoff.kr(0.3).linlin(0, 1, 150, 2000) + \freq.kr,
				\res.kr(0.4), 
				\dist.kr(0.8));

			sig = sig + ( SinOscFB.ar(\freq.kr / 2, \fb.kr(0.8) ) * 1.35);

			env = EnvGen.kr(
				Env.new(
					[0, 1, 0.75, 0.3, 0], 
					[\atk.kr(0.8), \dec.kr(1.2), \rel.kr(2), \rel.kr + 0.4]), 
					\t_trig.kr, 
					doneAction: 2);

			noise = InsideOut.ar(
				BrownNoise.ar(), mul: 0.1) * EnvGen.kr(Env.new(
					[0,1, 0.75, 0.3, 0], [\atk.kr, \dec.kr, \rel.kr, \rel.kr + 0.4] * 0.5), 
					\t_trig.kr);

			sig = LPF.ar(sig, 800);
			sig = DWGSoundBoard.ar(sig) + ( sig * 0.3);
			// sig = LPF.ar(sig,300) + sig;

			Out.ar(0, 
				//Mix.ar([sig, noise, dist])
				sig!2 * \vol.kr(0.2).linlin(0, 1, 0, 0.5) * env);

		}).add;


		SynthDef(\phys, {
			var sig0, sig1, env;
			var bpf0 = 1.2;
			var bpf1 = 0.85;
			var bpf2 = 0.673;
			var res0 = 3;
			var res1 = 4.987;
			var res2 = 7.012;

			sig0 = DWGBowedTor.ar(
				\freq.kr(300).lag(1.5),
				force: \force.kr(1),
				gate: \t_gate.kr(0),
				release: \rel.kr(0.1)
			);
			sig0 = DWGSoundBoard.ar(sig0);
			sig0 = BPF.ar(sig0, \freq.kr * res0, rq: bpf0) + sig0;
			sig0 = BPF.ar(sig0, \freq.kr * res1, rq: bpf1) + sig0;
			sig0 = BPF.ar(sig0, \freq.kr * res2, rq: bpf2) + sig0;

			sig1 = DWGBowedTor.ar(
				\freq.kr + LFNoise2.kr(1.3, 0.005).lag(1.5),
				force: \force.kr,
				gate: \t_gate.kr,
				release: \rel.kr(0.1)
			);
			sig1 = DWGSoundBoard.ar(sig1);
			sig1 = BPF.ar(sig1, \freq.kr * res0, rq: bpf0) + sig1;
			sig1 = BPF.ar(sig1, \freq.kr * res1, rq: bpf1) + sig1;
			sig1 = BPF.ar(sig1, \freq.kr * res2, rq: bpf2) + sig1;

			//env = EnvGen.kr(Env.new([0,1,0], [0.4, 2], [-4, 4]), \t_trig.kr(0));
			//DetectSilence.ar(( sig0 + sig1 )  * env, doneAction: 2);

			Out.ar(\out.kr(0), 
				Balance2.ar(
					sig0,
					sig1, 
					\pos.kr(0.0) + LFDNoise3.kr(8, 0.4)
				) * \vol.kr(0.01).linlin(0, 1, 0, 0.016) );

		}).add;

		// SynthDef(\percTrast{
		// 	var sig, env;

		// 	sig = PlayBuf.ar(
		// 		2,
		// 		buf,
		// 		\rate.kr(0.35),
		// 		\t_reset.kr(0),
		// 		\pos.kr(0) * BufFrames.kr(buf)
		// 	);
		// 	env = EnvGen.kr(
		// 		Env.perc(
		// 			\env.kr(0.1).linlin(0, 1, 0, 0.15), 
		// 			\env.kr(0.1).linlin(0, 1, 0, 1.6)
		// 		),
		// 		1, doneAction: 2
		// )
		// 
		//
		// })
	}
}
