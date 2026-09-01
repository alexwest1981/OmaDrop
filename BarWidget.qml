import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "custom.omadrop"

  property bool serverRunning: false
  property string serverUrl: "http://127.0.0.1:5380"
  property string localIp: "127.0.0.1"
  property var recentFiles: []
  property bool popupOpen: false
  property string qrPath: "/tmp/omadrop-qr.png"
  property int refreshTrigger: 0

  function close() { popupOpen = false }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  // ---------------------------------------------------------------------------
  // 1. Status Poller
  // ---------------------------------------------------------------------------
  Process {
    id: statusProc
    command: ["omarchy-omadrop", "status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var data = JSON.parse(text.trim())
          root.serverRunning = (data.running === true)
          root.serverUrl = data.url || ""
          root.localIp = data.ip || ""
          root.recentFiles = data.recent_files || []
          root.qrPath = data.qr_path || "/tmp/omadrop-qr.png"
          root.refreshTrigger += 1
        } catch (e) {}
      }
    }
  }

  Timer {
    id: statusTimer
    interval: 1500
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!statusProc.running) statusProc.running = true
    }
  }

  function runOmaDrop(action) {
    Quickshell.execDetached(["omarchy-omadrop", action])
    statusTimer.restart()
  }

  // ---------------------------------------------------------------------------
  // 2. Bar Button
  // ---------------------------------------------------------------------------
  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.serverRunning ? "󰄡 Drop" : "󰄡 Drop"
    active: root.popupOpen || root.serverRunning
    tooltipText: "OmaDrop (Fildelning mobil ↔ dator)\nKlicka för att visa QR-kod"
    onPressed: function(btn) {
      if (!root.serverRunning) {
        runOmaDrop("start")
      }
      root.popupOpen = !root.popupOpen
    }
  }

  // ---------------------------------------------------------------------------
  // 3. Interactive Graphical Popup Card
  // ---------------------------------------------------------------------------
  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(340))
    contentHeight: popup.fittedContentHeight(popCol.implicitHeight)

    Column {
      id: popCol
      anchors.fill: parent
      spacing: Style.space(12)

      // Header
      Row {
        spacing: Style.space(10)
        width: parent.width

        BorderSurface {
          width: Style.space(46)
          height: Style.space(46)
          radius: Style.spacing.labelGap
          color: Style.normalFillFor(root.bar.foreground, Color.accent)
          borderSpec: Border.controlSpec("normal", root.bar.foreground, Color.accent)

          Text {
            anchors.centerIn: parent
            text: "󰄡"
            color: Color.accent
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.displayMedium
          }
        }

        Column {
          spacing: Style.space(2)
          width: parent.width - Style.space(58)

          Text {
            text: "OmaDrop Fildelning"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.subtitle
            font.bold: true
          }

          Text {
            text: "Scanna med mobilens vanliga kamera"
            color: Qt.darker(root.bar.foreground, 1.3)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.bodySmall
          }
        }
      }

      // QR Code Container Card
      BorderSurface {
        width: parent.width
        height: Style.space(230)
        radius: Style.spacing.labelGap
        color: Qt.darker(root.bar.background || "#1a1b26", 1.3)
        borderSpec: Border.controlSpec("normal", root.bar.foreground, Color.accent)

        Column {
          anchors.centerIn: parent
          spacing: Style.space(8)

          // Crisp White Canvas for QR Code
          Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Style.space(160)
            height: Style.space(160)
            radius: Style.space(10)
            color: "#ffffff"

            Image {
              id: qrImg
              anchors.centerIn: parent
              width: Style.space(146)
              height: Style.space(146)
              fillMode: Image.PreserveAspectFit
              cache: false
              source: root.qrPath !== "" ? "file://" + root.qrPath + "?v=" + root.refreshTrigger : ""
              smooth: false
            }
          }

          // URL Text Pill (Click to copy)
          Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: urlRow.implicitWidth + Style.space(16)
            height: Style.space(24)
            radius: Style.space(12)
            color: copyMouse.containsMouse ? Style.normalFillFor(root.bar.foreground, Color.accent) : Qt.rgba(1, 1, 1, 0.06)

            Row {
              id: urlRow
              anchors.centerIn: parent
              spacing: Style.space(5)

              Text {
                text: "🔗 " + root.serverUrl
                color: root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
              }
            }

            MouseArea {
              id: copyMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                Quickshell.execDetached(["wl-copy", root.serverUrl])
                if (root.bar) root.bar.showTooltip(root, "Länk kopierad till urklipp!")
              }
            }
          }
        }
      }

      // Recent Files Section
      Column {
        width: parent.width
        spacing: Style.space(6)
        visible: root.recentFiles.length > 0

        Text {
          text: "📥 Senast mottagna filer:"
          color: Qt.darker(root.bar.foreground, 1.3)
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.caption
          font.bold: true
        }

        Repeater {
          model: root.recentFiles

          BorderSurface {
            width: parent.width
            height: Style.space(34)
            radius: Style.space(6)
            color: Qt.rgba(1, 1, 1, 0.04)
            borderSpec: Border.controlSpec("normal", root.bar.foreground, Color.accent)

            Row {
              anchors.fill: parent
              anchors.leftMargin: Style.space(10)
              anchors.rightMargin: Style.space(10)
              spacing: Style.space(8)

              Text {
                text: "📄"
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: Style.font.bodySmall
              }

              Text {
                text: modelData.name
                color: root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.bodySmall
                font.bold: true
                elide: Text.ElideMiddle
                width: parent.width - Style.space(90)
                anchors.verticalCenter: parent.verticalCenter
              }

              Text {
                text: modelData.size
                color: Qt.darker(root.bar.foreground, 1.4)
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.caption
                anchors.verticalCenter: parent.verticalCenter
              }
            }
          }
        }
      }

      // Action Buttons Row
      Row {
        width: parent.width
        spacing: Style.space(8)

        Button {
          width: (parent.width - Style.space(8)) / 2
          text: "📁 Öppna mapp"
          foreground: root.bar.foreground
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY
          onClicked: root.runOmaDrop("open")
        }

        Button {
          width: (parent.width - Style.space(8)) / 2
          text: root.serverRunning ? "🛑 Stäng av" : "▶ Starta"
          foreground: root.serverRunning ? "#f7768e" : "#9ece6a"
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY
          onClicked: {
            if (root.serverRunning) {
              root.runOmaDrop("stop")
            } else {
              root.runOmaDrop("start")
            }
          }
        }
      }
    }
  }
}
