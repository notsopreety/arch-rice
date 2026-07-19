import Quickshell
import QtQuick
import QtQuick.Layouts
import "../theme"
import "../services"
import "../core"

Item {
    id: root

    property var screen

    readonly property int activeWsId: Hypr.activeWsId
    readonly property var occupied: Hypr.getOccupiedWorkspaces()
    readonly property bool smartHide: true

    readonly property var visibleList: {
        var result = [];
        var maxWorkspaces = 10;
        if (root.activeWsId > maxWorkspaces) maxWorkspaces = root.activeWsId;
        for (var key in root.occupied) {
            var wsNum = parseInt(key);
            if (!isNaN(wsNum) && wsNum > maxWorkspaces) {
                maxWorkspaces = wsNum;
            }
        }
        for (var i = 1; i <= maxWorkspaces; i++) {
            if (i <= 5 || i === root.activeWsId || root.occupied[i]) {
                result.push(i);
            }
        }
        return result;
    }

    readonly property int activeIndex: root.visibleList.indexOf(root.activeWsId)
    property real idx1: activeIndex
    property real idx2: activeIndex

    Behavior on idx1 {
        NumberAnimation { duration: 180; easing.type: Easing.OutSine }
    }
    Behavior on idx2 {
        NumberAnimation { duration: 320; easing.type: Easing.OutSine }
    }

    function getXForIndex(idx) {
        let count = workspaceRepeater.count;
        if (count === 0) return 0;
        let i = Math.max(0, Math.min(count - 1, Math.floor(idx)));
        let f = idx - i;
        let item1 = workspaceRepeater.itemAt(i);
        if (i + 1 < count && f > 0) {
            let item2 = workspaceRepeater.itemAt(i + 1);
            let x1 = item1 ? item1.x : 0;
            let x2 = item2 ? item2.x : x1;
            return x1 + f * (x2 - x1);
        }
        return item1 ? item1.x : 0;
    }

    function getWidthForIndex(idx) {
        let count = workspaceRepeater.count;
        if (count === 0) return 0;
        let i = Math.max(0, Math.min(count - 1, Math.floor(idx)));
        let f = idx - i;
        let item1 = workspaceRepeater.itemAt(i);
        if (i + 1 < count && f > 0) {
            let item2 = workspaceRepeater.itemAt(i + 1);
            let w1 = item1 ? item1.width : 0;
            let w2 = item2 ? item2.width : w1;
            return w1 + f * (w2 - w1);
        }
        return item1 ? item1.width : 0;
    }

    function switchWs(dir) {
        var vis = root.visibleList;
        if (vis.length < 2) return;
        var idx = vis.indexOf(root.activeWsId);
        if (idx < 0) return;
        var next = (idx + dir + vis.length) % vis.length;
        if (vis[next] !== root.activeWsId) {
            Hypr.dispatch('hl.dsp.focus({ workspace = ' + vis[next] + ' })');
        }
    }

    implicitWidth: layout.implicitWidth
    implicitHeight: (Styling.barHeight - Styling.paddingSmall * 2) * Appearance.effectiveScale

    Rectangle {
        id: activePill
        z: 0
        height: 20 * Appearance.effectiveScale
        radius: height / 2
        color: Theme.primary

        x: layout.x + Math.min(root.getXForIndex(root.idx1), root.getXForIndex(root.idx2))
        width: {
            let x1 = root.getXForIndex(root.idx1);
            let x2 = root.getXForIndex(root.idx2);
            let w1 = root.getWidthForIndex(root.idx1);
            let w2 = root.getWidthForIndex(root.idx2);
            let right1 = x1 + w1;
            let right2 = x2 + w2;
            return Math.max(right1, right2) - Math.min(x1, x2);
        }

        anchors.verticalCenter: parent.verticalCenter
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 6 * Appearance.effectiveScale

        Repeater {
            id: workspaceRepeater
            model: root.visibleList

            delegate: Loader {
                required property int index
                required property int modelData

                source: "Workspace.qml"
                asynchronous: false

                onLoaded: {
                    item.workspaceId = modelData
                    item.isActive = Qt.binding(() => root.activeWsId === modelData)
                    item.isOccupied = Qt.binding(() => root.occupied[modelData] ?? false)
                    item.windows = Qt.binding(() => {
                        var rev = Hypr.revision;
                        return Hypr.getWorkspaceWindows(modelData);
                    })
                    item.clicked.connect(function() {
                        if (Hypr.activeWsId !== item.workspaceId) {
                            Hypr.dispatch('hl.dsp.focus({ workspace = ' + item.workspaceId + ' })');
                        }
                    })
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.leftMargin: -8
        anchors.rightMargin: -8
        propagateComposedEvents: true
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) root.switchWs(-1)
            else root.switchWs(1)
        }
    }
}
