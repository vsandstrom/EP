Fever {
	*new {
		^super.new.init;
	}

	init { 
		// --------------------------------------------------------------

		SynthDef(\sidePiece, {
			var sig, env, lfo1, lfo2, dirt, random, noise, sub;
			
			random = ( Rand(1, 5) % 0.25 );
			
			env = EnvGen.kr(Env.perc(\atk.kr(0.025), \rel.kr(0.65)), \t_trig.kr(0), doneAction: 0);

			lfo1 = SinOsc.kr( 8.3 + random );

			lfo2 = SinOsc.kr( 12.5 + random, 0.2 );

			dirt = LFDNoise3.kr(16.8);

			sig = 4.collect {
				SinOscFB.ar(( \freq.kr(32).midicps ) + ( (lfo1 + lfo2) * \modAmount.kr(0.25) ), feedback: dirt * \fbModVol.kr(0.4))
				+ 
				LPF.ar(VarSaw.ar(( \freq.kr(32).midicps ) + ( (lfo1 + lfo2) * \modAmount.kr(0.25) ), width: 0.63 * dirt * (
					\fbModVol.kr * 0.1), mul: 0.1 ), 2200);
			};

			sub = DPW3Tri.ar( (\freq.kr - 24).midicps, \subVol.kr(0.4) );

			noise = LFDNoise3.ar( 500, EnvGen.kr(Env.perc(\rel.kr * 3, \atk.kr, curve: 5), \t_trig.kr, doneAction: 2) );
			
			sig = Splay.ar( [sig, sub, noise], 0.35, center: \pan.kr(0.0) );

			Out.ar(\out.kr(0), sig * \vol.kr(0.35).linlin(0, 1, 0, 0.35) * env);

		}).add;

		// SynthDef(\sidePiece, {
		// 	var sig, env;
		// 	env = EnvGen.kr(Env.perc(\atk.kr(0.025), \rel.kr(0.65)), \t_trig.kr(0), doneAction: 2);
		// 	sig = 4.collect {
		// 		SinOsc.ar( \freq.kr(32).midicps );
		// 	};

		// 	sig = Splay.ar( sig, 0.35, center: \pan.kr(0.0) );

		// 	Out.ar(\out.kr(0), sig * \vol.kr(0.35) * env);
		// }).add;


		// --------------------------------------------------------------

		SynthDef(\karp, {
			var sig;

			sig = Pluck.ar(WhiteNoise.ar(0.1), \t_trig.kr, 10000.reciprocal, \freq.kr(300).reciprocal, \decay.kr(3), coef: \shape.kr(0.5).linlin(0,1,-0.2,0.65));

			Out.ar(\out.kr(0), sig);
		
		}).add;

		// --------------------------------------------------------------

		SynthDef(\fold, {  // \t_trig, \freq, \fold.
			var sig, env, out, verb, dirt;

			env = EnvGen.kr(
				envelope: Env(
					[0,1,0], [\atk.kr(0.4), \rel.kr(2.6)], curve: \lin
					), 
				gate: \t_trig.kr(0), levelScale: 1, timeScale: 1, doneAction: 2);

			dirt = LFDNoise3.kr(25);

			sig = LPF.ar( 
				Fold.ar(
					XFade2.ar(
						SinOsc.ar(
							\freq.kr(64).midicps), 
						DPW3Tri.ar(
							\freq.kr.midicps),
						\fold.kr(0.1).linlin(0, 1, -1, 1) + dirt.linlin(0, 1, 0, 0.1)),
					-1 * (\fold.kr + dirt.linexp(0, 1, 0.01, 0.05)),
					\fold.kr + dirt.linexp(0, 1, 0.01, 0.05)
				) * env, 5000 );

			Out.ar(\out.kr(0), Splay.ar(sig*\vol.kr(0.1).linlin(0, 1, 0, 0.35))).tanh; // maybe over-did it with .tanh?
			Out.ar(\out.kr+2, Splay.ar(sig!2*\vol.kr).linlin(0, 1, 0, 0.35)).tanh;
		
		}).add;

		// --------------------------------------------------------------

		SynthDef(\verb, {  // simple big room reverb.
			var in, sig;

			in = In.ar(\in.kr(2), 2); // ------- In.ar is different from SoundIn.ar. 
									  // ------- First takes signal from internal bus
									  // ------- Last only takes signal from sound card.
			sig = NHHall.ar(in: in, rt60: 14, stereo: 0.5, modRate: 0.2, modDepth: 0.3);
			
			Out.ar(\out.kr(0), Splay.ar(sig*( \verbVol.kr(0.4).linlin(0, 1, 0, 0.5) - (0.5 * 0.2 )) )).tanh; // .tanh smoothes out the out signal
			Out.ar(\out.kr, 
				Fold.ar(
					sig, 
					-1 * \verbFold.kr(0.2),
					\verbFold.kr)
				*\verbVol.kr.linlin(0, 1, 0, 0.4)).tanh;
		}).add;
		
		// --------------------------------------------------------------

		SynthDef(\sideVerb, {  // extra reverb chain for side-melody.
			var in, sig;

			in = In.ar(\in.kr(2), 2); // ------- In.ar is different from SoundIn.ar. 
									  // ------- First takes signal from internal bus
									  // ------- Last only takes signal from sound card.
			sig = NHHall.ar(in: in, rt60: 14, stereo: 0.5, modRate: 0.2, modDepth: 0.3);
			
			Out.ar(\out.kr(0), Splay.ar(sig*( \verbVol.kr(0.4).linlin(0, 1, 0, 0.5) - 0.2) )).tanh; // .tanh smoothes out the out signal
			Out.ar(\out.kr, Splay.ar(Fold.ar(sig, -1 * (\verbFold.kr(0.2)), \verbFold.kr)*\verbVol.kr.linlin(0, 1, 0, 0.5))).tanh;
		}).add;

		// --------------------------------------------------------------

		SynthDef(\lead, {  // arguments list: env: \atk, \rel, t_trig, mod: \modFreq, \modAmount, \modFold, sig: \carFold.
			var sig, env, mod, dirt;

			env = EnvGen.kr(
				Env(
					[0.001, 1, 0.001], 
					[\atk.kr(0.5), \rel.kr(2)],
					curve: \sqr),
					gate: \t_trig.kr(0),
					doneAction: 2
				);

			dirt = Dust.kr(0.5);

			mod = Fold.ar(
				LFTri.ar( 
					\modFreq.kr( 36.5 ), 
					mul: \modAmount.kr(0.05).linlin(0.3, 1, 0, 0.75)
				), 
				-1 * \modFold.kr(1), 
				\modFold.kr
			);
			// Tried LFTri as soundsource for carrier, but does not support fm through phase modulation since iphase only
			// sets initial phase.
			sig = Fold.ar(
				LFTri.ar(
					\freq.kr( 32 ).midicps, mod
				), 
				-1 * \carFold.kr(1) + env.linlin(0, 1, 1, 0), 
				\carFold.kr + env.linlin(0, 1, 1, 0)
			);

			Out.ar(\out.kr(0), Splay.ar(sig!2*env*\vol.kr(0.05).linlin(0, 1, 0, 0.35))).tanh;
			Out.ar(\out.kr(0)+2, Splay.ar(sig!2*env*\vol.kr.linlin(0, 1, 0, 0.35))).tanh;
		}).add;
		
		// --------------------------------------------------------------
		
		SynthDef(\passThru, {
			var sig = SoundIn.ar([\in.kr(0), \in.kr+1], mul: \passThruVol.kr(0.6));
			Out.ar(\out.kr(0), sig);
			Out.ar(\out.kr + 2, sig);
		}).add;

		// --------------------------------------------------------------

	}

}
