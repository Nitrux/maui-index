// Copyright 2018-2020 Camilo Higuita <milo.h@aol.com>
// Copyright 2018-2020 Nitrux Latinoamericana S.C.
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls

import org.mauikit.controls as Maui
import org.mauikit.filebrowsing as FB

FB.PlacesSideBar
{
    id: control

    asynchronous: true
    active: (enabled && visible) || item
    groups: appSettings.normalizeSidebarSections(appSettings.sidebarSections)
    quickPlaces: inx.quickPaths()
    quickPlacesEnabled: appSettings.quickSidebarSection
    showStoragePartitions: appSettings.showStoragePartitions
    mountRemovableOnClick: true
    currentPath: _stackView.depth === 1 && currentBrowser ? currentBrowser.currentPath : ""
    currentQuickPath: _stackView.depth === 2 ? "overview:///" : ""

    OpacityAnimator on opacity
    {
        from: 0
        to: 1
        duration: Maui.Style.units.longDuration
        running: control.status === Loader.Ready
    }

    onPlaceClicked: (path, mouse) =>
    {
        if (path === "overview:///")
        {
            _stackView.push(_homeViewComponent)
            if (_sideBarView.sideBar.collapsed)
                _sideBarView.sideBar.close()
            return
        }

        openPlace(path, mouse)
    }

    onContextMenuRequested: (path, type, index) =>
    {
        if (path === "overview:///")
            return

        menu.path = path
        menu.placeType = type
        menu.bookmarkIndex = index
        menu.show()
    }

    onOperationError: (message) =>
    {
        const text = String(message).trim().length ? message : i18n("The storage operation failed.")
        notify("dialog-error", i18n("Storage"), text)
    }

    onDeviceUnmounting: (label) => notify("media-eject", label, i18n("Unmounting device..."))
    onDevicePathUnavailable: (fallbackPath) => currentBrowser.openFolder(fallbackPath.length > 0 ? fallbackPath : FB.FM.homePath())

    Maui.ContextualMenu
    {
        id: menu

        property string path
        property string placeType
        property int bookmarkIndex: -1
        property bool hasBookmarkEntry: bookmarkIndex >= 0
        property bool isDeviceEntry: hasBookmarkEntry && control.list.isDevice(bookmarkIndex)
        property bool showRemoveAction: hasBookmarkEntry && !isDeviceEntry
        readonly property var menuActionList:
        {
            const actions = [actionsObject.openInNewTabAction, actionsObject.openInNewWindowAction, actionsObject.openInSplitViewAction]
            if (menu.showRemoveAction)
                actions.push(actionsObject.removeAction)
            return actions
        }

        onClosed:
        {
            menu.bookmarkIndex = -1
            menu.path = ""
            menu.placeType = ""
        }

        QtObject
        {
            id: actionsObject

            property Action openInNewTabAction: Action
            {
                text: i18n("Open in New Tab")
                icon.name: "tab-new"
                onTriggered: control.openMenuPlace(path => openTab(path))
            }

            property Action openInNewWindowAction: Action
            {
                text: i18n("Open in New Window")
                icon.name: "window-new"
                onTriggered: inx.openNewWindow(menu.path)
            }

            property Action openInSplitViewAction: Action
            {
                enabled: root.currentTab.count === 1
                text: i18n("Open in Split View")
                icon.name: "view-split-left-right"
                onTriggered: currentTab.split(menu.path, Qt.Horizontal)
            }

            property Action removeAction: Action
            {
                text: i18n("Remove")
                icon.name: "edit-delete"
                Maui.Controls.status: Maui.Controls.Negative
                onTriggered: control.list.removePlace(menu.bookmarkIndex)
            }
        }

        Repeater
        {
            model: menu.menuActionList
            delegate: MenuItem
            {
                action: modelData
            }
        }
    }

    function openMenuPlace(callback)
    {
        const index = menu.bookmarkIndex
        if (index >= 0 && control.list.isDevice(index) && control.list.setupNeeded(index))
        {
            control.requestDeviceSetup(index, control.list.get(index).udi, Qt.NoModifier, callback)
            return
        }

        callback(menu.path)
    }

    function openPlace(path, mouse)
    {
        if (mouse.modifiers & Qt.ControlModifier)
        {
            openTab(path)
        } else if (mouse.modifiers & Qt.AltModifier)
        {
            currentTab.split(path)
        } else
        {
            currentBrowser.openFolder(path)
        }

        if (_sideBarView.sideBar.collapsed)
            _sideBarView.sideBar.close()

        if (_stackView.depth === 2)
            _stackView.pop()
    }
}
