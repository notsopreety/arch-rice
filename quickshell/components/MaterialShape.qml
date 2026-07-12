import QtQuick
import QtQuick.Shapes
import "../theme"

Item {
    id: root

    property string shape: "circle"
    property color color: Theme.primary
    property color borderColor: "transparent"
    property real borderWidth: 0
    property real cornerRadius: -1

    // Animated properties for smooth morphing transitions
    property real animFreq: 0
    property real animMinScale: 1.0
    property real animMaxScale: 1.0

    Behavior on animFreq {
        NumberAnimation {
            duration: 600
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on animMinScale {
        NumberAnimation {
            duration: 600
            easing.type: Easing.InOutQuad
        }
    }
    Behavior on animMaxScale {
        NumberAnimation {
            duration: 600
            easing.type: Easing.InOutQuad
        }
    }

    // Force shape updates when dimensions, corner radius, or morph properties change
    onWidthChanged: updatePath()
    onHeightChanged: updatePath()
    onCornerRadiusChanged: updatePath()
    
    onAnimFreqChanged: updatePath()
    onAnimMinScaleChanged: updatePath()
    onAnimMaxScaleChanged: updatePath()

    onShapeChanged: {
        var params = getRadialParams(root.shape);
        if (params !== null) {
            root.animFreq = params.freq;
            root.animMinScale = params.min;
            root.animMaxScale = params.max;
        } else {
            // Instantly update for non-radial paths
            updatePath();
        }
    }

    Shape {
        id: shapeItem
        anchors.fill: parent

        // Enable high-quality offscreen MSAA anti-aliasing for polished edges
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

    // Maps shapes to their mathematical radial wave parameters
    function getRadialParams(shapeName) {
        switch (shapeName.toLowerCase().replace("-", "_")) {
            case "circle":         return { freq: 0,  min: 1.0,  max: 1.0 };
            case "sunny":          return { freq: 8,  min: 0.75, max: 0.95 };
            case "very_sunny":     return { freq: 8,  min: 0.6,  max: 0.98 };
            case "cookie_4":       return { freq: 4,  min: 0.8,  max: 0.98 };
            case "cookie_6":       return { freq: 6,  min: 0.82, max: 0.98 };
            case "cookie_7":       return { freq: 7,  min: 0.85, max: 0.98 };
            case "cookie_9":       return { freq: 9,  min: 0.87, max: 0.98 };
            case "cookie_12":      return { freq: 12, min: 0.9,  max: 0.98 };
            case "clover_4":       return { freq: 4,  min: 0.6,  max: 1.0 };
            case "clover_8":       return { freq: 8,  min: 0.7,  max: 1.0 };
            case "soft_burst":     return { freq: 12, min: 0.72, max: 0.95 };
            case "puffy_diamond":  return { freq: 4,  min: 0.75, max: 0.95 };
            case "flower":         return { freq: 8,  min: 0.5,  max: 0.95 };
            case "puffy":          return { freq: 10, min: 0.78, max: 0.98 };
            default:               return null; // Non-radial shapes
        }
    }

    function updatePath() {
        var w = root.width;
        var h = root.height;
        if (w <= 0 || h <= 0) return;

        var cx = w / 2;
        var cy = h / 2;
        var r_max = Math.min(w, h) / 2;

        var params = getRadialParams(root.shape);
        if (params !== null) {
            svgPath.path = generateRadialPath(cx, cy, r_max, root.animFreq, root.animMinScale, root.animMaxScale, true);
        } else {
            svgPath.path = generatePath(root.shape);
        }
    }

    function generatePath(shapeName) {
        var w = root.width;
        var h = root.height;
        if (w <= 0 || h <= 0) return "";

        var cx = w / 2;
        var cy = h / 2;
        var r_max = (w < h ? w : h) / 2;

        switch (shapeName.toLowerCase().replace("-", "_")) {
            case "square":
                var r = (cornerRadius >= 0) ? (cornerRadius < r_max ? cornerRadius : r_max) : r_max * 0.45;
                return "M " + (cx - r_max + r) + " " + (cy - r_max) +
                       " h " + (r_max * 2 - r * 2) +
                       " a " + r + " " + r + " 0 0 1 " + r + " " + r +
                       " v " + (r_max * 2 - r * 2) +
                       " a " + r + " " + r + " 0 0 1 -" + r + " " + r +
                       " h -" + (r_max * 2 - r * 2) +
                       " a " + r + " " + r + " 0 0 1 -" + r + " -" + r +
                       " v -" + (r_max * 2 - r * 2) +
                       " a " + r + " " + r + " 0 0 1 " + r + " -" + r + " Z";

            case "slanted":
                var r = (cornerRadius >= 0) ? (cornerRadius < r_max * 0.5 ? cornerRadius : r_max * 0.5) : r_max * 0.25;
                var slant = r_max * 0.35;
                return "M " + (cx - r_max + slant + r) + " " + (cy - r_max) +
                       " h " + (r_max * 2 - slant - r * 2) +
                       " a " + r + " " + r + " 0 0 1 " + r + " " + r +
                       " L " + (cx + r_max - r) + " " + (cy + r_max - r) +
                       " a " + r + " " + r + " 0 0 1 -" + r + " " + r +
                       " h -" + (r_max * 2 - slant - r * 2) +
                       " a " + r + " " + r + " 0 0 1 -" + r + " -" + r +
                       " L " + (cx - r_max + r) + " " + (cy - r_max + r) +
                       " a " + r + " " + r + " 0 0 1 " + r + " -" + r + " Z";

            case "arch":
                var r = (cornerRadius >= 0) ? (cornerRadius < r_max * 0.5 ? cornerRadius : r_max * 0.5) : r_max * 0.22;
                return "M " + (cx - r_max + r) + " " + (cy + r_max) +
                       " V " + (cy - r_max * 0.2) +
                       " C " + (cx - r_max) + " " + (cy - r_max) + " " + (cx + r_max) + " " + (cy - r_max) + " " + (cx + r_max) + " " + (cy - r_max * 0.2) +
                       " V " + (cy + r_max) + " Z";

            case "semicircle":
                return "M " + (cx - r_max) + " " + (cy + r_max * 0.5) +
                       " A " + r_max + " " + (r_max * 1.5) + " 0 0 1 " + (cx + r_max) + " " + (cy + r_max * 0.5) + " Z";

            case "oval":
                return "M " + cx + " " + (cy - r_max) +
                       " C " + (cx + r_max * 0.8) + " " + (cy - r_max * 0.9) + " " + (cx + r_max) + " " + (cy - r_max * 0.2) + " " + (cx + r_max * 0.8) + " " + (cy + r_max * 0.5) +
                       " C " + (cx + r_max * 0.5) + " " + (cy + r_max * 1.0) + " " + (cx - r_max * 0.8) + " " + (cy + r_max * 0.9) + " " + (cx - r_max * 0.8) + " " + (cy - r_max * 0.2) +
                       " C " + (cx - r_max * 0.8) + " " + (cy - r_max * 0.8) + " " + (cx - r_max * 0.5) + " " + (cy - r_max) + " " + cx + " " + (cy - r_max) + " Z";

            case "pill":
                var pr = (cornerRadius >= 0) ? (cornerRadius < r_max * 0.9 ? cornerRadius : r_max * 0.9) : r_max * 0.5;
                return "M " + (cx - r_max + pr) + " " + (cy - pr) +
                       " h " + (r_max * 2 - pr * 2) +
                       " a " + pr + " " + pr + " 0 0 1 0 " + (pr * 2) +
                       " h -" + (r_max * 2 - pr * 2) +
                       " a " + pr + " " + pr + " 0 0 1 0 -" + (pr * 2) + " Z";

            case "triangle":
                var r = (cornerRadius >= 0) ? (cornerRadius < r_max * 0.4 ? cornerRadius : r_max * 0.4) : r_max * 0.16;
                var pts = [
                    { x: cx, y: cy - r_max * 0.9 },
                    { x: cx + r_max * 0.95, y: cy + r_max * 0.8 },
                    { x: cx - r_max * 0.95, y: cy + r_max * 0.8 }
                ];
                return generateRoundedPolygon(pts, r);

            case "arrow":
                var r = (cornerRadius >= 0) ? (cornerRadius < r_max * 0.4 ? cornerRadius : r_max * 0.4) : r_max * 0.14;
                var pts = [
                    { x: cx, y: cy - r_max * 0.9 },
                    { x: cx + r_max * 0.9, y: cy + r_max * 0.7 },
                    { x: cx + r_max * 0.5, y: cy + r_max * 0.8 },
                    { x: cx, y: cy + r_max * 0.95 },
                    { x: cx - r_max * 0.5, y: cy + r_max * 0.8 },
                    { x: cx - r_max * 0.9, y: cy + r_max * 0.7 }
                ];
                return generateRoundedPolygon(pts, r);

            case "fan":
                return "M " + (cx - r_max) + " " + (cy + r_max) +
                       " V " + (cy - r_max * 0.6) +
                       " A " + (r_max * 1.6) + " " + (r_max * 1.6) + " 0 0 1 " + (cx + r_max * 0.6) + " " + (cy + r_max) + " Z";

            case "diamond":
                var r = (cornerRadius >= 0) ? (cornerRadius < r_max * 0.4 ? cornerRadius : r_max * 0.4) : r_max * 0.16;
                var pts = [
                    { x: cx, y: cy - r_max * 0.9 },
                    { x: cx + r_max * 0.9, y: cy },
                    { x: cx, y: cy + r_max * 0.9 },
                    { x: cx - r_max * 0.9, y: cy }
                ];
                return generateRoundedPolygon(pts, r);

            case "clamshell":
                var r = (cornerRadius >= 0) ? (cornerRadius < r_max * 0.3 ? cornerRadius : r_max * 0.3) : r_max * 0.12;
                var pts = [
                    { x: cx - r_max * 0.45, y: cy - r_max * 0.75 },
                    { x: cx + r_max * 0.45, y: cy - r_max * 0.75 },
                    { x: cx + r_max * 0.95, y: cy },
                    { x: cx + r_max * 0.45, y: cy + r_max * 0.75 },
                    { x: cx - r_max * 0.45, y: cy + r_max * 0.75 },
                    { x: cx - r_max * 0.95, y: cy }
                ];
                return generateRoundedPolygon(pts, r);

            case "pentagon":
                var r = (cornerRadius >= 0) ? (cornerRadius < r_max * 0.3 ? cornerRadius : r_max * 0.3) : r_max * 0.12;
                var pts = [
                    { x: cx, y: cy - r_max * 0.95 },
                    { x: cx + r_max * 0.95, y: cy - r_max * 0.25 },
                    { x: cx + r_max * 0.6, y: cy + r_max * 0.85 },
                    { x: cx - r_max * 0.6, y: cy + r_max * 0.85 },
                    { x: cx - r_max * 0.95, y: cy - r_max * 0.25 }
                ];
                return generateRoundedPolygon(pts, r);

            case "gem":
                var r = (cornerRadius >= 0) ? (cornerRadius < r_max * 0.3 ? cornerRadius : r_max * 0.3) : r_max * 0.12;
                var pts = [
                    { x: cx, y: cy - r_max * 0.95 },
                    { x: cx + r_max * 0.9, y: cy - r_max * 0.45 },
                    { x: cx + r_max * 0.9, y: cy + r_max * 0.45 },
                    { x: cx, y: cy + r_max * 0.95 },
                    { x: cx - r_max * 0.9, y: cy + r_max * 0.45 },
                    { x: cx - r_max * 0.9, y: cy - r_max * 0.45 }
                ];
                return generateRoundedPolygon(pts, r);

            case "burst":
                var r = (cornerRadius >= 0) ? (cornerRadius < r_max * 0.2 ? cornerRadius : r_max * 0.2) : r_max * 0.06;
                var pts = [];
                var count = 12 * 2;
                for (var i = 0; i < count; i++) {
                    var angle = (i / count) * 2 * Math.PI;
                    var rad = (i % 2 === 0) ? r_max * 0.95 : r_max * 0.65;
                    pts.push({ x: cx + rad * Math.cos(angle), y: cy + rad * Math.sin(angle) });
                }
                return generateRoundedPolygon(pts, r);

            case "boom":
                var r = (cornerRadius >= 0) ? (cornerRadius < r_max * 0.1 ? cornerRadius : r_max * 0.1) : r_max * 0.03;
                var pts = [];
                var count = 20 * 2;
                for (var i = 0; i < count; i++) {
                    var angle = (i / count) * 2 * Math.PI;
                    var rad = (i % 2 === 0) ? r_max * 0.95 : r_max * 0.45;
                    pts.push({ x: cx + rad * Math.cos(angle), y: cy + rad * Math.sin(angle) });
                }
                return generateRoundedPolygon(pts, r);

            case "soft_boom":
                return generateRadialPath(cx, cy, r_max, 20, 0.5, 0.95, true);

            case "ghost":
            case "ghost_ish":
                var path = "M " + (cx - r_max) + " " + (cy + r_max * 0.4) +
                           " C " + (cx - r_max) + " " + (cy - r_max * 0.9) + " " + (cx + r_max) + " " + (cy - r_max * 0.9) + " " + (cx + r_max) + " " + (cy + r_max * 0.4);
                for (var i = 0; i < 4; i++) {
                    var xVal = cx + r_max - (i + 0.5) * (r_max * 0.5);
                    var yVal = cy + r_max - (i % 2 === 0 ? r_max * 0.3 : 0);
                    var nextX = cx + r_max - (i + 1) * (r_max * 0.5);
                    path += " Q " + xVal + " " + yVal + " " + nextX + " " + (cy + r_max * 0.4);
                }
                path += " Z";
                return path;

            case "pixel_circle":
                return generatePixelShape(cx, cy, r_max, "circle");

            case "pixel_triangle":
                return generatePixelShape(cx, cy, r_max, "triangle");

            case "bun":
                var r1 = r_max * 0.35;
                return "M " + (cx - r_max) + " " + (cy - r1) +
                       " a " + r_max + " " + r1 + " 0 0 1 " + (r_max * 2) + " 0" +
                       " H " + (cx + r_max) +
                       " a " + r_max + " " + r1 + " 0 0 1 -" + (r_max * 2) + " 0 Z" +
                       " M " + (cx - r_max) + " " + (cy + r1) +
                       " a " + r_max + " " + r1 + " 0 0 1 " + (r_max * 2) + " 0" +
                       " H " + (cx + r_max) +
                       " a " + r_max + " " + r1 + " 0 0 1 -" + (r_max * 2) + " 0 Z";

            case "heart":
                var path = "";
                for (var t = 0; t <= 2 * Math.PI; t += 0.05) {
                    var xVal = 16 * Math.pow(Math.sin(t), 3);
                    var yVal = 13 * Math.cos(t) - 5 * Math.cos(2*t) - 2 * Math.cos(3*t) - Math.cos(4*t);
                    var sx = cx + xVal * (r_max / 17);
                    var sy = cy - yVal * (r_max / 17) + (r_max * 0.1);
                    if (t === 0) path += "M " + sx + " " + sy;
                    else path += " L " + sx + " " + sy;
                }
                path += " Z";
                return path;

            default:
                return "M " + cx + " " + (cy - r_max) + 
                       " A " + r_max + " " + r_max + " 0 1 0 " + cx + " " + (cy + r_max) + 
                       " A " + r_max + " " + r_max + " 0 1 0 " + cx + " " + (cy - r_max) + " Z";
        }
    }

    function generateRoundedPolygon(points, r) {
        if (points.length < 3) return "";
        var path = "";
        var len = points.length;

        function getOffsetPoint(pStart, pCorner, offset) {
            var dx = pStart.x - pCorner.x;
            var dy = pStart.y - pCorner.y;
            var dist = Math.sqrt(dx * dx + dy * dy);
            if (dist === 0) return pCorner;
            var scale = (offset < dist ? offset : dist) / dist;
            return {
                x: pCorner.x + dx * scale,
                y: pCorner.y + dy * scale
            };
        }

        for (var i = 0; i < len; i++) {
            var prev = points[(i - 1 + len) % len];
            var curr = points[i];
            var next = points[(i + 1) % len];

            var p1 = getOffsetPoint(prev, curr, r);
            var p2 = getOffsetPoint(next, curr, r);

            if (i === 0) {
                path += "M " + p1.x + " " + p1.y;
            } else {
                path += " L " + p1.x + " " + p1.y;
            }
            path += " Q " + curr.x + " " + curr.y + " " + p2.x + " " + p2.y;
        }
        path += " Z";
        return path;
    }

    function generateRadialPath(cx, cy, r_max, freq, minScale, maxScale, isSmooth) {
        var path = "";
        var steps = isSmooth ? 120 : freq * 2;
        var r_avg = r_max * (minScale + maxScale) / 2;
        var r_amp = r_max * (maxScale - minScale) / 2;

        for (var i = 0; i < steps; i++) {
            var theta = (i / steps) * 2 * Math.PI;
            var r = r_avg + r_amp * Math.cos(freq * theta);
            var x = cx + r * Math.cos(theta);
            var y = cy + r * Math.sin(theta);
            if (i === 0) path += "M " + x + " " + y;
            else path += " L " + x + " " + y;
        }
        path += " Z";
        return path;
    }

    function generatePixelShape(cx, cy, r_max, type) {
        var path = "";
        var size = r_max * 2;
        var pxSize = Math.max(4, Math.round(size / 16));

        if (type === "circle") {
            var gridRadius = 8;
            for (var gy = -gridRadius; gy <= gridRadius; gy++) {
                var gx = Math.round(Math.sqrt(gridRadius * gridRadius - gy * gy));
                var x1 = cx - gx * pxSize;
                var x2 = cx + gx * pxSize;
                var y1 = cy + gy * pxSize;
                
                if (gy === -gridRadius) path += "M " + x1 + " " + y1;
                else path += " H " + x1 + " V " + y1;
                path += " H " + x2;
            }
            path += " Z";
        } else {
            var steps = 8;
            path += "M " + cx + " " + (cy - r_max);
            for (var i = 0; i <= steps; i++) {
                var stepX = cx + (i / steps) * r_max;
                var stepY = cy - r_max + (i / steps) * (r_max * 2);
                path += " H " + stepX + " V " + stepY;
            }
            path += " H " + (cx - r_max);
            for (var i = steps; i >= 0; i--) {
                var stepX = cx - (i / steps) * r_max;
                var stepY = cy - r_max + (i / steps) * (r_max * 2);
                path += " V " + stepY + " H " + stepX;
            }
            path += " Z";
        }
        return path;
    }

    Component.onCompleted: {
        var params = getRadialParams(root.shape);
        if (params !== null) {
            root.animFreq = params.freq;
            root.animMinScale = params.min;
            root.animMaxScale = params.max;
        }
        updatePath();
    }
}
