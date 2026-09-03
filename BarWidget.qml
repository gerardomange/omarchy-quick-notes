import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "gmvs.quick-notes"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰠮"
    tooltipText: "Quick Notes (Super+N)"
    onPressed: function(buttonCode) {
      if (root.bar && typeof root.bar.run === "function") {
        root.bar.run("omarchy-shell shell toggle gmvs.quick-notes '{}'")
      } else {
        Quickshell.execDetached(["/usr/share/omarchy/bin/omarchy-shell", "shell", "toggle", "gmvs.quick-notes", "{}"])
      }
    }
  }
}
