pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property string filePath: ""
    property string fileContent: ""
    property bool isModified: false
    property string lastSavedContent: ""

    signal fileOpened()
    signal fileSaved()
    signal errorOccurred(string message)

    function newFile() {
        filePath = "";
        fileContent = "";
        lastSavedContent = "";
        isModified = false;
    }

    function openFile(path) {
        if (!path) return;
        
        let cleanPath = path.toString();
        if (cleanPath.startsWith("file://")) {
            cleanPath = cleanPath.substring(7);
        }

        root.filePath = cleanPath;
        reader.path = cleanPath;
        reader.reload();
    }

    function saveFile(content) {
        if (!filePath) return;
        writer.path = filePath;
        writer.setText(content);
    }

    function saveFileAs(path, content) {
        if (!path) return;
        let cleanPath = path.toString();
        if (cleanPath.startsWith("file://")) {
            cleanPath = cleanPath.substring(7);
        }
        filePath = cleanPath;
        writer.path = cleanPath;
        writer.setText(content);
    }

    property FileView reader: FileView {
        id: reader
        preload: true
        onLoaded: {
            root.fileContent = reader.text();
            root.lastSavedContent = root.fileContent;
            root.isModified = false;
            root.fileOpened();
        }
        onLoadFailed: (err) => {
            root.errorOccurred("Failed to load: " + err);
        }
    }

    property FileView writer: FileView {
        id: writer
        preload: false
        onSaved: {
            root.fileContent = lastSavedContent; // content saved matches
            root.isModified = false;
            root.fileSaved();
        }
        onSaveFailed: (err) => {
            root.errorOccurred("Failed to save: " + err);
        }
    }
}
