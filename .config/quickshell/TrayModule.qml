import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

/* Port of waybar's tray module: icons live in the same rounded pill as the
 * other modules, 13px icons with 12px spacing and hover tooltips. */
Rectangle {
    id: root

    color: Theme.base01
    radius: Theme.pillRadius
    implicitHeight: Theme.panelHeight
    implicitWidth: icons.implicitWidth + 20
    visible: SystemTray.items.values.length > 0

    Row {
        id: icons
        anchors.centerIn: parent
        spacing: 12

        Repeater {
            model: SystemTray.items
            delegate: Item {
                id: entry
                required property var modelData

                width: 13
                height: Theme.panelHeight

                Image {
                    anchors.centerIn: parent
                    width: 13
                    height: 13
                    sourceSize.width: 13
                    sourceSize.height: 13
                    smooth: true

                    // The two-argument iconPath() asks Quickshell's icon
                    // provider to try a fallback for icons missing from the
                    // current theme instead of painting a broken texture.
                    source: {
                        var icon = modelData.icon || "";
                        if (icon.indexOf("image://") === 0 || icon.indexOf("file://") === 0 ||
                            icon.charAt(0) === "/") return icon;
                        return Quickshell.iconPath(icon, "application-x-executable");
                    }
                }

                MouseArea {
                    id: trayMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: {
                        if (mouse.button === Qt.RightButton && modelData.hasMenu) {
                            // The SNI menu is handled by the app on activation
                            // in Waybar too; fall through to activate.
                        }
                        modelData.activate();
                    }
                }

                TooltipPopup {
                    anchorItem: entry
                    tipText: modelData.tooltipTitle || modelData.title || ""
                    show: trayMouse.containsMouse
                }
            }
        }
    }
}
