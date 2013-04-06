import 'model2.dart';
import 'dart:html';
import 'dart:math';

ready(List<Track> tracks) {
  for (Track track in tracks) {
    print("${track}");
    track.setValueChangedListener((Track track, int pitch, int tick, String newValue) {
        print("changed: ${pitch}, ${tick}, ${newValue}");
        print("new track: ${track}");
    });
  }
  Element trackElt = query("#track");
  Element tickElt = query("#tick");
  Element pitchElt = query("#pitch");
  Element valueElt = query("#value");
  Element submit = query("#submit");
  submit.onClick.listen((e) {
    int trackIndex = int.parse(trackElt.value);
    int tick = int.parse(tickElt.value);
    int pitch = int.parse(pitchElt.value);
    String value = valueElt.value;
    Track track = tracks[trackIndex];
    track.setValue(pitch, tick, value);
  });
  submit.disabled = false;
}


main() {
  loadDriveDocument(ready);
}

