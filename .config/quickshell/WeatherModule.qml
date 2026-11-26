import QtQuick
import Quickshell
import Quickshell.Io
import "Ui.js" as Ui

/*
 * Port of modules/weather/weather.go: curl https://en.wttr.in/<city>?0qnT,
 * parse lines 3-4, render the Go module's table tooltip. Interval matches
 * waybar's 1800s.
 */
Pill {
    id: root

    property string city: "Gdansk"
    property int refreshMs: 1800000
    property string parsedText: ""
    property string parsedTooltip: ""

    label: root.parsedText
    tooltip: root.parsedTooltip
    keepVisible: false

    Process {
        id: weatherProcess
        command: ["curl", "-sS", "--max-time", "10", "-A", "curl/8.0",
            "https://en.wttr.in/" + root.city + "?0qnT"]

        stdout: StdioCollector {
            id: collector
            onStreamFinished: root.parse(collector.text)
        }
    }

    Timer {
        interval: root.refreshMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: weatherProcess.running = true
    }

    function parse(body) {
        var result = Ui.parseWeather(body);
        if (!result) {
            root.parsedText = "⚠ weather";
            root.parsedTooltip = "Could not parse the wttr.in response.";
            root.stateClass = "error";
            return;
        }
        root.parsedText = result.text;
        root.parsedTooltip = result.tooltip;
        root.stateClass = "";
    }

    onClicked: Quickshell.execDetached(["ghostty", "-e", "sh", "-c",
        "curl v2.wttr.in/" + root.city + "; echo Done - press Enter to exit; read"])
}
