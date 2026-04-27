// Copyright 2018-2020 Camilo Higuita <milo.h@aol.com>
// Copyright 2018-2020 Slike Latinoamericana S.C.
//
// SPDX-License-Identifier: GPL-3.0-or-later


import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore

import org.mauikit.controls as Maui
import org.mauikit.filebrowsing as FB
import "home"

SectionGroup
{
    id: control
    title: i18n("Places")
    description: i18n("Quick access to common places.")

    function fileUrl(path)
    {
        const value = String(path)
        return value.startsWith("file://") ? value : "file://" + value
    }

    function appendPlace(location, fallbackLabel)
    {
        const path = StandardPaths.writableLocation(location)
        if (!path)
            return

        const url = fileUrl(path)
        if (!FB.FM.isDir(url))
            return

        const info = FB.FM.getFileInfo(url)
        placesModel.append({
            label: String(info.label || fallbackLabel),
            modified: String(info.modified || ""),
            icon: String(info.icon || "folder"),
            path: url,
            count: Number(info.count || 0)
        })
    }

    function reloadPlaces()
    {
        placesModel.clear()
        appendPlace(StandardPaths.DesktopLocation, i18n("Desktop"))
        appendPlace(StandardPaths.DocumentsLocation, i18n("Documents"))
        appendPlace(StandardPaths.DownloadLocation, i18n("Downloads"))
        appendPlace(StandardPaths.MusicLocation, i18n("Music"))
        appendPlace(StandardPaths.PicturesLocation, i18n("Pictures"))
        appendPlace(StandardPaths.MoviesLocation, i18n("Videos"))
    }

    browser.itemSize: 220
    browser.itemHeight: 70
    browser.implicitHeight: 140
    browser.model: placesModel

    ListModel
    {
        id: placesModel
    }

    template.template.content: Button
    {
        icon.name: "list-add"
        text: i18n("More")
        onClicked: openTab(StandardPaths.writableLocation(StandardPaths.HomeLocation))
    }

    browser.delegate: Item
    {
        height: GridView.view.cellHeight
        width: GridView.view.cellWidth

        Card
        {
            anchors.fill: parent
            anchors.margins: Maui.Style.space.small
            iconVisible: true
            iconSizeHint: Maui.Style.iconSizes.big
            label1.text: model.label
            label2.text: Qt.formatDateTime(new Date(model.modified), "d MMM yyyy")
            iconSource: model.icon
            checkable: selectionMode

            Maui.Badge
            {
                visible: model.count > 0
                text: model.count
            }

            onClicked: () =>
            {
                control.currentIndex = index
                _stackView.pop()
                currentBrowser.openFolder(model.path)
            }
        }
    }

    Component.onCompleted: reloadPlaces()
}
