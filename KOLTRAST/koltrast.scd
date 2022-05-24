
// TODO: 
// Create pingable filter synth, pinged by a Dust.kr, an airy eerie drone with emphasis on higher register.
// Create fft pitch tracking of koltrastar

// TODO: Now everything sounds pretty good in respect to the trigger function based on volume range of fieldrec.
// Should do a new layer, use this state as a backdrop for something more structured.


// TODO: make DWG synth move more, melody or movement in chords. 
// TODO: write more clear bass line
// TODO: write more interesting bass sound synth

s.options.outDevice = "Built-in Output";
s.options.inDevice = "Built-in Input";
s.options.outDevice;
ServerOptions.outDevices;
s.options.outDevice = "UltraLite AVB";
s.options.inDevice = "UltraLite AVB";
s.options.outDevice = "16A";
s.options.inDevice = "16A";
s.options.outDevice = "BlackHole 16ch";

s.options.outDevice = "Soundflower (2ch)";
s.options.inDevice = "Soundflower (2ch)";
s.reboot;
s.meter; 
s.plotTree;
s.makeGui
Server.killAll;

s.waitForBoot( { 
	var koltrast = Buffer.read(
		s,
		"./samples/ZOOM0078_LR.WAV"
	);
	var tempo = TempoClock.new(54/60);
	s.sync;
	MIDIClient.init;	
	// m = MIDIClockOut.new("UltraLite AVB", "MIDI Out", tempo);
	f = SixteenFaders.new;
	s.sync;
	
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
			
			~steth = Stethoscope.new(s, 4);
			~steth.window.alwaysOnTop = true;
	
		} 
	);


	// if (s.options.outDevice != "UltraLite AVB") {
	// 	s.options.outDevice = "UltraLite AVB";
	// 	s.options.inDevice = "UltraLite AVB";
	// 	"REBOOT: WRONG AUDIO DEVICE".postln;
	// 	s.reboot;
	// };

	s.sync;

	// SYNTHDEFS and Buffer assign

	Koltrast.new(koltrast);

	/// EQ ///

	SynthDef(\eq, {
		var in, eq;

		in = In.ar(0, 2);
		eq = BPeakEQ.ar(in, \freq.kr(150), \width.kr(1), \db.kr(-6), 0.5);
		Out.ar(0, eq);
	}).add;

	~eq = Synth(\eq); 
	~eq.set(\freq, 100, \width, 2, \db, -12);

	/// /// ///

	// AUX SYNTHDEFS (not used)

	SynthDef(\passThru, {
		var in;
		in = SoundIn.ar(\in.kr(8), \vol.kr(0.5));
		Out.ar(\out.kr(0), in!2);
	}).add;

	SynthDef(\euroThru, {
		var in;
		in = SoundIn.ar([ \in.kr(4), \in.kr + 1 ], \vol.kr(0.5));
		Out.ar(\out.kr(0), in);
	}).add;

	SynthDef(\springOut, {
		var in;
		in = In.ar(0, 2);
		Out.ar(\out.kr(6), in);
	}).add;
	
	s.sync;

	
	// ROUTINES 

	~rutt1 = Routine(
		{

			fork{
				var fund;
				var phys0, phys1, phys2, phys3, phys4;
				var pos = 5.collect({1.0.sum3rand});
				phys0 = Synth(\phys, 
					[\freq, 196, \rel, 1, \pos, pos[0], \vol, f.faderAt(9).asMap]);	// G
				phys1 = Synth(\phys,
					[\freq, 174, \rel, 1, \pos, pos[1], \vol, f.faderAt(9).asMap]);   // F
				phys2 = Synth(\phys,
					[\freq, 196/2,\rel, 1, \pos, pos[2], \vol, f.faderAt(9).asMap]); // G
				phys3 = Synth(\phys,
					[\freq, ( 175*3 ) / 2,\rel, 1, \pos, pos[3], \vol, f.faderAt(9).asMap]); // C
				phys4 = Synth(\phys,
					[\freq, ( 102*3 ) / 2, \rel, 1, \pos, pos[4], \vol, f.faderAt(9).asMap]); // Eb
				// 15.wait;

				loop{
					format("StereoPos: %", pos).postln;
					phys0.set(\freq, 103, \pos, pos[0]);  // Ab
					phys1.set(\freq, 116, \pos, pos[1]);  // Bb
					phys4.set(\freq, (116*3) / 2, \pos, pos[4]); // F
					phys3.set(\freq, 196*2, \pos, pos[3]); // G
					15.wait;
					pos = 5.collect({1.0.sum3rand});
					format("StereoPos: %", pos).postln;

					phys4.set(\freq, 138, \pos, pos[4]); // Db
					phys1.set(\freq, 174, \pos, pos[1]); // F 
					phys2.set(\freq, (175.2*3) / 2, \pos, pos[2]); // C
					phys3.set(\freq, (102.3*3) / 2, \pos, pos[3]); // Eb 
					phys0.set(\freq, 69.3, \pos, pos[0]); // Db
					15.wait;
					pos = 5.collect({1.0.sum3rand});
					format("StereoPos: %", pos).postln;

					phys0.set(\freq, (196*2), \pos, pos[0]);  // G
					phys4.set(\freq, (102.3*3)/4, \pos, pos[4]);  // Eb
					phys2.set(\freq, 116, \pos, pos[2]);  // Bb
					phys3.set(\freq, (196/2), \pos, pos[3]);  // G
					15.wait;
					pos = 5.collect({1.0.sum3rand});
					format("StereoPos: %", pos).postln;

					phys0.set(\freq, 196, \pos, pos[0]); // G
					phys1.set(\freq, 174, \pos, pos[1]); // F
					phys2.set(\freq, 196/2, \pos, pos[2]);  // G
					phys3.set(\freq, ( 175*3 ) / 2, \pos, pos[3]);
					phys4.set(\freq, ( 102*3 ) / 2, \pos, pos[4]);
					15.wait;
					pos = 5.collect({1.0.sum3rand});
					format("StereoPos: %", pos).postln;

				}
			};
			fork{
				var caust0, caust1, count = 0, cond = 0;
				var db = 69.3, eb = 77.8, g = 98, ab = 51.9;

				loop{
					if(cond == true) 
					{
						caust0 = Synth(\caust, 
							[\freq, db, \t_trig, 1, \rel, 7.5,  \vol, f.faderAt(8).asMap], 
							addAction: \addToHead);
						// caust1 = Synth(\caust, 
						// 	[ \freq, db*3, \t_trig, 1, \rel, 5, \vol, f.faderAt(8).asMap ],
						// 	addAction: \addToHead);
						"Db Ab".postln;
						15.wait;
						// cond = false;
					};
					// cond = true;

					caust0 = Synth(\caust, 
						[\freq, ab, \t_trig, 1, \rel, 4.25, \vol, f.faderAt(8).asMap],
						addAction: \addToHead); 
					// caust1 = Synth(\caust, 
					// 	[\freq, ab*3, \t_trig, 1, \rel, 4.25, \vol, f.faderAt(8).asMap],
					// 	addAction: \addToHead);
					"Ab Eb".postln;
					7.5.wait;

					caust0 = Synth(\caust,
						[\freq, eb, \t_trig, 1, \rel, 4.25, \vol, f.faderAt(8).asMap],
						addAction: \addToHead); 
					// caust1 = Synth(\caust,
					// 	[\freq, eb*3, \t_trig, 1, \rel, 4.25, \vol, f.faderAt(8).asMap],
					// 	addAction: \addToHead);
					"Eb Bb".postln;
					7.5.wait;

					count = count + 1;

					if(count == 4) {
						caust0 = Synth(\caust, 
							[\freq, db * 5/4, \t_trig, 1, \rel, 7.5, \vol, f.faderAt(8).asMap],
							addAction: \addToHead); 
						// caust1 = Synth(\caust,
						// 	[\freq, ab*3, \t_trig, 1, \rel, 7.5, \vol, f.fader[8].asMap],
						// 	addAction: \addToHead);
						"G D".postln;
						15.wait;
						cond = false;
						count = 0;
					}{
						cond = true;
					}
				}
			};
			fork{ // Perc from short samples of koltrast sample
				var rPos0 = rrand(0.0, 1.0);
				var rPos1 = rrand(0.0, 1.0);
				var rPos2 = rrand(0.0, 1.0);
				var rPos3 = rrand(0.0, 1.0);
				var count = 0;
				var pos = 0;
				loop{

					if ((count % 4) == 0){pos = rPos0};
					if ((count % 4) == 1){pos = rPos1};
					if ((count % 4) == 2){pos = rPos2};
					if ((count % 4) == 3){pos = rPos3};

					count = count + 1;
					{
						PlayBuf.ar(2, koltrast, 0.35, 1, BufFrames.kr(koltrast) * 
						f.faderAt(13).getSynchronous) 
						* EnvGen.kr(
							Env.perc(
								f.faderAt(11).getSynchronous.linlin(0, 1, 0, 0.15), 
								f.faderAt(11).getSynchronous.linlin(0, 1, 0, 1.8) 
							), 
							1, doneAction: 2)
						* f.faderAt(14).getSynchronous;
					}.play;
					// 3.75.wait;
					wait(3.75 / f.faderAt(12).getSynchronous.linlin(0, 1, 1, 64).round(1));
					//( 0.234375 ).wait;
				}
			}
		}
	);

	SystemClock.play(~rutt1);
	s.sync;

	// CREATE SYNTHS:


	~kol = Synth(\playback, [\rate, 0.35, \t_trig, 1, \vol, f.faderAt(15).asMap]);
	~kol.set(\hpf, 500);
	~verb = Synth(\verb, [\verbTime, f.faderAt(4).asMap, \verbVol, f.faderAt(5).asMap]);
	s.sync;
	~follow2 = Synth(\demandSynth2, 
		[ \loThresh, f.faderAt(1).asMap,
			\atk, f.faderAt(2).asMap,
			\rel, f.faderAt(3).asMap,
			\verbTime, f.faderAt(4).asMap,
			\verbVol, f.faderAt(5).asMap,
			\vol, f.faderAt(6).asMap,
			\hpf, 350],
			addAction: \addToTail); 

	~caust = Synth(\caust, [\t_trig, 0, \cutoff, f.faderAt(7).asMap]);
	// ~follow = Synth(\demandSynth, addAction: \addToTail);



// m.play;
4.2.wait;
//~pat.play;
// ~pat2.play;
});

(
var koltrast = Buffer.read(s, "/Users/viktorsandstrom/Documents/DAW/SC/Koltrast/ZOOM0078_LR.WAV");
{PlayBuf.ar(2, koltrast, 0.5, 1, BufFrames.kr(koltrast) * 0.34)
* EnvGen.kr(Env.perc(), 1, doneAction:2)}.play;
"bufloaded".postln;
)

0.042
