import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import org.mauikit.controls as Maui

import org.mauikit.filebrowsing as FB


Maui.DialogWindow
{
    id: control
    readonly property alias previewer : _previewer

    title: _previewer.title
    width: 700
    readonly property real preferredHeight: Math.max(680, _previewer.implicitHeight + page.headBar.implicitHeight + page.footBar.implicitHeight + (Maui.Style.space.big * 2))
    height: Math.min(Screen.desktopAvailableHeight * 0.9, preferredHeight)

    page.showTitle: true

    FilePreviewer
    {
        id: _previewer
        anchors.fill: parent

        focus: true
        Keys.enabled: true
        Keys.onEscapePressed: (event) =>
                              {
                                  control.close()
                                  event.accepted= true
                              }
    }

    page.headBar.leftContent: [
        ToolButton
        {
            icon.name: "document-open"
            display: AbstractButton.IconOnly
            focusPolicy: Qt.NoFocus
            ToolTip.visible: hovered
            ToolTip.text: i18n("Open")
            onClicked:
            {
                FB.FM.openUrl(_previewer.currentUrl)
            }
        }
    ]

    page.headBar.rightContent: ToolButton
    {
        icon.name: "documentinfo"
        checkable: true
        checked: _previewer.showInfo
        onClicked: _previewer.toggleInfo()
    }

    function forceActiveFocus()
    {
        _previewer.forceActiveFocus()
    }
}
