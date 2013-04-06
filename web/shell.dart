import "package:web_ui/web_ui.dart";
import "shell_controller.dart";
import "track_player.dart" as p;
import "model.dart" as m;

class Shell extends WebComponent {

  ShellController controller;
  int bpm;
  
  Shell() {
    this.bpm = m.currentBpm;
    m.onCurrentBpmChange.listen((int x) {
      this.bpm = x;
    });
  }
  
  start_player(event) {
    p.start_player();
  }
  stop_player(event) {
    p.stop_player();
  }
  
  incbpm(evt) {
    m.currentBpm = m.currentBpm + 10;
  }
  decbpm(evt) {
    m.currentBpm = m.currentBpm - 10;
  }
}
