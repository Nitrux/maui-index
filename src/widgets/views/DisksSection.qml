// Copyright 2018-2020 Camilo Higuita <milo.h@aol.com>
// Copyright 2018-2020 Slike Latinoamericana S.C.
//
// SPDX-License-Identifier: GPL-3.0-or-later


import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls as Maui
import org.maui.index as Index
import "home"

SectionGroup
{
    id: control
    property bool expanded: false

    title: i18n("Storage")
    description: i18n("Mounted drives with their used and free space")

    browser.itemSize: Math.min(browser.width * 0.45, 320)
    browser.itemHeight: 170
    browser.implicitHeight: expanded ? 360 : 170

    template.template.content: Button
    {
        text: control.expanded ? i18n("Collapse") : i18n("Expand")
        onClicked: control.expanded = !control.expanded
    }

    baseModel.list: Index.StorageModel {}

    browser.delegate: Item
    {
        width: GridView.view.cellWidth
        height: GridView.view.cellHeight
        readonly property bool currentItem: false

        Rectangle
        {
            anchors.fill: parent
            anchors.margins: Maui.Style.space.medium
            radius: Maui.Style.radiusV
            color: currentItem || _mouseArea.containsPress
                ? Maui.Theme.highlightColor
                : (_mouseArea.containsMouse ? Maui.Theme.hoverColor : "transparent")

            ColumnLayout
            {
                anchors.fill: parent
                anchors.margins: Maui.Style.space.medium
                spacing: Maui.Style.space.small

                RowLayout
                {
                    Layout.fillWidth: true
                    spacing: Maui.Style.space.medium

                    Maui.IconItem
                    {
                        iconSource: model.icon
                        iconSizeHint: Maui.Style.iconSizes.big
                        highlighted: currentItem
                    }

                    ColumnLayout
                    {
                        Layout.fillWidth: true
                        spacing: 0

                        Label
                        {
                            Layout.fillWidth: true
                            text: model.label
                            font.bold: true
                            elide: Text.ElideRight
                            color: currentItem ? Maui.Theme.highlightedTextColor : Maui.Theme.textColor
                        }

                        Label
                        {
                            Layout.fillWidth: true
                            text: model.details
                            elide: Text.ElideMiddle
                            opacity: 0.75
                            color: currentItem ? Maui.Theme.highlightedTextColor : Maui.Theme.textColor
                        }

                        Label
                        {
                            Layout.fillWidth: true
                            text: model.type
                            opacity: 0.65
                            color: currentItem ? Maui.Theme.highlightedTextColor : Maui.Theme.textColor
                        }
                    }
                }

                ProgressBar
                {
                    id: _usageBar
                    Layout.fillWidth: true
                    from: 0
                    to: 1
                    value: Number(model.value)
                    background: Rectangle
                    {
                        implicitHeight: 10
                        radius: height / 2
                        color: Qt.rgba(Maui.Theme.textColor.r, Maui.Theme.textColor.g, Maui.Theme.textColor.b, 0.18)
                    }
                    contentItem: Item
                    {
                        implicitHeight: 10

                        Rectangle
                        {
                            width: _usageBar.visualPosition * parent.width
                            height: parent.height
                            radius: height / 2
                            color: Maui.Theme.highlightColor
                        }
                    }
                }

                Label
                {
                    Layout.fillWidth: true
                    text: model.summary
                    wrapMode: Text.Wrap
                    color: currentItem ? Maui.Theme.highlightedTextColor : Maui.Theme.textColor
                }

                Label
                {
                    Layout.fillWidth: true
                    text: model.message
                    opacity: 0.75
                    color: currentItem ? Maui.Theme.highlightedTextColor : Maui.Theme.textColor
                }
            }
        }

        MouseArea
        {
            id: _mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            onClicked:
            {
                control.currentIndex = -1
                currentBrowser.openFolder(model.path)
            }
        }

        ToolTip.visible: _mouseArea.containsMouse
        ToolTip.delay: 1000
        ToolTip.text: model.label + "\n" + model.details + "\n" + model.summary
    }
}
