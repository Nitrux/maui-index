// Copyright 2018-2020 Camilo Higuita <milo.h@aol.com>
// Copyright 2018-2020 Slike Latinoamericana S.C.
//
// SPDX-License-Identifier: GPL-3.0-or-later


import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls as Maui

import org.mauikit.filebrowsing as FB
import "home"

SectionGroup
{
    id: control
    title: i18n("Devices and Remote")
    description: i18n("Remote locations and devices like disks, phones and cameras")

    function placeIcon(path, iconName, label)
    {
        const value = String(path)
        const text = String(label)

        if (value === "/" || value === "file:///")
            return "folder-red"

        if ((value.startsWith("/") || value.startsWith("file:///")) && text.startsWith("/"))
            return "folder"

        return iconName
    }

    function placeLabel(label)
    {
        const text = String(label)

        if (text.startsWith("/") && text.length > 15)
            return text.slice(0, 15) + "..."

        return text
    }

    browser.itemSize: Math.min(browser.width * 0.3, 180)
    browser.itemHeight: 220
    browser.implicitHeight: 220

    baseModel.list: FB.PlacesList
    {
        groups: [FB.FMList.DRIVES_PATH, FB.FMList.REMOTE_PATH]
    }

    browser.delegate: Item
    {
        width: GridView.view.cellWidth
        height: GridView.view.cellHeight
        readonly property bool currentItem: GridView.isCurrentItem

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

                Item
                {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 96

                    Maui.IconItem
                    {
                        anchors.centerIn: parent
                        iconSource: control.placeIcon(model.path, model.icon, model.label)
                        iconSizeHint: Maui.Style.iconSizes.huge
                        highlighted: currentItem
                    }
                }

                Label
                {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(implicitHeight, Maui.Style.iconSizes.big + Maui.Style.space.small)
                    Layout.maximumHeight: 84
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignTop
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                    text: control.placeLabel(model.label)
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
                control.currentIndex = index
                currentBrowser.openFolder(model.path)
            }
        }

        ToolTip.visible: _mouseArea.containsMouse
        ToolTip.delay: 1000
        ToolTip.text: model.label
    }
}
