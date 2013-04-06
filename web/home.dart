import "dart:html" as html;
import "shell_controller.dart";
import "model.dart";
import "model2.dart" as m2;
import 'package:web_ui/watcher.dart' as watchers;
import 'track_player.dart' as tp;

List<String> noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
ShellController shellController;

void main() {
  m2.loadDriveDocument(ready);
}

void ready(List<m2.Track> tracks) {
  var pianoPitches = <Pitch>[];
  for (int i = 42; i < 42 + 2 * 12; i++) {
    pianoPitches.add(new Pitch(i, noteNames[i % 12]));
  }
  var pianoModel = new InstrumentModel("Piano", pianoPitches);

  print(ALL_PERCS);
  var percussionModel = new InstrumentModel(
      "Percussion",
      [
       ALL_PERCS[1],
       ALL_PERCS[3],
       ALL_PERCS[7],
      ]
  );

  Map<String, InstrumentModel> instrumentModels = {
    'piano': pianoModel,
    'percussion': percussionModel,
  };
  
  List<Map> dest = [];
  for (m2.Track t in tracks) {
    var dt = {
      'id': t.getId().toString(),
      'instrument': t.getInstrument(),
      'grid': {},
    };
    for (int pitch in t.getPitches()) {
      String values = t.getValues(pitch);
      for (int tick = 0; tick < values.length; tick++) {
        dt['grid']["${tick}:${pitch}"] = values[tick];
      }
    }
    dest.add(dt);
    t.setValueChangedListener((m2.Track t, int pitch, int tick, String state) {
      print("addddd");
      tcec.add(new TrackChangeEvent(t, pitch, tick, state));
    });
  }
  tp.model["tracks"] = dest;
  cts = tracks;
  
  print("setting shellController");
  shellController = new ShellController(instrumentModels);
  watchers.dispatch();
  print("done");
}

List<Pitch> ALL_PERCS = <Pitch>[
        new Pitch(35, "Acoustic Base Drum"),
        new Pitch(36, "Bass Drum 1"),
        new Pitch(59, "Ride Cymbal 2"),
        new Pitch(60, "Hi Bongo"),
        new Pitch(37, "Side Stick"),
        new Pitch(61, "Low Bongo"),
        new Pitch(38, "Acoustic Snare"),
        new Pitch(62, "Mute Hi Conga"),
        new Pitch(39, "Hand Clap"),
        new Pitch(63, "Open Hi Conga"),
        new Pitch(40, "Electric Snare"),
        new Pitch(64, "Low Conga"),
        new Pitch(41, "Low Floor Tom"),
        new Pitch(65, "High Timbale"),
        new Pitch(42, "Closed Hi Hat"),
        new Pitch(66, "Low Timbale"),
        new Pitch(43, "High Floor Tom"),  
        new Pitch(67, "High Agogo"),
        new Pitch(44, "Pedal Hi-Hat"), 
        new Pitch(68, "Low Agogo"),
        new Pitch(45, "Low Tom"),
        new Pitch(69, "Cabasa"),
        new Pitch(46, "Open Hi-Hat"), 
        new Pitch(70, "Maracas"),
        new Pitch(47, "Low-Mid Tom"), 
        new Pitch(71, "Short Whistle"),
        new Pitch(48, "Hi Mid Tom"),
        new Pitch(72, "Long Whistle"),
        new Pitch(49, "Crash Cymbal 1"), 
        new Pitch(73, "Short Guiro"),
        new Pitch(50, "High Tom"),
        new Pitch(74, "Long Guiro"),
        new Pitch(51, "Ride Cymbal 1"), 
        new Pitch(75, "Claves"),
        new Pitch(52, "Chinese Cymbal"),
        new Pitch(76, "Hi Wood Block"),
        new Pitch(53, "Ride Bell"),
        new Pitch(77, "Low Wood Block"),
        new Pitch(54, "Tambourine"),  
        new Pitch(78, "Mute Cuica"),
        new Pitch(55, "Splash Cymbal"), 
        new Pitch(79, "Open Cuica"),
        new Pitch(56, "Cowbell"), 
        new Pitch(80, "Mute Triangle"),
        new Pitch(57, "Crash Cymbal 2"),  
        new Pitch(81, "Open Triangle"),
        new Pitch(58, "Vibraslap"),      
      ]..sort((Pitch a, Pitch b) => a.pitch - b.pitch);