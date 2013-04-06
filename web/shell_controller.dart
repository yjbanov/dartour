library controllers;

import "model.dart";
import "track_player.dart" as p;

class ShellController {
  List<Track> tracks = new List();
  RegExp regex = new RegExp(r"(\d+):(\d+)");
  
  ShellController(Map<String, InstrumentModel> instrModels) {
    int ti = 0;
    p.model['tracks'].forEach((Map dTrack) {
      String instrument = dTrack['instrument'];
      InstrumentModel im = instrModels[instrument];
      Map<String, String> dGrid = dTrack['grid'];
      Track track = new Track(im, dGrid, ti++);
      tracks.add(track);
    });
  }
}
