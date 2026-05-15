// Copyright 2018-2020 Camilo Higuita <milo.h@aol.com>
// Copyright 2018-2020 Nitrux Latinoamericana S.C.
//
// SPDX-License-Identifier: GPL-3.0-or-later


import QtQuick
import QtQml

import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls as Maui
import org.mauikit.filebrowsing as FB

Loader
{
    id: control
    asynchronous: true
    active: (control.enabled && control.visible) || item
    Keys.enabled: false
    focus: false
    readonly property var list: item && item.list ? item.list : null

    function placeIcon(path, iconName, label, type, isDeviceEntry)
    {
        const value = String(path)
        const text = String(label)
        const sectionType = String(type)

        if (isDeviceEntry && isDeviceSection(sectionType))
            return sectionType === i18n("Removable") ? "drive-removable-media" : "drive-harddisk"

        if (value === "/" || value === "file:///")
            return "folder-red"

        if ((value.startsWith("/") || value.startsWith("file:///")) && text.startsWith("/"))
            return "folder"

        return iconName
    }

    function sidebarIcon(path, iconName, label, type, isDeviceEntry)
    {
        const resolved = placeIcon(path, iconName, label, type, isDeviceEntry)
        return resolved === "folder-red" ? resolved : resolved + "-symbolic"
    }

    function usesSymbolicIcon(path, iconName, label, type, isDeviceEntry)
    {
        return placeIcon(path, iconName, label, type, isDeviceEntry) !== "folder-red"
    }

    function isDeviceSection(type)
    {
        const value = String(type)
        return value === i18n("Drives") || value === i18n("Removable")
    }

    function shouldShowPlace(index, type, path, label)
    {
        if (!isDeviceSection(type))
            return true

        if (!control.list || !control.list.isDevice(index))
            return false

        const url = String(path)
        const text = String(label)

        if (url === "/" || url === "file:///")
            return false

        if (text.startsWith("/"))
            return false

        return true
    }

    OpacityAnimator on opacity
    {
        from: 0
        to: 1
        duration: Maui.Style.units.longDuration
        running: control.status === Loader.Ready
    }

    sourceComponent: Pane
    {
        id: _sideBarPane
        readonly property alias list: _listBrowser.list
        padding: 0
        focus: false
        clip: true
        Maui.Theme.colorSet: Maui.Theme.Window

        function syncCurrentPlaceSelection(preserveContentY = true)
        {
            if (!currentBrowser)
                return

            const targetIndex = placesList.indexOfPath(currentBrowser.currentPath)
            const previousContentY = _listBrowser.flickable.contentY

            _listBrowser.currentIndex = targetIndex

            if (preserveContentY)
                _listBrowser.flickable.contentY = previousContentY
        }

        background: Rectangle
        {
            color: Maui.Theme.alternateBackgroundColor
            radius: settings.floatyUI ? Maui.Style.radiusV : 0
            border.color: settings.floatyUI ? Maui.Theme.backgroundColor : "transparent"
        }

        contentItem: Maui.ListBrowser
        {
            id: _listBrowser
            verticalScrollBarPolicy: ScrollBar.AlwaysOff
            focus: false
            focusPolicy: Qt.NoFocus
            Keys.enabled: false

            readonly property alias list : placesList

            holder.visible: count === 0
            holder.title: i18n("Bookmarks")
            holder.body: i18n("Your bookmarks will be listed here")

            Connections
            {
                target: root
                function onCurrentBrowserChanged()
                {
                    Qt.callLater(() => _sideBarPane.syncCurrentPlaceSelection(true))
                }
            }

            Connections
            {
                target: currentBrowser ? currentBrowser : null
                function onCurrentPathChanged()
                {
                    Qt.callLater(() => _sideBarPane.syncCurrentPlaceSelection(true))
                }
            }

            Loader
            {
                id: _menuLoader

                asynchronous: true
                sourceComponent: Maui.ContextualMenu
                {
                    id: _menu

                    property string path
                    property int bookmarkIndex : -1

                    onClosed: _menu.bookmarkIndex = -1

                    MenuItem
                    {
                        text: i18n("Open in New Tab")
                        icon.name: "tab-new"
                        onTriggered: openTab(_menu.path)
                    }

                    MenuItem
                    {
                        text: i18n("Open in New Window")
                        icon.name: "window-new"
                        onTriggered: inx.openNewWindow(_menu.path)
                    }

                    MenuItem
                    {
                        enabled: root.currentTab.count === 1
                        text: i18n("Open in Split View")
                        icon.name: "view-split-left-right"
                        onTriggered: currentTab.split(_menu.path, Qt.Horizontal)
                    }

                    MenuSeparator{}

                    MenuItem
                    {
                        enabled: _menu.bookmarkIndex >= 0
                        text: i18n("Remove")
                        icon.name: "edit-delete"
                        Maui.Controls.status: Maui.Controls.Negative
                        onTriggered: placesList.removePlace(_menu.bookmarkIndex)
                    }
                }
            }

            // flickable.topMargin: Maui.Style.contentMargins
            // flickable.bottomMargin: Maui.Style.contentMargins
            flickable.header: Loader
            {
                id: _quickSectionLoader
                asynchronous: true
                width: parent.width
                height: implicitHeight + _listBrowser.spacing*2
                active: appSettings.quickSidebarSection

                OpacityAnimator on opacity
                {
                    from: 0
                    to: 1
                    duration: Maui.Style.units.longDuration
                    running: _quickSectionLoader.status === Loader.Ready
                }

                sourceComponent: GridLayout
                {
                    id: _quickSection

                    rows: 3
                    columns: 3

                    columnSpacing: Maui.Style.defaultSpacing
                    rowSpacing: Maui.Style.defaultSpacing

                    Repeater
                    {
                        model: inx.quickPaths()

                        delegate: Maui.GridBrowserDelegate
                        {
                            Maui.Theme.colorSet: Maui.Theme.Button
                            Maui.Theme.inherit: false
                            readonly property string resolvedIcon: control.sidebarIcon(modelData.path, modelData.icon, modelData.label, modelData.type, false)

                            Layout.preferredHeight: Math.min(50, width)
                            Layout.preferredWidth: 50
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.columnSpan: modelData.path === "overview:///" ? 2 : 1

                            isCurrentItem: modelData.path === "overview:///" ? _stackView.depth === 2 : (currentBrowser.currentPath === modelData.path && _stackView.depth === 1)
                            iconSource: resolvedIcon
                            iconSizeHint: 16
                            template.isMask: control.usesSymbolicIcon(modelData.path, modelData.icon, modelData.label, modelData.type, false)
                            label1.text: modelData.label
                            labelsVisible: false
                            tooltipText: modelData.label
                            flat: false

                            onClicked: (mouse) =>
                                       {
                                           if(modelData.path === "overview:///")
                                           {
                                               _stackView.push(_homeViewComponent)
                                               if(control.collapsed)
                                               control.close()
                                               return
                                           }

                                           openPlace(modelData.path, mouse)

                                       }

                            onRightClicked:
                            {
                                _menuLoader.item.path = modelData.path
                                _menuLoader.item.show()
                            }

                            onPressAndHold:
                            {
                                _menuLoader.item.path = modelData.path
                                _menuLoader.item.show()
                            }
                        }
                    }
                }
            }

            model: Maui.BaseModel
            {
                id: placesModel
                list: FB.PlacesList
                {
                    id: placesList
                    groups: appSettings.sidebarSections
                }
            }

            Component.onCompleted:
            {
                _listBrowser.flickable.highlightFollowsCurrentItem = false
                Qt.callLater(() =>
                {
                    _listBrowser.flickable.positionViewAtBeginning()
                    _sideBarPane.syncCurrentPlaceSelection(true)
                })
            }

            delegate: Maui.ListDelegate
            {
                readonly property bool shownPlace: control.shouldShowPlace(index, model.type, model.path, model.label)
                isCurrentItem: ListView.isCurrentItem && _stackView.depth === 1
                width: ListView.view.width
                height: shownPlace ? implicitHeight : 0
                visible: shownPlace
                enabled: shownPlace

                iconSize: Maui.Style.iconSize
                label: model.label
                iconName: control.sidebarIcon(model.path, model.icon, model.label, model.type, placesList.isDevice(index))
                iconVisible: true
                template.isMask: control.usesSymbolicIcon(model.path, model.icon, model.label, model.type, placesList.isDevice(index)) && iconSize <= Maui.Style.iconSizes.medium

                template.content: ToolButton
                {
                    visible: placesList.isDevice(index) && placesList.setupNeeded(index)
                    icon.name: "media-mount"
                    flat: true
                    icon.height: Maui.Style.iconSizes.small
                    icon.width: Maui.Style.iconSizes.small
                    onClicked: placesList.requestSetup(index)
                }

                onClicked: (mouse) =>
                           {
                               if( placesList.isDevice(index) && placesList.setupNeeded(index))
                               {
                                   placesList.requestSetup(index)
                                   notify(model.icon, model.label, i18n("Mounting device..."))
                                   return
                               }

                               openPlace(model.path, mouse)
                           }

                onRightClicked:
                {
                    _menuLoader.item.path = model.path
                    _menuLoader.item.bookmarkIndex = index
                    _menuLoader.item.show()
                }

                onPressAndHold:
                {
                    _menuLoader.item.path = model.path
                    _menuLoader.item.bookmarkIndex = index
                    _menuLoader.item.show()
                }
            }

            section.property: "type"
            section.criteria: ViewSection.FullString
            section.delegate: Maui.LabelDelegate
            {
                width: ListView.view.width
                text: section
                isSection: true
                //                height: Maui.Style.toolBarHeightAlt
            }
        }
    }

    function openPlace(path, mouse)
    {

        if(mouse.modifiers & Qt.ControlModifier)
        {
            openTab(path)
        }else if(mouse.modifiers & Qt.AltModifier)
        {
            currentTab.split(path)
        }
        else
        {
            currentBrowser.openFolder(path)
        }

        if(_sideBarView.sideBar.collapsed)
            _sideBarView.sideBar.close()

        if(_stackView.depth === 2)
            _stackView.pop()

        if(control.collapsed)
            control.close()

    }
}
