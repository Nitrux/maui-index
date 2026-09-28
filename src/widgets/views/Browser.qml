// Copyright 2018-2020 Camilo Higuita <milo.h@aol.com>
// Copyright 2018-2020 Nitrux Latinoamericana S.C.
//
// SPDX-License-Identifier: GPL-3.0-or-later


import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

import org.mauikit.controls as Maui
import org.mauikit.filebrowsing as FB

import org.maui.index as Index

import "../previewer"
import ".."

Maui.SplitViewItem
{
    id: control

    readonly property alias browser : _browser
    readonly property alias settings : _browser.settings
    readonly property alias title : _browser.title
    readonly property alias emptyTrashAction : _emptyTrashAction
    readonly property bool supportsTerminal: control.currentPath.startsWith("file://")
    readonly property int terminalPanelHeight: _terminalSplitView.visible ? _terminalSplitView.height : 0

    property alias currentPath: _browser.currentPath
    property alias terminalVisible : _dirConf.terminalVisible

    Maui.Controls.title : currentPath
    Keys.enabled: true
    Keys.forwardTo: _browser

    background: null

    onCurrentPathChanged:
    {
        if (currentBrowser)
        {
            if (supportsTerminal)
            {
                syncTerminal(currentBrowser.currentPath)
            }
            else
            {
                terminalVisible = false
            }
        }
    }

    FileMenu
    {
        id: itemMenu
        onEncryptionChanged: (directory) => _fscrypt.invalidateStatus(directory)
    }

    FB.Fscrypt
    {
        id: _fscrypt
    }

    Component
    {
        id: _fscryptEmblemComponent

        Item
        {
            property var itemData
            readonly property url itemUrl: itemData && itemData.path ? itemData.path : ""
            readonly property string path: itemUrl.toString()
            readonly property bool isDirectory: itemData && (itemData.isdir === true || itemData.isdir === "true")
            property string encryptionStatus: _fscrypt.cachedStatus(itemUrl)

            implicitWidth: visible ? Maui.Style.iconSizes.small : 0
            implicitHeight: Maui.Style.iconSizes.small
            visible: isDirectory && (encryptionStatus === "encrypted_locked" || encryptionStatus === "encrypted_unlocked")

            Maui.Icon
            {
                anchors.centerIn: parent
                width: Maui.Style.iconSizes.small
                height: width
                source: encryptionStatus === "encrypted_locked" ? "emblem-locked" : "emblem-encrypted-unlocked"
                color: Maui.Theme.textColor
            }

            Component.onCompleted:
            {
                if (isDirectory && path.length > 0)
                    _fscrypt.requestStatus(itemUrl)
            }

            Connections
            {
                target: _fscrypt

                function onStatusChanged(directory, status)
                {
                    if (String(directory) === path)
                        encryptionStatus = status
                }
            }
        }
    }

    Component
    {
        id: _millerPreviewComponent
        MillerPreview
        {
        }
    }

    Maui.ContextualMenu
    {
        id: _tagMenu
        property string tag

        MenuItem
        {
            text: i18n("Edit")
            icon.name: "document-edit"
            onTriggered:
            {}
        }

        MenuItem
        {
            text: i18n("Remove")
            icon.name: "edit-delete"
            onTriggered:
            {
                var dialog = _removeTagDialogComponent.createObject(root, ({'tag' : _tagMenu.tag}))
                dialog.open()
            }
        }
    }

    Maui.ContextualMenu
    {
        id: _emptyAreaMenu
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        readonly property bool hasClipboardContent: !_browser.readOnly && _browser.currentFMList && _browser.currentFMList.clipboardHasContent

        MenuItem
        {
            id: _pasteMenuItem
            visible: _emptyAreaMenu.hasClipboardContent
            enabled: _emptyAreaMenu.hasClipboardContent
            height: visible ? implicitHeight : -_emptyAreaMenu.spacing
            text: i18n("Paste")
            icon.name: "edit-paste"
            onTriggered: _browser.paste()
        }

        MenuSeparator
        {
            visible: _emptyAreaMenu.hasClipboardContent
            height: visible ? implicitHeight : -_emptyAreaMenu.spacing
        }

        MenuItem
        {
            text: i18n("New Item")
            icon.name: "folder-new"
            onTriggered: _browser.newItem()
        }

        MenuItem
        {
            visible: supportsTerminal && !Maui.Handy.isMobile
            enabled: supportsTerminal && !Maui.Handy.isMobile
            text: i18n("Open Terminal Here")
            icon.name: "dialog-scripts"
            onTriggered: inx.openTerminal(_browser.currentPath, appSettings.terminalExecutable)
        }

        MenuItem
        {
            text: i18n("Select All")
            icon.name: "edit-select-all"
            onTriggered: _browser.selectAll()
        }
    }

    Component
    {
        id: _removeTagDialogComponent
        Maui.InfoDialog
        {
            id: _removeTagDialog
            property string tag

            title: i18n("Remove '%1'", tag)
            standardButtons: Dialog.Yes | Dialog.Cancel
            footer: DialogButtonBox
            {
                width: parent.width
                padding: Maui.Style.contentMargins
                standardButtons: _removeTagDialog.standardButtons

                delegate: Button
                {
                    focus: true
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                }
            }

            message: i18n("Are you sure you want to remove this tag? This operation can not be undone.")
            onClosed:
            {
                control.restoreBrowserFocus()
                destroy()
            }
            onAccepted:
            {
                FB.Tagging.removeTag(tag, false)
                close()
            }

            onRejected: close()
        }
    }

    Action
    {
        id: _emptyTrashAction
        text: i18n("Empty Trash")
        icon.name: "trash-empty"
        Maui.Controls.status: Maui.Controls.Negative
        enabled: _browser.currentFMList && _browser.currentFMList.count > 0
        onTriggered:
        {
            const job = FB.FM.emptyTrash()
            if(job && _browser.currentFMList)
            {
                job.finished.connect(() => _browser.currentFMList.clearContents())
            }
        }
    }

    Maui.SplitView
    {
        anchors.fill: parent
        anchors.bottomMargin: !selectionBar.hidden && (terminalVisible) ? selectionBar.height : 0
        spacing: 0
        orientation: Qt.Vertical
        background: null

        layer.enabled: GraphicsInfo.api !== GraphicsInfo.Software
                       && control.SplitView.view.count > 1
                       && control.SplitView.view.currentIndex !== control.splitIndex
        layer.effect: MultiEffect
        {
            saturation: -1
        }

        FB.FileBrowser
        {
            id: _browser
            browser.delegateInjector: _fscryptEmblemComponent

            SplitView.fillWidth: true
            SplitView.fillHeight: true
            Maui.Theme.colorSet: Maui.Theme.View
            background: null
            footBar.visible: false

            property int viewType: appSettings.globalViewType ? appSettings.viewType : _dirConf.viewType
            property alias sortBy : _dirConf.sortKey

            function setViewType(value)
            {
                if (appSettings.globalViewType)
                {
                    appSettings.viewType = value
                    return
                }

                _dirConf.viewType = value
            }

            headerContainer.margins: appSettings.floatyUI ? Maui.Style.contentMargins : 0
            headerContainer.topMargin: 0

            altHeader: _browserView.altHeader
            selectionBar: root.selectionBar
            gridItemSize: switch(appSettings.gridSize)
                          {
                          case 0: return 78;
                          case 1: return 96;
                          case 2: return 126;
                          case 3: return 166;
                          case 4: return 216;
                          default: return 126;
                          }

            listItemSize:   switch(appSettings.listSize)
                            {
                            case 0: return 32;
                            case 1: return 48;
                            case 2: return 64;
                            case 3: return 96;
                            case 4: return 120;
                            default: return 96;
                            }

            selectionMode: root.selectionMode
            onSelectionModeChanged:
            {
                root.selectionMode = selectionMode
                selectionMode = Qt.binding(function() { return root.selectionMode })
            } // rebind this property in case filebrowser breaks it

            settings.showHiddenFiles: appSettings.showHiddenFiles
            settings.showThumbnails: appSettings.showThumbnails
            settings.foldersFirst: sortSettings.foldersFirst
            settings.group: sortSettings.group

            settings.sortBy:  _dirConf.sortKey
            settings.viewType: _browser.viewType

            audioFallbackImageSource: (settings.viewType === FB.FMList.LIST_VIEW || settings.viewType === FB.FMList.MILLER_VIEW) ? "qrc:/assets/cover_32x32.svg" : "qrc:/assets/cover_64x64.svg"

            onFileRequested: (path) => openPreview(path)

            Index.FolderConfig
            {
                id:  _dirConf
                path: control.currentPath
                enabled: appSettings.dirConf
                fallbackSortKey: sortSettings.sortBy
                fallbackViewType: appSettings.viewType
            }

            browser.holder.actions: []

            Connections
            {
                target: _browser.dropArea
                ignoreUnknownSignals: true
                function onEntered()
                {
                    control.focusSplitItem()
                }
            }

            onKeyPress: (event) =>
                        {
                            if (event.key === Qt.Key_Forward)
                            {
                                _browser.goForward()
                                event.accepted = true
                                return
                            }

                            if((event.key === Qt.Key_T) && (event.modifiers & Qt.ControlModifier))
                            {
                                openTab(control.currentPath)
                                event.accepted = true
                                return
                            }

                            // Shortcut for closing tab
                            if((event.key === Qt.Key_W) && (event.modifiers & Qt.ControlModifier))
                            {
                                if(_browserView.browserList.count > 1)
                                root.closeTab(_browserView.currentTabIndex)
                                event.accepted = true
                                return
                            }

                            if((event.key === Qt.Key_K) && (event.modifiers & Qt.ControlModifier))
                            {
                                pathBar.pathBar.showEntryBar()
                                event.accepted = true
                                return
                            }

                            if(event.key === Qt.Key_F4)
                            {
                                if (supportsTerminal)
                                {
                                    toogleTerminal()
                                    event.accepted = true
                                }
                                return
                            }

                            if(event.key === Qt.Key_F3)
                            {
                                toogleSplitView()
                                event.accepted = true
                                return
                            }

                            if((event.key === Qt.Key_N) && (event.modifiers & Qt.ControlModifier))
                            {
                                newItem()
                                event.accepted = true
                                return
                            }

                            if((event.key === Qt.Key_H) && (event.modifiers & Qt.ControlModifier))
                            {
                                appSettings.showHiddenFiles = !appSettings.showHiddenFiles
                                event.accepted = true
                                return
                            }

                            if(event.key === Qt.Key_Space)
                            {
                                if(_browser.viewType !== FB.FMList.MILLER_VIEW
                                        && _browser.currentIndex > -1
                                        && _browser.currentView.count > 0)
                                {
                                    openPreview(_browser.currentFMModel.get(_browser.currentIndex).path)
                                }
                                event.accepted = true
                                return
                            }
                        }

            onItemClicked: (index) =>
                           {
                               if (_browser.viewType === FB.FMList.MILLER_VIEW)
                                   return

                               const item = currentFMModel.get(index)

                               //                handleSelectionState(item)

                               if(Maui.Handy.singleClick)
                               {
                                   if(appSettings.previewFiles && item.isdir != "true" && !root.selectionMode)
                                   {
                                       openPreview(item.path)
                                   }else
                                   {
                                       openItem(index)
                                   }
                               }
                           }

            onItemDoubleClicked: (index) =>
                                 {
                                     if (_browser.viewType === FB.FMList.MILLER_VIEW)
                                         return

                                     const item = currentFMModel.get(index)
                                     //                handleSelectionState(item)

                                     if(!Maui.Handy.singleClick)
                                     {
                                         if(appSettings.previewFiles && item.isdir != "true" && !root.selectionMode)
                                         {
                                             openPreview(item.path)
                                         }else
                                         {
                                             openItem(index)
                                         }
                                     }
                                 }

            onItemRightClicked: (index) =>
                                {
                                    const itemIndex = _browser.currentFMModel.mappedToSource(index)
                                    const item = _browser.currentFMModel.get(index)
                                    //                handleSelectionState(item)

                                    if(item.path.startsWith("tags://"))
                                    {
                                        _tagMenu.tag = item.label
                                        _tagMenu.show()
                                    }

                                    if(_browser.currentFMList.pathType !== FB.FMList.TRASH_PATH && _browser.currentFMList.pathType !== FB.FMList.REMOTE_PATH)
                                    {
                                        itemMenu.showFor(itemIndex)
                                    }
                                }

            onRightClicked:
            {
                _emptyAreaMenu.show()
            }
        }

        Maui.SplitViewItem
        {
            id: _terminalSplitView
            SplitView.fillWidth: true
            SplitView.preferredHeight: 200
            SplitView.maximumHeight: parent.height * 0.5
            SplitView.minimumHeight : 100
            autoClose: false
            visible: control.terminalVisible
            focus: false
            focusPolicy: Qt.NoFocus
            background: null
            Loader
            {
                id: terminalLoader
                Maui.Controls.title: i18n("Terminal")
                anchors.fill: parent
                visible: active
                asynchronous: true
                active: terminalVisible || item
                focus: false
                onLoaded:
                {
                    control.forceActiveFocus()
                    syncTerminal(currentBrowser.currentPath)
                }
            }

        }
    }

    Component.onCompleted:
    {
        _browser.millerPreviewComponent = _millerPreviewComponent

        //set these values in here to avoid global binding them, so each view can have different sorting settings
        settings.foldersFirst = sortSettings.foldersFirst
        settings.group = sortSettings.group

        terminalLoader.setSource("Terminal.qml", ({'session.initialWorkingDirectory': supportsTerminal ? control.currentPath.replace("file://", "") : ""}))
        control.forceActiveFocus()
    }

    function syncTerminal(path)
    {
        if (terminalLoader.item && appSettings.syncTerminal && FB.FM.fileExists(path))
            terminalLoader.item.session.changeDir(path.replace("file://", ""))
    }

    function handleSelectionState(item)
    {
        if((selectionBar.count > 0) && (!Maui.Handy.isMobile) && (!item || !selectionBar.contains(item.url)))
        {
            selectionBar.clear()
        }
    }

    function toogleTerminal()
    {
        if (!supportsTerminal)
            return

        terminalVisible = !terminalVisible

        if (terminalVisible)
        {
            terminalLoader.item.forceActiveFocus()
        }
        else
        {
            control.forceActiveFocus()
        }
    }

    function restoreBrowserFocus()
    {
        Qt.callLater(() => control.forceActiveFocus())
    }

    function forceActiveFocus()
    {
        browser.forceActiveFocus()
    }
}
