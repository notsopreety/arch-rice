import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property string shape: "cookie_12"
    property alias shapeMode: root.shape
    property color color: "#6750A4"
    property real borderWidth: 0
    property color borderColor: "transparent"
    property real rotateSpeed: 5.0
    property bool animated: true

    implicitWidth: 100
    implicitHeight: 100

    onWidthChanged: updatePath()
    onHeightChanged: updatePath()
    onShapeChanged: updatePath()

    Component.onCompleted: updatePath()

    function getRadialParams(shapeName) {
        let name = (shapeName || "").toLowerCase().replace("-", "_");
        if (name === "circle") return { freq: 0, min: 1.0, max: 1.0 };
        return { freq: 12, min: 0.90, max: 0.98 };
    }

    function updatePath() {
        let w = root.width;
        let h = root.height;
        if (w <= 0 || h <= 0) return;

        let cx = w / 2;
        let cy = h / 2;
        let r_max = Math.min(w, h) / 2;

        let params = getRadialParams(root.shape);
        svgPath.path = generateRadialPath(cx, cy, r_max, params.freq, params.min, params.max);
    }

    function generateRadialPath(cx, cy, r_max, freq, minScale, maxScale) {
        if (freq === 0) {
            let r = r_max * maxScale;
            return "M " + (cx + r) + " " + cy +
                   " A " + r + " " + r + " 0 1 0 " + (cx - r) + " " + cy +
                   " A " + r + " " + r + " 0 1 0 " + (cx + r) + " " + cy + " Z";
        }

        let steps = Math.max(120, freq * 20);
        let pathStr = "";

        for (let i = 0; i <= steps; i++) {
            let angle = (i / steps) * (2 * Math.PI);
            let wave = (Math.sin(angle * freq) + 1) / 2;
            let r_factor = minScale + wave * (maxScale - minScale);
            let r = r_max * r_factor;

            let x = cx + r * Math.cos(angle);
            let y = cy + r * Math.sin(angle);

            if (i === 0) {
                pathStr += "M " + x + " " + y;
            } else {
                pathStr += " L " + x + " " + y;
            }
        }
        pathStr += " Z";
        return pathStr;
    }

    Item {
        id: shapeContainer
        anchors.fill: parent

        RotationAnimation on rotation {
            running: root.animated && root.rotateSpeed > 0
            from: 0
            to: 360
            duration: Math.max(500, (11 - root.rotateSpeed) * 2000)
            loops: Animation.Infinite
        }

        Shape {
            anchors.fill: parent
            layer.enabled: true
            layer.samples: 8
            layer.smooth: true

            ShapePath {
                id: shapePath
                fillColor: root.color
                strokeColor: root.borderColor
                strokeWidth: root.borderWidth
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                PathSvg {
                    id: svgPath
                    path: ""
                }
            }
        }
    }
}
