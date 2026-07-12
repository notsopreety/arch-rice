pragma Singleton

import QtQuick 6.10
import Quickshell
import Quickshell.Io
import "." as QsServices

// Screenshot/Screen Recording Service
Singleton {
    id: root
    
    property bool isRecording: false
    property double recordingStartedAt: 0
    property string lastScreenshotPath: ""
    property string lastRecordingPath: ""
    property string screenshotsDir: "/home/sawmer/Pictures/Screenshots"

    property string _slurpGeometry: ""
    property string _ocrGeometry: ""
    property string _windowGeomText: ""
    
    Component.onCompleted: {
        // Create screenshots directory if it doesn't exist
        mkdirProc.running = true
    }
    
    Process {
        id: mkdirProc
        command: ["mkdir", "-p", root.screenshotsDir]
    }
    
    function runOcrCopy() {
        ocrSlurpProc.exec(["slurp"])
    }
    
    
    function takeScreenshot(mode: string) {
        // mode: "screen", "window", "region"
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19)
        const filename = `screenshot-${timestamp}.png`
        const filepath = `${screenshotsDir}/${filename}`
        
        if (mode === "region") {
            // For region selection, use slurp to get geometry then grim to capture
            slurpProc.exec(["slurp"])
        } else if (mode === "screen") {
            // Capture entire screen
            screenshotProc.exec(["grim", filepath])
            root.lastScreenshotPath = filepath
        } else if (mode === "window") {
            // For active window, we need to use hyprctl to get window geometry
            // then use slurp with those coordinates
            windowGeomProc.exec(["sh", "-c", "hyprctl activewindow -j | jq -r '.at[0],.at[1],.size[0],.size[1]' | paste -sd ' '"])
        }
    }
    
    // Get region geometry with slurp
    Process {
        id: slurpProc
        stdout: StdioCollector {
            onStreamFinished: root._slurpGeometry = text.trim()
        }
        onExited: code => {
            const geometry = root._slurpGeometry
            root._slurpGeometry = ""
            if (code === 0 && geometry !== "") {
                const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19)
                const filename = `screenshot-${timestamp}.png`
                const filepath = `${root.screenshotsDir}/${filename}`

                QsServices.Logger.debug("Screenshot", `Capturing region: ${geometry}`)
                screenshotProc.exec(["grim", "-g", geometry, filepath])
                root.lastScreenshotPath = filepath
            } else if (code !== 0) {
                QsServices.Logger.error("Screenshot", `slurp failed with code: ${code}`)
            }
        }
    }

    // Get region geometry for OCR with slurp
    Process {
        id: ocrSlurpProc
        stdout: StdioCollector {
            onStreamFinished: root._ocrGeometry = text.trim()
        }
        onExited: code => {
            const geometry = root._ocrGeometry
            root._ocrGeometry = ""
            if (code === 0 && geometry !== "") {
                QsServices.Logger.debug("Screenshot", `OCR capturing region: ${geometry}`)
                ocrProc.exec(["sh", "-c", `grim -g "${geometry}" - | tesseract - stdout 2>/dev/null | wl-copy`])
            } else if (code !== 0) {
                QsServices.Logger.error("Screenshot", `OCR slurp failed with code: ${code}`)
            }
        }
    }

    Process {
        id: ocrProc
        onExited: code => {
            if (code === 0) {
                QsServices.Logger.info("Screenshot", "OCR completed and text copied to clipboard")
                notifyProc.exec([
                    "notify-send",
                    "-r", "1002",
                    "-a", "Screenshot OCR",
                    "-i", "edit-paste",
                    "OCR Completed",
                    "Text extracted and copied to clipboard"
                ])
            } else {
                QsServices.Logger.error("Screenshot", `OCR process failed with code: ${code}`)
                notifyProc.exec([
                    "notify-send",
                    "-r", "1002",
                    "-a", "Screenshot OCR",
                    "OCR Failed",
                    "Could not extract text from region"
                ])
            }
        }
    }
    
    // Get active window geometry
    // ... (unchanged code block for windowGeomProc)
    Process {
        id: windowGeomProc
        stdout: StdioCollector {
            onStreamFinished: root._windowGeomText = text.trim()
        }
        onExited: code => {
            const out = root._windowGeomText
            root._windowGeomText = ""
            if (code === 0 && out !== "") {
                const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19)
                const filename = `screenshot-${timestamp}.png`
                const filepath = `${root.screenshotsDir}/${filename}`
                const parts = out.split(' ')
                if (parts.length === 4) {
                    const geometry = `${parts[0]},${parts[1]} ${parts[2]}x${parts[3]}`
                    QsServices.Logger.debug("Screenshot", `Capturing window: ${geometry}`)
                    screenshotProc.exec(["grim", "-g", geometry, filepath])
                    root.lastScreenshotPath = filepath
                }
            } else if (code !== 0) {
                QsServices.Logger.error("Screenshot", `window geometry failed with code: ${code}`)
            }
        }
    }
    
    Process {
        id: screenshotProc
        onExited: code => {
            if (code === 0) {
                QsServices.Logger.info("Screenshot", `Saved: ${root.lastScreenshotPath}`)
                
                // Copy to clipboard using wl-copy with shell redirection
                clipboardProc.exec(["sh", "-c", `wl-copy < "${root.lastScreenshotPath}"`])
                
                notifyProc.exec([
                    "notify-send",
                    "-r", "1003",
                    "-a", "Screenshot",
                    "-i", root.lastScreenshotPath,
                    "Screenshot captured",
                    `Saved and copied to clipboard`
                ])
            } else {
                QsServices.Logger.error("Screenshot", `Failed with code: ${code}`)
            }
        }
    }
    
    Process {
        id: clipboardProc
    }
    
    Process {
        id: notifyProc
    }
    
    function startRecording() {
        if (isRecording) return
        
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19)
        const filename = `recording-${timestamp}.mp4`
        const filepath = `${screenshotsDir}/${filename}`
        root.lastRecordingPath = filepath
        
        recordProc.exec([
            "sh", "-c",
            `wf-recorder -f "${filepath}" -c h264_vaapi -d /dev/dri/renderD128 --audio="$(pactl get-default-sink).monitor"`
        ])
        
        root.isRecording = true
        root.recordingStartedAt = new Date().getTime()
        QsServices.Logger.info("Screenshot", "Recording started")
    }
    
    Process {
        id: recordProc
        onExited: code => {
            root.isRecording = false
            root.recordingStartedAt = 0
            if (code === 0) {
                QsServices.Logger.info("Screenshot", `Recording saved: ${root.lastRecordingPath}`)
                notifyProc.exec([
                    "notify-send",
                    "-r", "1004",
                    "-a", "Screen Recorder",
                    "Screen recording saved",
                    root.lastRecordingPath
                ])
            }
        }
    }
    
    function stopRecording() {
        if (!isRecording) return
        
        stopRecordProc.running = true
        // isRecording will be set to false when the recording process finishes
    }
    
    Process {
        id: stopRecordProc
        command: ["pkill", "-SIGINT", "wf-recorder"]
    }
    
    function openScreenshotsFolder() {
        openProc.exec(["xdg-open", screenshotsDir])
    }
    
    Process {
        id: openProc
    }
    
    function copyLastScreenshot() {
        if (!lastScreenshotPath) return

        copyProc.exec(["sh", "-c", `wl-copy < "${lastScreenshotPath}"`])
    }
    
    Process {
        id: copyProc
    }
    
    function deleteLastScreenshot() {
        if (!lastScreenshotPath) return
        
        deleteProc.exec(["rm", lastScreenshotPath])
    }
    
    Process {
        id: deleteProc
        onExited: code => {
            if (code === 0) {
                QsServices.Logger.info("Screenshot", `Deleted: ${root.lastScreenshotPath}`)
                root.lastScreenshotPath = ""
            }
        }
    }
}
