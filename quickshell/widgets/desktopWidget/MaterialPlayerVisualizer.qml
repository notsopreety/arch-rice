import QtQuick

Canvas {
    id: root

    property var points: []
    property color color: "#6750A4"
    property real maxVisualizerValue: 1000
    property int smoothing: 2
    property bool live: true

    anchors.fill: parent

    onPointsChanged: {
        root.requestPaint()
    }

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        var pts = root.points || [];
        var n = pts.length;
        if (n < 2) return;

        var maxVal = root.maxVisualizerValue || 1000;
        var h = height;
        var w = width;

        // Smoothing moving average
        var smoothWindow = root.smoothing;
        var smoothPoints = [];
        for (var i = 0; i < n; ++i) {
            var sum = 0, count = 0;
            for (var j = -smoothWindow; j <= smoothWindow; ++j) {
                var idx = Math.max(0, Math.min(n - 1, i + j));
                sum += (pts[idx] || 0);
                count++;
            }
            smoothPoints.push(sum / count);
        }
        if (!root.live) smoothPoints.fill(0);

        ctx.beginPath();
        ctx.moveTo(0, h);

        var step = w / (n - 1);
        for (var i = 0; i < n; ++i) {
            var x = i * step;
            var val = (smoothPoints[i] / maxVal) * (h * 0.45);
            var y = h - val;

            if (i === 0) {
                ctx.lineTo(x, y);
            } else {
                var prevX = (i - 1) * step;
                var prevY = h - ((smoothPoints[i - 1] / maxVal) * (h * 0.45));
                var cpx1 = prevX + step / 2;
                var cpy1 = prevY;
                var cpx2 = prevX + step / 2;
                var cpy2 = y;
                ctx.bezierCurveTo(cpx1, cpy1, cpx2, cpy2, x, y);
            }
        }
        ctx.lineTo(w, h);
        ctx.closePath();

        ctx.fillStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, 0.22);
        ctx.fill();
    }
}
