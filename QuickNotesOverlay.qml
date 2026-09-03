import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui
import "NotesFormatter.js" as NotesFormatter

Item {
  id: root

  property string omarchyPath: Quickshell.env("OMARCHY_PATH")
  property var shell: null
  property var manifest: null

  property bool opened: false
  property bool loading: false
  property bool copied: false
  property string statsText: "0 lines · 0 words"

  property string notesPath: Quickshell.env("HOME") + "/.local/state/omarchy/quick-notes.md"
  property string fontFamily: Style.font.family
  property color background: Color.menu.background
  property color foreground: Color.menu.text
  property color border: Color.menu.border
  property var borderSpec: Border.surfaceSpec("menu", "border", border, Math.max(1, Style.space(2)))
  property color scrim: Color.menu.scrim
  readonly property int cornerRadius: Style.cornerRadius
  readonly property int contentMargin: Style.spacing.panelPadding

  readonly property int cardWidth: Math.min(Style.space(720), panel.width - Style.gapsOut * 2)
  readonly property int cardHeight: Math.min(Style.space(560), panel.height - Style.gapsOut * 2)

  function open(payloadJson) {
    root.opened = true
    Qt.callLater(function() {
      editor.forceActiveFocus()
      root.updateStats()
    })
  }

  function close() {
    root.saveNow()
    root.opened = false
  }

  function dismiss() {
    root.close()
    if (root.shell && typeof root.shell.hide === "function") {
      root.shell.hide((root.manifest && root.manifest.id) || "gmvs.quick-notes")
    }
  }

  function toggle() {
    if (root.opened) root.dismiss()
    else root.open("{}")
  }

  function loadNotes(content) {
    root.loading = true
    if (editor.text !== content) {
      editor.text = content || ""
    }
    root.loading = false
    root.updateStats()
  }

  function saveNow() {
    if (root.loading) return
    saveDebounceTimer.stop()
    notesFile.setText(editor.text)
  }

  function updateStats() {
    var s = NotesFormatter.getStats(editor.text)
    var text = s.lines + (s.lines === 1 ? " line" : " lines") + " · " + s.words + (s.words === 1 ? " word" : " words")
    if (s.tasks > 0) {
      text += " · " + s.doneTasks + "/" + s.tasks + " done"
    }
    root.statsText = text
  }

  function copyAll() {
    if (!editor.text) return
    Quickshell.execDetached(["bash", "-c", "printf %s " + Util.shellQuote(editor.text) + " | wl-copy"])
    root.copied = true
    copiedResetTimer.restart()
    Quickshell.execDetached([root.omarchyPath + "/bin/omarchy-notification-send", "-g", "󰠮", "Quick Notes", "Notes copied to clipboard"])
  }

  function clearNotes() {
    if (!editor.text) return
    editor.text = ""
    root.saveNow()
    root.updateStats()
    editor.forceActiveFocus()
  }

  function triggerReminder() {
    var reminder = NotesFormatter.parseReminder(editor)
    if (reminder) {
      Quickshell.execDetached([root.omarchyPath + "/bin/omarchy-reminder", String(reminder.minutes), reminder.message])
      root.dismiss()
    } else {
      Quickshell.execDetached([
        root.omarchyPath + "/bin/omarchy-notification-send",
        "-g", "󰢌",
        "Reminder Hint",
        "Format current line like '15m Call doctor' or '30 Check oven' to set a reminder"
      ])
    }
  }

  FileView {
    id: notesFile
    path: root.notesPath
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: root.loadNotes(text())
    onLoadFailed: root.loadNotes("")
    onFileChanged: reload()
  }

  Timer {
    id: saveDebounceTimer
    interval: 350
    repeat: false
    onTriggered: root.saveNow()
  }

  Timer {
    id: copiedResetTimer
    interval: 2000
    repeat: false
    onTriggered: root.copied = false
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "gmvs-quick-notes"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    // Scrim backdrop
    Rectangle {
      anchors.fill: parent
      color: root.scrim
    }

    // Dismiss when clicking outside the card
    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    // Main Card
    BorderSurface {
      id: card
      width: root.cardWidth
      height: root.cardHeight
      radius: root.cornerRadius
      anchors.centerIn: parent
      color: root.background
      borderSpec: root.borderSpec
      padding: root.contentMargin

      // Swallow clicks on card so they don't dismiss
      MouseArea {
        anchors.fill: parent
        onClicked: {}
      }

      Column {
        anchors.fill: parent
        anchors.topMargin: card.contentTopInset
        anchors.rightMargin: card.contentRightInset
        anchors.bottomMargin: card.contentBottomInset
        anchors.leftMargin: card.contentLeftInset
        spacing: Style.space(12)

        // ------------------------------------------------ Header
        Row {
          width: parent.width
          height: Style.space(34)
          spacing: Style.space(10)

          // Left: App Icon & Title
          Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(8)

            Text {
              textFormat: Text.PlainText
              text: "󰠮"
              font.family: Style.font.family
              font.pixelSize: Style.font.heading
              color: Color.accent
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              textFormat: Text.PlainText
              text: "Quick Notes"
              font.family: root.fontFamily
              font.pixelSize: Style.font.heading
              font.bold: true
              color: root.foreground
              anchors.verticalCenter: parent.verticalCenter
            }

            // Save status pill
            BorderSurface {
              radius: Style.cornerRadius
              color: "transparent"
              borderSpec: Border.controlSpec("normal", root.foreground, Color.accent)
              implicitWidth: saveStatusText.implicitWidth + Style.space(12)
              implicitHeight: saveStatusText.implicitHeight + Style.space(4)
              anchors.verticalCenter: parent.verticalCenter

              Text {
                id: saveStatusText
                textFormat: Text.PlainText
                anchors.centerIn: parent
                text: saveDebounceTimer.running ? "Saving..." : "Saved"
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                color: Color.muted
              }
            }
          }

          // Spacer to push action buttons right
          Item {
            width: Math.max(0, parent.width - parent.children[0].implicitWidth - actionButtonsRow.implicitWidth - Style.space(20))
            height: 1
          }

          // Right Toolbar
          Row {
            id: actionButtonsRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(6)

            Button {
              text: "• Bullet"
              tooltipText: "Insert bullet point"
              bordered: true
              focusable: false
              fontSize: Style.font.caption
              horizontalPadding: Style.space(8)
              verticalPadding: Style.space(4)
              onClicked: {
                NotesFormatter.insertBullet(editor)
                editor.forceActiveFocus()
              }
            }

            Button {
              text: "1. Number"
              tooltipText: "Insert numbered list item"
              bordered: true
              focusable: false
              fontSize: Style.font.caption
              horizontalPadding: Style.space(8)
              verticalPadding: Style.space(4)
              onClicked: {
                NotesFormatter.insertNumber(editor)
                editor.forceActiveFocus()
              }
            }

            Button {
              text: "󰄱 Task"
              tooltipText: "Insert task checkbox (Ctrl+D to toggle)"
              bordered: true
              focusable: false
              fontSize: Style.font.caption
              horizontalPadding: Style.space(8)
              verticalPadding: Style.space(4)
              onClicked: {
                NotesFormatter.insertTask(editor)
                editor.forceActiveFocus()
              }
            }

            Button {
              text: "Remind"
              iconText: "󰢌"
              tooltipText: "Set reminder from line (Ctrl+R)"
              bordered: true
              focusable: false
              fontSize: Style.font.caption
              horizontalPadding: Style.space(8)
              verticalPadding: Style.space(4)
              onClicked: root.triggerReminder()
            }

            Button {
              text: root.copied ? "Copied!" : "Copy"
              iconText: root.copied ? "✓" : "󰅍"
              tooltipText: "Copy all notes (Ctrl+Shift+C)"
              bordered: true
              focusable: false
              fontSize: Style.font.caption
              horizontalPadding: Style.space(8)
              verticalPadding: Style.space(4)
              onClicked: root.copyAll()
            }

            Button {
              iconText: "󰃢"
              tooltipText: "Clear notes"
              bordered: true
              focusable: false
              fontSize: Style.font.caption
              horizontalPadding: Style.space(8)
              verticalPadding: Style.space(4)
              onClicked: root.clearNotes()
            }

            Button {
              iconText: "✕"
              tooltipText: "Close (Esc)"
              bordered: true
              focusable: false
              fontSize: Style.font.caption
              horizontalPadding: Style.space(8)
              verticalPadding: Style.space(4)
              onClicked: root.dismiss()
            }
          }
        }

        // Divider
        PanelSeparator {
          width: parent.width
          strength: 0.15
        }

        // ------------------------------------------------ Editor Box
        Item {
          id: editorContainer
          width: parent.width
          height: card.height - card.contentTopInset - card.contentBottomInset - Style.space(34) - Style.space(28) - Style.space(36)

          Flickable {
            id: flickable
            anchors.fill: parent
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            contentWidth: width
            contentHeight: Math.max(height, editor.paintedHeight + Style.space(40))

            function ensureVisible(r) {
              if (contentY >= r.y)
                contentY = r.y
              else if (contentY + height <= r.y + r.height + Style.space(24))
                contentY = r.y + r.height + Style.space(24) - height
            }

            // Text placeholder when empty
            Text {
              anchors.fill: parent
              visible: editor.text === "" && !editor.inputMethodComposing
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.42)
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              wrapMode: Text.Wrap
              text: "Write notes, tasks, or reminders...\n\n" +
                    "• Type '- ' or '* ' to start a bullet list\n" +
                    "• Type '1. ' to start a numbered list\n" +
                    "• Type '[ ] ' or '[] ' to start a checklist\n" +
                    "• Press Enter to create the next list item\n" +
                    "• Press Enter on an empty item to exit list\n" +
                    "• Press Ctrl+D to toggle task checkbox\n" +
                    "• Type '15m Buy milk' and click Remind (or Ctrl+R) to set a desktop reminder\n" +
                    "• Press Esc to close (auto-saves instantly)"
            }

            TextEdit {
              id: editor
              width: flickable.width - Style.space(14)
              focus: true
              wrapMode: TextEdit.Wrap
              textFormat: TextEdit.PlainText
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              color: root.foreground
              selectionColor: Style.selectionFillFor(root.foreground, Color.accent)
              selectedTextColor: root.foreground
              selectByMouse: true
              activeFocusOnPress: true

              onCursorRectangleChanged: flickable.ensureVisible(cursorRectangle)

              onTextChanged: {
                if (!root.loading) {
                  saveDebounceTimer.restart()
                }
                root.updateStats()
              }

              Keys.priority: Keys.BeforeItem
              Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) {
                  root.dismiss()
                  event.accepted = true
                  return
                }

                if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                  var isShift = (event.modifiers & Qt.ShiftModifier) !== 0 || event.key === Qt.Key_Backtab
                  if (NotesFormatter.handleTab(editor, isShift)) {
                    event.accepted = true
                    return
                  }
                }

                if ((event.modifiers & Qt.ControlModifier) && (event.key === Qt.Key_D || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
                  if (NotesFormatter.toggleTask(editor)) {
                    event.accepted = true
                    return
                  }
                }

                if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_S) {
                  root.saveNow()
                  event.accepted = true
                  return
                }

                if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_R) {
                  root.triggerReminder()
                  event.accepted = true
                  return
                }

                if ((event.modifiers & Qt.ControlModifier) && (event.modifiers & Qt.ShiftModifier) && event.key === Qt.Key_C) {
                  root.copyAll()
                  event.accepted = true
                  return
                }

                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                  if (event.modifiers & Qt.ShiftModifier) {
                    return // Let default shift+enter insert standard newline
                  }
                  if (NotesFormatter.handleEnter(editor)) {
                    event.accepted = true
                    return
                  }
                }

                if (event.key === Qt.Key_Space) {
                  if (NotesFormatter.handleSpace(editor)) {
                    event.accepted = true
                    return
                  }
                }
              }
            }
          }

          // Subtle custom scroll indicator
          Rectangle {
            id: scrollBar
            anchors.right: parent.right
            anchors.rightMargin: Style.space(2)
            width: Style.space(4)
            radius: Style.space(2)
            color: Color.accent
            opacity: flickable.contentHeight > flickable.height ? 0.45 : 0
            visible: opacity > 0
            y: flickable.visibleArea.yPosition * flickable.height
            height: Math.max(Style.space(24), flickable.visibleArea.heightRatio * flickable.height)
          }
        }

        // Divider
        PanelSeparator {
          width: parent.width
          strength: 0.12
        }

        // ------------------------------------------------ Footer Status Bar
        Row {
          width: parent.width
          height: Style.space(18)

          // Keyboard shortcut hints
          Text {
            anchors.verticalCenter: parent.verticalCenter
            textFormat: Text.PlainText
            text: "Esc: Close   ·   Enter: List Item   ·   Tab: Indent   ·   Ctrl+D: Checkbox   ·   Ctrl+R: Remind"
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            color: Color.muted
          }

          // Spacer
          Item {
            width: Math.max(0, parent.width - parent.children[0].implicitWidth - statsLabel.implicitWidth)
            height: 1
          }

          // Stats (lines, words, checklist items)
          Text {
            id: statsLabel
            anchors.verticalCenter: parent.verticalCenter
            textFormat: Text.PlainText
            text: root.statsText
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            color: Color.muted
          }
        }
      }
    }
  }
}
