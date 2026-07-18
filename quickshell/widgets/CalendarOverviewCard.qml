import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC
import Quickshell
import Quickshell.Io
import "../theme"
import "../components"
import "../services"

Card {
    id: root

    property date displayDate: new Date()
    property date selectedDate: new Date()
    property string activeTab: "calendar"

    // Temporary values for alarm setup
    property int alarmAddHour: {
        var h = new Date().getHours();
        var h12 = h % 12;
        return h12 === 0 ? 12 : h12;
    }
    property int alarmAddMin: new Date().getMinutes()
    property bool alarmAddIsPM: new Date().getHours() >= 12
    property int editingAlarmIndex: -1
    property string alarmAddRepeatMode: "once"

    readonly property int selectedDaysCount: {
        let today = new Date();
        today.setHours(0, 0, 0, 0);
        let sel = new Date(root.selectedDate);
        sel.setHours(0, 0, 0, 0);
        let diffTime = sel.getTime() - today.getTime();
        let diffDays = Math.round(diffTime / (1000 * 60 * 60 * 24));
        return diffDays;
    }

    // ----------------------------------------------------
    // General Helper Functions
    // ----------------------------------------------------
    function startOfWeek(dateObj) {
        const d = new Date(dateObj);
        const jsDow = d.getDay();
        const diff = (jsDow + 7) % 7; // Sunday start
        d.setDate(d.getDate() - diff);
        return d;
    }

    // ----------------------------------------------------
    // TO-DO LIST DATA & FUNCTIONS
    // ----------------------------------------------------
    ListModel {
        id: todoModel
    }

    FileView {
        id: todoFile
        path: Quickshell.shellPath("todo.json")
        blockLoading: true
        blockWrites: true
        watchChanges: true
        onLoaded: {
            try {
                let content = todoFile.text().trim();
                if (content.length > 0) {
                    let list = JSON.parse(content);
                    todoModel.clear();
                    for (let i = 0; i < list.length; i++) {
                        todoModel.append(list[i]);
                    }
                } else {
                    todoModel.clear();
                    todoModel.append({ "text": "Complete QML refactoring", "done": false });
                    todoModel.append({ "text": "Update Quick Settings bar", "done": true });
                }
            } catch (e) {
                console.log("[CalendarOverviewCard] Failed to parse todo.json: " + e);
            }
        }
    }

    function saveTodo() {
        try {
            let list = [];
            for (let i = 0; i < todoModel.count; i++) {
                list.push({
                    "text": todoModel.get(i).text,
                    "done": todoModel.get(i).done
                });
            }
            todoFile.setText(JSON.stringify(list, null, 2));
        } catch (e) {
            console.log("[CalendarOverviewCard] Failed to write todo.json: " + e);
        }
    }

    // ----------------------------------------------------
    // MAIN LAYOUT
    // ----------------------------------------------------
    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Vertical Tab Bar (Material Side Navigation)
        Item {
            id: sideTabBarContainer
            Layout.preferredWidth: 64
            Layout.fillHeight: true

            Column {
                id: sideTabBar
                anchors.centerIn: parent
                spacing: 12

                // Calendar Tab Button
                Item {
                    width: 64
                    height: 46

                    Rectangle {
                        id: calPill
                        width: 48
                        height: 26
                        radius: 13
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: root.activeTab === "calendar"
                            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.18)
                            : (calMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.05) : "transparent")

                        DankIcon {
                            name: "calendar_month"
                            size: 16
                            anchors.centerIn: parent
                            color: root.activeTab === "calendar" ? Theme.primary : Qt.rgba(255, 255, 255, 0.7)
                        }
                    }

                    Text {
                        text: "Calendar"
                        font.family: "Inter"
                        font.pixelSize: 9
                        font.weight: root.activeTab === "calendar" ? Font.Medium : Font.Normal
                        color: root.activeTab === "calendar" ? Theme.primary : Qt.rgba(255, 255, 255, 0.7)
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    MouseArea {
                        id: calMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activeTab = "calendar"
                    }
                }

                // To Do Tab Button
                Item {
                    width: 64
                    height: 46

                    Rectangle {
                        id: todoPill
                        width: 48
                        height: 26
                        radius: 13
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: root.activeTab === "todo"
                            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.18)
                            : (todoMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.05) : "transparent")

                        DankIcon {
                            name: "task_alt"
                            size: 16
                            anchors.centerIn: parent
                            color: root.activeTab === "todo" ? Theme.primary : Qt.rgba(255, 255, 255, 0.7)
                        }
                    }

                    Text {
                        text: "To Do"
                        font.family: "Inter"
                        font.pixelSize: 9
                        font.weight: root.activeTab === "todo" ? Font.Medium : Font.Normal
                        color: root.activeTab === "todo" ? Theme.primary : Qt.rgba(255, 255, 255, 0.7)
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    MouseArea {
                        id: todoMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activeTab = "todo"
                    }
                }

                // Timer Tab Button
                Item {
                    width: 64
                    height: 46

                    Rectangle {
                        id: timerPill
                        width: 48
                        height: 26
                        radius: 13
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: root.activeTab === "timer"
                            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.18)
                            : (timerMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.05) : "transparent")

                        DankIcon {
                            name: "hourglass"
                            size: 16
                            anchors.centerIn: parent
                            color: root.activeTab === "timer" ? Theme.primary : Qt.rgba(255, 255, 255, 0.7)
                        }
                    }

                    Text {
                        text: "Timer"
                        font.family: "Inter"
                        font.pixelSize: 9
                        font.weight: root.activeTab === "timer" ? Font.Medium : Font.Normal
                        color: root.activeTab === "timer" ? Theme.primary : Qt.rgba(255, 255, 255, 0.7)
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    MouseArea {
                        id: timerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activeTab = "timer"
                    }
                }

                // Stopwatch Tab Button
                Item {
                    width: 64
                    height: 46

                    Rectangle {
                        id: swPill
                        width: 48
                        height: 26
                        radius: 13
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: root.activeTab === "stopwatch"
                            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.18)
                            : (swMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.05) : "transparent")

                        DankIcon {
                            name: "timer"
                            size: 16
                            anchors.centerIn: parent
                            color: root.activeTab === "stopwatch" ? Theme.primary : Qt.rgba(255, 255, 255, 0.7)
                        }
                    }

                    Text {
                        text: "Stopwatch"
                        font.family: "Inter"
                        font.pixelSize: 9
                        font.weight: root.activeTab === "stopwatch" ? Font.Medium : Font.Normal
                        color: root.activeTab === "stopwatch" ? Theme.primary : Qt.rgba(255, 255, 255, 0.7)
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    MouseArea {
                        id: swMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activeTab = "stopwatch"
                    }
                }

                // Alarm Tab Button
                Item {
                    width: 64
                    height: 46

                    Rectangle {
                        id: alarmPill
                        width: 48
                        height: 26
                        radius: 13
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: root.activeTab === "alarm"
                            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.18)
                            : (alarmMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.05) : "transparent")

                        DankIcon {
                            name: "alarm"
                            size: 16
                            anchors.centerIn: parent
                            color: root.activeTab === "alarm" ? Theme.primary : Qt.rgba(255, 255, 255, 0.7)
                        }
                    }

                    Text {
                        text: "Alarm"
                        font.family: "Inter"
                        font.pixelSize: 9
                        font.weight: root.activeTab === "alarm" ? Font.Medium : Font.Normal
                        color: root.activeTab === "alarm" ? Theme.primary : Qt.rgba(255, 255, 255, 0.7)
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    MouseArea {
                        id: alarmMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activeTab = "alarm"
                    }
                }
            }
        }

        // Vertical Divider
        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            Layout.leftMargin: 4
            Layout.rightMargin: 12
            color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
        }

        // Content Area Container
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // ------------------------------------------------
            // 1. Calendar View
            // ------------------------------------------------
            Column {
                anchors.fill: parent
                visible: root.activeTab === "calendar"
                spacing: 12

                Item {
                    width: parent.width
                    height: root.selectedDaysCount > 0 ? 42 : 32

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        color: prevMonthArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "chevron_left"
                            iconSize: 20
                            color: Theme.primary
                        }

                        MouseArea {
                            id: prevMonthArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                let newDate = new Date(root.displayDate);
                                newDate.setMonth(newDate.getMonth() - 1);
                                root.displayDate = newDate;
                            }
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.displayDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                            font.family: Theme.font.family
                            font.pixelSize: 15
                            color: "white"
                            font.weight: Font.DemiBold
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: root.selectedDaysCount > 0
                            text: root.selectedDaysCount + (root.selectedDaysCount === 1 ? " day selected" : " days selected")
                            font.family: Theme.font.family
                            font.pixelSize: 10
                            color: Theme.primary
                            font.weight: Font.Medium
                        }
                    }

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        color: nextMonthArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "chevron_right"
                            iconSize: 20
                            color: Theme.primary
                        }

                        MouseArea {
                            id: nextMonthArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                let newDate = new Date(root.displayDate);
                                newDate.setMonth(newDate.getMonth() + 1);
                                root.displayDate = newDate;
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    height: 24

                    Repeater {
                        model: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

                        Rectangle {
                            width: parent.width / 7
                            height: 24
                            color: "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.family: Theme.font.family
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: Theme.primary
                                opacity: 0.8
                            }
                        }
                    }
                }

                Grid {
                    id: calendarGrid
                    width: parent.width
                    height: parent.height - (root.selectedDaysCount > 0 ? 42 : 32) - 24 - 12
                    columns: 7
                    rows: 6

                    readonly property date firstDay: {
                        const firstOfMonth = new Date(root.displayDate.getFullYear(), root.displayDate.getMonth(), 1);
                        return root.startOfWeek(firstOfMonth);
                    }

                    Repeater {
                        model: 42

                        Rectangle {
                            id: dayCell
                            readonly property date dayDate: {
                                const date = new Date(calendarGrid.firstDay);
                                date.setDate(date.getDate() + index);
                                return date;
                            }
                            readonly property bool isCurrentMonth: dayDate.getMonth() === root.displayDate.getMonth()
                            readonly property bool isToday: dayDate.toDateString() === new Date().toDateString()
                            readonly property bool isSelected: dayDate.toDateString() === root.selectedDate.toDateString()

                            width: parent.width / 7
                            height: parent.height / 6
                            color: "transparent"

                            Rectangle {
                                id: dayHighlight
                                anchors.centerIn: parent
                                width: 34
                                height: 34
                                radius: 17
                                
                                color: isSelected 
                                    ? Theme.primary 
                                    : (isToday ? "transparent" : (dayArea.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent"))
                                
                                border.color: isToday 
                                    ? Theme.primary 
                                    : (isSelected ? Theme.primary : "transparent")
                                border.width: isToday ? 1.5 : 0

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }
                                
                                // Material You feedback
                                scale: dayArea.pressed ? 0.9 : (dayArea.containsMouse ? 1.05 : 1.0)
                                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                                Text {
                                    anchors.centerIn: parent
                                    text: dayCell.dayDate.getDate()
                                    font.family: Theme.font.family
                                    font.pixelSize: 12
                                    color: isSelected 
                                        ? Theme.onPrimary 
                                        : (isToday ? Theme.primary : (isCurrentMonth ? "white" : Qt.rgba(1, 1, 1, 0.25)))
                                    font.weight: (isToday || isSelected) ? Font.Bold : Font.Normal
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }

                            MouseArea {
                                id: dayArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedDate = dayCell.dayDate
                            }
                        }
                    }
                }
            }

            // ------------------------------------------------
            // 2. To Do List View
            // ------------------------------------------------
            // ------------------------------------------------
            // 2. To Do List View (Android MD3 Style)
            // ------------------------------------------------
            ColumnLayout {
                anchors.fill: parent
                visible: root.activeTab === "todo"
                spacing: 14

                // Header with Statistics
                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 2
                    
                    Text {
                        text: qsTr("My Tasks")
                        font.family: Theme.font.family
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                        color: "white"
                    }

                    Item { Layout.fillWidth: true }

                    // Task counters
                    Text {
                        readonly property int activeCount: {
                            let count = 0;
                            for (let i = 0; i < todoModel.count; i++) {
                                if (!todoModel.get(i).done) count++;
                            }
                            return count;
                        }
                        text: activeCount === 0 ? qsTr("All done!") : activeCount + qsTr(" remaining")
                        font.family: Theme.font.family
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Theme.primary
                        opacity: 0.85
                    }
                }

                // Input Bar (MD3 Pill Style)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    radius: 23
                    color: taskInput.activeFocus ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : Qt.rgba(255, 255, 255, 0.04)
                    border.color: taskInput.activeFocus ? Theme.primary : Qt.rgba(255, 255, 255, 0.08)
                    border.width: taskInput.activeFocus ? 1.5 : 1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 8
                        spacing: 12

                        MaterialSymbol {
                            text: "add_task"
                            iconSize: 18
                            color: taskInput.activeFocus ? Theme.primary : Qt.rgba(255, 255, 255, 0.4)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        TextInput {
                            id: taskInput
                            Layout.fillWidth: true
                            verticalAlignment: TextInput.AlignVCenter
                            color: "white"
                            font.family: Theme.font.family
                            font.pixelSize: 13
                            clip: true
                            selectByMouse: true

                            property string placeholderText: "Add a task..."

                            Text {
                                text: taskInput.placeholderText
                                color: Qt.rgba(255, 255, 255, 0.35)
                                font: taskInput.font
                                visible: !taskInput.text && !taskInput.activeFocus
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                            }

                            Keys.onReturnPressed: {
                                let txt = taskInput.text.trim();
                                if (txt.length > 0) {
                                    todoModel.insert(0, { "text": txt, "done": false });
                                    taskInput.text = "";
                                    root.saveTodo();
                                }
                            }
                        }

                        Rectangle {
                            id: addTaskBtn
                            width: 32
                            height: 32
                            radius: 16
                            color: taskInput.text.trim().length > 0 ? Theme.primary : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }

                            MaterialSymbol {
                                text: "arrow_upward"
                                iconSize: 16
                                color: taskInput.text.trim().length > 0 ? Theme.onPrimary : Qt.rgba(255, 255, 255, 0.3)
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    let txt = taskInput.text.trim();
                                    if (txt.length > 0) {
                                        todoModel.insert(0, { "text": txt, "done": false });
                                        taskInput.text = "";
                                        root.saveTodo();
                                    }
                                }
                            }
                        }
                    }
                }

                // Tasks List View
                ListView {
                    id: todoList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 6
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: todoModel

                    add: Transition {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutQuad }
                        NumberAnimation { property: "scale"; from: 0.85; to: 1.0; duration: 200; easing.type: Easing.OutQuad }
                    }
                    remove: Transition {
                        NumberAnimation { property: "opacity"; to: 0; duration: 150 }
                        NumberAnimation { property: "scale"; to: 0.85; duration: 150 }
                    }
                    displaced: Transition {
                        NumberAnimation { properties: "y"; duration: 200; easing.type: Easing.OutQuad }
                    }

                    QQC.ScrollBar.vertical: QQC.ScrollBar {
                        policy: QQC.ScrollBar.AsNeeded
                    }

                    delegate: Rectangle {
                        id: taskRow
                        width: todoList.width
                        height: 46
                        radius: 12
                        
                        // Soft primary tinted color for active tasks, fully transparent for done tasks
                        color: model.done 
                            ? "transparent" 
                            : (taskHover.hovered ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : Qt.rgba(255, 255, 255, 0.02))
                        
                        border.color: model.done 
                            ? "transparent" 
                            : (taskHover.hovered ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2) : Qt.rgba(255, 255, 255, 0.04))
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        HoverHandler {
                            id: taskHover
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 8
                            spacing: 12

                            // Checkbox (Material Design 3 style)
                            Rectangle {
                                id: checkbox
                                width: 20
                                height: 20
                                radius: 10
                                color: model.done ? Theme.primary : "transparent"
                                border.color: model.done ? "transparent" : (checkboxArea.containsMouse ? Theme.primary : Qt.rgba(255, 255, 255, 0.4))
                                border.width: model.done ? 0 : 1.5

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }
                                
                                scale: checkboxArea.pressed ? 0.85 : 1.0
                                Behavior on scale { NumberAnimation { duration: 100 } }

                                MaterialSymbol {
                                    text: "check"
                                    iconSize: 13
                                    color: Theme.onPrimary
                                    anchors.centerIn: parent
                                    visible: model.done
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                MouseArea {
                                    id: checkboxArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        model.done = !model.done;
                                        root.saveTodo();
                                    }
                                }
                            }

                            // Task Text
                            Text {
                                Layout.fillWidth: true
                                text: model.text
                                font.family: Theme.font.family
                                font.pixelSize: 12
                                color: model.done ? Qt.rgba(255, 255, 255, 0.35) : "white"
                                font.strikeout: model.done
                                font.weight: model.done ? Font.Normal : Font.Medium
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            // Delete Button (Custom centered icon button)
                            Rectangle {
                                id: taskDelBtn
                                width: 28
                                height: 28
                                radius: 14
                                color: delArea.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : "transparent"
                                opacity: taskHover.hovered ? 0.9 : 0.0
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on opacity { NumberAnimation { duration: 150 } }

                                MaterialSymbol {
                                    text: "close"
                                    iconSize: 16
                                    color: delArea.containsMouse ? Theme.error : Qt.rgba(255, 255, 255, 0.4)
                                    anchors.centerIn: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    id: delArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        todoModel.remove(index);
                                        root.saveTodo();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ------------------------------------------------
            // 3. Timer View (Android MD3 Style)
            // ------------------------------------------------
            Item {
                anchors.fill: parent
                visible: root.activeTab === "timer"

                // Countdown Mode UI
                ColumnLayout {
                    anchors.fill: parent
                    visible: !TimerStopwatchService.timerSetupMode
                    spacing: 14

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        // Minimalist Circular Progress Track (MD3 Accent Track)
                        Rectangle {
                            width: 140
                            height: 140
                            radius: 70
                            color: Qt.rgba(255, 255, 255, 0.02)
                            border.color: Qt.rgba(255, 255, 255, 0.05)
                            border.width: 5
                            anchors.centerIn: parent

                            // Active progress fill representation
                            Canvas {
                                id: timerProgressCanvas
                                anchors.fill: parent
                                rotation: -90 // Start from the top
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.reset();
                                    ctx.clearRect(0, 0, width, height);
                                    
                                    var ratio = TimerStopwatchService.timerSeconds / TimerStopwatchService.timerTotal;
                                    var center = width / 2;
                                    var radius = center - 2.5; // Align to border center

                                    ctx.beginPath();
                                    ctx.strokeStyle = Theme.primary;
                                    ctx.lineWidth = 5;
                                    ctx.lineCap = "round";
                                    ctx.arc(center, center, radius, 0, 2 * Math.PI * ratio, false);
                                    ctx.stroke();
                                }
                                
                                Connections {
                                    target: TimerStopwatchService
                                    function onTimerSecondsChanged() {
                                        timerProgressCanvas.requestPaint();
                                    }
                                }
                            }

                            // Digital countdown text inside the circle
                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                 Text {
                                    text: TimerStopwatchService.formatTimer(TimerStopwatchService.timerSeconds)
                                    font.family: Theme.font.monospace
                                    font.pixelSize: 26
                                    font.weight: Font.DemiBold
                                    color: "white"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    text: TimerStopwatchService.timerRunning ? "RUNNING" : "PAUSED"
                                    font.family: Theme.font.family
                                    font.pixelSize: 8
                                    font.weight: Font.Bold
                                    color: TimerStopwatchService.timerRunning ? Theme.primary : Qt.rgba(255, 255, 255, 0.35)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }
                        }
                    }

                    // Timer Action Buttons
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 16
                        Layout.bottomMargin: 14

                        // Start/Pause Button (Custom centered icon button)
                        Rectangle {
                            id: timerPlayBtn
                            width: 44
                            height: 44
                            radius: 22
                            color: TimerStopwatchService.timerRunning ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : Theme.primary
                            border.color: TimerStopwatchService.timerRunning ? Theme.primary : "transparent"
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }

                            MaterialSymbol {
                                text: TimerStopwatchService.timerRunning ? "pause" : "play_arrow"
                                iconSize: 22
                                color: TimerStopwatchService.timerRunning ? Theme.primary : Theme.onPrimary
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: TimerStopwatchService.timerRunning = !TimerStopwatchService.timerRunning
                            }
                        }

                        // Stop/Reset Button (Custom centered icon button)
                        Rectangle {
                            id: timerStopBtn
                            width: 44
                            height: 44
                            radius: 22
                            color: stopArea.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.15) : Qt.rgba(255, 255, 255, 0.05)
                            border.color: stopArea.containsMouse ? Theme.error : Qt.rgba(255, 255, 255, 0.1)
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }

                            MaterialSymbol {
                                text: "replay"
                                iconSize: 20
                                color: stopArea.containsMouse ? Theme.error : Qt.rgba(255, 255, 255, 0.6)
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            MouseArea {
                                id: stopArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    TimerStopwatchService.timerRunning = false;
                                    TimerStopwatchService.timerSetupMode = true;
                                }
                            }
                        }
                    }
                }

                // Setup Mode UI (Duration Picker)
                ColumnLayout {
                    anchors.fill: parent
                    visible: TimerStopwatchService.timerSetupMode
                    spacing: 14

                    // Header
                    Text {
                        text: "Set Timer Duration"
                        font.family: Theme.font.family
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: Qt.rgba(255, 255, 255, 0.7)
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 12
                    }

                    // Time inputs row (MD3 styled cards)
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 16
                        Layout.fillHeight: true

                        // Minutes Card
                        Rectangle {
                            implicitWidth: 80
                            implicitHeight: 96
                            radius: 16
                            color: Qt.rgba(255, 255, 255, 0.03)
                            border.color: minInput.activeFocus ? Theme.primary : Qt.rgba(255, 255, 255, 0.08)
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.topMargin: 4
                                anchors.bottomMargin: 6
                                spacing: 0

                                Rectangle {
                                    id: minUp
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 32; height: 20
                                    radius: 10
                                    color: minUpArea.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    
                                    MaterialSymbol {
                                        text: "keyboard_arrow_up"
                                        iconSize: 18
                                        color: "white"
                                        anchors.centerIn: parent
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    MouseArea {
                                        id: minUpArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: TimerStopwatchService.setupMins = Math.min(99, TimerStopwatchService.setupMins + 1)
                                    }
                                }

                                TextInput {
                                    id: minInput
                                    text: String(TimerStopwatchService.setupMins).padStart(2, '0')
                                    font.family: Theme.font.monospace
                                    font.pixelSize: 24
                                    font.weight: Font.DemiBold
                                    color: "white"
                                    selectByMouse: true
                                    horizontalAlignment: TextInput.AlignHCenter
                                    Layout.alignment: Qt.AlignHCenter
                                    validator: IntValidator { bottom: 0; top: 99 }
                                    inputMethodHints: Qt.ImhDigitsOnly
                                    width: 36

                                    onEditingFinished: {
                                        let val = parseInt(text);
                                        if (isNaN(val)) val = 0;
                                        val = Math.min(99, Math.max(0, val));
                                        TimerStopwatchService.setupMins = val;
                                        text = String(val).padStart(2, '0');
                                        focus = false;
                                    }

                                    Connections {
                                        target: TimerStopwatchService
                                        function onSetupMinsChanged() {
                                            if (!minInput.activeFocus) {
                                                minInput.text = String(TimerStopwatchService.setupMins).padStart(2, '0');
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    id: minDown
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 32; height: 20
                                    radius: 10
                                    color: minDownArea.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    
                                    MaterialSymbol {
                                        text: "keyboard_arrow_down"
                                        iconSize: 18
                                        color: "white"
                                        anchors.centerIn: parent
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    MouseArea {
                                        id: minDownArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: TimerStopwatchService.setupMins = Math.max(0, TimerStopwatchService.setupMins - 1)
                                    }
                                }

                                Text { text: "MINUTES"; font.family: Theme.font.family; font.pixelSize: 8; font.weight: Font.Bold; color: Qt.rgba(255, 255, 255, 0.4); Layout.alignment: Qt.AlignHCenter }
                            }
                        }

                        Text {
                            text: ":"
                            font.family: Theme.font.family
                            font.pixelSize: 26
                            font.weight: Font.DemiBold
                            color: Theme.primary
                            Layout.alignment: Qt.AlignVCenter
                        }

                        // Seconds Card
                        Rectangle {
                            implicitWidth: 80
                            implicitHeight: 96
                            radius: 16
                            color: Qt.rgba(255, 255, 255, 0.03)
                            border.color: secInput.activeFocus ? Theme.primary : Qt.rgba(255, 255, 255, 0.08)
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.topMargin: 4
                                anchors.bottomMargin: 6
                                spacing: 0

                                Rectangle {
                                    id: secUp
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 32; height: 20
                                    radius: 10
                                    color: secUpArea.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    
                                    MaterialSymbol {
                                        text: "keyboard_arrow_up"
                                        iconSize: 18
                                        color: "white"
                                        anchors.centerIn: parent
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    MouseArea {
                                        id: secUpArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: TimerStopwatchService.setupSecs = (TimerStopwatchService.setupSecs + 1) % 60
                                    }
                                }

                                TextInput {
                                    id: secInput
                                    text: String(TimerStopwatchService.setupSecs).padStart(2, '0')
                                    font.family: Theme.font.monospace
                                    font.pixelSize: 24
                                    font.weight: Font.DemiBold
                                    color: "white"
                                    selectByMouse: true
                                    horizontalAlignment: TextInput.AlignHCenter
                                    Layout.alignment: Qt.AlignHCenter
                                    validator: IntValidator { bottom: 0; top: 59 }
                                    inputMethodHints: Qt.ImhDigitsOnly
                                    width: 36

                                    onEditingFinished: {
                                        let val = parseInt(text);
                                        if (isNaN(val)) val = 0;
                                        val = Math.min(59, Math.max(0, val));
                                        TimerStopwatchService.setupSecs = val;
                                        text = String(val).padStart(2, '0');
                                        focus = false;
                                    }

                                    Connections {
                                        target: TimerStopwatchService
                                        function onSetupSecsChanged() {
                                            if (!secInput.activeFocus) {
                                                secInput.text = String(TimerStopwatchService.setupSecs).padStart(2, '0');
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    id: secDown
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 32; height: 20
                                    radius: 10
                                    color: secDownArea.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    
                                    MaterialSymbol {
                                        text: "keyboard_arrow_down"
                                        iconSize: 18
                                        color: "white"
                                        anchors.centerIn: parent
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    MouseArea {
                                        id: secDownArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: TimerStopwatchService.setupSecs = (TimerStopwatchService.setupSecs - 1 + 60) % 60
                                    }
                                }

                                Text { text: "SECONDS"; font.family: Theme.font.family; font.pixelSize: 8; font.weight: Font.Bold; color: Qt.rgba(255, 255, 255, 0.4); Layout.alignment: Qt.AlignHCenter }
                            }
                        }
                    }

                    // Preset Quick Action Buttons (MD3 Chips)
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 8

                        Repeater {
                            model: [1, 3, 5, 10]
                            
                            Rectangle {
                                id: presetBtn
                                width: 56
                                height: 24
                                radius: 12
                                color: presetArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : Qt.rgba(255, 255, 255, 0.04)
                                border.color: presetArea.containsMouse ? Theme.primary : Qt.rgba(255, 255, 255, 0.1)
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                Text {
                                    text: modelData + "m"
                                    color: "white"
                                    font.family: Theme.font.family
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                    anchors.centerIn: parent
                                }
                                MouseArea {
                                    id: presetArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        TimerStopwatchService.setupMins = modelData;
                                        TimerStopwatchService.setupSecs = 0;
                                    }
                                }
                            }
                        }
                    }

                    // Start Action Button (MD3 Elevated Pill)
                    Rectangle {
                        id: startTimerBtn
                        Layout.alignment: Qt.AlignHCenter
                        Layout.bottomMargin: 14
                        width: 120
                        height: 38
                        radius: 19
                        
                        readonly property bool canStart: (TimerStopwatchService.setupMins > 0 || TimerStopwatchService.setupSecs > 0)
                        color: canStart ? Theme.primary : Qt.rgba(255, 255, 255, 0.03)
                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            MaterialSymbol {
                                text: "play_arrow"
                                iconSize: 18
                                color: startTimerBtn.canStart ? Theme.onPrimary : Qt.rgba(255, 255, 255, 0.2)
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            Text {
                                text: "Start"
                                font.family: Theme.font.family
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: startTimerBtn.canStart ? Theme.onPrimary : Qt.rgba(255, 255, 255, 0.2)
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: startTimerBtn.canStart
                            cursorShape: startTimerBtn.canStart ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                TimerStopwatchService.timerTotal = (TimerStopwatchService.setupMins * 60) + TimerStopwatchService.setupSecs;
                                TimerStopwatchService.timerSeconds = TimerStopwatchService.timerTotal;
                                TimerStopwatchService.timerSetupMode = false;
                                TimerStopwatchService.timerRunning = true;
                            }
                        }
                    }
                }
            }

            // ------------------------------------------------
            // 4. Stopwatch View
            // ------------------------------------------------
            ColumnLayout {
                anchors.fill: parent
                visible: root.activeTab === "stopwatch"
                spacing: 16

                // Stopwatch time display (huge & clean monospace)
                Text {
                    id: swDisplay
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 16
                    text: TimerStopwatchService.formatStopwatch(TimerStopwatchService.stopwatchTime)
                    font.family: Theme.font.monospace
                    font.pixelSize: 34
                    font.weight: Font.DemiBold
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                }

                // Control Action Row (Play/Pause, Lap, Reset)
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 16
                    Layout.bottomMargin: 4

                    // Lap Button (Custom secondary outlined style)
                    Rectangle {
                        id: swLapBtn
                        width: 40
                        height: 40
                        radius: 20
                        readonly property bool canLap: TimerStopwatchService.swRunning
                        color: canLap ? (lapArea.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(255, 255, 255, 0.03)) : "transparent"
                        border.color: canLap ? (lapArea.containsMouse ? Theme.primary : Qt.rgba(255, 255, 255, 0.15)) : Qt.rgba(255, 255, 255, 0.05)
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        MaterialSymbol {
                            text: "flag"
                            iconSize: 18
                            color: swLapBtn.canLap ? "white" : Qt.rgba(255, 255, 255, 0.2)
                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        MouseArea {
                            id: lapArea
                            anchors.fill: parent
                            enabled: swLapBtn.canLap
                            hoverEnabled: true
                            cursorShape: swLapBtn.canLap ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                let formatted = TimerStopwatchService.formatStopwatch(TimerStopwatchService.stopwatchTime);
                                TimerStopwatchService.swLaps.insert(0, { "lapNum": TimerStopwatchService.swLaps.count + 1, "lapTime": formatted });
                            }
                        }
                    }

                    // Play / Pause Toggle (Large primary Fab style)
                    Rectangle {
                        id: swPlayBtn
                        width: 52
                        height: 52
                        radius: 26
                        color: TimerStopwatchService.swRunning ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : Theme.primary
                        border.color: TimerStopwatchService.swRunning ? Theme.primary : "transparent"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }

                        MaterialSymbol {
                            text: TimerStopwatchService.swRunning ? "pause" : "play_arrow"
                            iconSize: 24
                            color: TimerStopwatchService.swRunning ? Theme.primary : Theme.onPrimary
                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!TimerStopwatchService.swRunning) {
                                    TimerStopwatchService.swStartTime = Date.now();
                                    TimerStopwatchService.swRunning = true;
                                } else {
                                    TimerStopwatchService.swBaseTime = TimerStopwatchService.stopwatchTime;
                                    TimerStopwatchService.swRunning = false;
                                }
                            }
                        }
                    }

                    // Reset Button (Custom secondary outlined style)
                    Rectangle {
                        id: swResetBtn
                        width: 40
                        height: 40
                        radius: 20
                        color: resetArea.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : Qt.rgba(255, 255, 255, 0.03)
                        border.color: resetArea.containsMouse ? Theme.error : Qt.rgba(255, 255, 255, 0.15)
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        MaterialSymbol {
                            text: "replay"
                            iconSize: 18
                            color: resetArea.containsMouse ? Theme.error : Qt.rgba(255, 255, 255, 0.6)
                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: resetArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                TimerStopwatchService.swRunning = false;
                                TimerStopwatchService.stopwatchTime = 0;
                                TimerStopwatchService.swBaseTime = 0;
                                TimerStopwatchService.swLaps.clear();
                            }
                        }
                    }
                }

                // Scrollable Laps Container
                ListView {
                    id: lapsList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.bottomMargin: 4
                    spacing: 6
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: TimerStopwatchService.swLaps

                    add: Transition {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutQuad }
                        NumberAnimation { property: "scale"; from: 0.9; to: 1.0; duration: 200; easing.type: Easing.OutQuad }
                    }
                    remove: Transition {
                        NumberAnimation { property: "opacity"; to: 0; duration: 150 }
                    }
                    displaced: Transition {
                        NumberAnimation { properties: "y"; duration: 200; easing.type: Easing.OutQuad }
                    }

                    QQC.ScrollBar.vertical: QQC.ScrollBar {
                        policy: QQC.ScrollBar.AsNeeded
                    }

                    delegate: Rectangle {
                        width: lapsList.width
                        height: 28
                        radius: 8
                        color: Qt.rgba(255, 255, 255, 0.02)
                        border.color: Qt.rgba(255, 255, 255, 0.04)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12

                            Text {
                                text: "Lap " + model.lapNum
                                font.family: Theme.font.family
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: Qt.rgba(255, 255, 255, 0.5)
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: model.lapTime
                                font.family: Theme.font.monospace
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: "white"
                            }
                        }
                    }

                    // Empty state fallback when no laps recorded
                    Text {
                        anchors.centerIn: parent
                        visible: TimerStopwatchService.swLaps.count === 0
                        text: "No laps recorded"
                        font.family: Theme.font.family
                        font.pixelSize: 12
                        color: Qt.rgba(255, 255, 255, 0.3)
                    }
                }
            }

            // ------------------------------------------------
            // 5. Alarm View (Material You / MD3 Style)
            // ------------------------------------------------
            ColumnLayout {
                anchors.fill: parent
                visible: root.activeTab === "alarm"
                spacing: 14

                // Alarm Creator Section (MD3 Card style)
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 80
                    radius: 16
                    color: Qt.rgba(255, 255, 255, 0.03)
                    border.color: Qt.rgba(255, 255, 255, 0.06)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        // Time Input Container (Pill Shaped card)
                        Rectangle {
                            implicitWidth: 112
                            implicitHeight: 48
                            radius: 24
                            color: Qt.rgba(255, 255, 255, 0.05)
                            border.color: (alarmHourInput.activeFocus || alarmMinInput.activeFocus) ? Theme.primary : Qt.rgba(255, 255, 255, 0.1)
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 4

                                // Hour Input
                                TextInput {
                                    id: alarmHourInput
                                    text: String(root.alarmAddHour).padStart(2, '0')
                                    font.family: Theme.font.monospace
                                    font.pixelSize: 18
                                    font.weight: Font.DemiBold
                                    color: "white"
                                    selectByMouse: true
                                    horizontalAlignment: TextInput.AlignHCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                    validator: IntValidator { bottom: 1; top: 12 }
                                    inputMethodHints: Qt.ImhDigitsOnly
                                    width: 32

                                    onEditingFinished: {
                                        let val = parseInt(text);
                                        if (isNaN(val) || val < 1 || val > 12) val = 7;
                                        root.alarmAddHour = val;
                                        text = String(val).padStart(2, '0');
                                        focus = false;
                                    }

                                    Connections {
                                        target: root
                                        function onAlarmAddHourChanged() {
                                            if (!alarmHourInput.activeFocus) {
                                                alarmHourInput.text = String(root.alarmAddHour).padStart(2, '0');
                                            }
                                        }
                                    }
                                }

                                Text { 
                                    text: ":"
                                    color: Theme.primary
                                    font.family: Theme.font.monospace
                                    font.pixelSize: 18
                                    font.weight: Font.Bold 
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                // Minute Input
                                TextInput {
                                    id: alarmMinInput
                                    text: String(root.alarmAddMin).padStart(2, '0')
                                    font.family: Theme.font.monospace
                                    font.pixelSize: 18
                                    font.weight: Font.DemiBold
                                    color: "white"
                                    selectByMouse: true
                                    horizontalAlignment: TextInput.AlignHCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                    validator: IntValidator { bottom: 0; top: 59 }
                                    inputMethodHints: Qt.ImhDigitsOnly
                                    width: 32

                                    onEditingFinished: {
                                        let val = parseInt(text);
                                        if (isNaN(val) || val < 0 || val > 59) val = 0;
                                        root.alarmAddMin = val;
                                        text = String(val).padStart(2, '0');
                                        focus = false;
                                    }

                                    Connections {
                                        target: root
                                        function onAlarmAddMinChanged() {
                                            if (!alarmMinInput.activeFocus) {
                                                alarmMinInput.text = String(root.alarmAddMin).padStart(2, '0');
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // AM/PM & Repeat Toggles stacked column
                        ColumnLayout {
                            spacing: 4
                            Layout.alignment: Qt.AlignVCenter

                            // AM/PM Toggle Button (Custom filter chip)
                            Rectangle {
                                id: amPmBtn
                                width: 42
                                height: 22
                                radius: 11
                                color: root.alarmAddIsPM ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : Qt.rgba(255, 255, 255, 0.05)
                                border.color: root.alarmAddIsPM ? Theme.primary : Qt.rgba(255, 255, 255, 0.15)
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                Text {
                                    text: root.alarmAddIsPM ? "PM" : "AM"
                                    color: root.alarmAddIsPM ? Theme.primary : "white"
                                    font.family: Theme.font.family
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    anchors.centerIn: parent
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.alarmAddIsPM = !root.alarmAddIsPM
                                }
                            }

                            // Repeat Toggle Button (Custom filter chip)
                            Rectangle {
                                id: repeatBtn
                                width: 42
                                height: 22
                                radius: 11
                                color: root.alarmAddRepeatMode === "daily" ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : Qt.rgba(255, 255, 255, 0.05)
                                border.color: root.alarmAddRepeatMode === "daily" ? Theme.primary : Qt.rgba(255, 255, 255, 0.15)
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                Text {
                                    text: root.alarmAddRepeatMode === "daily" ? "Daily" : "Once"
                                    color: root.alarmAddRepeatMode === "daily" ? Theme.primary : "white"
                                    font.family: Theme.font.family
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    anchors.centerIn: parent
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.alarmAddRepeatMode = (root.alarmAddRepeatMode === "once" ? "daily" : "once")
                                }
                            }
                        }

                        // Label Input & Actions column
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Layout.alignment: Qt.AlignVCenter

                            // Label Input Textfield
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 22
                                radius: 6
                                color: Qt.rgba(255, 255, 255, 0.05)
                                border.color: labelInput.activeFocus ? Theme.primary : Qt.rgba(255, 255, 255, 0.1)
                                border.width: 1

                                TextInput {
                                    id: labelInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: "white"
                                    font.family: Theme.font.family
                                    font.pixelSize: 10
                                    clip: true

                                    Text {
                                        text: "Alarm label..."
                                        color: Qt.rgba(255, 255, 255, 0.3)
                                        font: labelInput.font
                                        visible: !labelInput.text && !labelInput.activeFocus
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }

                            // Actions row (Cancel & Add/Save buttons)
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Item { Layout.fillWidth: true }

                                // Cancel Edit Button
                                Rectangle {
                                    id: cancelEditBtn
                                    visible: root.editingAlarmIndex !== -1
                                    width: 22
                                    height: 22
                                    radius: 11
                                    color: cancelArea.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(255, 255, 255, 0.03)
                                    border.color: cancelArea.containsMouse ? Theme.primary : Qt.rgba(255, 255, 255, 0.15)
                                    border.width: 1
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    MaterialSymbol {
                                        text: "close"
                                        iconSize: 12
                                        color: "white"
                                        anchors.centerIn: parent
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    MouseArea {
                                        id: cancelArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.editingAlarmIndex = -1;
                                            labelInput.text = "";
                                            var now = new Date();
                                            var h = now.getHours();
                                            root.alarmAddHour = (h % 12) === 0 ? 12 : (h % 12);
                                            root.alarmAddMin = now.getMinutes();
                                            root.alarmAddIsPM = h >= 12;
                                        }
                                    }
                                }

                                // Add / Save Button (MD3 Filled Icon Button)
                                Rectangle {
                                    id: addAlarmBtn
                                    width: 44
                                    height: 22
                                    radius: 11
                                    color: Theme.primary

                                    MaterialSymbol {
                                        text: root.editingAlarmIndex === -1 ? "add" : "check"
                                        iconSize: 14
                                        color: Theme.onPrimary
                                        anchors.centerIn: parent
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (root.editingAlarmIndex === -1) {
                                                TimerStopwatchService.alarms.append({
                                                    "hour": root.alarmAddHour,
                                                    "minute": root.alarmAddMin,
                                                    "isPM": root.alarmAddIsPM,
                                                    "label": labelInput.text.trim() || "Alarm",
                                                    "enabled": true,
                                                    "repeatMode": root.alarmAddRepeatMode,
                                                    "lastTriggeredMinute": -1
                                                });
                                            } else {
                                                TimerStopwatchService.alarms.setProperty(root.editingAlarmIndex, "hour", root.alarmAddHour);
                                                TimerStopwatchService.alarms.setProperty(root.editingAlarmIndex, "minute", root.alarmAddMin);
                                                TimerStopwatchService.alarms.setProperty(root.editingAlarmIndex, "isPM", root.alarmAddIsPM);
                                                TimerStopwatchService.alarms.setProperty(root.editingAlarmIndex, "label", labelInput.text.trim() || "Alarm");
                                                TimerStopwatchService.alarms.setProperty(root.editingAlarmIndex, "repeatMode", root.alarmAddRepeatMode);
                                                root.editingAlarmIndex = -1;
                                            }
                                            labelInput.text = "";
                                            var now = new Date();
                                            var h = now.getHours();
                                            root.alarmAddHour = (h % 12) === 0 ? 12 : (h % 12);
                                            root.alarmAddMin = now.getMinutes();
                                            root.alarmAddIsPM = h >= 12;
                                            TimerStopwatchService.saveAlarms();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Alarms List View
                ListView {
                    id: alarmsList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 6
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: TimerStopwatchService.alarms

                    add: Transition {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutQuad }
                        NumberAnimation { property: "scale"; from: 0.9; to: 1.0; duration: 200; easing.type: Easing.OutQuad }
                    }
                    remove: Transition {
                        NumberAnimation { property: "opacity"; to: 0; duration: 150 }
                    }
                    displaced: Transition {
                        NumberAnimation { properties: "y"; duration: 200; easing.type: Easing.OutQuad }
                    }

                    QQC.ScrollBar.vertical: QQC.ScrollBar {
                        policy: QQC.ScrollBar.AsNeeded
                    }

                    delegate: Rectangle {
                        id: alarmRow
                        width: alarmsList.width
                        height: 52
                        radius: 12
                        color: alarmHover.hovered ? Qt.rgba(255, 255, 255, 0.04) : Qt.rgba(255, 255, 255, 0.01)
                        border.color: Qt.rgba(255, 255, 255, 0.04)
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }

                        HoverHandler {
                            id: alarmHover
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            // Alarm Time & Tag Column (MD3-like spacing)
                            ColumnLayout {
                                spacing: 1
                                Layout.alignment: Qt.AlignVCenter

                                RowLayout {
                                    spacing: 4
                                    Text {
                                        text: String(model.hour).padStart(2, '0') + ":" + String(model.minute).padStart(2, '0')
                                        font.family: Theme.font.monospace
                                        font.pixelSize: 18
                                        font.weight: Font.DemiBold
                                        color: model.enabled ? "white" : Qt.rgba(255, 255, 255, 0.35)
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                    Text {
                                        text: model.isPM ? "PM" : "AM"
                                        font.family: Theme.font.family
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                        color: model.enabled ? Theme.primary : Qt.rgba(255, 255, 255, 0.25)
                                        Layout.alignment: Qt.AlignBottom
                                        Layout.bottomMargin: 2
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                }

                                RowLayout {
                                    spacing: 6
                                    Text {
                                        text: model.label
                                        font.family: Theme.font.family
                                        font.pixelSize: 10
                                        color: model.enabled ? Qt.rgba(255, 255, 255, 0.6) : Qt.rgba(255, 255, 255, 0.3)
                                        elide: Text.ElideRight
                                        Layout.maximumWidth: 120
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                    // Repeat Pill Indicator
                                    Rectangle {
                                        implicitWidth: 36
                                        implicitHeight: 14
                                        radius: 7
                                        color: model.enabled ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Qt.rgba(255, 255, 255, 0.04)
                                        border.color: model.enabled ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.25) : "transparent"
                                        border.width: 1
                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: (model.repeatMode === "daily" ? "Daily" : "Once")
                                            font.family: Theme.font.family
                                            font.pixelSize: 8
                                            font.weight: Font.Bold
                                            color: model.enabled ? Theme.primary : Qt.rgba(255, 255, 255, 0.25)
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Action buttons & Switch layout
                            RowLayout {
                                spacing: 8
                                Layout.alignment: Qt.AlignVCenter

                                // Edit Alarm Button (Custom centered icon button)
                                Rectangle {
                                    id: alarmEditBtn
                                    visible: alarmHover.hovered
                                    width: 28
                                    height: 28
                                    radius: 14
                                    color: editArea.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    MaterialSymbol {
                                        text: "edit"
                                        iconSize: 15
                                        color: editArea.containsMouse ? Theme.primary : Qt.rgba(255, 255, 255, 0.6)
                                        anchors.centerIn: parent
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    MouseArea {
                                        id: editArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.alarmAddHour = model.hour;
                                            root.alarmAddMin = model.minute;
                                            root.alarmAddIsPM = model.isPM;
                                            labelInput.text = model.label;
                                            root.alarmAddRepeatMode = model.repeatMode || "once";
                                            root.editingAlarmIndex = index;
                                        }
                                    }
                                }

                                // Delete Alarm Button (Custom centered icon button)
                                Rectangle {
                                    id: alarmDelBtn
                                    visible: alarmHover.hovered
                                    width: 28
                                    height: 28
                                    radius: 14
                                    color: delAlarmArea.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : "transparent"
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    MaterialSymbol {
                                        text: "delete"
                                        iconSize: 15
                                        color: delAlarmArea.containsMouse ? Theme.error : Qt.rgba(255, 255, 255, 0.6)
                                        anchors.centerIn: parent
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }

                                    MouseArea {
                                        id: delAlarmArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            TimerStopwatchService.alarms.remove(index);
                                            TimerStopwatchService.saveAlarms();
                                        }
                                    }
                                }

                                // MD3 Style Switch (Enable/Disable toggle)
                                Rectangle {
                                    id: switchTrack
                                    width: 34
                                    height: 20
                                    radius: 10
                                    color: model.enabled ? Theme.primary : Qt.rgba(255, 255, 255, 0.15)
                                    border.color: model.enabled ? "transparent" : Qt.rgba(255, 255, 255, 0.25)
                                    border.width: model.enabled ? 0 : 1.5
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Rectangle {
                                        width: model.enabled ? 14 : 10
                                        height: model.enabled ? 14 : 10
                                        radius: model.enabled ? 7 : 5
                                        color: model.enabled ? Theme.onPrimary : Qt.rgba(255, 255, 255, 0.45)
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: model.enabled ? 17 : 4

                                        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                        Behavior on width { NumberAnimation { duration: 120 } }
                                        Behavior on height { NumberAnimation { duration: 120 } }
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            model.enabled = !model.enabled;
                                            TimerStopwatchService.saveAlarms();
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
