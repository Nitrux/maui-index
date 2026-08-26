import QtQuick
import QtQuick.Controls

import org.mauikit.controls as Maui

Item
{
    Maui.Icon
    {
        anchors.centerIn: parent
        source: iteminfo.icon
        height: Math.min(128, Math.min(parent.width, parent.height))
        width: height
    }
}
