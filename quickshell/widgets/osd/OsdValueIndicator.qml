import "../../core"
import "../../widgets"
import "../../core/functions" as Functions
import "../../theme"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

/**
 * Refactored OSD Value Indicator (Volume/Brightness)
 * Simplified structure with beautiful glassmorphism and entrance animations.
 */
Item {
    id: valueIndicatorRoot
    
    // Required properties
    property real value: 0
    property string icon: ""
    property string name: ""
    property var shape
    property bool rotateIcon: false
    property bool scaleIcon: false
    property bool isMuted: false
    property color highlightColor: isMuted ? Theme.outline : Theme.primary

    // Slidable control properties/signals
    signal sliderMoved(real newValue)
    readonly property bool isSliderPressed: portedSlider.pressed

    // Root dimensions for the Loader/PanelWindow
    implicitWidth: 340 * Appearance.effectiveScale
    implicitHeight: 48 * Appearance.effectiveScale

    Component.onCompleted: {
        // Run entrance animations on load
        iconSlideIn.to = 0;
        iconSlideIn.start();
        centerScaleIn.start();
        badgeSlideIn.to = 0;
        badgeSlideIn.start();
    }

    // ── Glassmorphism toggle ──────────────────────────────────────────────
    property bool glassmorphism: false

    FileView {
        id: glassFlag
        path: Quickshell.env("HOME") + "/.config/hypr/.glassmorphism_enabled"
        watchChanges: true
        onFileChanged: glassFlagTimer.restart()
        Component.onCompleted: { try { glassFlag.reload(); valueIndicatorRoot.glassmorphism = true; } catch(e) { valueIndicatorRoot.glassmorphism = false; } }
        onLoaded: valueIndicatorRoot.glassmorphism = true
        onLoadFailed: valueIndicatorRoot.glassmorphism = false
    }
    Timer { id: glassFlagTimer; interval: 200; repeat: false; onTriggered: { try { glassFlag.reload(); } catch(e) {} } }

    // Main Glassmorphic Container
    Rectangle {
        id: valueIndicator
        anchors.fill: parent
        radius: height / 2
        color: valueIndicatorRoot.glassmorphism ? Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.35) : Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.95)
        border.color: valueIndicatorRoot.glassmorphism ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
        border.width: 1
        clip: true
        Behavior on color { ColorAnimation { duration: 400 } }
        Behavior on border.color { ColorAnimation { duration: 400 } }

        // Glossy glare reflection overlay (Android 16 glassmorphic style)
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: parent.height * 0.45
            radius: parent.radius
            visible: valueIndicatorRoot.glassmorphism
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.12) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.00) }
            }
            border.color: "transparent"
            z: 999
        }

        RowLayout {
            id: valueRow
            anchors.fill: parent
            anchors.leftMargin: 12 * Appearance.effectiveScale
            anchors.rightMargin: 12 * Appearance.effectiveScale
            spacing: 12 * Appearance.effectiveScale
 
            // ── Left Slot: Icon Wrapper ──
            Item {
                id: iconWrapper
                Layout.preferredWidth: 32 * Appearance.effectiveScale
                Layout.preferredHeight: 32 * Appearance.effectiveScale
                Layout.alignment: Qt.AlignVCenter

                // Entrance Slide-In
                transform: Translate { id: iconTranslate; x: -40 }
                NumberAnimation { id: iconSlideIn; target: iconTranslate; property: "x"; duration: 600; easing.type: Easing.OutBack }

                // Glowing Aura behind the icon
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.9
                    height: parent.height * 0.9
                    radius: width / 2
                    color: valueIndicatorRoot.highlightColor
                    opacity: 0.2
                    
                    Behavior on color { ColorAnimation { duration: 400 } }
                }

                MaterialShapeWrappedMaterialSymbol {
                    id: iconMain
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    
                    rotation: valueIndicatorRoot.rotateIcon ? valueIndicatorRoot.value * 360 : 0
                    scale: valueIndicatorRoot.scaleIcon ? (0.85 + valueIndicatorRoot.value * 0.3) : 1.0
                    
                    Behavior on rotation {
                        RotationAnimation {
                            duration: 250
                            direction: RotationAnimation.Shortest
                            easing.type: Easing.OutCubic
                        }
                    }
                    
                    Behavior on scale {
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.OutBack
                        }
                    }
                    
                    shapeString: (typeof valueIndicatorRoot.shape === "string") ? valueIndicatorRoot.shape : "Circle"
                    text: valueIndicatorRoot.icon
                    iconSize: 18 * Appearance.effectiveScale
                    
                    color: Theme.primaryContainer
                    colSymbol: "#ffffff"
                }
            }

            // ── Center Slot: Slider Control ──
            Item {
                id: centerWrapper
                Layout.fillWidth: true
                Layout.preferredHeight: 32 * Appearance.effectiveScale
                Layout.alignment: Qt.AlignVCenter

                // Entrance Scale-In
                scale: 0.0
                opacity: 0.0
                ParallelAnimation {
                    id: centerScaleIn
                    NumberAnimation { target: centerWrapper; property: "scale"; from: 0.0; to: 1.0; duration: 700; easing.type: Easing.OutBack }
                    NumberAnimation { target: centerWrapper; property: "opacity"; from: 0.0; to: 1.0; duration: 500 }
                }
                
                StyledSlider {
                    id: portedSlider
                    anchors.centerIn: parent
                    width: parent.width
                    
                    from: 0
                    to: 1
                    enabled: true
                    
                    configuration: StyledSlider.Configuration.M
                    animateValue: !pressed
                    
                    handleMargins: 4 * Appearance.effectiveScale
                    highlightColor: valueIndicatorRoot.highlightColor
                    trackColor: Theme.surfaceVariant
                    handleColor: valueIndicatorRoot.highlightColor

                    onMoved: {
                        valueIndicatorRoot.sliderMoved(value);
                    }

                    Binding on value {
                        value: valueIndicatorRoot.value
                        when: !portedSlider.pressed
                    }
                }
                
                Text {
                    anchors.centerIn: parent
                    text: valueIndicatorRoot.name.toUpperCase()
                    font.pixelSize: 9 * Appearance.effectiveScale
                    font.weight: Font.Bold
                    color: "#ffffff"
                    opacity: 0.35
                    z: 10
                }
            }

            // ── Right Slot: Value Indicator Badge ──
            Rectangle {
                id: valueSlot
                Layout.preferredWidth: 44 * Appearance.effectiveScale
                Layout.preferredHeight: 32 * Appearance.effectiveScale
                Layout.alignment: Qt.AlignVCenter
                
                radius: 12 * Appearance.effectiveScale
                color: Theme.secondaryContainer
                border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.1)
                border.width: 1

                // Entrance Slide-In
                transform: Translate { id: badgeTranslate; x: 40 }
                NumberAnimation { id: badgeSlideIn; target: badgeTranslate; property: "x"; duration: 600; easing.type: Easing.OutBack }

                Text {
                    anchors.centerIn: parent
                    text: Math.round(valueIndicatorRoot.value * 100)
                    font.pixelSize: 13 * Appearance.effectiveScale
                    font.family: Appearance.font.family.numbers
                    font.weight: Font.DemiBold
                    color: "#ffffff"
                    
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    renderType: Text.NativeRendering
                }
            }
        }
    }

    SequentialAnimation {
        id: iconBounceAnim
        NumberAnimation { target: iconWrapper; property: "scale"; from: 1.0; to: 1.25; duration: 150; easing.type: Easing.OutBack }
        NumberAnimation { target: iconWrapper; property: "scale"; from: 1.25; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
    }

    property string previousIcon: ""
    onIconChanged: {
        const isVolumeIcon = icon.startsWith("volume_");
        const wasVolumeIcon = previousIcon.startsWith("volume_");
        
        if (isVolumeIcon && wasVolumeIcon) {
            if (icon === "volume_off" || previousIcon === "volume_off") {
                iconBounceAnim.restart();
            }
        } else {
            iconBounceAnim.restart();
        }
        previousIcon = icon;
    }
}
