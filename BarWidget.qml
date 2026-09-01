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

  // ---------------------------------------------------------------------------
  // i18n System Language Localization Dictionary
  // ---------------------------------------------------------------------------
  readonly property var i18nDict: ({
    en: {
      tooltip: "OmaDrop (File Transfer Phone ↔ PC)\nClick to show QR code",
      title: "OmaDrop File Sharing",
      subtitle: "Scan with your regular phone camera",
      copied: "Link copied to clipboard!",
      recent_title: "📥 Recently received files:",
      btn_open: "📁 Open folder",
      btn_stop: "🛑 Stop",
      btn_start: "▶ Start",
      same_wifi: "Same Wi-Fi required"
    },
    sv: {
      tooltip: "OmaDrop (Fildelning mobil ↔ dator)\nKlicka för att visa QR-kod",
      title: "OmaDrop Fildelning",
      subtitle: "Scanna med mobilens vanliga kamera",
      copied: "Länk kopierad till urklipp!",
      recent_title: "📥 Senast mottagna filer:",
      btn_open: "📁 Öppna mapp",
      btn_stop: "🛑 Stäng av",
      btn_start: "▶ Starta",
      same_wifi: "Kräver samma Wi-Fi"
    },
    nl: {
      tooltip: "OmaDrop (Bestandsoverdracht Telefoon ↔ PC)\nKlik voor QR-code",
      title: "OmaDrop Bestandsoverdracht",
      subtitle: "Scan met de camera van je telefoon",
      copied: "Link gekopieerd naar klembord!",
      recent_title: "📥 Recent ontvangen bestanden:",
      btn_open: "📁 Map openen",
      btn_stop: "🛑 Stoppen",
      btn_start: "▶ Starten",
      same_wifi: "Vereist dezelfde Wi-Fi"
    },
    ja: {
      tooltip: "OmaDrop (スマホ ↔ PC ファイル転送)\nクリックしてQRコードを表示",
      title: "OmaDrop ファイル共有",
      subtitle: "スマホの標準カメラでスキャン",
      copied: "リンクをクリップボードにコピーしました！",
      recent_title: "📥 最近受信したファイル:",
      btn_open: "📁 フォルダを開く",
      btn_stop: "🛑 停止",
      btn_start: "▶ 開始",
      same_wifi: "同じWi-Fi接続が必要です"
    },
    de: {
      tooltip: "OmaDrop (Dateiübertragung Handy ↔ PC)\nKlicken für QR-Code",
      title: "OmaDrop Dateifreigabe",
      subtitle: "Mit der Handykamera scannen",
      copied: "Link in Zwischenablage kopiert!",
      recent_title: "📥 Zuletzt empfangene Dateien:",
      btn_open: "📁 Ordner öffnen",
      btn_stop: "🛑 Beenden",
      btn_start: "▶ Starten",
      same_wifi: "Gleiches WLAN erforderlich"
    },
    fr: {
      tooltip: "OmaDrop (Transfert Téléphone ↔ PC)\nCliquer pour le code QR",
      title: "OmaDrop Partage de fichiers",
      subtitle: "Scannez avec l'appareil photo du téléphone",
      copied: "Lien copié dans le presse-papiers !",
      recent_title: "📥 Fichiers récemment reçus :",
      btn_open: "📁 Ouvrir le dossier",
      btn_stop: "🛑 Arrêter",
      btn_start: "▶ Démarrer",
      same_wifi: "Même Wi-Fi requis"
    },
    es: {
      tooltip: "OmaDrop (Transferencia Móvil ↔ PC)\nHaz clic para código QR",
      title: "OmaDrop Compartir archivos",
      subtitle: "Escanea con la cámara de tu móvil",
      copied: "¡Enlace copiado al portapapeles!",
      recent_title: "📥 Archivos recibidos recientemente:",
      btn_open: "📁 Abrir carpeta",
      btn_stop: "🛑 Detener",
      btn_start: "▶ Iniciar",
      same_wifi: "Misma red Wi-Fi requerida"
    },
    zh: {
      tooltip: "OmaDrop (手机 ↔ 电脑 文件传输)\n点击显示二维码",
      title: "OmaDrop 文件传输",
      subtitle: "使用手机相机扫码",
      copied: "链接已复制到剪贴板！",
      recent_title: "📥 最近接收的文件:",
      btn_open: "📁 打开文件夹",
      btn_stop: "🛑 停止",
      btn_start: "▶ 启动",
      same_wifi: "需要连接到同一 Wi-Fi"
    }
  })

  readonly property var langKey: {
    var loc = Qt.locale().name.toLowerCase()
    var shortCode = loc.split("_")[0].split("-")[0]
    return i18nDict[shortCode] ? shortCode : "en"
  }

  readonly property var str: i18nDict[langKey] || i18nDict.en

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
    text: "󰄡 Drop"
    active: root.popupOpen || root.serverRunning
    tooltipText: root.str.tooltip
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
            text: root.str.title
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.subtitle
            font.bold: true
          }

          Text {
            text: root.str.subtitle
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
                if (root.bar) root.bar.showTooltip(root, root.str.copied)
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
          text: root.str.recent_title
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
          text: root.str.btn_open
          foreground: root.bar.foreground
          horizontalPadding: Style.spacing.controlPaddingX
          verticalPadding: Style.spacing.controlPaddingY
          onClicked: root.runOmaDrop("open")
        }

        Button {
          width: (parent.width - Style.space(8)) / 2
          text: root.serverRunning ? root.str.btn_stop : root.str.btn_start
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
