import "package:web_ui/web_ui.dart";
import "dart:html";
import "model.dart";

class CellComponent extends WebComponent {
  Track track;
  Tick tick;

  cellClicked(var evt) {
    tick.state = STATES[(STATES.indexOf(tick.state) + 1) % STATES.length];
  }
}
