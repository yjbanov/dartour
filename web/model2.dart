import 'dart:html';
import 'package:js/js.dart' as js;

class CollaborativeMap {
  js.Proxy proxy;
  CollaborativeMap(js.Proxy proxy) {
    this.proxy = proxy;
  }
  
  int getInt(String key) {
    int result = proxy.get(key);
    return result;
  }
  
  String getString(String key) {
    String result = proxy.get(key);
    return result;
  }
  
  CollaborativeMap getMap(String key) {
    js.Proxy inner = proxy.get(key);
    return new CollaborativeMap(inner);
  }
  
  CollaborativeList getList(String key) {
    js.Proxy inner = proxy.get(key);
    return new CollaborativeList(inner);
  }
  
  JsArray items() {
    js.Proxy inner = proxy.items();
    return new JsArray(inner);
  }
  
  setString(String key, String value) {
    proxy.set(key, value);
  }
  
  void addValueChangedListener(js.Callback callback) {
    var EventType = js.context.gapi.drive.realtime.EventType;
    proxy.addEventListener(EventType.VALUE_CHANGED, callback);
  }
  
  CollaborativeMap retain() {
    js.retain(proxy);
    return this;
  }
}

class CollaborativeList {
  js.Proxy proxy;
  CollaborativeList(js.Proxy inner) {
    proxy = inner;
  }
  int length() {
    return proxy.length;
  }
  CollaborativeMap getMap(int index) {
    js.Proxy inner = proxy.get(index);
    if (inner == null) {
      throw "no such map at %{index}";
    }
    return new CollaborativeMap(inner);
  }
  JsArray items() {
    return new JsArray(proxy.asArray());
  }
}

class JsArray {
  js.Proxy proxy;
  JsArray(js.Proxy proxy) {
    this.proxy = proxy;
  }
  int length() {
    return proxy.length;
  }
  int getInt(int index) {
    int result = proxy[index];
    return result;
  }
  String getString(int index) {
    String result = proxy[index];
    return result;
  }
  JsArray getArray(int index) {
    js.Proxy inner = proxy[index];
    return new JsArray(inner);
  }
  CollaborativeMap getMap(int index) {
    js.Proxy inner = proxy[index];
    return new CollaborativeMap(inner);
  }
}

class Track {
  CollaborativeMap track;
  Track(CollaborativeMap inner) {
    inner.retain();
    this.track = inner;
  }
  
  int getId() {
    //print("Track.getId()");
    return js.scoped(() {
      return track.getInt("id");
    });
  }
  
  String getInstrument() {
    print("Track.getInstrument()");
    return js.scoped(() {
      return track.getString("instrument");
    });
  }
  
  List<int> getPitches() {
    print("Track.getPitches()");
    return js.scoped(() {
      JsArray items = track.getMap("grid").items();
      List<int> result = new List();
      for (int i = 0; i < items.length(); i++) {
        JsArray pair = items.getArray(i);
        List<String> key = pair.getString(0).split(":");
        int pitch = int.parse(key[1]);
        result.add(pitch);
      }
      result.sort();
      return result;
    });
  }
  
  String getValues(int pitch) {
    print("Track.getValues()");
    return js.scoped(() {
      List<String> result = new List();
      JsArray items = track.getMap("grid").items();
      for (int i = 0; i < items.length(); i++) {
        JsArray pair = items.getArray(i);
        List<String> key = pair.getString(0).split(":");
        int tick = int.parse(key[0]);
        int candidatePitch = int.parse(key[1]);
        if (pitch == candidatePitch) {
          if (result.length <= tick) {
            result.addAll(new List.filled(tick + 1 - result.length, "_"));
          }
          String value = pair.getString(1);
          result[tick] = value;
        }
      }
      return result.join("");
    });
  }
  
  void setValue(int pitch, int tick, String value) {
    print("Track.setValues()");
    js.scoped(() {
      CollaborativeMap grid = track.getMap("grid");
      String key = "${tick}:${pitch}";
      grid.setString(key, value);
    });
  }
  
  setValueChangedListener(Function onChange) {
    js.scoped(() {
      var callback = new js.Callback.many((e) {
        print("got a change");
        List<String> key = e.property.split(":");
        int tick = int.parse(key[0]);
        int pitch = int.parse(key[1]);
        String value = e.newValue;          
        onChange(this, pitch, tick, value);
      });
      track.getMap("grid").addValueChangedListener(callback);
    });
  }
  
  String toString() {
    print("Track.toString()");
    var out = new StringBuffer();
    out.writeln("id=${getId()}");
    out.writeln("instrument=${getInstrument()}");
    out.writeln("grid:");
    for (int pitch in getPitches()) {
      out.writeln("${pitch} => ${getValues(pitch)}");
    }
    return out.toString();
  }
}


loadDriveDocument(Function ready) {

    onFileLoaded(js.Proxy rootProxy) {
      print("loaded");
      CollaborativeMap root = new CollaborativeMap(js.retain(rootProxy));
  
      JsArray trackProxies = root.getList("tracks").items();
      List<Track> tracks = new List();
      for (int i = 0; i < trackProxies.length(); i++) {
        CollaborativeMap trackProxy = trackProxies.getMap(i);
        Track track = new Track(trackProxy);
        print("track loaded: ${track.getId()}");
        tracks.add(track);
      }
      ready(tracks);
    }
      
    js.scoped(() {
      js.context.startRealtime(new js.Callback.many(onFileLoaded));
    });
}