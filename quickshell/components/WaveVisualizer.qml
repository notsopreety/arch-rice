import QtQuick
import QtQuick.Effects

Canvas {
    id: root

    property color waveColor: "blue"
    property bool active: false
    property double waveYPercent: 0.72
    property Item maskSource: null
    property real phase: 0

    layer.enabled: maskSource !== null
    layer.effect: MultiEffect {
        maskEnabled: root.maskSource !== null
        maskSource: ShaderEffectSource {
            sourceItem: root.maskSource
            hideSource: true
        }
    }

    Timer {
        interval: 16
        running: root.active
        repeat: true
        onTriggered: {
            root.phase += 0.05
            root.requestPaint()
        }
    }

    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        // Wave 1: lighter background wave
        drawWave(ctx, Qt.rgba(root.waveColor.r, root.waveColor.g, root.waveColor.b, 0.22), 14, phase)
        // Wave 2: slightly more opaque foreground wave
        drawWave(ctx, Qt.rgba(root.waveColor.r, root.waveColor.g, root.waveColor.b, 0.35), 9, phase * 0.9)
    }

    function drawWave(ctx, color, amplitude, currentPhase) {
        ctx.beginPath()
        ctx.fillStyle = color
        var waveY = height * root.waveYPercent
        ctx.moveTo(0, height)
        for (var x = 0; x <= width; x += 5) {
            var y = waveY + Math.sin(x * 0.02 + currentPhase) * amplitude
            ctx.lineTo(x, y)
        }
        ctx.lineTo(width, height)
        ctx.closePath()
        ctx.fill()
    }
}
