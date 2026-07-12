import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Qt5Compat.GraphicalEffects
import QtCore
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../components"
import "../services"

FloatingWindow {
    id: win

    title: "Calculator"
    implicitWidth:  400
    implicitHeight: scientificMode ? 810 : 640
    minimumSize:    Qt.size(360, 580)

    color: "transparent"

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    // ── State ──────────────────────────────────────────────────────────────
    property string currentTab:    "calc"
    property string expression:    ""
    property string result:        ""
    property bool   lastWasEqual:  false
    property bool   scientificMode: false
    property bool   secondMode:    false   // 2nd-function toggle
    property bool   radianMode:    false   // rad vs deg

    readonly property var history: CalculatorService.history

    // ── Theme ──────────────────────────────────────────────────────────────
    readonly property color clBg:     "#0f0f11"
    readonly property color clSurf:   "#161619"
    readonly property color clAccent: Theme.primary
    readonly property color clOnAcc:  Theme.onPrimary

    // ── Math helpers ───────────────────────────────────────────────────────
    function factorial(n) {
        n = Math.floor(Math.abs(n));
        if (n > 170) return Infinity;
        if (n <= 1)  return 1;
        let r = 1;
        for (let i = 2; i <= n; i++) r *= i;
        return r;
    }

    // ── Evaluation ─────────────────────────────────────────────────────────
    function evaluateExpression() {
        if (!expression) return;
        try {
            let expr = expression
                .replace(/×/g, "*")
                .replace(/÷/g, "/")
                .replace(/−/g, "-")
                .replace(/π/g, "PI")
                .replace(/²/g, "**2")
                .replace(/\^/g, "**")
                .replace(/%/g, "/100");

            // postfix factorial: 5! → fact(5), )! → fact(...)
            expr = expr.replace(/(\d+(?:\.\d+)?|\))\s*!/g, "fact($1)");

            // auto-close parentheses
            let opens  = (expr.match(/\(/g) || []).length;
            let closes = (expr.match(/\)/g) || []).length;
            while (opens > closes) { expr += ")"; closes++; }

            // degree/radian context
            let useDeg = !win.radianMode;
            let toR    = useDeg ? (x) => x * Math.PI / 180 : (x) => x;
            let fromR  = useDeg ? (x) => x * 180 / Math.PI : (x) => x;

            // evaluate with named math context
            let fn = new Function(
                "PI", "E",
                "sin", "cos", "tan",
                "asin", "acos", "atan",
                "log", "lg", "ln",
                "sqrt", "cbrt",
                "fact", "abs", "pow", "exp",
                `"use strict"; return (${expr});`
            );

            let val = fn(
                Math.PI,  Math.E,
                (x) => Math.sin(toR(x)),
                (x) => Math.cos(toR(x)),
                (x) => Math.tan(toR(x)),
                (x) => fromR(Math.asin(x)),
                (x) => fromR(Math.acos(x)),
                (x) => fromR(Math.atan(x)),
                (x) => Math.log10(x),
                (x) => Math.log10(x),
                (x) => Math.log(x),
                (x) => Math.sqrt(x),
                (x) => Math.cbrt(x),
                (x) => win.factorial(x),
                (x) => Math.abs(x),
                (x, y) => Math.pow(x, y),
                (x) => Math.exp(x)
            );

            if (val === undefined || val === null || isNaN(val)) {
                result = "Error";
            } else if (!isFinite(val)) {
                result = val > 0 ? "∞" : "-∞";
            } else {
                let fmt;
                if (Math.abs(val) >= 1e15 || (val !== 0 && Math.abs(val) < 1e-9)) {
                    fmt = val.toExponential(6);
                } else if (val % 1 !== 0) {
                    fmt = parseFloat(val.toFixed(10)).toString();
                } else {
                    fmt = val.toString();
                }
                result = fmt;
                CalculatorService.addEntry(expression, result);
            }
        } catch (e) {
            result = "Error";
        }
    }

    // ── Input helpers ──────────────────────────────────────────────────────
    function append(char) {
        if (lastWasEqual) {
            let ops = ["+", "−", "×", "÷", "%", "^"];
            expression = ops.includes(char) ? (result + char) : char;
            result = "";
            lastWasEqual = false;
            return;
        }
        let ops = ["+", "−", "×", "÷"];
        if (ops.includes(char)) {
            if (expression.length === 0 && char !== "−") return;
            if (ops.includes(expression.slice(-1))) {
                expression = expression.slice(0, -1) + char;
                return;
            }
        }
        expression += char;
    }

    // ── Input helpers ──────────────────────────────────────────────────────
    function backspace() {
        if (lastWasEqual) { clear(); return; }
        if (expression.length > 0) {
            // Remove multi-char function names cleanly
            let funcs = ["asin(","acos(","atan(","sin(","cos(","tan(","log(","ln(","sqrt(","cbrt(","lg("];
            for (let f of funcs) {
                if (expression.endsWith(f)) {
                    expression = expression.slice(0, -f.length);
                    return;
                }
            }
            expression = expression.slice(0, -1);
        }
    }

    function clear() { expression = ""; result = ""; lastWasEqual = false; }

    // ── Root container ────────────────────────────────────────────────────
    Rectangle {
        id: bg
        anchors.fill: parent
        radius:       0
        color:        win.clBg

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled:        true
            shadowColor:          Qt.rgba(0, 0, 0, 0.65)
            shadowBlur:           0.9
            shadowVerticalOffset: 10
        }

        focus: true
        Keys.onPressed: (ev) => {
            if (ev.key >= Qt.Key_0 && ev.key <= Qt.Key_9) {
                append((ev.key - Qt.Key_0).toString()); ev.accepted = true;
            } else if (ev.key === Qt.Key_Plus)    { append("+");   ev.accepted = true;
            } else if (ev.key === Qt.Key_Minus)   { append("−");   ev.accepted = true;
            } else if (ev.key === Qt.Key_Asterisk){ append("×");   ev.accepted = true;
            } else if (ev.key === Qt.Key_Slash)   { append("÷");   ev.accepted = true;
            } else if (ev.key === Qt.Key_Period)  { append(".");   ev.accepted = true;
            } else if (ev.key === Qt.Key_Percent) { append("%");   ev.accepted = true;
            } else if (ev.key === Qt.Key_Enter || ev.key === Qt.Key_Return || ev.key === Qt.Key_Equal) {
                evaluateExpression(); lastWasEqual = true; ev.accepted = true;
            } else if (ev.key === Qt.Key_Backspace) { backspace(); ev.accepted = true;
            } else if (ev.key === Qt.Key_Escape)    { clear();     ev.accepted = true; }
        }

        ColumnLayout {
            anchors.fill:    parent
            spacing:         0

            // ── HEADER (title + history icon) ──────────────────────────────
            RowLayout {
                Layout.fillWidth:      true
                Layout.leftMargin:     20
                Layout.rightMargin:    20
                Layout.topMargin:      16
                Layout.bottomMargin:   0
                Layout.preferredHeight: 36
                spacing: 8

                Text {
                    text: "Calculator"
                    font.family:    Theme.font.family
                    font.pixelSize: 13
                    font.weight:    Font.Bold
                    color:          "white"
                    opacity:        0.8
                }

                Item { Layout.fillWidth: true }

                // History tab toggle
                Rectangle {
                    width: 34; height: 28; radius: 8
                    color: win.currentTab === "history"
                           ? Qt.rgba(win.clAccent.r, win.clAccent.g, win.clAccent.b, 0.18)
                           : "transparent"
                    DankIcon {
                        anchors.centerIn: parent
                        name: "history"; size: 18
                        color: win.currentTab === "history" ? win.clAccent : Qt.rgba(1,1,1,0.55)
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: win.currentTab = win.currentTab === "history" ? "calc" : "history"
                    }
                }
            }

            // ── DISPLAY AREA ──────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth:      true
                Layout.preferredHeight: win.scientificMode ? 130 : 160
                color: "transparent"

                // A subtle linear gradient for screen-like depth
                LinearGradient {
                    anchors.fill: parent
                    start: Qt.point(0, 0)
                    end: Qt.point(0, height)
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.02) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                ColumnLayout {
                    anchors {
                        left: parent.left; right: parent.right; bottom: parent.bottom
                        leftMargin: 24; rightMargin: 24; bottomMargin: 12
                    }
                    spacing: 0

                    // Expression
                    Text {
                        Layout.fillWidth: true
                        text: win.expression || "0"
                        font.family:    Theme.font.monospace
                        font.pixelSize: {
                            let len = win.expression.length;
                            if (len > 30) return 14;
                            if (len > 20) return 18;
                            if (len > 12) return 22;
                            return 28;
                        }
                        color: win.result !== "" ? Qt.rgba(1,1,1,0.42) : "white"
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideLeft
                    }

                    // Result
                    Text {
                        Layout.fillWidth: true
                        text: win.result
                        font.family:    Theme.font.monospace
                        font.pixelSize: win.result.length > 14 ? 24 : (win.result.length > 9 ? 32 : 44)
                        font.weight:    Font.Light
                        color:          "white"
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideLeft
                        visible: win.result !== ""
                    }
                }
            }

            // thin separator
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1,1,1,0.05)
            }

            // ── CALC / HISTORY SWITCHER ────────────────────────────────────
            StackLayout {
                Layout.fillWidth:  true
                Layout.fillHeight: true
                currentIndex: win.currentTab === "calc" ? 0 : 1

                // ─── CALCULATOR KEYS ──────────────────────────────────────
                Item {
                    // Pad the outer container
                    Item {
                        anchors.fill: parent
                        anchors.margins: 10

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 8

                            // ── SCIENTIFIC PANEL (shown only in scientific mode) ──
                            GridLayout {
                                id: sciPanel
                                Layout.fillWidth: true
                                visible:  win.scientificMode
                                columns:  5
                                rowSpacing:    8
                                columnSpacing: 8
                                // Height is 2 rows worth
                                Layout.preferredHeight: win.scientificMode ? (rowH * 2 + 8) : 0

                                readonly property real rowH: 46

                                // ── Row 1: 2nd | rad/deg | sin | cos | tan ──────────
                                CalculatorButton {
                                    text:      "2nd"
                                    colorType: win.secondMode ? "active" : "muted"
                                    active:    win.secondMode
                                    onClicked: win.secondMode = !win.secondMode
                                    Layout.preferredHeight: sciPanel.rowH
                                }
                                CalculatorButton {
                                    text:      win.radianMode ? "rad" : "deg"
                                    colorType: win.radianMode ? "active" : "muted"
                                    active:    win.radianMode
                                    onClicked: win.radianMode = !win.radianMode
                                    Layout.preferredHeight: sciPanel.rowH
                                }
                                CalculatorButton {
                                    text:      win.secondMode ? "sin⁻¹" : "sin"
                                    colorType: "muted"
                                    onClicked: win.append(win.secondMode ? "asin(" : "sin(")
                                    Layout.preferredHeight: sciPanel.rowH
                                }
                                CalculatorButton {
                                    text:      win.secondMode ? "cos⁻¹" : "cos"
                                    colorType: "muted"
                                    onClicked: win.append(win.secondMode ? "acos(" : "cos(")
                                    Layout.preferredHeight: sciPanel.rowH
                                }
                                CalculatorButton {
                                    text:      win.secondMode ? "tan⁻¹" : "tan"
                                    colorType: "muted"
                                    onClicked: win.append(win.secondMode ? "atan(" : "tan(")
                                    Layout.preferredHeight: sciPanel.rowH
                                }

                                // ── Row 2: xʸ | lg | ln | ( | ) ─────────────────────
                                CalculatorButton {
                                    text:      win.secondMode ? "y√x" : "xʸ"
                                    colorType: "muted"
                                    onClicked: win.append("^")
                                    Layout.preferredHeight: sciPanel.rowH
                                }
                                CalculatorButton {
                                    text:      win.secondMode ? "10ˣ" : "lg"
                                    colorType: "muted"
                                    onClicked: win.append(win.secondMode ? "pow(10," : "log(")
                                    Layout.preferredHeight: sciPanel.rowH
                                }
                                CalculatorButton {
                                    text:      win.secondMode ? "eˣ" : "ln"
                                    colorType: "muted"
                                    onClicked: win.append(win.secondMode ? "exp(" : "ln(")
                                    Layout.preferredHeight: sciPanel.rowH
                                }
                                CalculatorButton {
                                    text:      "("
                                    colorType: "muted"
                                    onClicked: win.append("(")
                                    Layout.preferredHeight: sciPanel.rowH
                                }
                                CalculatorButton {
                                    text:      ")"
                                    colorType: "muted"
                                    onClicked: win.append(")")
                                    Layout.preferredHeight: sciPanel.rowH
                                }
                            }

                            // ── MAIN KEYS GRID ────────────────────────────────────
                            // Scientific mode: 5 columns; Basic mode: 4 columns
                            // The main grid always fills the remaining space

                            // ━━━ SCIENTIFIC 5-col GRID ━━━━━━━━━━━━━━━━━━━━━━━━━━━
                            GridLayout {
                                visible:  win.scientificMode
                                Layout.fillWidth:  true
                                Layout.fillHeight: true
                                columns:       5
                                rowSpacing:    8
                                columnSpacing: 8

                                // Row 3 (sci): √x | AC | ⌫ | % | ÷
                                CalculatorButton {
                                    text:      win.secondMode ? "x²" : "√x"
                                    colorType: "muted"
                                    onClicked: win.append(win.secondMode ? "²" : "sqrt(")
                                }
                                CalculatorButton {
                                    text:      "AC"
                                    colorType: "error"
                                    onClicked: win.clear()
                                }
                                CalculatorButton {
                                    iconName:  "backspace"
                                    iconSize:  20
                                    colorType: "muted"
                                    onClicked: win.backspace()
                                }
                                CalculatorButton {
                                    text:      "%"
                                    colorType: "operator"
                                    onClicked: win.append("%")
                                }
                                CalculatorButton {
                                    text:      "÷"
                                    colorType: "operator"
                                    onClicked: win.append("÷")
                                }

                                // Row 4 (sci): x! | 7 | 8 | 9 | ×
                                CalculatorButton {
                                    text:      win.secondMode ? "1/x" : "x!"
                                    colorType: "muted"
                                    onClicked: win.append(win.secondMode ? "(1/" : "!")
                                }
                                CalculatorButton { text: "7"; onClicked: win.append("7") }
                                CalculatorButton { text: "8"; onClicked: win.append("8") }
                                CalculatorButton { text: "9"; onClicked: win.append("9") }
                                CalculatorButton {
                                    text:      "×"
                                    colorType: "operator"
                                    onClicked: win.append("×")
                                }

                                // Row 5 (sci): 1/x | 4 | 5 | 6 | −
                                CalculatorButton {
                                    text:      win.secondMode ? "x!" : "1/x"
                                    colorType: "muted"
                                    onClicked: win.append(win.secondMode ? "!" : "(1/")
                                }
                                CalculatorButton { text: "4"; onClicked: win.append("4") }
                                CalculatorButton { text: "5"; onClicked: win.append("5") }
                                CalculatorButton { text: "6"; onClicked: win.append("6") }
                                CalculatorButton {
                                    text:      "−"
                                    colorType: "operator"
                                    onClicked: win.append("−")
                                }

                                // Row 6 (sci): π | 1 | 2 | 3 | +
                                CalculatorButton {
                                    text:      "π"
                                    colorType: "muted"
                                    onClicked: win.append("π")
                                }
                                CalculatorButton { text: "1"; onClicked: win.append("1") }
                                CalculatorButton { text: "2"; onClicked: win.append("2") }
                                CalculatorButton { text: "3"; onClicked: win.append("3") }
                                CalculatorButton {
                                    text:      "+"
                                    colorType: "operator"
                                    onClicked: win.append("+")
                                }

                                // Row 7 (sci): [collapse] | e | 0 | . | =
                                CalculatorButton {
                                    iconName:  "expand_more"
                                    iconSize:  22
                                    colorType: "muted"
                                    onClicked: win.scientificMode = false
                                }
                                CalculatorButton {
                                    text:      "e"
                                    colorType: "muted"
                                    onClicked: win.append("E")
                                }
                                CalculatorButton { text: "0"; onClicked: win.append("0") }
                                CalculatorButton { text: "."; onClicked: win.append(".") }
                                CalculatorButton {
                                    text:      "="
                                    colorType: "primary"
                                    onClicked: { win.evaluateExpression(); win.lastWasEqual = true; }
                                }
                            }

                            // ━━━ BASIC 4-col GRID ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                            GridLayout {
                                visible:  !win.scientificMode
                                Layout.fillWidth:  true
                                Layout.fillHeight: true
                                columns:       4
                                rowSpacing:    10
                                columnSpacing: 10

                                // Row 1: AC | ⌫ | % | ÷
                                CalculatorButton {
                                    text:      "AC"
                                    colorType: "error"
                                    onClicked: win.clear()
                                }
                                CalculatorButton {
                                    iconName:  "backspace"
                                    iconSize:  22
                                    colorType: "muted"
                                    onClicked: win.backspace()
                                }
                                CalculatorButton {
                                    text:      "%"
                                    colorType: "operator"
                                    onClicked: win.append("%")
                                }
                                CalculatorButton {
                                    text:      "÷"
                                    colorType: "operator"
                                    onClicked: win.append("÷")
                                }

                                // Row 2: 7 | 8 | 9 | ×
                                CalculatorButton { text: "7"; onClicked: win.append("7") }
                                CalculatorButton { text: "8"; onClicked: win.append("8") }
                                CalculatorButton { text: "9"; onClicked: win.append("9") }
                                CalculatorButton {
                                    text:      "×"
                                    colorType: "operator"
                                    onClicked: win.append("×")
                                }

                                // Row 3: 4 | 5 | 6 | −
                                CalculatorButton { text: "4"; onClicked: win.append("4") }
                                CalculatorButton { text: "5"; onClicked: win.append("5") }
                                CalculatorButton { text: "6"; onClicked: win.append("6") }
                                CalculatorButton {
                                    text:      "−"
                                    colorType: "operator"
                                    onClicked: win.append("−")
                                }

                                // Row 4: 1 | 2 | 3 | +
                                CalculatorButton { text: "1"; onClicked: win.append("1") }
                                CalculatorButton { text: "2"; onClicked: win.append("2") }
                                CalculatorButton { text: "3"; onClicked: win.append("3") }
                                CalculatorButton {
                                    text:      "+"
                                    colorType: "operator"
                                    onClicked: win.append("+")
                                }

                                // Row 5: [expand↑] | 0 | . | =
                                CalculatorButton {
                                    iconName:  "expand_less"
                                    iconSize:  24
                                    colorType: "muted"
                                    onClicked: win.scientificMode = true
                                }
                                CalculatorButton { text: "0"; onClicked: win.append("0") }
                                CalculatorButton { text: "."; onClicked: win.append(".") }
                                CalculatorButton {
                                    text:      "="
                                    colorType: "primary"
                                    onClicked: { win.evaluateExpression(); win.lastWasEqual = true; }
                                }
                            }
                        }
                    }
                }

                // ─── HISTORY PANEL ─────────────────────────────────────────
                Item {
                    ColumnLayout {
                        anchors.fill:    parent
                        anchors.margins: 16
                        spacing:         12

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "History"
                                font.family:    Theme.font.family
                                font.pixelSize: 14
                                font.weight:    Font.Bold
                                color:          "white"
                            }
                            Item { Layout.fillWidth: true }

                            Rectangle {
                                width: 88; height: 28; radius: 14
                                color:        "transparent"
                                border.color: Theme.error
                                border.width: 1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    DankIcon { name: "delete_sweep"; size: 14; color: Theme.error }
                                    Text {
                                        text: "Delete All"
                                        font.family:    Theme.font.family
                                        font.pixelSize: 9
                                        font.weight:    Font.Bold
                                        color:          Theme.error
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: CalculatorService.clearHistory()
                                }
                            }
                        }

                        ListView {
                            id: histList
                            Layout.fillWidth:  true
                            Layout.fillHeight: true
                            spacing:    10
                            clip:       true
                            model:      win.history

                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                width:  histList.width
                                height: 100
                                radius: 14
                                color:  win.clSurf
                                border.color: Qt.rgba(1,1,1,0.04)

                                ColumnLayout {
                                    anchors.fill:    parent
                                    anchors.margins: 14
                                    spacing:         4

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text:           modelData.expr
                                            font.family:    Theme.font.monospace
                                            font.pixelSize: 14
                                            color:          Qt.rgba(1,1,1,0.7)
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text:           modelData.time.toUpperCase()
                                            font.family:    Theme.font.family
                                            font.pixelSize: 8
                                            color:          Qt.rgba(1,1,1,0.28)
                                        }
                                    }

                                    Text {
                                        text:            "= " + modelData.res
                                        font.family:     Theme.font.monospace
                                        font.pixelSize:  20
                                        font.weight:     Font.Medium
                                        color:           win.clAccent
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignRight
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Item { Layout.fillWidth: true }

                                        Rectangle {
                                            width: 70; height: 24; radius: 12
                                            color:        "transparent"
                                            border.color: Qt.rgba(1,1,1,0.18)
                                            RowLayout {
                                                anchors.centerIn: parent; spacing: 3
                                                DankIcon { name: "delete"; size: 12; color: "white" }
                                                Text { text: "Delete"; font.family: Theme.font.family; font.pixelSize: 9; color: "white" }
                                            }
                                            MouseArea {
                                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                onClicked: CalculatorService.deleteEntry(index)
                                            }
                                        }

                                        Rectangle {
                                            width: 60; height: 24; radius: 12
                                            color:        "transparent"
                                            border.color: Qt.rgba(1,1,1,0.18)
                                            RowLayout {
                                                anchors.centerIn: parent; spacing: 3
                                                DankIcon { name: "content_copy"; size: 12; color: "white" }
                                                Text { text: "Copy"; font.family: Theme.font.family; font.pixelSize: 9; color: "white" }
                                            }
                                            MouseArea {
                                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    try {
                                                        ClipboardService.setText(modelData.res);
                                                    } catch (e) {
                                                        console.error("Clipboard copy failed:", e);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        currentTab = "calc";
    }
}
