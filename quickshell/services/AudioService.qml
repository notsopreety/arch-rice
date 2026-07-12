pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    function getAvailableSinks() {
        return Pipewire.nodes.values.filter(node => node.audio && node.isSink && !node.isStream);
    }

    function setSink(node: PwNode): bool {
        if (!node)
            return false;
        Pipewire.preferredDefaultAudioSink = node;
        return true;
    }

    function setDefaultSinkByName(name) {
        if (!name)
            return false;
        for (const node of getAvailableSinks()) {
            if (node?.name === name)
                return setSink(node);
        }
        return false;
    }

    function sinkIcon(node) {
        if (!node)
            return "speaker";

        const props = node.properties || {};
        const formFactor = (props["device.form-factor"] || "").toLowerCase();

        switch (formFactor) {
        case "headphone":
        case "headset":
        case "hands-free":
        case "handset":
            return "headset";
        case "tv":
        case "monitor":
            return "tv";
        case "speaker":
        case "computer":
        case "hifi":
        case "portable":
        case "car":
            return "speaker";
        }

        const bus = (props["device.bus"] || "").toLowerCase();
        if (bus === "bluetooth")
            return "headset";

        const name = (node.name || "").toLowerCase();
        if (name.includes("hdmi"))
            return "tv";
        if (name.includes("iec958") || name.includes("spdif"))
            return "speaker";

        if (bus === "usb")
            return "headset";

        return "speaker";
    }

    function displayName(node) {
        if (!node) {
            return "";
        }

        if (node.properties && node.properties["node.description"]) {
            const desc = node.properties["node.description"];
            if (desc !== node.name) {
                return desc;
            }
        }

        if (node.description && node.description !== node.name) {
            return node.description;
        }

        if (node.properties && node.properties["device.description"]) {
            return node.properties["device.description"];
        }

        if (node.nickname && node.nickname !== node.name) {
            return node.nickname;
        }

        if (node.name.includes("analog-stereo")) {
            return "Built-in Audio Analog Stereo";
        }
        if (node.name.includes("bluez")) {
            return "Bluetooth Audio";
        }
        if (node.name.includes("usb")) {
            return "USB Audio";
        }
        if (node.name.includes("hdmi")) {
            return "HDMI Audio";
        }

        return node.name;
    }
}
