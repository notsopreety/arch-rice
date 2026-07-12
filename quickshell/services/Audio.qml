pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    property bool ready: sink !== null && sink.audio !== null
    property bool muted: ready ? sink.audio.muted : false
    property real volume: ready ? sink.audio.volume : 0.0
    readonly property int percentage: Math.round(volume * 100)

    property bool sourceReady: source !== null && source.audio !== null
    property bool sourceMuted: sourceReady ? source.audio.muted : false
    property real sourceVolume: sourceReady ? source.audio.volume : 0.0
    readonly property int sourcePercentage: Math.round(sourceVolume * 100)

    PwObjectTracker {
        objects: {
            var objs = [];
            if (root.sink) objs.push(root.sink);
            if (root.source) objs.push(root.source);
            return objs;
        }
    }

    function setVolume(newVolume) {
        if (ready) {
            sink.audio.volume = Math.max(0, Math.min(1.0, newVolume));
        }
    }

    function increaseVolume() {
        setVolume(volume + 0.05);
    }

    function decreaseVolume() {
        setVolume(volume - 0.05);
    }

    function setMute(m) {
        if (ready) {
            sink.audio.muted = m;
        }
    }

    function toggleMute() {
        if (ready) {
            sink.audio.muted = !sink.audio.muted;
        }
    }

    function setSourceVolume(newVolume) {
        if (sourceReady) {
            source.audio.volume = Math.max(0, Math.min(1.5, newVolume));
        }
    }

    function setSourceMute(m) {
        if (sourceReady) {
            source.audio.muted = m;
        }
    }

    function toggleSourceMute() {
        if (sourceReady) {
            source.audio.muted = !source.audio.muted;
        }
    }
}
