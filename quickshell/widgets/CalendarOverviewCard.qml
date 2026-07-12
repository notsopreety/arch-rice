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
                    height: root.selectedDaysCount > 0 ? 38 : 28

                    Rectangle {
                        width: 28
                        height: 28
                        radius: Theme.rounding.normal
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        color: prevMonthArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1) : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "‹"
                            font.family: Theme.font.family
                            font.pixelSize: 18
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
                            font.pixelSize: 14
                            color: "white"
                            font.weight: Font.Medium
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
                        width: 28
                        height: 28
                        radius: Theme.rounding.normal
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        color: nextMonthArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1) : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "›"
                            font.family: Theme.font.family
                            font.pixelSize: 18
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
                    height: 18

                    Repeater {
                        model: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

                        Rectangle {
                            width: parent.width / 7
                            height: 18
                            color: "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.family: Theme.font.family
                                font.pixelSize: 11
                                color: Qt.rgba(1, 1, 1, 0.5)
                            }
                        }
                    }
                }

                Grid {
                    id: calendarGrid
                    width: parent.width
                    height: parent.height - (root.selectedDaysCount > 0 ? 38 : 28) - 18 - 12
                    columns: 7
                    rows: 6

                    readonly property date firstDay: {
                        const firstOfMonth = new Date(root.displayDate.getFullYear(), root.displayDate.getMonth(), 1);
                        return root.startOfWeek(firstOfMonth);
                    }

                    Repeater {
                        model: 42

                        Rectangle {
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
                                anchors.centerIn: parent
                                width: 28
                                height: 28
                                color: isSelected ? Theme.primary : isToday ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.25) : dayArea.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent"
                                radius: 14
                                border.color: isToday && !isSelected ? Theme.primary : "transparent"
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: dayDate.getDate()
                                    font.family: Theme.font.family
                                    font.pixelSize: 11
                                    color: isSelected ? Theme.onPrimary : isToday ? Theme.primary : isCurrentMonth ? "white" : Qt.rgba(1, 1, 1, 0.3)
                                    font.weight: (isToday || isSelected) ? Font.Bold : Font.Normal
                                }
                            }

                            MouseArea {
                                id: dayArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedDate = dayDate
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
                spacing: 12

                // Input Bar (MD3 Pill Style)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    radius: 22
                    color: Qt.rgba(255, 255, 255, 0.04)
                    border.color: taskInput.activeFocus ? Theme.primary : Qt.rgba(255, 255, 255, 0.08)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 12
                        spacing: 8

                        DankIcon {
                            name: "edit"
                            size: 16
                            color: taskInput.activeFocus ? Theme.primary : Qt.rgba(255, 255, 255, 0.4)
                        }

                        TextInput {
                            id: taskInput
                            Layout.fillWidth: true
                            verticalAlignment: TextInput.AlignVCenter
                            color: "white"
                            font.family: "Inter"
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
                                    todoModel.append({ "text": txt, "done": false });
                                    taskInput.text = "";
                                    root.saveTodo();
                                }
                            }
                        }

                        QQC.Button {
                            id: addTaskBtn
                            implicitWidth: 32
                            implicitHeight: 32
                            background: Rectangle {
                                color: taskInput.text.trim().length > 0 ? Theme.primary : Qt.rgba(255, 255, 255, 0.05)
                                radius: 16
                            }
                            contentItem: DankIcon {
                                name: "add"
                                size: 14
                                color: taskInput.text.trim().length > 0 ? Theme.onPrimary : Qt.rgba(255, 255, 255, 0.3)
                            }
                            onClicked: {
                                let txt = taskInput.text.trim();
                                if (txt.length > 0) {
                                    todoModel.append({ "text": txt, "done": false });
                                    taskInput.text = "";
                                    root.saveTodo();
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
                    spacing: 8
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: todoModel

                    QQC.ScrollBar.vertical: QQC.ScrollBar {
                        policy: QQC.ScrollBar.AsNeeded
                    }

                    delegate: Rectangle {
                        id: taskRow
                        width: todoList.width
                        height: 48
                        radius: 16
                        color: taskHover.hovered ? Qt.rgba(255, 255, 255, 0.05) : Qt.rgba(255, 255, 255, 0.02)
                        border.color: Qt.rgba(255, 255, 255, 0.05)
                        border.width: 1

                        HoverHandler {
                            id: taskHover
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 12
                            spacing: 12

                            // MD3 Style Checkbox / Circle
                            Rectangle {
                                width: 22
                                height: 22
                                radius: 11
                                color: model.done ? Theme.primary : "transparent"
                                border.color: model.done ? "transparent" : Qt.rgba(255, 255, 255, 0.3)
                                border.width: model.done ? 0 : 2

                                DankIcon {
                                    name: "check"
                                    size: 14
                                    color: Theme.onPrimary
                                    anchors.centerIn: parent
                                    visible: model.done
                                }

                                MouseArea {
                                    anchors.fill: parent
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
                                font.family: "Inter"
                                font.pixelSize: 13
                                color: model.done ? Qt.rgba(255, 255, 255, 0.35) : "white"
                                font.strikeout: model.done
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }

                            // Delete Action Button
                            QQC.Button {
                                id: taskDelBtn
                                visible: taskHover.hovered
                                implicitWidth: 28
                                implicitHeight: 28

                                background: Rectangle {
                                    color: taskDelBtn.hovered ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.15) : "transparent"
                                    radius: 14
                                }

                                contentItem: DankIcon {
                                    name: "delete"
                                    size: 14
                                    color: Theme.error
                                }

                                onClicked: {
                                    todoModel.remove(index);
                                    root.saveTodo();
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
                    spacing: 12

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        // Minimalist Circular Progress Track (MD3 Accent Track)
                        Rectangle {
                            width: 130
                            height: 130
                            radius: 65
                            color: Qt.rgba(255, 255, 255, 0.02)
                            border.color: Qt.rgba(255, 255, 255, 0.05)
                            border.width: 6
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
                                    var radius = center - 3; // Align to border center

                                    ctx.beginPath();
                                    ctx.strokeStyle = Theme.primary;
                                    ctx.lineWidth = 6;
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
                                spacing: 2

                                Text {
                                    text: TimerStopwatchService.formatTimer(TimerStopwatchService.timerSeconds)
                                    font.family: "Inter"
                                    font.pixelSize: 24
                                    font.weight: Font.Bold
                                    color: "white"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    text: TimerStopwatchService.timerRunning ? "RUNNING" : "PAUSED"
                                    font.family: "Inter"
                                    font.pixelSize: 8
                                    font.weight: Font.Bold
                                    color: TimerStopwatchService.timerRunning ? Theme.primary : Qt.rgba(255, 255, 255, 0.35)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }
                    }

                    // Timer Action Buttons
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 16
                        Layout.bottomMargin: 12

                        // Start/Pause Button (MD3 Fab style)
                        QQC.Button {
                            id: timerPlayBtn
                            implicitWidth: 44
                            implicitHeight: 44
                            background: Rectangle {
                                color: TimerStopwatchService.timerRunning ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : Theme.primary
                                radius: 22
                                border.color: TimerStopwatchService.timerRunning ? Theme.primary : "transparent"
                                border.width: 1
                            }
                            contentItem: DankIcon {
                                name: TimerStopwatchService.timerRunning ? "pause" : "play_arrow"
                                size: 20
                                color: TimerStopwatchService.timerRunning ? Theme.primary : Theme.onPrimary
                            }
                            onClicked: TimerStopwatchService.timerRunning = !TimerStopwatchService.timerRunning
                        }

                        // Stop/Reset Button (MD3 Outlined Action style)
                        QQC.Button {
                            id: timerStopBtn
                            implicitWidth: 44
                            implicitHeight: 44
                            background: Rectangle {
                                color: timerStopBtn.hovered ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.15) : Qt.rgba(255, 255, 255, 0.05)
                                border.color: Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.3)
                                border.width: 1
                                radius: 22
                            }
                            contentItem: DankIcon {
                                name: "refresh"
                                size: 20
                                color: Theme.error
                            }
                            onClicked: {
                                TimerStopwatchService.timerRunning = false;
                                TimerStopwatchService.timerSetupMode = true;
                            }
                        }
                    }
                }

                // Setup Mode UI (Duration Picker)
                ColumnLayout {
                    anchors.fill: parent
                    visible: TimerStopwatchService.timerSetupMode
                    spacing: 12

                    // Header
                    Text {
                        text: "Set Timer Duration"
                        font.family: "Inter"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        color: Qt.rgba(255, 255, 255, 0.7)
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 8
                    }

                    // Time inputs row (MD3 styled cards)
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 12
                        Layout.fillHeight: true

                        // Minutes Card
                        Rectangle {
                            implicitWidth: 72
                            implicitHeight: 88
                            radius: 16
                            color: Qt.rgba(255, 255, 255, 0.03)
                            border.color: minInput.activeFocus ? Theme.primary : Qt.rgba(255, 255, 255, 0.08)
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.topMargin: 4
                                anchors.bottomMargin: 4
                                spacing: 0

                                QQC.Button {
                                    id: minUp
                                    Layout.alignment: Qt.AlignHCenter
                                    implicitWidth: 40; implicitHeight: 20
                                    background: Rectangle { color: minUp.hovered ? Qt.rgba(255, 255, 255, 0.06) : "transparent"; radius: 10 }
                                    contentItem: DankIcon {
                                        name: "arrow_drop_up"
                                        size: 16
                                        color: "white"
                                    }
                                    onClicked: TimerStopwatchService.setupMins = Math.min(99, TimerStopwatchService.setupMins + 5)
                                }

                                TextInput {
                                    id: minInput
                                    text: String(TimerStopwatchService.setupMins).padStart(2, '0')
                                    font.family: "Inter"
                                    font.pixelSize: 22
                                    font.weight: Font.Bold
                                    color: "white"
                                    selectByMouse: true
                                    horizontalAlignment: TextInput.AlignHCenter
                                    Layout.alignment: Qt.AlignHCenter
                                    validator: IntValidator { bottom: 0; top: 99 }
                                    inputMethodHints: Qt.ImhDigitsOnly
                                    width: 32

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

                                QQC.Button {
                                    id: minDown
                                    Layout.alignment: Qt.AlignHCenter
                                    implicitWidth: 40; implicitHeight: 20
                                    background: Rectangle { color: minDown.hovered ? Qt.rgba(255, 255, 255, 0.06) : "transparent"; radius: 10 }
                                    contentItem: DankIcon {
                                        name: "arrow_drop_down"
                                        size: 16
                                        color: "white"
                                    }
                                    onClicked: TimerStopwatchService.setupMins = Math.max(0, TimerStopwatchService.setupMins - 5)
                                }

                                Text { text: "MINUTES"; font.family: "Inter"; font.pixelSize: 7; font.weight: Font.Bold; color: Qt.rgba(255, 255, 255, 0.4); Layout.alignment: Qt.AlignHCenter }
                            }
                        }

                        Text {
                            text: ":"
                            font.family: "Inter"
                            font.pixelSize: 24
                            font.weight: Font.Bold
                            color: Theme.primary
                            Layout.alignment: Qt.AlignVCenter
                        }

                        // Seconds Card
                        Rectangle {
                            implicitWidth: 72
                            implicitHeight: 88
                            radius: 16
                            color: Qt.rgba(255, 255, 255, 0.03)
                            border.color: secInput.activeFocus ? Theme.primary : Qt.rgba(255, 255, 255, 0.08)
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.topMargin: 4
                                anchors.bottomMargin: 4
                                spacing: 0

                                QQC.Button {
                                    id: secUp
                                    Layout.alignment: Qt.AlignHCenter
                                    implicitWidth: 40; implicitHeight: 20
                                    background: Rectangle { color: secUp.hovered ? Qt.rgba(255, 255, 255, 0.06) : "transparent"; radius: 10 }
                                    contentItem: DankIcon {
                                        name: "arrow_drop_up"
                                        size: 16
                                        color: "white"
                                    }
                                    onClicked: TimerStopwatchService.setupSecs = (TimerStopwatchService.setupSecs + 5) % 60
                                }

                                TextInput {
                                    id: secInput
                                    text: String(TimerStopwatchService.setupSecs).padStart(2, '0')
                                    font.family: "Inter"
                                    font.pixelSize: 22
                                    font.weight: Font.Bold
                                    color: "white"
                                    selectByMouse: true
                                    horizontalAlignment: TextInput.AlignHCenter
                                    Layout.alignment: Qt.AlignHCenter
                                    validator: IntValidator { bottom: 0; top: 59 }
                                    inputMethodHints: Qt.ImhDigitsOnly
                                    width: 32

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

                                QQC.Button {
                                    id: secDown
                                    Layout.alignment: Qt.AlignHCenter
                                    implicitWidth: 40; implicitHeight: 20
                                    background: Rectangle { color: secDown.hovered ? Qt.rgba(255, 255, 255, 0.06) : "transparent"; radius: 10 }
                                    contentItem: DankIcon {
                                        name: "arrow_drop_down"
                                        size: 16
                                        color: "white"
                                    }
                                    onClicked: TimerStopwatchService.setupSecs = (TimerStopwatchService.setupSecs - 5 + 60) % 60
                                }

                                Text { text: "SECONDS"; font.family: "Inter"; font.pixelSize: 7; font.weight: Font.Bold; color: Qt.rgba(255, 255, 255, 0.4); Layout.alignment: Qt.AlignHCenter }
                            }
                        }
                    }

                    // Preset Quick Action Buttons (MD3 Chips)
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 8

                        Repeater {
                            model: [1, 3, 5, 10]
                            QQC.Button {
                                id: presetBtn
                                implicitWidth: 44
                                implicitHeight: 22
                                background: Rectangle {
                                    color: presetBtn.hovered ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : Qt.rgba(255, 255, 255, 0.04)
                                    border.color: presetBtn.hovered ? Theme.primary : Qt.rgba(255, 255, 255, 0.1)
                                    border.width: 1
                                    radius: 11
                                }
                                contentItem: Text {
                                    text: modelData + "m"
                                    color: "white"
                                    font.family: "Inter"
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: {
                                    TimerStopwatchService.setupMins = modelData;
                                    TimerStopwatchService.setupSecs = 0;
                                }
                            }
                        }
                    }

                    // Start Action Button (MD3 Elevated Pill)
                    QQC.Button {
                        id: startTimerBtn
                        Layout.alignment: Qt.AlignHCenter
                        Layout.bottomMargin: 10
                        implicitWidth: 100
                        implicitHeight: 32

                        background: Rectangle {
                            color: (TimerStopwatchService.setupMins > 0 || TimerStopwatchService.setupSecs > 0) ? Theme.primary : Qt.rgba(255, 255, 255, 0.03)
                            radius: 16
                        }

                        contentItem: RowLayout {
                            spacing: 4
                            Layout.alignment: Qt.AlignHCenter
                            DankIcon {
                                name: "play_arrow"
                                size: 14
                                color: (TimerStopwatchService.setupMins > 0 || TimerStopwatchService.setupSecs > 0) ? Theme.onPrimary : Qt.rgba(255, 255, 255, 0.2)
                            }
                            Text {
                                text: "Start"
                                font.family: "Inter"
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                color: (TimerStopwatchService.setupMins > 0 || TimerStopwatchService.setupSecs > 0) ? Theme.onPrimary : Qt.rgba(255, 255, 255, 0.2)
                            }
                        }

                        enabled: (TimerStopwatchService.setupMins > 0 || TimerStopwatchService.setupSecs > 0)
                        onClicked: {
                            TimerStopwatchService.timerTotal = (TimerStopwatchService.setupMins * 60) + TimerStopwatchService.setupSecs;
                            TimerStopwatchService.timerSeconds = TimerStopwatchService.timerTotal;
                            TimerStopwatchService.timerSetupMode = false;
                            TimerStopwatchService.timerRunning = true;
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
                spacing: 12

                // Stopwatch time display (huge)
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 12
                    text: TimerStopwatchService.formatStopwatch(TimerStopwatchService.stopwatchTime)
                    font.family: Theme.font.monospace
                    font.pixelSize: 32
                    font.weight: Font.Bold
                    color: "white"
                }

                // Control Action Row (Play/Pause, Lap, Reset)
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12

                    // Play / Pause Toggle
                    QQC.Button {
                        id: swPlayBtn
                        implicitWidth: 44
                        implicitHeight: 36
                        background: Rectangle {
                            color: swPlayBtn.hovered ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : Qt.rgba(255, 255, 255, 0.05)
                            radius: 8
                        }
                        contentItem: DankIcon {
                            name: TimerStopwatchService.swRunning ? "pause" : "play_arrow"
                            size: 18
                            color: Theme.primary
                        }
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

                    // Lap Button
                    QQC.Button {
                        id: swLapBtn
                        implicitWidth: 44
                        implicitHeight: 36
                        enabled: TimerStopwatchService.swRunning
                        background: Rectangle {
                            color: swLapBtn.enabled ? (swLapBtn.hovered ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(255, 255, 255, 0.03)) : "transparent"
                            radius: 8
                        }
                        contentItem: DankIcon {
                            name: "outlined_flag" // Flags/Laps representation
                            size: 18
                            color: swLapBtn.enabled ? "#ffffff" : Qt.rgba(255, 255, 255, 0.2)
                        }
                        onClicked: {
                            let formatted = TimerStopwatchService.formatStopwatch(TimerStopwatchService.stopwatchTime);
                            TimerStopwatchService.swLaps.insert(0, { "lapNum": TimerStopwatchService.swLaps.count + 1, "lapTime": formatted });
                        }
                    }

                    // Reset Button
                    QQC.Button {
                        id: swResetBtn
                        implicitWidth: 44
                        implicitHeight: 36
                        background: Rectangle {
                            color: swResetBtn.hovered ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.15) : Qt.rgba(255, 255, 255, 0.05)
                            radius: 8
                        }
                        contentItem: DankIcon {
                            name: "refresh"
                            size: 18
                            color: Theme.error
                        }
                        onClicked: {
                            TimerStopwatchService.swRunning = false;
                            TimerStopwatchService.stopwatchTime = 0;
                            TimerStopwatchService.swBaseTime = 0;
                            TimerStopwatchService.swLaps.clear();
                        }
                    }
                }

                // Scrollable Laps Container
                ListView {
                    id: lapsList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.bottomMargin: 4
                    spacing: 4
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: TimerStopwatchService.swLaps

                    QQC.ScrollBar.vertical: QQC.ScrollBar {
                        policy: QQC.ScrollBar.AsNeeded
                    }

                    delegate: Rectangle {
                        width: lapsList.width
                        height: 26
                        radius: 4
                        color: Qt.rgba(255, 255, 255, 0.02)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12

                            Text {
                                text: "Lap " + model.lapNum
                                font.family: "Inter"
                                font.pixelSize: 11
                                color: Qt.rgba(255, 255, 255, 0.5)
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: model.lapTime
                                font.family: Theme.font.monospace
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: "white"
                            }
                        }
                    }

                    // Empty state fallback when no laps recorded
                    Text {
                        anchors.centerIn: parent
                        visible: TimerStopwatchService.swLaps.count === 0
                        text: "No laps recorded"
                        font.family: "Inter"
                        font.pixelSize: 11
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
                spacing: 12

                // Alarm Creator Section (MD3 Card style)
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 76
                    radius: 16
                    color: Qt.rgba(255, 255, 255, 0.04)
                    border.color: Qt.rgba(255, 255, 255, 0.08)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        // Time Input Container (Pill Shaped card)
                        Rectangle {
                            implicitWidth: 104
                            implicitHeight: 48
                            radius: 24
                            color: Qt.rgba(255, 255, 255, 0.06)
                            border.color: (alarmHourInput.activeFocus || alarmMinInput.activeFocus) ? Theme.primary : Qt.rgba(255, 255, 255, 0.1)
                            border.width: 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 4

                                // Hour Input
                                TextInput {
                                    id: alarmHourInput
                                    text: String(root.alarmAddHour).padStart(2, '0')
                                    font.family: "Inter"
                                    font.pixelSize: 18
                                    font.weight: Font.Bold
                                    color: "white"
                                    selectByMouse: true
                                    horizontalAlignment: TextInput.AlignHCenter
                                    validator: IntValidator { bottom: 1; top: 12 }
                                    inputMethodHints: Qt.ImhDigitsOnly
                                    width: 24

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
                                    font.family: "Inter"
                                    font.pixelSize: 18
                                    font.weight: Font.Bold 
                                }

                                // Minute Input
                                TextInput {
                                    id: alarmMinInput
                                    text: String(root.alarmAddMin).padStart(2, '0')
                                    font.family: "Inter"
                                    font.pixelSize: 18
                                    font.weight: Font.Bold
                                    color: "white"
                                    selectByMouse: true
                                    horizontalAlignment: TextInput.AlignHCenter
                                    validator: IntValidator { bottom: 0; top: 59 }
                                    inputMethodHints: Qt.ImhDigitsOnly
                                    width: 24

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

                            // AM/PM Toggle Button (MD3 Filter Chip)
                            QQC.Button {
                                id: amPmBtn
                                implicitWidth: 42
                                implicitHeight: 22
                                background: Rectangle {
                                    color: root.alarmAddIsPM ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : Qt.rgba(255, 255, 255, 0.05)
                                    border.color: root.alarmAddIsPM ? Theme.primary : Qt.rgba(255, 255, 255, 0.15)
                                    border.width: 1
                                    radius: 11
                                }
                                contentItem: Text {
                                    text: root.alarmAddIsPM ? "PM" : "AM"
                                    color: root.alarmAddIsPM ? Theme.primary : "white"
                                    font.family: "Inter"
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: root.alarmAddIsPM = !root.alarmAddIsPM
                            }

                            // Repeat Toggle Button (MD3 Filter Chip)
                            QQC.Button {
                                id: repeatBtn
                                implicitWidth: 42
                                implicitHeight: 22
                                background: Rectangle {
                                    color: root.alarmAddRepeatMode === "daily" ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : Qt.rgba(255, 255, 255, 0.05)
                                    border.color: root.alarmAddRepeatMode === "daily" ? Theme.primary : Qt.rgba(255, 255, 255, 0.15)
                                    border.width: 1
                                    radius: 11
                                }
                                contentItem: Text {
                                    text: root.alarmAddRepeatMode === "daily" ? "Daily" : "Once"
                                    color: root.alarmAddRepeatMode === "daily" ? Theme.primary : "white"
                                    font.family: "Inter"
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: root.alarmAddRepeatMode = (root.alarmAddRepeatMode === "once" ? "daily" : "once")
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
                                    font.family: "Inter"
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
                                QQC.Button {
                                    id: cancelEditBtn
                                    visible: root.editingAlarmIndex !== -1
                                    implicitWidth: 22
                                    implicitHeight: 22
                                    background: Rectangle {
                                        color: Qt.rgba(255, 255, 255, 0.05)
                                        border.color: Qt.rgba(255, 255, 255, 0.15)
                                        border.width: 1
                                        radius: 11
                                    }
                                    contentItem: DankIcon {
                                        name: "close"
                                        size: 11
                                        color: "white"
                                    }
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

                                // Add / Save Button (MD3 Filled Icon Button)
                                QQC.Button {
                                    id: addAlarmBtn
                                    implicitWidth: 44
                                    implicitHeight: 22
                                    background: Rectangle {
                                        color: Theme.primary
                                        radius: 11
                                    }
                                    contentItem: DankIcon {
                                        name: root.editingAlarmIndex === -1 ? "add" : "check"
                                        size: 13
                                        color: Theme.onPrimary
                                    }
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

                // Alarms List View
                ListView {
                    id: alarmsList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: TimerStopwatchService.alarms

                    QQC.ScrollBar.vertical: QQC.ScrollBar {
                        policy: QQC.ScrollBar.AsNeeded
                    }

                    delegate: Rectangle {
                        id: alarmRow
                        width: alarmsList.width
                        height: 54
                        radius: 16
                        color: alarmHover.hovered ? Qt.rgba(255, 255, 255, 0.05) : Qt.rgba(255, 255, 255, 0.02)
                        border.color: Qt.rgba(255, 255, 255, 0.05)
                        border.width: 1

                        HoverHandler {
                            id: alarmHover
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 12

                            // Alarm Time & Tag Column (MD3-like spacing)
                            ColumnLayout {
                                spacing: 2
                                Layout.alignment: Qt.AlignVCenter

                                RowLayout {
                                    spacing: 4
                                    Text {
                                        text: String(model.hour).padStart(2, '0') + ":" + String(model.minute).padStart(2, '0')
                                        font.family: "Inter"
                                        font.pixelSize: 18
                                        font.weight: Font.Bold
                                        color: model.enabled ? "white" : Qt.rgba(255, 255, 255, 0.35)
                                    }
                                    Text {
                                        text: model.isPM ? "PM" : "AM"
                                        font.family: "Inter"
                                        font.pixelSize: 10
                                        font.weight: Font.Medium
                                        color: model.enabled ? Theme.primary : Qt.rgba(255, 255, 255, 0.25)
                                        Layout.alignment: Qt.AlignBottom
                                        Layout.bottomMargin: 2
                                    }
                                }

                                RowLayout {
                                    spacing: 6
                                    Text {
                                        text: model.label
                                        font.family: "Inter"
                                        font.pixelSize: 10
                                        color: model.enabled ? Qt.rgba(255, 255, 255, 0.6) : Qt.rgba(255, 255, 255, 0.3)
                                        elide: Text.ElideRight
                                        Layout.maximumWidth: 100
                                    }
                                    // Repeat Pill Indicator
                                    Rectangle {
                                        implicitWidth: 36
                                        implicitHeight: 14
                                        radius: 7
                                        color: model.enabled ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Qt.rgba(255, 255, 255, 0.05)
                                        border.color: model.enabled ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.25) : "transparent"
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: (model.repeatMode === "daily" ? "Daily" : "Once")
                                            font.family: "Inter"
                                            font.pixelSize: 8
                                            font.weight: Font.Bold
                                            color: model.enabled ? Theme.primary : Qt.rgba(255, 255, 255, 0.25)
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Action buttons & Switch layout
                            RowLayout {
                                spacing: 8
                                Layout.alignment: Qt.AlignVCenter

                                // Edit Alarm Button
                                QQC.Button {
                                    id: alarmEditBtn
                                    visible: alarmHover.hovered
                                    implicitWidth: 28
                                    implicitHeight: 28

                                    background: Rectangle {
                                        color: alarmEditBtn.hovered ? Qt.rgba(255, 255, 255, 0.08) : "transparent"
                                        radius: 14
                                    }

                                    contentItem: DankIcon {
                                        name: "edit"
                                        size: 14
                                        color: Qt.rgba(255, 255, 255, 0.7)
                                    }

                                    onClicked: {
                                        root.alarmAddHour = model.hour;
                                        root.alarmAddMin = model.minute;
                                        root.alarmAddIsPM = model.isPM;
                                        labelInput.text = model.label;
                                        root.alarmAddRepeatMode = model.repeatMode || "once";
                                        root.editingAlarmIndex = index;
                                    }
                                }

                                // Delete Alarm Button
                                QQC.Button {
                                    id: alarmDelBtn
                                    visible: alarmHover.hovered
                                    implicitWidth: 28
                                    implicitHeight: 28

                                    background: Rectangle {
                                        color: alarmDelBtn.hovered ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.15) : "transparent"
                                        radius: 14
                                    }

                                    contentItem: DankIcon {
                                        name: "delete"
                                        size: 14
                                        color: Theme.error
                                    }

                                    onClicked: {
                                        TimerStopwatchService.alarms.remove(index);
                                        TimerStopwatchService.saveAlarms();
                                    }
                                }

                                // MD3 Style Switch (Enable/Disable toggle)
                                Rectangle {
                                    width: 34
                                    height: 20
                                    radius: 10
                                    color: model.enabled ? Theme.primary : Qt.rgba(255, 255, 255, 0.15)
                                    border.color: model.enabled ? "transparent" : Qt.rgba(255, 255, 255, 0.25)
                                    border.width: model.enabled ? 0 : 1.5

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
