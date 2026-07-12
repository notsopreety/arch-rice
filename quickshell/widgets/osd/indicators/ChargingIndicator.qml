import QtQuick
import QtQuick.Layouts
import "../../../core"
import "../../../theme"
import "../../../services"
import "../../"

Item {
    id: root

    // Required properties by OSD loader interface
    readonly property bool isSliderPressed: false

    implicitWidth: 340 * Appearance.effectiveScale
    implicitHeight: 48 * Appearance.effectiveScale

    readonly property bool isPluggedIn: Battery.isPluggedIn
    readonly property real batteryPercentage: Battery.percentage

    // Smooth animated percentage for startup liquid rise & changes
    property real animatedPercentage: 0.0
    
    // Smooth color interpolation for transitioning states
    readonly property color waveColor: {
        if (isPluggedIn) {
            return "#2ecc71" // Green when charging
        } else {
            if (batteryPercentage < 0.2) return "#ff4d4d" // Red
            if (batteryPercentage < 0.5) return "#ffa502" // Orange/Yellow
            return Theme.primary // Accent theme color
        }
    }

    property real phase: 0

    // Smooth wave movement animation - running when charging
    NumberAnimation {
        id: waveAnim
        target: root
        property: "phase"
        from: 0
        to: Math.PI * 2
        duration: 1800
        loops: Animation.Infinite
        running: isPluggedIn
    }

    // Gentle continuous micro-rotation of the canvas bubbles phase on discharge
    NumberAnimation {
        id: gentleAnim
        target: root
        property: "phase"
        from: 0
        to: Math.PI * 2
        duration: 8000
        loops: Animation.Infinite
        running: !isPluggedIn
    }

    // Trigger startup animations on creation
    Component.onCompleted: {
        animatedPercentage = Battery.percentage;
        // Entrance slide-in signals
        iconSlideIn.to = 0;
        iconSlideIn.start();
        textScaleIn.start();
        badgeSlideIn.to = 0;
        badgeSlideIn.start();
    }

    // Smooth percentage changes transition
    Behavior on animatedPercentage {
        NumberAnimation {
            duration: 900
            easing.type: Easing.OutCubic
        }
    }

    // Force canvas repaint on state changes
    onPhaseChanged: canvas.requestPaint()
    onAnimatedPercentageChanged: canvas.requestPaint()
    onIsPluggedInChanged: {
        canvas.requestPaint();
        // If state changed, sync animatedPercentage smoothly
        animatedPercentage = Battery.percentage;
    }

    // Glassmorphic shadow / back glow
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: "transparent"
        border.color: "transparent"
        
        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            radius: parent.radius
            color: "transparent"
            border.color: isPluggedIn ? Qt.rgba(46/255, 204/255, 113/255, 0.15) : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1)
            border.width: 2
            
            // Fade out glow on unplug
            Behavior on border.color {
                ColorAnimation { duration: 400 }
            }
        }
    }

    // Main Glassmorphic Container
    Rectangle {
        id: bgContainer
        anchors.fill: parent
        radius: height / 2
        color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.45)
        border.color: Qt.rgba(255, 255, 255, 0.18)
        border.width: 1

        // Canvas for wave animation and bubble particle effect
        Canvas {
            id: canvas
            anchors.fill: parent
            antialiasing: true

            // Particle system state
            property var bubbles: []
            
            Component.onCompleted: {
                // Initialize bubbles with random offsets and sizing
                for (var i = 0; i < 22; i++) {
                    bubbles.push({
                        x: Math.random(), 
                        y: Math.random(), 
                        r: 1.0 + Math.random() * 2.0, 
                        speed: 0.3 + Math.random() * 0.8, 
                        wobbleSpeed: 0.04 + Math.random() * 0.06,
                        wobbleAmp: 2 + Math.random() * 3,
                        phase: Math.random() * Math.PI * 2
                    });
                }
            }

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.clearRect(0, 0, width, height);

                // Clip path for rounded rect capsule
                var radius = height / 2;
                ctx.beginPath();
                ctx.moveTo(radius, 0);
                ctx.lineTo(width - radius, 0);
                ctx.quadraticCurveTo(width, 0, width, radius);
                ctx.lineTo(width, height - radius);
                ctx.quadraticCurveTo(width, height, width - radius, height);
                ctx.lineTo(radius, height);
                ctx.quadraticCurveTo(0, height, 0, height - radius);
                ctx.lineTo(0, radius);
                ctx.quadraticCurveTo(0, 0, radius, 0);
                ctx.closePath();
                ctx.clip();

                // Liquid fill level (target y based on animated percentage)
                var targetY = height * (1.0 - root.animatedPercentage);

                var amp = 4 * Appearance.effectiveScale;
                var freq = 0.025; // wave stretch frequency

                // 1. Draw Back Wave (lower opacity, offset phase)
                drawWave(ctx, targetY, root.phase + Math.PI, root.waveColor, 0.45, amp, freq);

                // 2. Draw Front Wave (main fill)
                drawWave(ctx, targetY, root.phase, root.waveColor, 0.80, amp, freq);

                // 3. Draw Neon Gloss Top Highlight Line
                ctx.strokeStyle = root.isPluggedIn ? "#ffffff" : root.waveColor;
                ctx.lineWidth = 1.5 * Appearance.effectiveScale;
                ctx.globalAlpha = 0.6;
                ctx.beginPath();
                ctx.moveTo(0, targetY + amp * Math.sin(root.phase));
                for (var x = 0; x <= width; x += 4) {
                    var y = targetY + amp * Math.sin(x * freq + root.phase);
                    y = Math.max(0, Math.min(height, y));
                    ctx.lineTo(x, y);
                }
                ctx.stroke();

                // 4. Update and Draw Effervescent Bubbles
                if (root.animatedPercentage > 0.02) {
                    ctx.fillStyle = "#ffffff";
                    
                    for (var i = 0; i < bubbles.length; i++) {
                        var b = bubbles[i];
                        
                        if (root.isPluggedIn) {
                            b.y -= b.speed * 0.015; 
                            b.phase += b.wobbleSpeed;
                        } else {
                            b.y -= b.speed * 0.005; 
                            b.phase += b.wobbleSpeed * 0.4;
                        }
                        
                        var px = b.x * width;
                        var waveY = targetY + amp * Math.sin(px * freq + root.phase);
                        
                        if ((b.y * height) < waveY || b.y < 0) {
                            b.y = 1.0;
                            b.x = Math.random();
                        }
                        
                        var py = b.y * height;
                        var finalX = px + b.wobbleAmp * Math.sin(b.phase);
                        
                        var distToSurface = py - waveY;
                        var bubbleOpacity = Math.min(0.5, Math.max(0.0, distToSurface / 20.0));
                        
                        ctx.globalAlpha = bubbleOpacity;
                        ctx.beginPath();
                        ctx.arc(finalX, py, b.r * Appearance.effectiveScale, 0, Math.PI * 2);
                        ctx.closePath();
                        ctx.fill();
                    }
                }
            }

            function drawWave(ctx, targetY, phase, color, opacity, amp, freq) {
                ctx.fillStyle = color;
                ctx.globalAlpha = opacity;
                ctx.beginPath();
                ctx.moveTo(0, height);
                ctx.lineTo(0, targetY);

                for (var x = 0; x <= width; x += 4) {
                    var y = targetY + amp * Math.sin(x * freq + phase);
                    y = Math.max(0, Math.min(height, y));
                    ctx.lineTo(x, y);
                }

                ctx.lineTo(width, height);
                ctx.closePath();
                ctx.fill();
            }
        }

        // Glossy glare reflection overlay (Android 16 glassmorphic highlight)
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Qt.rgba(255, 255, 255, 0.16) }
                GradientStop { position: 0.4; color: Qt.rgba(255, 255, 255, 0.04) }
                GradientStop { position: 0.42; color: Qt.rgba(255, 255, 255, 0.0) }
                GradientStop { position: 1.0; color: Qt.rgba(255, 255, 255, 0.0) }
            }
            border.color: "transparent"
        }

        // Content Row Layout
        RowLayout {
            id: contentRow
            anchors.fill: parent
            anchors.leftMargin: 12 * Appearance.effectiveScale
            anchors.rightMargin: 12 * Appearance.effectiveScale
            spacing: 12 * Appearance.effectiveScale

            // ── Left Slot: Icon Wrapper with Smooth Transitions ──
            Item {
                id: iconWrapper
                Layout.preferredWidth: 32 * Appearance.effectiveScale
                Layout.preferredHeight: 32 * Appearance.effectiveScale
                Layout.alignment: Qt.AlignVCenter
                
                // Entrance animation property
                transform: Translate { id: iconTranslate; x: -40 }
                NumberAnimation { id: iconSlideIn; target: iconTranslate; property: "x"; duration: 600; easing.type: Easing.OutBack }

                // Glowing aura behind icon
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.9
                    height: parent.height * 0.9
                    radius: width / 2
                    color: root.isPluggedIn ? "#2ecc71" : root.waveColor
                    opacity: 0.25
                    
                    Behavior on color { ColorAnimation { duration: 450 } }
                    
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: root.isPluggedIn
                        NumberAnimation { from: 0.15; to: 0.45; duration: 1000; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 0.45; to: 0.15; duration: 1000; easing.type: Easing.InOutQuad }
                    }
                }

                // 1. Bolt Icon (visible when plugged in)
                MaterialShapeWrappedMaterialSymbol {
                    id: boltIcon
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    
                    shapeString: "Gem"
                    text: "bolt"
                    iconSize: 18 * Appearance.effectiveScale
                    
                    color: "#2ecc71"
                    colSymbol: "#ffffff"

                    opacity: root.isPluggedIn ? 1.0 : 0.0
                    scale: root.isPluggedIn ? 1.0 : 0.5

                    Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutQuad } }
                    Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }

                    // Pulse bolt icon scale when charging
                    SequentialAnimation on scale {
                        running: root.isPluggedIn
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 1.16; duration: 900; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 1.16; to: 1.0; duration: 900; easing.type: Easing.InOutQuad }
                    }
                }

                // 2. Discharging Icon (visible when unplugged)
                MaterialShapeWrappedMaterialSymbol {
                    id: normalIcon
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    
                    shapeString: "Gem"
                    text: "flash_off"
                    iconSize: 18 * Appearance.effectiveScale
                    
                    color: Theme.primaryContainer
                    colSymbol: "#ffffff"

                    opacity: root.isPluggedIn ? 0.0 : 1.0
                    scale: root.isPluggedIn ? 0.5 : 1.0

                    Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutQuad } }
                    Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
                }
            }

            // ── Center Slot: Glassmorphic Status Text ──
            Rectangle {
                id: textWrapper
                Layout.fillWidth: true
                Layout.preferredHeight: 32 * Appearance.effectiveScale
                Layout.alignment: Qt.AlignVCenter
                radius: 16 * Appearance.effectiveScale
                color: Qt.rgba(0, 0, 0, 0.20)
                border.color: Qt.rgba(255, 255, 255, 0.08)
                border.width: 1

                // Entrance Scale-in Animation
                scale: 0.0
                opacity: 0.0
                ParallelAnimation {
                    id: textScaleIn
                    NumberAnimation { target: textWrapper; property: "scale"; from: 0.0; to: 1.0; duration: 700; easing.type: Easing.OutBack }
                    NumberAnimation { target: textWrapper; property: "opacity"; from: 0.0; to: 1.0; duration: 500 }
                }
                
                Text {
                    anchors.centerIn: parent
                    text: (root.isPluggedIn ? "Charging" : "Discharging") + " • " + Math.round(root.batteryPercentage * 100) + "%"
                    font.pixelSize: 13 * Appearance.effectiveScale
                    font.weight: Font.Medium
                    color: "#ffffff"
                    elide: Text.ElideRight
                    
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    renderType: Text.NativeRendering
                }
            }

            // ── Right Slot: Category Label ──
            Rectangle {
                id: contextSlot
                Layout.preferredWidth: 44 * Appearance.effectiveScale
                Layout.preferredHeight: 32 * Appearance.effectiveScale
                Layout.alignment: Qt.AlignVCenter
                radius: 12 * Appearance.effectiveScale
                color: root.isPluggedIn ? Qt.rgba(46/255, 204/255, 113/255, 0.25) : Theme.secondaryContainer
                border.color: root.isPluggedIn ? Qt.rgba(46/255, 204/255, 113/255, 0.4) : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.1)
                border.width: 1

                // Entrance slide-in from right
                transform: Translate { id: badgeTranslate; x: 40 }
                NumberAnimation { id: badgeSlideIn; target: badgeTranslate; property: "x"; duration: 600; easing.type: Easing.OutBack }

                Behavior on color { ColorAnimation { duration: 400 } }
                Behavior on border.color { ColorAnimation { duration: 400 } }

                Text {
                    anchors.centerIn: parent
                    text: "BAT"
                    font.pixelSize: 11 * Appearance.effectiveScale
                    font.weight: Font.DemiBold
                    color: root.isPluggedIn ? "#2ecc71" : "#ffffff"
                    opacity: 0.9
                    
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    renderType: Text.NativeRendering
                }
            }
        }
    }
}
