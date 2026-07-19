import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC
import Qt5Compat.GraphicalEffects
import Quickshell
import "../../theme"
import "../../services"
import "../../components"
import "../../core"

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // ── Search + Controls Card ──
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: searchCol.implicitHeight + 20
            radius: Theme.rounding.normal
            color: Qt.rgba(255, 255, 255, 0.06)
            border.color: Qt.rgba(255, 255, 255, 0.12)
            border.width: 1

            ColumnLayout {
                id: searchCol
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                // Outlined Search Input container with floating label (Emojiboard style)
                Item {
                    Layout.fillWidth: true
                    height: 52

                    Rectangle {
                        id: searchBg
                        anchors.fill: parent
                        anchors.topMargin: 6
                        radius: 8
                        color: "transparent"
                        border.color: animeSearchField.activeFocus ? Theme.primary : Qt.rgba(255, 255, 255, 0.12)
                        border.width: animeSearchField.activeFocus ? 2 : 1
                        Behavior on border.color { ColorAnimation { duration: 180 } }
                        Behavior on border.width { NumberAnimation { duration: 180 } }
                    }

                    Rectangle {
                        x: 12
                        y: 0
                        height: 14
                        width: labelText.implicitWidth + 8
                        color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.95)
                        
                        Text {
                            id: labelText
                            anchors.centerIn: parent
                            text: "Tags"
                            font.pixelSize: 10
                            font.family: Theme.font.family
                            font.weight: Font.Medium
                            color: animeSearchField.activeFocus ? Theme.primary : Qt.rgba(255, 255, 255, 0.4)
                            Behavior on color { ColorAnimation { duration: 180 } }
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.topMargin: 6
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Text {
                            text: "󰍉"
                            font.family: Theme.font.monospace
                            font.pixelSize: 18
                            color: animeSearchField.activeFocus ? Theme.primary : Qt.rgba(255, 255, 255, 0.5)
                            Layout.alignment: Qt.AlignVCenter
                            Behavior on color { ColorAnimation { duration: 180 } }
                        }

                        TextInput {
                            id: animeSearchField
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            color: "#ffffff"
                            font.family: Theme.font.family
                            font.pixelSize: 14
                            clip: true
                            selectByMouse: true
                            selectionColor: Theme.primary
                            selectedTextColor: "#ffffff"
                            
                            property string placeholderText: "Search tags (e.g. vocaloid)..."
                            
                            Keys.onReturnPressed: BooruService.search(animeSearchField.text)

                            Text {
                                text: animeSearchField.placeholderText
                                color: Qt.rgba(255, 255, 255, 0.35)
                                font: animeSearchField.font
                                visible: !animeSearchField.text && !animeSearchField.activeFocus
                            }
                        }

                        Rectangle {
                            width: 24; height: 24; radius: 12
                            visible: animeSearchField.text.length > 0
                            color: Qt.rgba(255, 255, 255, 0.1)

                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                font.pixelSize: 10
                                color: Qt.rgba(255, 255, 255, 0.6)
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { 
                                    animeSearchField.text = ""; 
                                    BooruService.search(""); 
                                }
                            }
                        }
                    }
                }

                // Provider pills + NSFW toggle
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: BooruService.providerList
                        delegate: Rectangle {
                            width: providerText.implicitWidth + 20
                            height: 28
                            radius: 14
                            color: BooruService.currentProvider === modelData
                                   ? Theme.primary : Qt.rgba(255, 255, 255, 0.08)
                            border.color: BooruService.currentProvider === modelData
                                          ? "transparent" : Qt.rgba(255, 255, 255, 0.12)
                            border.width: 1

                            Text {
                                id: providerText
                                anchors.centerIn: parent
                                text: modelData.split(".")[0]
                                font.family: Theme.font.family
                                font.pixelSize: 11
                                font.weight: BooruService.currentProvider === modelData ? Font.Bold : Font.Normal
                                color: BooruService.currentProvider === modelData
                                       ? Theme.background : "white"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    BooruService.currentProvider = modelData;
                                    if (animeSearchField.text.length > 0)
                                        BooruService.search(animeSearchField.text);
                                    else
                                        BooruService.search("");
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // NSFW label + switch
                    Text {
                        text: "NSFW"
                        font.family: Theme.font.family
                        font.pixelSize: 11
                        color: BooruService.nsfwEnabled ? Theme.error : Qt.rgba(1, 1, 1, 0.4)
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Material Switch Pill (Bluetooth style)
                    Item {
                        width: 44
                        height: 26
                        Layout.alignment: Qt.AlignVCenter

                        Rectangle {
                            id: toggleTrack
                            anchors.fill: parent
                            radius: 13
                            color: BooruService.nsfwEnabled ? Theme.primary : Qt.rgba(255, 255, 255, 0.08)
                            border.width: BooruService.nsfwEnabled ? 0 : 1.5
                            border.color: BooruService.nsfwEnabled ? "transparent" : Qt.rgba(255, 255, 255, 0.2)
                            Behavior on color { ColorAnimation { duration: 180 } }
                        }

                        Rectangle {
                            id: toggleThumb
                            width: 18
                            height: 18
                            radius: 9
                            anchors.verticalCenter: parent.verticalCenter
                            x: BooruService.nsfwEnabled ? toggleTrack.width - width - 4 : 4
                            color: BooruService.nsfwEnabled ? Theme.background : Qt.rgba(255, 255, 255, 0.6)
                            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
                            Behavior on color { ColorAnimation { duration: 180 } }

                            Text {
                                anchors.centerIn: parent
                                text: "󰄬"
                                font.family: Theme.font.monospace
                                font.pixelSize: 11
                                color: Theme.primary
                                opacity: BooruService.nsfwEnabled ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 150 } }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                BooruService.nsfwEnabled = !BooruService.nsfwEnabled;
                            }
                        }
                    }
                }
            }
        }

        // ── Image Grid ──
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            GridView {
                id: imageGrid
                anchors.fill: parent
                model: BooruService.images
                cellWidth: parent.width / 2
                cellHeight: 115 * Appearance.effectiveScale
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                // Hide scrollbar
                QQC.ScrollBar.vertical: QQC.ScrollBar {
                    policy: QQC.ScrollBar.AlwaysOff
                }

                delegate: Item {
                    width: imageGrid.cellWidth
                    height: imageGrid.cellHeight

                    Rectangle {
                        id: cardFrame
                        anchors.fill: parent
                        anchors.margins: 8
                        radius: 12
                        color: Qt.rgba(255, 255, 255, 0.03)
                        border.color: Qt.rgba(255, 255, 255, 0.08)
                        border.width: 1
                        clip: true

                        // Rounded mask for perfect curving matching the wallpaper tab
                        Rectangle {
                            id: maskShape
                            anchors.fill: parent
                            radius: 12
                            visible: false
                        }

                        Image {
                            id: previewImg
                            anchors.fill: parent
                            source: model.previewUrl
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            asynchronous: true
                            visible: false
                            
                            // Smooth subtle zoom effect on hover
                            scale: mouseArea.containsMouse ? 1.05 : 1.0
                            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
                        }

                        OpacityMask {
                            anchors.fill: parent
                            source: previewImg
                            maskSource: maskShape
                        }

                        // Bottom-to-top gradient shadow for readability
                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 0.7; color: Qt.rgba(0, 0, 0, 0.1) }
                                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.65) }
                            }
                            opacity: mouseArea.containsMouse ? 1.0 : 0.4
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }

                        // Loading spinner indicator
                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: Qt.rgba(0, 0, 0, 0.2)
                            visible: previewImg.status === Image.Loading

                            Text {
                                anchors.centerIn: parent
                                text: "󰇚"
                                font.family: Theme.font.monospace
                                font.pixelSize: 22
                                color: Qt.rgba(255, 255, 255, 0.4)
                            }
                        }

                        // MD3 Styled Float-In Overlay Buttons on hover
                        Column {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 6
                            opacity: mouseArea.containsMouse ? 1.0 : 0.0
                            y: mouseArea.containsMouse ? 0 : 8
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                            Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

                            Item { width: 1; height: Math.max(0, parent.height - 46) } // Push down

                            // Copy Link Action Pill
                            Rectangle {
                                width: parent.width - 20
                                height: 20
                                anchors.horizontalCenter: parent.horizontalCenter
                                radius: 10
                                color: Qt.rgba(0, 0, 0, 0.6)
                                border.color: Qt.rgba(255, 255, 255, 0.15)
                                border.width: 1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    DankIcon { name: "content_copy"; size: 10; color: "white" }
                                    Text {
                                        text: "Copy URL (L-Click)"
                                        font.family: "Inter"
                                        font.pixelSize: 8
                                        font.weight: Font.Medium
                                        color: "white"
                                    }
                                }
                            }

                            // Set Wallpaper Action Pill
                            Rectangle {
                                width: parent.width - 20
                                height: 20
                                anchors.horizontalCenter: parent.horizontalCenter
                                radius: 10
                                color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.85)
                                border.color: Qt.rgba(255, 255, 255, 0.1)
                                border.width: 1

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    DankIcon { name: "wallpaper"; size: 10; color: Theme.onPrimary }
                                    Text {
                                        text: "Set Wallpaper (R-Click)"
                                        font.family: "Inter"
                                        font.pixelSize: 8
                                        font.weight: Font.Bold
                                        color: Theme.onPrimary
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            
                            onClicked: (mouse) => {
                                let url = model.sampleUrl || model.fullUrl;
                                let ext = "jpg";
                                if (url.indexOf(".png") !== -1) ext = "png";
                                else if (url.indexOf(".webp") !== -1) ext = "webp";
                                
                                let cleanName = "wall_" + index + "_" + Math.floor(Date.now() / 1000) + "." + ext;
                                let dest = "/tmp/anime-walls/" + cleanName;

                                if (mouse.button === Qt.LeftButton) {
                                    Quickshell.execDetached([
                                        "sh", "-c",
                                        "printf '%s' '" + model.fullUrl + "' | wl-copy && notify-send -r 1011 -a 'Anime Gallery' 'Clipboard' 'Image URL copied to clipboard!'"
                                    ]);
                                } else if (mouse.button === Qt.RightButton) {
                                    Quickshell.execDetached([
                                        "sh", "-c",
                                        "notify-send -r 1012 -a 'Anime Gallery' -t 1500 'Wallpaper' 'Applying wallpaper...' && mkdir -p /tmp/anime-walls && curl -sL '" + url + "' -o '" + dest + "' && /home/sawmer/.config/scripts/wall.sh -i '" + dest + "'"
                                    ]);
                                }
                            }

                            // Top-Right Save/Download Button (Visible on Hover)
                            Rectangle {
                                id: saveButton
                                width: 28
                                height: 28
                                radius: 14
                                color: Qt.rgba(0, 0, 0, 0.6)
                                border.color: Qt.rgba(255, 255, 255, 0.15)
                                border.width: 1
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 10
                                z: 15
                                
                                opacity: mouseArea.containsMouse ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 200 } }
                                
                                DankIcon {
                                    name: "download"
                                    size: 14
                                    color: "white"
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        let url = model.fullUrl;
                                        let ext = "jpg";
                                        if (url.indexOf(".png") !== -1) ext = "png";
                                        else if (url.indexOf(".webp") !== -1) ext = "webp";
                                        
                                        let cleanName = "anime_" + index + "_" + Math.floor(Date.now() / 1000) + "." + ext;
                                        let dest = "/home/sawmer/Pictures/" + cleanName;
                                        
                                        Quickshell.execDetached([
                                            "sh", "-c",
                                            "notify-send -r 1013 -a 'Anime Gallery' -t 1500 'Download' 'Downloading image...' && mkdir -p /home/sawmer/Pictures && curl -sL '" + url + "' -o '" + dest + "' && notify-send -r 1013 -a 'Anime Gallery' 'Image Saved' 'Saved to ~/Pictures/" + cleanName + "'"
                                        ]);
                                    }
                                }
                            }
                        }
                    }
                }

                // Auto-load more
                onContentYChanged: {
                    if (contentHeight > 0 && contentY + height >= contentHeight - 200 && !BooruService.isLoading) {
                        BooruService.loadMore();
                    }
                }
            }

            // Empty state placeholder
            Column {
                anchors.centerIn: parent
                spacing: 12
                visible: BooruService.images.count === 0 && !BooruService.isLoading

                Text {
                    text: "󰀞"
                    font.family: Theme.font.monospace
                    font.pixelSize: 48
                    color: Qt.rgba(1, 1, 1, 0.15)
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Search for anime images"
                    font.family: Theme.font.family
                    font.pixelSize: 14
                    color: Qt.rgba(1, 1, 1, 0.3)
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            // Loading spinner at bottom
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 12
                width: loadingRow.implicitWidth + 20
                height: 32
                radius: 16
                color: Qt.rgba(0, 0, 0, 0.6)
                visible: BooruService.isLoading

                RowLayout {
                    id: loadingRow
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: "Loading..."
                        font.family: Theme.font.family
                        font.pixelSize: 11
                        color: "white"
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        BooruService.search("");
    }
}
