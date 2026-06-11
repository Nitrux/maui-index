import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls as Maui
import org.maui.index as Index

Control
{
    id: control

    Maui.Theme.colorSet: Maui.Theme.Button
    Maui.Theme.inherit: false

    implicitWidth: _layout.implicitWidth + rightPadding + leftPadding
    implicitHeight: _layout.implicitHeight + topPadding + bottomPadding

    padding: Maui.Style.defaultPadding
    rightPadding: Maui.Style.space.big
    leftPadding: rightPadding

    property bool checked: ListView.isCurrentItem
    property int delegateIndex: 0
    property string tooltipText: ""
    readonly property bool atRightEdge: delegateIndex === ListView.view.count - 1 && (control.x + control.width) >= (ListView.view.contentX + ListView.view.rightEdgeX)

    ToolTip.delay: 1000
    ToolTip.timeout: 5000
    ToolTip.visible: _mouseArea.containsMouse || _mouseArea.containsPress
    ToolTip.text: control.tooltipText

    property alias text: _label.text

    signal rightClicked()
    signal clicked()
    signal doubleClicked()
    signal pressAndHold()

    background: Index.PathArrowBackground
    {
        id: _arrowBG
        color: control.checked ? Maui.Theme.highlightColor : (control.hovered ? Maui.Theme.hoverColor : Maui.Theme.backgroundColor)
        arrowWidth: 8
        flatLeft: control.delegateIndex === 0
        flatRight: control.atRightEdge
        leftRadius: flatLeft ? Maui.Style.radiusV : 0
        rightRadius: flatRight ? Maui.Style.radiusV : 0
    }

    contentItem: MouseArea
    {
        id: _mouseArea
        propagateComposedEvents: true
        preventStealing: false
        hoverEnabled: !Maui.Handy.isMobile
        acceptedButtons: Qt.RightButton | Qt.LeftButton
        onClicked: (mouse) =>
                   {
                       if(!Maui.Handy.isMobile && mouse.button === Qt.RightButton)
                           control.rightClicked()
                       else
                           control.clicked()
                   }

        onDoubleClicked: control.doubleClicked()
        onPressAndHold: control.pressAndHold()

        containmentMask: _arrowBG

        RowLayout
        {
            id: _layout
            anchors.fill: parent

            Label
            {
                id: _label

                Layout.fillWidth: true
                Layout.fillHeight: true

                horizontalAlignment: Qt.AlignHCenter
                verticalAlignment: Qt.AlignVCenter

                elide: Qt.ElideRight
                wrapMode: Text.NoWrap
                opacity: control.checked ? 1 : 0.6

                font.weight: control.checked ? Font.DemiBold : Font.Normal
                color: control.checked ? Maui.Theme.highlightedTextColor : Maui.Theme.textColor
            }
        }
    }
}
