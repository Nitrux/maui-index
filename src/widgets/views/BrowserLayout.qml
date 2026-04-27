// Copyright 2018-2020 Camilo Higuita <milo.h@aol.com>
// Copyright 2018-2020 Nitrux Latinoamericana S.C.
//
// SPDX-License-Identifier: GPL-3.0-or-later


import QtQuick
import QtQuick.Controls
import QtQuick.Effects

import org.mauikit.controls as Maui
import org.mauikit.filebrowsing as FB

Item
{
    id: control

    focus: true

    property url path
    property url path2

    readonly property alias orientation : _splitView.orientation
    readonly property alias currentIndex : _splitView.currentIndex
    readonly property alias count : _splitView.count

    readonly property alias currentItem : _splitView.currentItem
    readonly property alias model : _splitView.contentModel
    readonly property string title : count === 2 ?  model.get(0).browser.title + "  -  " + model.get(1).browser.title : browser.title
    readonly property var actionsBarActions: currentItem && currentItem.browser.currentFMList && currentItem.browser.currentFMList.pathType === FB.FMList.TRASH_PATH
                                             ? [_newTabAction, currentItem.emptyTrashAction, _splitViewAction, _showTerminalAction]
                                             : [_newTabAction, _viewHiddenAction, _splitViewAction, _showTerminalAction]

    readonly property FB.FileBrowser browser : currentItem.browser
    readonly property Maui.SplitView splitView : _splitView

    Maui.Controls.title: title
    Maui.Controls.toolTipText: browser.currentPath
    Maui.Controls.iconName: "folder"

    Maui.SplitView
    {
        id: _splitView
        anchors.fill: parent
        orientation: width > 600 ? Qt.Horizontal :  Qt.Vertical
        background: null
    }

    Loader
    {
        id: _actionsBarLoader
        active: settings.showActionsBar
        visible: status == Loader.Ready
        asynchronous: true

        sourceComponent: Pane
        {
            id: _pane
            Maui.Theme.colorSet: Maui.Theme.Complementary
            Maui.Theme.inherit: false

            x: control.width - width - Maui.Style.space.big
            y: control.height - height - currentItem.terminalPanelHeight - (currentItem.browser.footBar.visible ? currentItem.browser.footBar.height : 0) - Maui.Style.space.big
            background: Rectangle
            {
                radius: Maui.Style.radiusV
                color: Maui.Theme.alternateBackgroundColor
                border.color: Maui.Theme.alternateBackgroundColor
                layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software
                layer.effect: MultiEffect
                {
                    autoPaddingEnabled: true
                    shadowEnabled: true
                    shadowColor: "#000000"
                }
            }

            ScaleAnimator on scale
            {
                from: 0
                to: 1
                duration: Maui.Style.units.longDuration
                running: visible
                easing.type: Easing.OutInQuad
            }

            OpacityAnimator on opacity
            {
                from: 0
                to: 1
                duration: Maui.Style.units.longDuration
                running: visible
            }

            contentItem: Row
            {
                spacing: Maui.Style.defaultSpacing

                Item
                {
                    id: _dragHandle
                    width: Maui.Style.space.big
                    height: _actionsGrid.implicitHeight

                    Row
                    {
                        anchors.centerIn: parent
                        spacing: 3

                        Repeater
                        {
                            model: 2

                            Column
                            {
                                spacing: 3

                                Repeater
                                {
                                    model: 4

                                    Rectangle
                                    {
                                        width: 2
                                        height: width
                                        radius: width / 2
                                        color: Maui.Theme.textColor
                                        opacity: _dragHandleHandler.active ? 0.9 : 0.55
                                    }
                                }
                            }
                        }
                    }

                    DragHandler
                    {
                        id: _dragHandleHandler
                        target: _pane
                        xAxis.maximum: control.width - _pane.width
                        xAxis.minimum: 0

                        yAxis.enabled : false

                        onActiveChanged:
                        {
                            if(!active)
                            {
                                const pos = centroid.velocity.x
                                _pane.x = Qt.binding(()=> { return pos < 0 ? Maui.Style.space.big : control.width - _pane.width - Maui.Style.space.big })
                                _pane.y = Qt.binding(()=> { return control.height - _pane.height - control.currentItem.terminalPanelHeight - (control.currentItem.browser.footBar.visible ? control.currentItem.browser.footBar.height : 0) - Maui.Style.space.big })
                            }
                        }
                    }

                    HoverHandler
                    {
                        cursorShape: _dragHandleHandler.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    }
                }

                Grid
                {
                    id: _actionsGrid
                    columns: 2
                    rows: 2

                    Repeater
                    {
                        model: control.actionsBarActions

                        ToolButton
                        {
                            id: _actionButton
                            readonly property bool destructive: modelData && modelData.Maui.Controls.status === Maui.Controls.Negative
                            Maui.Theme.colorSet: Maui.Theme.Complementary
                            Maui.Controls.status: modelData && modelData.Maui.Controls.status ? modelData.Maui.Controls.status : Maui.Controls.Normal

                            action: modelData
                            display: ToolButton.IconOnly
                            flat: false
                            icon.color: destructive ? "#fafafa" : _actionButton.color

                            background: Rectangle
                            {
                                radius: Maui.Style.radiusV
                                color: _actionButton.destructive
                                    ? (_actionButton.pressed || _actionButton.down || _actionButton.checked
                                       ? Qt.darker(Maui.Theme.negativeBackgroundColor, 1.12)
                                       : (_actionButton.hovered
                                          ? Qt.lighter(Maui.Theme.negativeBackgroundColor, 1.05)
                                          : Maui.Theme.negativeBackgroundColor))
                                    : (_actionButton.pressed || _actionButton.down || _actionButton.checked
                                       ? _actionButton.Maui.Theme.highlightColor
                                       : (_actionButton.highlighted || _actionButton.hovered
                                          ? _actionButton.Maui.Theme.hoverColor
                                          : _actionButton.Maui.Theme.backgroundColor))

                                function statusBorderColor()
                                {
                                    switch(_actionButton.Maui.Controls.status)
                                    {
                                    case Maui.Controls.Positive:
                                        return _actionButton.Maui.Theme.positiveBackgroundColor
                                    case Maui.Controls.Negative:
                                        return _actionButton.Maui.Theme.negativeBackgroundColor
                                    case Maui.Controls.Neutral:
                                        return _actionButton.Maui.Theme.neutralBackgroundColor
                                    case Maui.Controls.Normal:
                                    default:
                                        return "transparent"
                                    }
                                }

                                border.color: _actionButton.destructive
                                    ? "transparent"
                                    : (_actionButton.Maui.Controls.status ? statusBorderColor() : "transparent")
                            }
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: split(control.path, Qt.Vertical)

    Component
    {
        id: _browserComponent
        Browser {}
    }

    function forceActiveFocus()
    {
        if(control.currentItem)
            control.currentItem.forceActiveFocus()
    }

    function split(path, orientation)
    {
        if(splitView.count === 2)
        {
            return
        }

        const browser = _browserComponent.createObject(splitView, {'browser.currentPath': path})
        splitView.addItem(browser)
        splitView.currentIndex = Math.max(splitView.count - 1, 0)
        browser.forceActiveFocus()

        if(path2.toString().length > 0 && splitView.count === 1)
        {
            const browser2 = _browserComponent.createObject(splitView, {'browser.currentPath': path2})
            splitView.addItem(browser2)
            splitView.currentIndex = Math.max(splitView.count - 1, 0)
            browser2.forceActiveFocus()
        }
    }

    function pop()
    {
        if(splitView.count === 1)
        {
            return //can not pop all the browsers, leave at least 1
        }
        const index = splitView.currentIndex === 1 ? 0 : 1
        splitView.closeSplit(index)
    }
}
