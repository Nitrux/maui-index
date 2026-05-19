// Copyright 2018-2020 Camilo Higuita <milo.h@aol.com>
// Copyright 2018-2020 Nitrux Latinoamericana S.C.
//
// SPDX-License-Identifier: GPL-3.0-or-later


import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

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
    readonly property bool supportsTerminal : true
    readonly property int terminalPanelHeight: _terminalSplitView.visible ? _terminalSplitView.height : 0

    property alias currentPath: _browser.currentPath
    property alias terminalVisible : _dirConf.terminalVisible

    Maui.Controls.title : currentPath
    Keys.enabled: true
    Keys.forwardTo: _browser

    background: null

    onCurrentPathChanged:
    {
        if(currentBrowser)
        {
            syncTerminal(currentBrowser.currentPath)
        }
    }

    FileMenu
    {
        id: itemMenu
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
        modal: true
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
            enabled: !Maui.Handy.isMobile
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

        FB.FileBrowser
        {
            id: _browser

            SplitView.fillWidth: true
            SplitView.fillHeight: true
            Maui.Theme.colorSet: Maui.Theme.View
            background: null
            footBar.visible: false

            property alias viewType : _dirConf.viewType
            property alias sortBy : _dirConf.sortKey

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
            settings.viewType: _dirConf.viewType

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
                                toogleTerminal()
                                event.accepted = true
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
                                if(_browser.currentIndex > -1 && _browser.currentView.count > 0)
                                {
                                    openPreview(_browser.currentFMModel.get(_browser.currentIndex).path)
                                }
                                event.accepted = true
                                return
                            }
                        }

            onItemClicked: (index) =>
                           {
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
        //set these values in here to avoid global binding them, so each view can have different sorting settings
        settings.foldersFirst = sortSettings.foldersFirst
        settings.group = sortSettings.group

        terminalLoader.setSource("Terminal.qml", ({'session.initialWorkingDirectory': control.currentPath.replace("file://", "")}))
        control.forceActiveFocus()
    }

    function syncTerminal(path)
    {
        if(terminalLoader.item && appSettings.syncTerminal && FB.FM.fileExists(path))
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
        terminalVisible = !terminalVisible

        if(terminalVisible)
        {
            terminalLoader.item.forceActiveFocus()
        }else
        {
            control.forceActiveFocus()
        }
    }

    function forceActiveFocus()
    {
        browser.forceActiveFocus()
    }
}
