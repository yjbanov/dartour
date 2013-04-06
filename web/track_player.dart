import 'dart:html';
import 'dart:web_audio';
import 'dart:async';
import 'dart:math';
import 'model.dart' as m;

AudioContext audioContext = new AudioContext();
TrackPlayer player = new TrackPlayer(audioContext);
const String kPercussion = 'percussion';

final organEnvelope = [0.05, 0.0, 1.0, 0.08];
final malletEnvelope = [0.01, 1.0, 0.0, 1.0];
final pianoEnvelope = [0.01, 1.0, 0.2, 0.1];

var instrument_data = {
    'sine': { 'oscillator_type': 'sine', 'envelope': organEnvelope },
    'square': { 'oscillator_type': 'square', 'envelope': organEnvelope },
    'sawtooth': { 'oscillator_type': 'saw', 'envelope': organEnvelope },
    'even_harmonics': { 'oscillator_type': 'custom', 'harmonics': [6, 1, 0, 1, 0, 1, 0, 1], 'envelope': organEnvelope},
    'odd_harmonics': { 'oscillator_type': 'custom', 'harmonics': [6, 0, 1, 0, 1, 0, 1, 0, 1], 'envelope': organEnvelope},
    'octave_harmonics': { 'oscillator_type': 'custom', 'harmonics': [6, 1, 0, 1, 0, 0, 0, 1], 'envelope': organEnvelope},
    'fractional_harmonics_1': { 'oscillator_type': 'custom', 'harmonics': [0, 0, 6, 1, 1, 1, 1], 'denominator': 3, 'envelope': organEnvelope},
    'fractional_harmonics_2': { 'oscillator_type': 'custom', 'harmonics': [0, 0, 6, 0, 2, 0, 2], 'denominator': 3, 'envelope': organEnvelope},
    'xylophone': { 'oscillator_type': 'sine', 'envelope': malletEnvelope },
    'piano': {'envelope': pianoEnvelope,
              'denominator': 3,
              'harmonics': [0, 0, 8, 7, 6, 7, 6, 5, 6, 5, 4, 5, 4, 3, 4],
              'oscillator_type': 'custom'},
     'synth': {'envelope': organEnvelope,
               'oscillator_type': 'saw',
               'filter': {'type': 'lowpass', 'q': 5}},
};

Map<String, List<Map>> model = {
    'tracks': []
};

class TrackPlayer {
  var model;
  var instruments;
  var percussion_instruments;
  final AudioContext audioContext;
  var destinationNode;
  bool needToRestartTimer = false;
  var track_note = {}; // maps track id to another map
                       // which maps instrument# -> Node
  Timer timer = null;
  
  bpmChanged(int newValue) {
    needToRestartTimer = true;
  }
  
  TrackPlayer(this.audioContext) {
    m.onCurrentBpmChange.listen(bpmChanged);
  }
  
  keyState(track, tick, pitch) {
    var key = '${tick}:${pitch}';
    var val = track['grid'][key];
    if (val == null)
      return '_';
    return val;
  }
  
  void OnTick(Timer timer) {
    var tracks = model['tracks'];
    tracks.forEach((track) {
      var track_id = track['id'];
      var track_instrument = track['instrument'];
      var tracked_notes = track_note[track_id];
      // TODO(kurovtsev): optimize when we handle Google Drive Realtime model events.
      for (int pitch = 1; pitch < 128; pitch++) {
        var previous_note = tracked_notes == null ? null : tracked_notes[pitch];
        var key_state = keyState(track, m.currentTick, pitch);
        if ((key_state == '_' || key_state == 'x') && previous_note != null) {
          previous_note.gain.exponentialRampToValueAtTime(0, instruments.GetReleaseTime(track_instrument));
          new Timer(new Duration(seconds: 5), () => previous_note.disconnect(0));
//          previous_note.disconnect(0);
          tracked_notes.remove(pitch);
        }
        if (key_state == 'x') {
          var source;
          if (track_instrument == kPercussion) {
            source = percussion_instruments.CreateInstrumentNode(track_instrument, pitch);
            source.connect(destinationNode, 0, 0);
            source.noteOn(0);
          } else {
            source = instruments.CreateHarmonicsNode(track_instrument, pitch);
            source.connect(destinationNode, 0, 0);
            track_note.putIfAbsent(track_id, () => new Map<int, AudioNode>());
            track_note[track_id][pitch] = source;
          }
        }
      }
    });
    m.currentTick = (m.currentTick + 1) % m.TICKS;
    if (needToRestartTimer) {
      timer.cancel();
      startTimer();
    }
  }
  
  void startTimer() {
    needToRestartTimer = false;
    var duration = new Duration(milliseconds: Duration.MILLISECONDS_PER_MINUTE~/m.currentBpm);
    timer = new Timer.periodic(duration, OnTick);
  }
  
  void Play(model, percussion_instruments, instruments) {
    destinationNode = audioContext.createGainNode();
    destinationNode.connect(audioContext.destination, 0, 0);
    
    this.model = model;
    this.percussion_instruments = percussion_instruments;
    this.instruments = instruments;
    startTimer();
  }

  void Stop() {
    if (this.timer != null) {
      this.timer.cancel();
      this.timer = null;
    }
  }
}

class Instruments {
  final audioContext;
  final instrumentData;
  Map<String, WaveTable> wavetables = {};
  
  CreateWaveTable(harmonics) {
    Float32Array re = new Float32Array(harmonics.length + 1);
    re[0] = 0;
//    re.setRange(1, harmonics.length, harmonics);
    for (int i = 0; i < harmonics.length; i++) {
      re[i + 1] = harmonics[i];
    }
    Float32Array im = new Float32Array(harmonics.length + 1);
    return audioContext.createWaveTable(re, im);
  }
  
  Instruments(this.audioContext, this.instrumentData) {
    this.instrumentData.forEach((name, v) {
      var harmonics = v['harmonics'];
      if (v['oscillator_type'] == 'custom' && harmonics != null) {
        var wt = CreateWaveTable(harmonics);
        wavetables[name] = wt;
      }
    });
  }
  
  GetReleaseTime(instrument_name) {
    var instrument = instrumentData[instrument_name];
    if (instrument['envelope'] != null) {
      return instrument['envelope'][3];
    }
    return 0;
  }
  
  getHertz(pitch) {
    return 440 * pow(2, (pitch - 49) / 12);
  }
  
  CreateHarmonicsNode(name, note) {
    var instrument = instrumentData[name];
    var denominator = instrument['denominator'];
    var oscillator = audioContext.createOscillator();
    oscillator.type = instrument['oscillator_type'];
    if (wavetables[name] != null) {
      oscillator.setWaveTable(wavetables[name]);
    }
    double hertz = getHertz(note);
    oscillator.frequency.value = hertz / (denominator == null ? 1 : denominator);
    
    var gain = audioContext.createGainNode();
    
    if (instrument['filter'] != null) {
      var filterDescriptor = instrument['filter'];
      var filter = audioContext.createBiquadFilter();
      filter.type = filterDescriptor['type'] == null ? 'lowpass' : filterDescriptor['type'];
      filter.frequency.value = hertz;
      if (filterDescriptor['q'] != null) {
        filter.Q.value = filterDescriptor['q'];
      }
      oscillator.connect(filter, 0, 0);
      filter.connect(gain, 0, 0);
    } else {
      oscillator.connect(gain, 0, 0);
    }
    
    oscillator.noteOn(0);
    
    return ApplyEnvelope(gain, instrument['envelope']);
  }
  
  ApplyEnvelope(gainNode, envelopeData) {
    gainNode.gain.setValueAtTime(0.0, 0.0);
    gainNode.gain.linearRampToValueAtTime(1.0, envelopeData[0]);
    gainNode.gain.setTargetValueAtTime(envelopeData[2], envelopeData[0], envelopeData[1]);
    return gainNode;
  }
}

class PercussionInstruments {
  final audioContext;
  var percussion_patches = new Map<int, AudioBuffer>();
  var inflight = [];
  
  PercussionInstruments(this.audioContext) {
  }
  
  Future LoadPercussion(instrument_number, url) {
    Completer c = new Completer();
    inflight.add(c.future);
    var response_future = HttpRequest.request(url, method: "GET", responseType: "arraybuffer");
    response_future.then((http_response) {
      print('Loaded ' + url);
      // asynchronous decoding
      audioContext.decodeAudioData(http_response.response, (buffer) {
        percussion_patches[instrument_number] = buffer;
        print('Decoded ' + url);
        c.complete(instrument_number);
      }, (error) {
        print('Error decoding wav file');
        c.completeError(error);
      });
    }).catchError((exception) => c.completeError(exception));
    return c.future;
  }
  
  Future<List> WaitForLoad() {
    return Future.wait(inflight);
  }
  
  CreateInstrumentNode(name, pitch) {
    var source = audioContext.createBufferSource();
    source.buffer = percussion_patches[pitch];
    return source;
  }
}

start_player() {
  var instruments = new Instruments(audioContext, instrument_data);
  var percussion_instruments = new PercussionInstruments(audioContext);
  percussion_instruments.LoadPercussion(42, '../percussion/hihat-cl.wav');
  percussion_instruments.LoadPercussion(38, '../percussion/snare.wav');
  percussion_instruments.LoadPercussion(36, '../percussion/bass-drum.wav');
  // TODO(kurovtsev): ugly code.
  percussion_instruments.WaitForLoad().then((x) {
    print('all loaded');
    player.Play(model, percussion_instruments, instruments);
  });
}

stop_player() {
  player.Stop();
}
