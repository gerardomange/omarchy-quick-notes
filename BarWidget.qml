import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

BarWidget {
  id: root

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰠮"
    tooltipText: "Quick Notes (Super+N)"
    onPressed: function(buttonCode) {
      Quickshell.execDetached(["omarchy-shell", "shell", "toggle", "gmvs.quick-notes", "{}"])
    }
  }
}
