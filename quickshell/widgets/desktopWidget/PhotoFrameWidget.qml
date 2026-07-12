import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.folderlistmodel
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import "../../theme"
import "../../components"
import "../../core"
import QtQuick.Shapes

Item {
    id: root
    
    // Default size for the widget
    width: 200 * Appearance.effectiveScale
    height: 200 * Appearance.effectiveScale
    
    property string imagePath: "/home/sawmer/Pictures/Images/"
    property int settingsX: -1
    property int settingsY: -1
    property string settingsShape: "cookie_4"
    property bool isActive: true
    
    property string currentImage: ""
    property var imageList: []
    property bool useImageA: true
    
    onCurrentImageChanged: {
        if (currentImage === "") return;
        if (imageA.source.toString() === "") {
            imageA.source = currentImage;
            return;
        }
        if (useImageA) {
            imageB.source = currentImage;
            fadeAnim.target = imageB;
            fadeAnim2.target = imageA;
            crossFade.start();
            useImageA = false;
        } else {
            imageA.source = currentImage;
            fadeAnim.target = imageA;
            fadeAnim2.target = imageB;
            crossFade.start();
            useImageA = true;
        }
    }
    
    ParallelAnimation {
        id: crossFade
        NumberAnimation {
            id: fadeAnim
            property: "opacity"
            to: 1.0
            duration: 600
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            id: fadeAnim2
            property: "opacity"
            to: 0.0
            duration: 600
            easing.type: Easing.InOutQuad
        }
    }
    
    property var stylesList: [
        { shape: "cookie_4", width: 200, height: 200 },
        { shape: "puffy", width: 200, height: 200 },
        { shape: "circle", width: 200, height: 200 },
        { shape: "square", width: 200, height: 200 },
        { shape: "pill", width: 280, height: 140 },
        { shape: "square_rect", width: 280, height: 140 }
    ]

    function cycleNextStyle() {
        let currentIndex = 0;
        for (let i = 0; i < stylesList.length; i++) {
            if (stylesList[i].shape === root.settingsShape) {
                currentIndex = i;
                break;
            }
        }
        
        let nextIndex = (currentIndex + 1) % stylesList.length;
        let nextStyle = stylesList[nextIndex];
        
        root.width = nextStyle.width * Appearance.effectiveScale;
        root.height = nextStyle.height * Appearance.effectiveScale;
        root.settingsShape = nextStyle.shape;
        root.saveSettings(root.x, root.y, nextStyle.shape);
    }
    
    // Align default position to bottom-right
    x: settingsX >= 0 ? settingsX : (parent ? parent.width - width - 40 * Appearance.effectiveScale : 0)
    y: settingsY >= 0 ? settingsY : (parent ? parent.height - height - 40 * Appearance.effectiveScale : 0)
    visible: isActive
    
    function loadSettings(jsonText) {
        if (!jsonText || jsonText.trim() === "") {
            console.log("[PhotoFrame] Empty settings file loaded, skipping parse.");
            return;
        }
        try {
            let data = JSON.parse(jsonText);
            let pf = data.photoFrame || {};
            if (pf.isActive !== undefined) root.isActive = pf.isActive;
            if (pf.imagePath) root.imagePath = pf.imagePath;
            if (pf.photoFrameX !== undefined) root.settingsX = pf.photoFrameX;
            if (pf.photoFrameY !== undefined) root.settingsY = pf.photoFrameY;
            if (pf.photoFrameShape !== undefined) {
                root.settingsShape = pf.photoFrameShape;
                // Apply dimensions based on loaded shape
                let found = false;
                for (let i = 0; i < root.stylesList.length; i++) {
                    if (root.stylesList[i].shape === pf.photoFrameShape) {
                        root.width = root.stylesList[i].width * Appearance.effectiveScale;
                        root.height = root.stylesList[i].height * Appearance.effectiveScale;
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    root.width = 200 * Appearance.effectiveScale;
                    root.height = 200 * Appearance.effectiveScale;
                }
            }
            console.log("[PhotoFrame] Successfully loaded settings. isActive:", root.isActive);
        } catch(e) {
            console.error("Failed to parse settings.json for PhotoFrame:", e);
        }
    }
    
    Timer {
        id: reloadTimer
        interval: 150
        running: false
        repeat: false
        onTriggered: settingsFile.reload()
    }
    
    FileView {
        id: settingsFile
        path: Quickshell.env("HOME") + "/.config/quickshell/settings.json"
        watchChanges: true
        preload: true
        
        onLoaded: root.loadSettings(text())
        onFileChanged: reloadTimer.restart()
    }
    
    Process {
        id: saveSettingsProc
    }
    
    function saveSettings(newX, newY, newShape) {
        let path = Quickshell.env("HOME") + "/.config/quickshell/settings.json";
        let cmd = "import json, os; path = '" + path + "'; " +
                  "data = json.load(open(path)) if os.path.exists(path) else {}; " +
                  "pf = data.setdefault('photoFrame', {}); ";
        let updates = [];
        if (newX !== undefined) updates.push("pf['photoFrameX'] = " + Math.round(newX));
        if (newY !== undefined) updates.push("pf['photoFrameY'] = " + Math.round(newY));
        if (newShape !== undefined) updates.push("pf['photoFrameShape'] = '" + newShape + "'");
        cmd += updates.join("; ") + "; " +
               "tmp = path + '.tmp'; " +
               "f = open(tmp, 'w'); " +
               "json.dump(data, f, indent=2); " +
               "f.close(); " +
               "os.replace(tmp, path)";
        
        saveSettingsProc.command = ["python3", "-c", cmd];
        saveSettingsProc.running = true;
    }
    
    readonly property string folderUrl: {
        if (!imagePath) return "";
        let path = imagePath;
        if (path.startsWith("file://")) return path;
        if (path.startsWith("/")) return "file://" + path;
        return "file:///" + path;
    }
    
    FolderListModel {
        id: folderModel
        folder: root.folderUrl
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.gif"]
        showDirs: false
        onCountChanged: updateImageList()
        onStatusChanged: {
            console.log("PhotoFrame FolderListModel status changed:", status, "count:", count);
            if (status === FolderListModel.Ready || count > 0) {
                updateImageList();
            }
        }
    }
    
    function updateImageList() {
        let list = [];
        for (let i = 0; i < folderModel.count; i++) {
            let url = folderModel.get(i, "fileUrl");
            if (!url) {
                let path = folderModel.get(i, "filePath");
                if (path) {
                    url = "file://" + path;
                }
            }
            if (url) {
                list.push(url.toString());
            }
        }
        console.log("PhotoFrame updateImageList: folder =", root.folderUrl, "count =", folderModel.count, "list =", list.length);
        imageList = list;
        if (currentImage === "" && list.length > 0) {
            selectRandomImage();
        }
    }
    
    function selectRandomImage() {
        if (imageList.length === 0) {
            console.log("PhotoFrame selectRandomImage: no images available");
            return;
        }
        let index = Math.floor(Math.random() * imageList.length);
        currentImage = imageList[index];
        console.log("PhotoFrame selected image:", currentImage);
    }
    
    Timer {
        id: rotateTimer
        interval: 5 * 60 * 1000 // 5 minutes
        running: true
        repeat: true
        onTriggered: selectRandomImage()
    }
    
    // Drag-to-scale animation matching Clock behavior
    scale: dragArea.pressed ? 0.98 : (dragArea.containsMouse ? 1.02 : 1.0)
    Behavior on scale {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutQuad
        }
    }
    
    // Helper to generate radial wavy paths
    function generateRadialPath(cx, cy, r_max, freq, minScale, maxScale, phaseOffset) {
        let path = "";
        let steps = 120;
        let r_avg = r_max * (minScale + maxScale) / 2;
        let r_amp = r_max * (maxScale - minScale) / 2;

        for (let i = 0; i < steps; i++) {
            let theta = (i / steps) * 2 * Math.PI;
            let r = r_avg + r_amp * Math.cos(freq * (theta + phaseOffset));
            let x = cx + r * Math.cos(theta);
            let y = cy + r * Math.sin(theta);
            if (i === 0) path += "M " + x + " " + y;
            else path += " L " + x + " " + y;
        }
        path += " Z";
        return path;
    }

    // Component for shape rendering
    component PhotoFrameShape: Item {
        id: shapeRoot
        property string shapeName: "circle"
        property color fillColor: "white"
        property color strokeColor: "transparent"
        property real strokeWidth: 0
        
        Shape {
            id: localShape
            anchors.fill: parent
            layer.enabled: true
            layer.samples: 8
            layer.smooth: true
            
            ShapePath {
                fillColor: shapeRoot.fillColor
                strokeColor: shapeRoot.strokeColor
                strokeWidth: shapeRoot.strokeWidth
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin
                
                PathSvg {
                    path: {
                        let w = shapeRoot.width;
                        let h = shapeRoot.height;
                        if (w <= 0 || h <= 0) return "";
                        let cx = w / 2;
                        let cy = h / 2;
                        let r_max = Math.min(w, h) / 2;
                        
                        let name = shapeRoot.shapeName;
                        if (name === "cookie_4") {
                            return root.generateRadialPath(cx, cy, r_max, 4, 0.8, 0.98, Math.PI / 4);
                        } else if (name === "puffy") {
                            return root.generateRadialPath(cx, cy, r_max, 10, 0.78, 0.98, 0);
                        } else if (name === "circle") {
                            return "M " + cx + " " + (cy - r_max) + 
                                   " A " + r_max + " " + r_max + " 0 1 0 " + cx + " " + (cy + r_max) + 
                                   " A " + r_max + " " + r_max + " 0 1 0 " + cx + " " + (cy - r_max) + " Z";
                        } else if (name === "square") {
                            let r = 24 * Appearance.effectiveScale; // Rounded square corners
                            return "M " + (cx - r_max + r) + " " + (cy - r_max) +
                                   " h " + (r_max * 2 - r * 2) +
                                   " a " + r + " " + r + " 0 0 1 " + r + " " + r +
                                   " v " + (r_max * 2 - r * 2) +
                                   " a " + r + " " + r + " 0 0 1 -" + r + " " + r +
                                   " h -" + (r_max * 2 - r * 2) +
                                   " a " + r + " " + r + " 0 0 1 -" + r + " -" + r +
                                   " v -" + (r_max * 2 - r * 2) +
                                   " a " + r + " " + r + " 0 0 1 " + r + " -" + r + " Z";
                        } else if (name === "pill") {
                            let pr = h / 2;
                            return "M " + (cx - w/2 + pr) + " " + (cy - h/2) +
                                   " h " + (w - pr * 2) +
                                   " a " + pr + " " + pr + " 0 0 1 0 " + h +
                                   " h -" + (w - pr * 2) +
                                   " a " + pr + " " + pr + " 0 0 1 0 -" + h + " Z";
                        } else if (name === "square_rect") {
                            let r = 24 * Appearance.effectiveScale; // Rounded rectangle corners
                            return "M " + (cx - w/2 + r) + " " + (cy - h/2) +
                                   " h " + (w - r * 2) +
                                   " a " + r + " " + r + " 0 0 1 " + r + " " + r +
                                   " v " + (h - r * 2) +
                                   " a " + r + " " + r + " 0 0 1 -" + r + " " + r +
                                   " h -" + (w - r * 2) +
                                   " a " + r + " " + r + " 0 0 1 -" + r + " -" + r +
                                   " v -" + (h - r * 2) +
                                   " a " + r + " " + r + " 0 0 1 " + r + " -" + r + " Z";
                        }
                        return "";
                    }
                }
            }
        }
    }
    
    // Masked Image Container
    Item {
        id: imageWrapper
        anchors.fill: parent
        
        Item {
            id: fadingContainer
            anchors.fill: parent
            visible: false
            
            Image {
                id: imageA
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                opacity: 1.0
                asynchronous: true
            }
            
            Image {
                id: imageB
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                opacity: 0.0
                asynchronous: true
            }
        }
        
        PhotoFrameShape {
            id: maskShape
            anchors.fill: parent
            shapeName: root.settingsShape
            fillColor: "white"
            visible: true
        }
        
        ShaderEffectSource {
            id: maskShaderSource
            anchors.fill: parent
            sourceItem: maskShape
            hideSource: true
        }
        
        OpacityMask {
            anchors.fill: parent
            source: fadingContainer
            maskSource: maskShaderSource
        }
    }
    
    // Border overlay
    PhotoFrameShape {
        anchors.fill: parent
        shapeName: root.settingsShape
        fillColor: "transparent"
        strokeColor: Theme.primary
        strokeWidth: 2 * Appearance.effectiveScale
    }
    
    // Interactive mouse area for dragging and right click popup
    MouseArea {
        id: dragArea
        anchors.fill: parent
        drag.target: root
        drag.axis: Drag.XAndYAxis
        hoverEnabled: true
        cursorShape: containsMouse ? Qt.SizeAllCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        
        onReleased: {
            if (drag.active) {
                root.saveSettings(root.x, root.y, root.settingsShape);
            }
        }
        
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                root.cycleNextStyle();
            } else if (mouse.button === Qt.MiddleButton) {
                root.selectRandomImage();
            }
        }
    }
    
    // Touch area to capture 3-finger touchscreen gestures
    MultiPointTouchArea {
        anchors.fill: parent
        mouseEnabled: false
        
        onPressed: (touchPoints) => {
            if (touchPoints.length === 3) {
                root.selectRandomImage();
            }
        }
    }
}
