import QtQuick
import Quickshell
import "../theme"

Text {
    id: textItem
    property bool isMonospace: false

    FontLoader {
        id: interFont
        source: "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/fonts/inter/InterVariable.ttf"
    }

    FontLoader {
        id: firaCodeFont
        source: "file://" + Quickshell.env("HOME") + "/.config/quickshell/assets/fonts/nerd-fonts/FiraCodeNerdFont-Regular.ttf"
    }

    color: Theme.onSurface
    font.family: isMonospace ? firaCodeFont.name : interFont.name
    font.pixelSize: Theme.font.sizeNormal
    wrapMode: Text.WordWrap
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
}
