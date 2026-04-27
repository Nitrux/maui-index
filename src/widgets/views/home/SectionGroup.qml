// Copyright 2018-2020 Camilo Higuita <milo.h@aol.com>
// Copyright 2018-2020 Slike Latinoamericana S.C.
//
// SPDX-License-Identifier: GPL-3.0-or-later


import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls as Maui

Maui.SectionGroup
{
    id: control

    Maui.Theme.colorSet: Maui.Theme.Window
    Maui.Theme.inherit: false

    property alias browser: _gridView
    property alias baseModel: _baseModel
    property alias currentIndex : _gridView.currentIndex
    property var verticalScrollTarget: null

    padding: Maui.Style.space.medium

    function scrollOverview(delta)
    {
        if (!verticalScrollTarget)
            return

        const maxContentY = Math.max(0, verticalScrollTarget.contentHeight - verticalScrollTarget.height)
        verticalScrollTarget.contentY = Math.max(0, Math.min(maxContentY, verticalScrollTarget.contentY - delta))
    }

    background: Rectangle
    {
        color: Maui.Theme.backgroundColor
        radius: Maui.Style.radiusV
    }

    Maui.GridBrowser
    {
        id: _gridView
        clip: true

        verticalScrollBarPolicy: ScrollBar.AlwaysOff
        horizontalScrollBarPolicy:  ScrollBar.AsNeeded
        currentIndex: -1

        Layout.fillWidth: true
        Layout.preferredHeight: implicitHeight + topPadding + bottomPadding
        Layout.fillHeight: true

        // flickable.flow: GridView.FlowTopToBottom
        Maui.Controls.orientation: Qt.Horizontal

        itemSize: 220
        itemHeight: 70
        adaptContent: false

        holder.visible: count === 0
        holder.title: i18n("Nothing in here yet.")
        holder.body: i18n("Check back later.")

        model: Maui.BaseModel
        {
            id: _baseModel
        }

        MouseArea
        {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            propagateComposedEvents: true
            scrollGestureEnabled: false
            z: 100

            onWheel: (wheel) =>
            {
                if (Math.abs(wheel.angleDelta.y) >= Math.abs(wheel.angleDelta.x))
                {
                    control.scrollOverview(wheel.angleDelta.y)
                    wheel.accepted = true
                }
                else
                {
                    wheel.accepted = false
                }
            }
        }
    }
}
