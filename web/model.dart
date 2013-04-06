import "dart:async";
import "dart:math";
import "package:web_ui/web_ui.dart";
import 'package:web_ui/watcher.dart' as watchers;
import "model2.dart" as m2;

List<m2.Track> cts;

const int TICKS = 32;
int _currentTick = 0;
StreamController<int> currentTickSC = new StreamController.broadcast();
int get currentTick => _currentTick;
Stream<int> get onTickChange => currentTickSC.stream;
set currentTick(int newValue) {
  _currentTick = newValue;
  currentTickSC.add(newValue);
}

int _currentBpm = 160;
StreamController<int> currentBpmSC = new StreamController.broadcast();
int get currentBpm => _currentBpm;
Stream<int> get onCurrentBpmChange => currentBpmSC.stream;
set currentBpm(int newValue) {
  _currentBpm = newValue;
  currentBpmSC.add(newValue);
}

class TrackChangeEvent {
  int pitch;
  int tick;
  m2.Track track;
  String state;
  
  TrackChangeEvent(this.track, this.pitch, this.tick, this.state);
}

StreamController<TrackChangeEvent> tcec = new StreamController.broadcast();
Stream<TrackChangeEvent> onTrackChange = tcec.stream;

class Track {
  String instrument;
  List<Note> notes = <Note>[];
  Map<String, String> grid;
  int ti;
  Map<int, Note> pitchToNote = new Map<int, Note>();
  Track(InstrumentModel im, this.grid, this.ti) {
    this.instrument = im.uiName;
    for (Pitch p in im.pitches) {
      var note = new Note(p, grid, this);
      notes.add(note);
      pitchToNote[p.pitch] = note;
    }
  }
  
  setState(int tick, int pitch, String state) {
    Note note = pitchToNote[pitch];
    note.setState(tick, state);
  }
}

class Note {
  Map<String, String> grid;
  Pitch pitch;
  List<Cell> cells;
  Track t;

  Note(this.pitch, this.grid, this.t) {
    cells = new List();
    cells.add(new HeaderCell());
    for (var i = 0; i < TICKS; i++) {
      cells.add(new Tick(this, i, grid));
    }
    for (var i = 1; i < 33; i++) {
      Tick tick = cells[i];
      tick.init();
    }
  }

  String get name => pitch.uiName;

  setState(int tick, String state) {
    Tick cell = cells[tick + 1];
    cell.state = state;
  }
}

abstract class Cell {
  Map<String, String> get style;
  String get cssClass;
}

Map<String, String> EMPTY_MAP = new Map();

class HeaderCell extends Cell {
  Map<String, String> get style => EMPTY_MAP;
  String get cssClass => "headerCell";
}

var STATES = <String>["_", "x", "="];

/// Notifies subscribers when a string changes
class StringChangeStream extends Stream<String> {
  fireChange(String value) {
  }
}

class Tick extends Cell {

  Map<String, String> grid;
  /// Note that owns this tick cell
  Note owner;
  /// Tick index in the list of ticks
  int index;
  /// True state of the tick
  String _state;
  /// Broadcasts state change events
  StreamController<String> stateStreamController = new StreamController.broadcast();
  /// Determines UI decorations
  String uiState;
  bool isPlaying = false;
  /// Neighboring ticks
  Tick left, right;

  Tick(this.owner, this.index, this.grid) {
    String s = grid["${this.index}:${owner.pitch.pitch}"];
    if (s != null) {
      this._state = s;
    } else {
      this._state = "_";
    }
  }

  init() {
    int leftIndex = index;
    if (leftIndex > 0) {
      left = owner.cells[leftIndex];
      left.onChange.listen((String) {
        computeUiState();
      });
    } else {
      left = null;
    };
    int rightIndex = index + 2;
    if (rightIndex < owner.cells.length) {
      right = owner.cells[rightIndex];
      right.onChange.listen((String) {
        computeUiState();
      });
    } else {
      right = null;
    };
    this.onChange.listen((String) {
      computeUiState();
    });
    computeUiState();
    onTickChange.listen((int tick) {
      bool newIsPlaying = ((tick - 2) % TICKS) == index;
      if (newIsPlaying != isPlaying) {
        isPlaying = newIsPlaying;
        watchers.dispatch();
      }
    });
    onTrackChange.listen((TrackChangeEvent e) {
      if (e.track.getId() == owner.t.ti && e.pitch == owner.pitch.pitch && e.tick == this.index) {
        this.state = e.state;
      }
    });
  }

  Stream get onChange => stateStreamController.stream;

  String get state {
    return _state;
  }

  String set state(String newState) {
    bool stateChanged = _state != newState;
    if (stateChanged) {
      _state = newState;
      grid["${this.index}:${owner.pitch.pitch}"] = newState;
      if (stateStreamController.hasSubscribers) {
        stateStreamController.add(newState);
      }
      int ti = owner.t.ti;
      m2.Track ct = cts[ti];
      ct.setValue(owner.pitch.pitch, this.index, newState);
    }
  }

  computeUiState() {
    if (this.state == "_") {
      uiState = "EMPTY";
    } else if (this.state == "=") {
      bool starts = left == null || left.state == "_";
      bool ends = right == null || right.state != "=";
      uiState = getUiState(starts, ends);
    } else {
      bool ends = right == null || right.state != "=";
      uiState = getUiState(true, ends);
    }
  }

  String getUiState(bool starts, bool ends) {
    if (starts && ends) {
      return "STARTS_ENDS";
    } else if (starts) {
      return "STARTS";
    } else if (ends) {
      return "ENDS";
    } else {
      return "CONTINUES";
    }
  }

  String get cssClass => "noteCell";
}

class InstrumentModel {
  String uiName;
  List<Pitch> pitches;
  InstrumentModel(this.uiName, this.pitches);
}

class Pitch {
  int pitch;
  String uiName;
  Pitch(this.pitch, this.uiName);
  String toString() {
    return "Pitch(${pitch}, ${uiName})";
  }
}
