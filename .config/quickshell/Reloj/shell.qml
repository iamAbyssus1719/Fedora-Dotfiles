import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick.Effects

// ============================================================================
//  Diseño elegante (basado en tu reloj anterior):
//  hora pequeña arriba, día grande en Anurati, fecha y prompt con carrusel
//  de comandos; logo Tux/Fedora a la izquierda, stats con barritas a la
//  derecha y polen flotante.
// ============================================================================
PanelWindow {
    id: window
    screen: Quickshell.screens.find(s => s.name === "HDMI-A-1")

    WlrLayershell.layer: WlrLayer.Background
    exclusiveZone: 0

    anchors {
        top: true
    }

    margins {
        top: 80
    }

    implicitWidth: 1500
    implicitHeight: 440
    color: "transparent"

    // ---------- Colores ----------
    readonly property color blanco:  "#ffffff"
    readonly property color tenue:   "#e6e6e6"
    readonly property color oscuro:  "#222222"
    readonly property color halo:    "#050a07"
    readonly property color alerta:  "#ff9f43"      // solo cuando CPU/RAM/DSK pasan de 85 %

    // Color máximo del brillo que respira alrededor del día, la hora y la fecha.
    // Si quieres más contraste sobre las hojas claras, cámbialo por un tono oscuro, p. ej. "#0b140e".
    readonly property color brilloMax: "#ffffff"

    // ---------- Fases de animación (ciclos cerrados) ----------
    property real fase: 0          // balanceo / flotación: 0 -> 2π
    property real tOnda: 0         // onda de las letras del día
    property real tPart: 0         // polen

    NumberAnimation {
        target: window; property: "fase"
        from: 0; to: 2 * Math.PI; duration: 5000
        loops: Animation.Infinite; running: true
    }
    NumberAnimation {
        target: window; property: "tOnda"
        from: 0; to: 14000; duration: 14000
        loops: Animation.Infinite; running: true
    }
    NumberAnimation {
        target: window; property: "tPart"
        from: 0; to: 1; duration: 90000
        loops: Animation.Infinite; running: true
    }

    function bump(t) {
        if (t <= 0 || t >= 1300) return 0
        var s = Math.sin(Math.PI * t / 1300)
        return -16 * s * s
    }

    // ---------- Fecha / hora ----------
    SystemClock {
        id: sysTime
        precision: SystemClock.Seconds
    }

    // Solo notifican cuando cambian (no cada segundo)
    readonly property string diaNombre: Qt.formatDateTime(sysTime.date, "dddd").toUpperCase()
    readonly property string fechaTexto: Qt.formatDateTime(sysTime.date, "dd MMM yyyy").toUpperCase()
    readonly property string horaTexto: Qt.formatDateTime(sysTime.date, "hh")
    readonly property string minTexto: Qt.formatDateTime(sysTime.date, "mm")
    readonly property string segTexto: Qt.formatDateTime(sysTime.date, "ss")

    // ---------- Logos ASCII ----------
    property bool mostrarFedora: false

    readonly property string asciiTux: [
        "    .--.   ",
        "   |o_o |  ",
        "   |:_/ |  ",
        "  //   \\ \\ ",
        " (|     | )",
        "/'\\_   _/`\\",
        "\\___)=(___/"
    ].join("\n")

    readonly property string asciiFedora: [
        "          ,'''''.",
        "         |   ,.  |",
        "         |  |  '_'",
        "    ,....|  |..",
        "  .'  ,_;|   ..'",
        "  |  |   |  |",
        "  |  ',_,'  |",
        "   '.     ,'",
        "     '''''"
    ].join("\n")

    Timer {
        interval: 25000
        running: true
        repeat: true
        onTriggered: window.mostrarFedora = !window.mostrarFedora
    }

    // ---------- Stats del sistema ----------
    property real cpu: 0
    property real ram: 0
    property real disco: 0
    property real prevTotal: 0
    property real prevIdle: 0

    Process {
        id: stats
        command: ["sh", "-c",
            "head -1 /proc/stat; " +
            "free -m | awk '/Mem/{printf \"%d\\n\", $3*100/$2}'; " +
            "df --output=pcent / | tail -1 | tr -dc '0-9'; echo"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var p = text.trim().split("\n")
                if (p.length < 3) return

                var f = p[0].trim().split(/\s+/)
                var idle = parseInt(f[4]) + parseInt(f[5])
                var total = 0
                for (var i = 1; i <= 8; i++) total += parseInt(f[i])
                if (window.prevTotal > 0) {
                    var dt = total - window.prevTotal
                    var di = idle - window.prevIdle
                    if (dt > 0) window.cpu = 100 * (1 - di / dt)
                }
                window.prevTotal = total
                window.prevIdle = idle

                window.ram = parseInt(p[1])
                window.disco = parseInt(p[2])
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: if (!stats.running) stats.running = true
    }

    // ---------- Carrusel de comandos ----------
    readonly property var comandos: [
        "sudo dnf update",
        "uname -r",
        "cat /etc/os-release",
        "systemctl status sshd",
        "journalctl -xe",
        "lsblk",
        "ip a",
        "df -h",
        "free -h",
        "htop",
        "fastfetch",
        "ls -la ~/.config",
        "grep -r 'linux' ~/",
        "git log --oneline",
        "ssh abyssus@server",
        "tar -xzvf backup.tar.gz",
        "ping -c 4 fedoraproject.org",
        "chmod +x script.sh",
        "sudo dnf install neovim",
        "man bash"
    ]

    property int cmdIdx: 0
    property int escrito: 0
    property string fase_cmd: "escribiendo"
    property int espera: 0
    property bool cursorOn: true
    readonly property string comandoActual: comandos[cmdIdx]

    Timer {
        interval: 70
        running: true
        repeat: true
        onTriggered: {
            if (window.fase_cmd === "escribiendo") {
                if (window.escrito < window.comandoActual.length) {
                    window.escrito++
                } else {
                    window.fase_cmd = "espera"
                    window.espera = 0
                }
            } else if (window.fase_cmd === "espera") {
                window.espera++
                if (window.espera >= 36)
                    window.fase_cmd = "borrando"
            } else {
                if (window.escrito > 0) {
                    window.escrito--
                } else {
                    window.cmdIdx = (window.cmdIdx + 1) % window.comandos.length
                    window.fase_cmd = "escribiendo"
                }
            }
        }
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: window.cursorOn = !window.cursorOn
    }

    // =====================================================================
    //  Componentes
    // =====================================================================

    // Texto con brillo que respira (glowA <-> glowB) y "roll" opcional al cambiar
    component FxText: Item {
        id: fx

        property string text: ""
        property string family: "Inconsolata ExtraBold"
        property int pixelSize: 28
        property real letterSpacing: 0
        property bool bold: false
        property bool italic: false
        property real lineHeight: 1.0
        property int hAlign: Text.AlignLeft
        property color textColor: "#ffffff"

        property color glowA: "#222222"
        property color glowB: "#ffffff"
        property color glowActual: glowA
        property int glowPeriod: 2500
        property real shadowBlur: 2.0
        property real shadowOpacity: 1.0
        property real shadowX: 0
        property real shadowY: 0

        property bool roll: false
        property string shown: ""
        property string prevText: ""

        Component.onCompleted: shown = text
        onTextChanged: {
            if (roll && shown !== "") {
                prevText = shown
                rollAnim.restart()
            }
            shown = text
        }

        implicitWidth: main.implicitWidth
        implicitHeight: main.implicitHeight

        Text {
            id: old
            text: fx.prevText
            textFormat: Text.PlainText
            color: fx.textColor
            opacity: 0
            lineHeight: fx.lineHeight
            horizontalAlignment: fx.hAlign
            font { family: fx.family; pixelSize: fx.pixelSize; bold: fx.bold; italic: fx.italic; letterSpacing: fx.letterSpacing }
        }

        Text {
            id: main
            textFormat: Text.PlainText
            text: fx.shown
            color: fx.textColor
            lineHeight: fx.lineHeight
            horizontalAlignment: fx.hAlign
            font { family: fx.family; pixelSize: fx.pixelSize; bold: fx.bold; italic: fx.italic; letterSpacing: fx.letterSpacing }

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowBlur: fx.shadowBlur
                shadowOpacity: fx.shadowOpacity
                shadowVerticalOffset: fx.shadowY
                shadowHorizontalOffset: fx.shadowX
                shadowColor: fx.glowActual
            }
        }

        ParallelAnimation {
            id: rollAnim
            NumberAnimation { target: main; property: "opacity"; from: 0; to: 1; duration: 450; easing.type: Easing.OutCubic }
            NumberAnimation { target: main; property: "y"; from: 10; to: 0; duration: 450; easing.type: Easing.OutCubic }
            NumberAnimation { target: old; property: "opacity"; from: 1; to: 0; duration: 280; easing.type: Easing.InQuad }
            NumberAnimation { target: old; property: "y"; from: 0; to: -10; duration: 280; easing.type: Easing.InQuad }
        }

        SequentialAnimation {
            running: fx.glowA !== fx.glowB
            loops: Animation.Infinite
            ColorAnimation { target: fx; property: "glowActual"; from: fx.glowA; to: fx.glowB; duration: fx.glowPeriod; easing.type: Easing.InOutSine }
            ColorAnimation { target: fx; property: "glowActual"; from: fx.glowB; to: fx.glowA; duration: fx.glowPeriod; easing.type: Easing.InOutSine }
        }
    }

    // Stat vertical:  CPU  8%
    //                 ━━━━━━━━
    component Stat: Column {
        id: st
        property string etiqueta: ""
        property real valor: 0
        spacing: 6

        FxText {
            text: st.etiqueta + " " + String(Math.round(st.valor)).padStart(3, " ") + "%"
            pixelSize: 21
            bold: true
            letterSpacing: 3
            glowA: "#050a07"
            glowB: "#050a07"
            shadowBlur: 0.7
            shadowOpacity: 0.95
            shadowY: 1
        }

        Rectangle {
            id: pista
            width: 160
            height: 3
            radius: 2
            color: "#40ffffff"

            Rectangle {
                height: parent.height
                radius: 2
                width: pista.width * Math.max(0, Math.min(1, st.valor / 100))
                color: st.valor >= 85 ? "#ff9f43" : "#ffffff"
                Behavior on width { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
            }
        }
    }

    // =====================================================================
    //  Polen flotante (muy sutil, detrás de todo)
    // =====================================================================
    Item {
        anchors.fill: parent

        Repeater {
            model: 14

            delegate: Rectangle {
                required property int index
                readonly property int ciclos: 2 + (index % 4)
                readonly property real q: (window.tPart * ciclos + index * 0.173) % 1

                width: 2 + (index % 3)
                height: width
                radius: width / 2
                color: "#e4efd2"
                x: ((index * 211) % window.width) + Math.sin(window.tPart * 2 * Math.PI * ciclos * 2 + index) * 16
                y: window.height - q * (window.height + 20)
                opacity: 0.4 * Math.sin(Math.PI * q)
            }
        }
    }

    // =====================================================================
    //  Contenido:   [ logo ]   [ hora · DÍA · fecha · prompt ]   [ stats ]
    // =====================================================================
    Row {
        id: contenedor
        anchors.centerIn: parent
        spacing: 16

        opacity: 0
        transform: [
            Translate { id: entradaY; y: -40 },
            Translate { y: Math.sin(window.fase) * 4 }
        ]

        Component.onCompleted: animIntro.start()

        ParallelAnimation {
            id: animIntro
            NumberAnimation { target: contenedor; property: "opacity"; from: 0; to: 1; duration: 1000; easing.type: Easing.OutCubic }
            NumberAnimation { target: entradaY; property: "y"; from: -40; to: 0; duration: 1200; easing.type: Easing.OutBack }
        }

        // ---------- IZQUIERDA: logo Tux <-> Fedora ----------
        Item {
            width: 230
            height: 250
            anchors.verticalCenter: parent.verticalCenter

            FxText {
                anchors.centerIn: parent
                text: window.asciiTux
                lineHeight: 0.9
                pixelSize: 22
                bold: true
                glowA: "#050a07"
                glowB: "#050a07"
                shadowBlur: 0.8
                shadowY: 1

                opacity: window.mostrarFedora ? 0 : 1
                scale: window.mostrarFedora ? 0.96 : 1
                Behavior on opacity { NumberAnimation { duration: 650; easing.type: Easing.InOutQuad } }
                Behavior on scale   { NumberAnimation { duration: 650; easing.type: Easing.InOutQuad } }
            }

            FxText {
                anchors.centerIn: parent
                text: window.asciiFedora
                lineHeight: 0.9
                pixelSize: 22
                bold: true
                glowA: "#050a07"
                glowB: "#050a07"
                shadowBlur: 0.8
                shadowY: 1

                opacity: window.mostrarFedora ? 1 : 0
                scale: window.mostrarFedora ? 1 : 0.96
                Behavior on opacity { NumberAnimation { duration: 650; easing.type: Easing.InOutQuad } }
                Behavior on scale   { NumberAnimation { duration: 650; easing.type: Easing.InOutQuad } }
            }
        }

        // ---------- CENTRO ----------
        Column {
            id: centro
            width: 840
            spacing: 10
            anchors.verticalCenter: parent.verticalCenter

            // Hora: 16  48  09   (solo los segundos ruedan cada segundo)
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 26

                FxText { text: window.horaTexto; roll: true; pixelSize: 28; bold: true; letterSpacing: 12; shadowBlur: 2.0; glowB: window.brilloMax }
                FxText { text: window.minTexto;  roll: true; pixelSize: 28; bold: true; letterSpacing: 12; shadowBlur: 2.0; glowB: window.brilloMax }
                FxText { text: window.segTexto;  roll: true; pixelSize: 28; bold: true; letterSpacing: 12; shadowBlur: 2.0; glowB: window.brilloMax }
            }

            // Día grande con onda + brisa
            Row {
                id: diaRow
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 0

                Repeater {
                    model: window.diaNombre.split("")

                    delegate: FxText {
                        text: modelData
                        family: "Anurati"
                        pixelSize: 120
                        letterSpacing: 12
                        shadowBlur: 2.5
                        glowB: window.brilloMax

                        transformOrigin: Item.Bottom
                        rotation: 1.2 * Math.sin(window.fase - index * 0.8)
                        opacity: 0.88 + 0.12 * (0.5 + 0.5 * Math.sin(window.fase - index * 0.8 + 1.2))
                        transform: Translate { y: window.bump(window.tOnda - index * 180) }
                    }
                }
            }

            // Fecha
            FxText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: window.fechaTexto
                roll: true
                pixelSize: 42
                bold: true
                letterSpacing: 5
                shadowBlur: 2.5
                glowB: window.brilloMax
            }

            // Prompt con carrusel de comandos (discreto)
            FxText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "abyssus1719@fedora:~$ " + window.comandoActual.substring(0, window.escrito)
                      + (window.cursorOn ? "█" : " ")
                pixelSize: 20
                bold: true
                textColor: window.tenue
                glowA: "#050a07"
                glowB: "#050a07"
                shadowBlur: 0.7
                shadowY: 1
                opacity: 0.85
            }
        }

        // ---------- DERECHA: stats ----------
        Item {
            width: 230
            height: 250
            anchors.verticalCenter: parent.verticalCenter

            Column {
                anchors.centerIn: parent
                spacing: 18

                Stat { etiqueta: "CPU"; valor: window.cpu }
                Stat { etiqueta: "RAM"; valor: window.ram }
                Stat { etiqueta: "DSK"; valor: window.disco }
            }
        }
    }
}
