// Copyright 2018-2020 Camilo Higuita <milo.h@aol.com>
// Copyright 2018-2020 Nitrux Latinoamericana S.C.
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtCore

import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls as Maui

import org.mauikit.filebrowsing as FB
import org.mauikit.archiver as Arc
import org.maui.index as Index

import "widgets"
import "widgets/views"
import "widgets/previewer"

Maui.ApplicationWindow
{
    id: root
    title: currentTab ? currentTab.title : ""
    color: "transparent"
    background: null

    Maui.Handy.singleClick: Maui.Handy.hasTransientTouchInput

    property QtObject tagsDialog : null
    property var pendingNetworkServer: null
    property string initialNetworkRefreshBasePath: ""
    property bool networkAuthenticationErrorNotified: false

    Timer
    {
        id: _initialNetworkRefreshTimer
        interval: 250
        repeat: false
        onTriggered:
        {
            const list = root.currentBrowser ? root.currentBrowser.currentFMList : null
            const basePath = root.initialNetworkRefreshBasePath
            root.initialNetworkRefreshBasePath = ""
            if (!list || !basePath)
                return

            let currentPath = String(list.path)
            while (currentPath.endsWith("/"))
                currentPath = currentPath.substring(0, currentPath.length - 1)
            if (currentPath !== basePath && !currentPath.startsWith(basePath + "/"))
                return

            list.refresh()
        }
    }

    readonly property alias selectionBar : _browserView.selectionBar
    readonly property alias pathBar: _headBarMiddleLoader.item

    readonly property alias currentTab : _browserView.currentTab
    readonly property alias currentSplit : _browserView.currentSplit
    readonly property FB.FileBrowser currentBrowser : currentSplit.browser

    readonly property alias appSettings : settings

    FB.FileOperationDialog
    {
        id: _fileOperationDialog
        anchorItem: _fileOperationIndicator
        replaceConflicts: appSettings.replaceConflicts
        onClosed: root.restoreBrowserFocus()
    }

    Component
    {
        id: _networkDialogComponent

        Maui.InfoDialog
        {
            id: networkDialog
            implicitWidth: Math.min(root.width - Maui.Style.contentMargins * 2, Maui.Style.units.gridUnit * 30)
            title: editServer ? i18n("Edit server") : credentialsOnly ? i18n("Enter server credentials") : i18n("Connect to a server")
            standardButtons: Dialog.Ok | Dialog.Cancel
            Component.onCompleted:
            {
                standardButton(Dialog.Ok).text = editServer ? i18n("Save") : i18n("Connect")
                if (initialProtocol.length)
                    protocolCombo.currentIndex = ["smb", "sftp", "ftp", "dav"].indexOf(initialProtocol)
                addressField.text = initialAddress
                usernameField.text = initialUsername
                rememberPassword = initialRememberPassword
            }

            property string initialProtocol: ""
            property string initialAddress: ""
            property string initialUsername: ""
            property bool credentialsOnly: false
            property bool initialRememberPassword: false
            property int openTarget: 0
            property bool editServer: false
            property var editingServer: null
            property bool rememberPassword: false
            property string selectedProtocol: ["smb", "sftp", "ftp", "dav"][protocolCombo.currentIndex]

            function connectToServer()
            {
                let host = addressField.text.trim()
                if (!host.length)
                    return

                const schemeSeparator = host.indexOf("://")
                if (schemeSeparator >= 0)
                    host = host.substring(schemeSeparator + 3)

                const credentialsSeparator = host.lastIndexOf("@")
                if (credentialsSeparator >= 0)
                    host = host.substring(credentialsSeparator + 1)

                const server = ({protocol: networkDialog.selectedProtocol, address: host, username: usernameField.text.trim()})
                const password = passwordField.text
                if (networkDialog.editServer)
                {
                    root.updateNetworkServer(networkDialog.editingServer, server)
                    if (server.username.length > 0 && password.length > 0)
                        Index.NetworkPasswordManager.prepare(server.protocol, server.address, server.username, password)
                    if (server.username.length > 0 && networkDialog.rememberPassword && password.length > 0)
                        Index.NetworkPasswordManager.save(server.protocol, server.address, server.username, password)
                    else if (server.username.length > 0 && !networkDialog.rememberPassword)
                        Index.NetworkPasswordManager.remove(server.protocol, server.address, server.username)
                    networkDialog.close()
                    return
                }
                if (server.username.length > 0)
                    Index.NetworkPasswordManager.prepare(server.protocol, server.address, server.username, password)
                if (rememberPassword && server.username.length > 0)
                    Index.NetworkPasswordManager.save(server.protocol, server.address, server.username, password)
                if (networkDialog.openTarget === 0)
                    root.pendingNetworkServer = ({protocol: server.protocol, address: server.address, username: server.username, rememberPassword: rememberPassword, path: server.protocol + "://" + server.address})
                const url = root.networkServerUrl(server)
                root.openNetworkUrl(url, networkDialog.openTarget)
                networkDialog.close()
            }

            onAccepted: networkDialog.connectToServer()
            onRejected: networkDialog.close()
            onClosed: networkDialog.destroy()

            Maui.FlexSectionItem
            {
                label1.text: i18n("Protocol")
                label2.text: i18n("Protocol used to connect to the server.")
                label2.wrapMode: Text.Wrap

                ComboBox
                {
                    id: protocolCombo
                    Layout.fillWidth: true
                    model: [i18n("SMB"), i18n("SFTP"), i18n("FTP"), i18n("WebDAV")]
                }
            }

            Maui.FlexSectionItem
            {
                label1.text: i18n("Server address")
                label2.text: i18n("Address and optional path of the server.")
                label2.wrapMode: Text.Wrap

                Maui.TextField
                {
                    id: addressField
                    Layout.fillWidth: true
                    placeholderText: i18n("server.example.com/share")
                    inputMethodHints: Qt.ImhUrlCharactersOnly
                }
            }

            Maui.FlexSectionItem
            {
                label1.text: i18n("Username")
                label2.text: i18n("Username used to authenticate with the server.")
                label2.wrapMode: Text.Wrap

                Maui.TextField
                {
                    id: usernameField
                    Layout.fillWidth: true
                    placeholderText: i18n("Username")
                }
            }

            Maui.FlexSectionItem
            {
                label1.text: i18n("Password")
                label2.text: i18n("Password used to authenticate with the server.")
                label2.wrapMode: Text.Wrap

                Maui.PasswordField
                {
                    id: passwordField
                    Layout.fillWidth: true
                    placeholderText: i18n("Password")
                    echoMode: TextInput.Password
                    actions: []
                    passwordMaskDelay: 0
                }
            }

            Maui.FlexSectionItem
            {
                label1.text: i18n("Remember password")
                label2.text: i18n("Store this server password in the system Secret Service.")
                label2.wrapMode: Text.Wrap

                Switch
                {
                    checkable: true
                    checked: networkDialog.rememberPassword
                    onToggled: networkDialog.rememberPassword = checked
                }
            }
        }
    }

    Component
    {
        id: _disconnectDialogComponent

        Maui.InfoDialog
        {
            id: disconnectDialog
            property var server: null
            title: server ? i18n("Remove server") : i18n("Disconnect from server")
            message: server ? i18n("Do you want to remove this server from the Network view?") : i18n("Do you want to disconnect from this server?")
            standardButtons: Dialog.Yes | Dialog.Cancel
            Component.onCompleted: standardButton(Dialog.Yes).text = server ? i18n("Remove") : i18n("Disconnect")

            onAccepted:
            {
                if (server)
                    root.removeNetworkServer(server)
                else
                    root.currentBrowser.openFolder("remote:/")
                disconnectDialog.close()
            }

            onRejected: disconnectDialog.close()
            onClosed: disconnectDialog.destroy()
        }
    }

    Connections
    {
        target: root.currentBrowser ? root.currentBrowser.currentFMList : null

        function onStatusChanged()
        {
            if (!root.pendingNetworkServer || !target)
                return

            const server = root.pendingNetworkServer
            const expectedPath = String(server.path).replace(/\/+$/, "")
            const targetPath = String(target.path).replace(/\/+$/, "")
            const pathMatchesServer = targetPath === expectedPath || targetPath.startsWith(expectedPath + "/")
            if (!pathMatchesServer)
                return

            const connectionFailed = target.status.code === FB.PathStatus.ERROR
                                     || (target.status.code === FB.PathStatus.READY
                                         && target.status.empty
                                         && target.count <= 0)

            if (connectionFailed)
            {
                _initialNetworkRefreshTimer.stop()
                root.initialNetworkRefreshBasePath = ""
                if (!root.networkAuthenticationErrorNotified)
                {
                    root.networkAuthenticationErrorNotified = true
                    root.notify("dialog-error", i18n("Connection failed"), i18n("The server rejected the credentials or could not be reached."))
                    Qt.callLater(() => root.networkAuthenticationErrorNotified = false)
                }
                root.handleNetworkAuthenticationFailure(String(target.path))
                root.pendingNetworkServer = null
                return
            }

            if (target.status.code === FB.PathStatus.READY)
            {
                root.pendingNetworkServer = null
                root.addNetworkServer(server.protocol, server.address, server.username)
                root.initialNetworkRefreshBasePath = expectedPath
                _initialNetworkRefreshTimer.restart()
            }
        }

        function onAuthenticationError()
        {
            const path = target ? String(target.path) : ""
            if (!root.networkAuthenticationErrorNotified)
            {
                root.networkAuthenticationErrorNotified = true
                root.notify("dialog-error", i18n("Authentication failed"), i18n("The server rejected the password."))
                Qt.callLater(() => root.networkAuthenticationErrorNotified = false)
            }
            root.handleNetworkAuthenticationFailure(path)
        }

        function onWarning(message)
        {
            if (!message || !root.currentBrowser || !root.currentBrowser.isRemoteConnection || root.networkAuthenticationErrorNotified)
                return

            root.notify("dialog-error", i18n("Server error"), message)
        }
    }

    property alias currentTabIndex : _browserView.currentTabIndex
    property bool selectionMode: false
    function resolveFooterBar()
    {
        const footerContainerChild = resolveFooterContainerChild()

        return footerContainerChild && footerContainerChild.item ? footerContainerChild.item : footerContainerChild
    }

    function resolveFooterContainerChild()
    {
        return _pageLayout && _pageLayout.footerContainer && _pageLayout.footerContainer.visibleChildren.length > 0
                ? _pageLayout.footerContainer.visibleChildren[0]
                : null
    }

    function setSidebarVisible(visible)
    {
        settings.sidebarVisible = visible

        if (settings.sync)
            settings.sync()

    }

    function ensureFooterBarHeight(reason)
    {
        if (!_pageLayout || !_pageLayout.split || _pageLayout.splitIn !== ToolBar.Footer)
            return

        const footerBar = resolveFooterBar()
        if (!footerBar)
            return

        footerBar.preferredHeight = root.isWide ? Maui.Style.rowHeightAlt : Maui.Style.rowHeight
        footerBar.position = ToolBar.Footer
        footerBar.topPadding = root.isWide ? Maui.Style.defaultPadding : Maui.Style.space.small
        footerBar.bottomPadding = root.isWide ? Maui.Style.defaultPadding : Maui.Style.space.small
    }

    onWidthChanged:
    {
        Qt.callLater(() => ensureFooterBarHeight("root width changed"))
    }

    onHeightChanged:
    {
        Qt.callLater(() => ensureFooterBarHeight("root height changed"))
    }

    onCurrentBrowserChanged:
    {
        Qt.callLater(() => ensureFooterBarHeight("currentBrowser changed"))
    }

    onPathBarChanged:
    {
        Qt.callLater(() => ensureFooterBarHeight("pathBar changed"))
    }

    Timer
    {
        id: _footerStartupTimer
        repeat: true
        running: true
        interval: 250
        property int ticks: 0
        onTriggered:
        {
            root.ensureFooterBarHeight("startup tick " + ticks)
            ticks++
            if (ticks >= 12)
                stop()
        }
    }

    Maui.WindowBlur
    {
        view: root
        geometry: Qt.rect(0, 0, root.width, root.height)
        windowRadius: Maui.Style.radiusV
        enabled: true
    }

    Rectangle
    {
        anchors.fill: parent
        color: Maui.Theme.backgroundColor
        opacity: 0.76
        radius: Maui.Style.radiusV
    }

    Maui.Notify
    {
        id: _notifyOperation
        componentName: "org.kde.index"
        eventId: "fileOperation"
    }

    Settings
    {
        id: settings
        category: "Browser"

        property bool showHiddenFiles: false
        property bool showThumbnails: true
        property bool previewFiles : Maui.Handy.isMobile
        property bool restoreSession:  false
        property bool overviewStart : false
        property bool deleteToTrash: true
        property bool replaceConflicts: false
        property var networkServers: []

        property int viewType : FB.FMList.LIST_VIEW
        property int listSize : 0 // s-m-l-x-xl
        property int gridSize : 3 // s-m-l-x-xl

        property var lastSession : [[({'path': FB.FM.homePath()})]]
        property int lastTabIndex : 0

        property bool quickSidebarSection : true
        property bool showStoragePartitions : false
        property string sidebarSections: "13, 1, 3, 2"

        function sidebarSectionOrder()
        {
            return [
                FB.FMList.BOOKMARKS_PATH,
                FB.FMList.REMOTE_PATH,
                FB.FMList.REMOVABLE_PATH,
                FB.FMList.DRIVES_PATH]
        }

        function sidebarSectionsToArray(sections)
        {
            if (!sections)
                return []

            if (Array.isArray(sections))
                return sections.map(section => Number(section)).filter(section => !Number.isNaN(section))

            const text = String(sections).trim()
            if (!text.length || text.startsWith("@"))
                return []

            const matches = text.match(/\d+/g) || []
            return matches.map(section => Number(section)).filter(section => !Number.isNaN(section))
        }

        function sidebarSectionsToString(sections)
        {
            return normalizeSidebarSections(sections).join(", ")
        }

        function normalizeSidebarSections(sections)
        {
            const source = sidebarSectionsToArray(sections)
            const normalized = []
            const order = sidebarSectionOrder()

            for (const candidate of order)
            {
                if (source.includes(candidate))
                    normalized.push(candidate)
            }

            if (!normalized.includes(FB.FMList.DRIVES_PATH))
                normalized.push(FB.FMList.DRIVES_PATH)

            return normalized
        }

        function hasSidebarSection(section)
        {
            return normalizeSidebarSections(sidebarSections).indexOf(Number(section)) >= 0
        }


        property alias sideBarWidth : _sideBarView.sideBar.preferredWidth

        property bool dirConf : true
        property bool globalViewType: false
        property bool syncTerminal: true
        property bool autoPlayPreviews: true
        property font terminalFont: Maui.Style.monospacedFont
        property string terminalColorScheme: "Maui-Dark"
        property string terminalExecutable: "/usr/bin/station"
        property bool showActionsBar: true
        property bool sidebarVisible: true
        property string lastUsedTag
        property bool floatyUI : root.isWide
        property bool windowTranslucency : true
    }

    Settings
    {
        id: sortSettings
        category: "Sorting"
        property bool foldersFirst: true
        property int sortBy: FB.FMList.LABEL
        property int sortOrder: Qt.AscendingOrder
        property bool group: false
    }

    onClosing: (close) =>
               {
                   close.accepted = !settings.restoreSession
                   var tabs = []

                   for(var i = 0; i < _browserView.browserList.count; i ++)
                   {
                       const tab = _browserView.browserList.contentModel.get(i)
                       var tabPaths = []

                       for(var j = 0; j < tab.model.count; j++)
                       {
                           const browser = tab.model.get(j)
                           const tabMap = {'path': browser.currentPath}
                           tabPaths.push(tabMap)

                       }

                       tabs.push(tabPaths)
                   }

                   settings.lastSession = tabs
                   settings.lastTabIndex = currentTabIndex

                   close.accepted = true
               }

    ///////Actions
    Action
    {
        id: _newTabAction
        icon.name: "tab-new"
        text: i18n("New tab")
        onTriggered: root.openTab(currentBrowser.currentPath)
    }

    Action
    {
        id: _viewHiddenAction
        icon.name: "view-hidden"
        text: i18n("View Hidden")
        checkable: true
        checked: settings.showHiddenFiles
        onTriggered: settings.showHiddenFiles = !settings.showHiddenFiles
    }

    Action
    {
        id: _splitViewAction
        text: i18n("Split View")
        icon.name: currentTab.orientation === Qt.Horizontal ? "view-split-left-right" : "view-split-top-bottom"
        checked: currentTab.count === 2
        enabled: !currentBrowser || FB.FMList.MILLER_VIEW === undefined || currentBrowser.viewType !== FB.FMList.MILLER_VIEW
        checkable: true
        onTriggered: toogleSplitView()
    }

    Action
    {
        id: _showTerminalAction
        text: i18n("Terminal")
        enabled: currentTab && currentTab.currentItem ? currentTab.currentItem.supportsTerminal : false
        icon.name: "utilities-terminal"
        checked : currentTab && currentBrowser ? currentTab.currentItem.terminalVisible : false
        checkable: true

        onTriggered: currentTab.currentItem.toogleTerminal()
    }

    Component
    {
        id: _tagsDialogComponent

        FB.TagsDialog
        {
            Maui.Notification
            {
                id: _taggedNotification
                iconName: "dialog-info"
                title: i18n("Tagged")
                message: i18n("File was tagged successfully")

                Action
                {
                    property string tag
                    id: _openTagAction
                    text: tag
                    onTriggered:
                    {
                        openTab("tags:///"+tag)
                    }
                }
            }

            taglist.strict: false
            composerList.strict: false
            onClosed: root.restoreBrowserFocus()

            onTagsReady: (tags) =>
                         {
                             if(tags.length === 1)
                             {
                                 _openTagAction.tag = tags[0]
                                 _taggedNotification.dispatch()
                             }

                             settings.lastUsedTag = tags.length > 0 ? tags[0] : ""

                             if(root.currentBrowser && root.currentBrowser.currentFMList)
                                 root.currentBrowser.currentFMList.refresh()
                         }
        }
    }

    Component
    {
        id: _openWithDialogComponent
        FB.OpenWithDialog
        {
            onClosed:
            {
                root.restoreBrowserFocus()
                destroy()
            }
        }
    }

    Component
    {
        id: _configDialogComponent
        SettingsDialog
        {
            onClosed:
            {
                root.restoreBrowserFocus()
                destroy()
            }
        }
    }

    Component
    {
        id: _shortcutsDialogComponent
        ShortcutsDialog
        {
            onClosed:
            {
                root.restoreBrowserFocus()
                destroy()
            }
        }
    }

    Component
    {
        id: _extractDialogComponent

        Arc.ExtractDialog
        {
            destination:  currentBrowser.currentPath
            onClosed:
            {
                root.restoreBrowserFocus()
                destroy()
            }
        }
    }

    Component
    {
        id: _compressDialogComponent

        Arc.NewArchiveDialog
        {
            id: _compressDialog
            destination: currentBrowser.currentPath
            onDone: _compressDialog.compress()
            onClosed:
            {
                root.restoreBrowserFocus()
                destroy()
            }
        }
    }

    Component
    {
        id: _previewerComponent

        PreviewerDialog
        {
            onClosed:
            {
                root.restoreBrowserFocus()
                destroy()
            }
        }
    }

    Component
    {
        id: _browserComponent
        BrowserLayout {}
    }

    // Maui.NotifyAction
    // {
    //     id: _extractionFinishedAction
    //     text: i18n("Open folder")
    // }

    // Index.CompressedFile
    // {
    //     id: _compressedFile

    //     onExtractionFinished:
    //     {
    //         _notifyOperation.title = i18n("Extracted")
    //         _notifyOperation.message = i18n("File was extracted")
    //         _notifyOperation.defaultAction = _extractionFinishedAction
    //         _notifyOperation.iconName = "application-x-archive"
    //         _notifyOperation.send()
    //     }
    // }

    Maui.SideBarView
    {
        id: _sideBarView
        anchors.fill: parent
        sideBar.preferredWidth: Maui.Style.units.gridUnit * 12
        sideBar.minimumWidth: Maui.Style.units.gridUnit * 12
        Maui.Theme.colorSet: Maui.Theme.Window

        background: null

        sideBar.autoShow: true
        sideBar.floats: sideBar.collapsed
        sideBar.autoHide: true
        sideBarContent: Item
        {
            anchors.fill: parent
            anchors.margins: Maui.Style.contentMargins
            anchors.rightMargin: 0

            PlacesSideBar
            {
                id: placesSidebar
                focus: false
                focusPolicy: Qt.NoFocus
                anchors.fill: parent
                anchors.rightMargin: 0
            }
        }

        Connections
        {
            target: _sideBarView.sideBar

            function onOpened()
            {
                root.setSidebarVisible(true)
            }

            function onClosed()
            {
                root.setSidebarVisible(false)
            }

        }

        Maui.PageLayout
        {
            id: _pageLayout
            anchors.fill: parent
            clip: true

            split: width < 800
            splitIn: ToolBar.Footer

            altHeader: Maui.Handy.isMobile
            Maui.Controls.showCSD: true

            headBar.forceCenterMiddleContent: true
            headBar.preferredHeight: root.isWide ? Maui.Style.rowHeightAlt : Maui.Style.rowHeight
            headBar.topPadding: root.isWide ? Maui.Style.defaultPadding : Maui.Style.space.small
            headBar.bottomPadding: root.isWide ? Maui.Style.defaultPadding : Maui.Style.space.small
            headerMargins: Maui.Handy.isMobile ? 0 : Maui.Style.contentMargins
            footerMargins: headerMargins

            Maui.Theme.colorSet: Maui.Theme.View
            background: null

            onSplitChanged:
            {
                Qt.callLater(() => root.ensureFooterBarHeight("pageLayout split changed"))
            }

            onWidthChanged:
            {
                Qt.callLater(() => root.ensureFooterBarHeight("pageLayout width changed"))
            }

            onHeightChanged:
            {
                Qt.callLater(() => root.ensureFooterBarHeight("pageLayout height changed"))
            }

            Component
            {
                id: _historyActionsComponent
                Maui.ToolActions
                {
                    autoExclusive: false
                    checkable: false
                    display: ToolButton.IconOnly

                    Action
                    {
                        icon.name: "go-previous"
                        onTriggered: root.currentBrowser.goBack()
                    }

                    Action
                    {
                        icon.name: "go-next"
                        onTriggered: root.currentBrowser.goForward()
                    }
                }
            }

            Component
            {
                id: _millerHistoryActionsComponent
                Maui.ToolActions
                {
                    autoExclusive: false
                    checkable: false
                    display: ToolButton.IconOnly

                    Action
                    {
                        icon.name: "go-previous"
                        onTriggered: root.currentBrowser.goBack()
                    }

                    Action
                    {
                        text: i18n("Go up")
                        icon.name: "go-up"
                        onTriggered: root.currentBrowser.goUp()
                    }

                    Action
                    {
                        icon.name: "go-next"
                        onTriggered: root.currentBrowser.goForward()
                    }
                }
            }

            leftContent:  [

                Loader
                {
                    id: _sidebarToggleLoader
                    asynchronous: true
                    active: !!_sideBarView.sideBar
                    visible: active

                    sourceComponent: ToolButton
                    {
                        icon.name: _sideBarView.sideBar.visible ? "sidebar-collapse" : "sidebar-expand"
                        onClicked:
                        {
                            const nextVisible = !_sideBarView.sideBar.visible
                            root.setSidebarVisible(nextVisible, "header toggle")

                            if (nextVisible)
                                _sideBarView.sideBar.open()
                            else
                                _sideBarView.sideBar.close()
                        }
                        checked: _sideBarView.sideBar.visible
                        ToolTip.delay: 1000
                        ToolTip.timeout: 5000
                        ToolTip.visible: hovered
                        ToolTip.text: i18n("Toggle sidebar")
                    }
                },

                ToolSeparator
                {
                    visible: _sidebarToggleLoader.active
                    topPadding: 10
                    bottomPadding: 10
                },

                Loader
                {
                    id: _overviewBackLoader
                    asynchronous: true
                    active: _stackView.depth > 1
                    visible: active

                    sourceComponent: ToolButton
                    {
                        icon.name: "go-previous"
                        display: ToolButton.IconOnly
                        onClicked: _stackView.pop()
                    }
                },

                Loader
                {
                    id: _historyActionsLoader
                    asynchronous: false
                    active: _stackView.depth === 1 && !!root.currentBrowser
                    visible: active
                    sourceComponent: root.currentBrowser
                                     && root.currentBrowser.viewType === FB.FMList.MILLER_VIEW
                                     ? _millerHistoryActionsComponent
                                     : _historyActionsComponent
                },

                Loader
                {
                    id: _viewTypeActionsLoader
                    asynchronous: false
                    active: _stackView.depth === 1 && !!root.currentBrowser
                    visible: active

                    sourceComponent: Maui.ToolActions
                    {
                        enabled: !appSettings.globalViewType
                        autoExclusive: true
                        expanded: root.isWide
                        cyclic: true
                        display: ToolButton.IconOnly

                        Action
                        {
                            text: i18n("List")
                            icon.name: "view-list-details"
                            checked: currentBrowser.viewType === FB.FMList.LIST_VIEW
                            checkable: true
                            onTriggered:
                            {
                                if(currentBrowser)
                                {
                                    currentBrowser.setViewType(FB.FMList.LIST_VIEW)
                                }
                            }
                        }

                        Action
                        {
                            text: i18n("Grid")
                            icon.name: "view-list-icons"
                            checked:  currentBrowser.viewType === FB.FMList.ICON_VIEW
                            checkable: true

                            onTriggered:
                            {
                                if(currentBrowser)
                                {
                                    currentBrowser.setViewType(FB.FMList.ICON_VIEW)
                                }
                            }
                        }

                        Action
                        {
                            text: i18n("Miller columns")
                            icon.name: "view-split-miller-column"
                            checked: currentBrowser.viewType === FB.FMList.MILLER_VIEW
                            checkable: true
                            enabled: FB.FMList.MILLER_VIEW !== undefined

                            onTriggered:
                            {
                                if(currentBrowser && FB.FMList.MILLER_VIEW !== undefined)
                                    currentBrowser.setViewType(FB.FMList.MILLER_VIEW)
                            }
                        }
                    }
                },

                ToolSeparator
                {
                    visible: !_pageLayout.split && _viewTypeActionsLoader.active && _searchToggleLoader.active
                    topPadding: 10
                    bottomPadding: 10
                }
            ]

            rightContent: [

                ToolSeparator
                {
                    visible: !_pageLayout.split && _fileOperationIndicator.visible
                    topPadding: 10
                    bottomPadding: 10
                },

                FB.FileOperationIndicator
                {
                    id: _fileOperationIndicator
                    transferCenter: _fileOperationDialog
                    Maui.Controls.badgeText: ""

                    contentItem: RowLayout
                    {
                        spacing: Maui.Style.space.small

                        Maui.Icon
                        {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: Maui.Style.iconSize
                            Layout.preferredHeight: Maui.Style.iconSize
                            source: _fileOperationIndicator.icon.name
                            color: _fileOperationIndicator.color
                        }

                        ToolButton
                        {
                            visible: _fileOperationIndicator.transferCount > 1
                            text: _fileOperationIndicator.transferCount
                            display: ToolButton.TextOnly
                            implicitHeight: Maui.Style.iconSize
                            topPadding: 0
                            bottomPadding: 0
                            font.bold: true
                            font.pointSize: Maui.Style.fontSizes.small
                            ToolTip.visible: false
                            ToolTip.text: ""
                            onClicked: {}

                            background: Rectangle
                            {
                                color: Maui.Theme.alternateBackgroundColor
                                radius: Maui.Style.radiusV
                            }
                        }
                    }
                },

                ToolSeparator
                {
                    visible: !_pageLayout.split && _viewTypeActionsLoader.active && _networkConnectLoader.active
                    topPadding: 10
                    bottomPadding: 10
                },

                Loader
                {
                    id: _networkConnectLoader
                    asynchronous: true
                    active: _stackView.depth === 1 && !!root.currentSplit && (root.currentSplit.isNetworkView === true || root.currentSplit.isRemoteConnection === true)
                    visible: active

                    sourceComponent: ToolButton
                    {
                        icon.name: root.currentSplit.isRemoteConnection ? "network-disconnect" : "folder-network"
                        ToolTip.visible: hovered
                        ToolTip.text: root.currentSplit.isRemoteConnection ? i18n("Disconnect from server") : i18n("Connect to a server")
                        onClicked: root.currentSplit.isRemoteConnection ? root.openDisconnectDialog() : root.openNetworkDialog()
                    }
                },

                ToolSeparator
                {
                    visible: root.isWide && _viewTypeActionsLoader.active && _searchToggleLoader.active
                    topPadding: 10
                    bottomPadding: 10
                },

                Loader
                {
                    id: _searchToggleLoader
                    asynchronous: true
                    active: root.isWide && _stackView.depth === 1 && !!root.currentBrowser
                    visible: active

                    sourceComponent: ToolButton
                    {
                        icon.name: "edit-find"
                        checked: currentBrowser.headBar.visible
                        checkable: true
                        onClicked: currentBrowser.toggleSearchBar()
                    }
                },

                ToolSeparator
                {
                    visible: root.isWide && _searchToggleLoader.active && _mainMenuLoader.active
                    topPadding: 10
                    bottomPadding: 10
                    Layout.preferredWidth: visible ? implicitWidth : 0
                },

                Loader
                {
                    asynchronous: true
                    active: !root.isWide && _browserView.browserList.count > 1
                    visible: active
                    sourceComponent: _tabOverviewButtonComponent
                },

                ToolSeparator
                {
                    visible: !root.isWide && _browserView.browserList.count > 1
                    topPadding: 10
                    bottomPadding: 10
                },

                Loader
                {
                    id: _mainMenuLoader
                    asynchronous: true
                    active: _stackView.depth === 1 && !!root.currentBrowser
                    visible: active
                    sourceComponent: Maui.ToolButtonMenu
                    {
                        id: _mainMenu
                        icon.name:  "overflow-menu"

                        Menu
                        {
                            icon.name: "view-sort"
                            title: i18n("Sort")
                            Maui.Controls.component: Component
                            {
                                Item
                                {
                                    implicitWidth: 0
                                    implicitHeight: 0
                                    visible: false
                                }
                            }

                            MenuItem
                            {
                                text: i18n("Type")
                                checked: currentBrowser.sortBy === FB.FMList.MIME
                                checkable: true
                                autoExclusive: true
                                onTriggered:
                                {
                                    currentBrowser.sortBy = FB.FMList.MIME
                                }
                            }

                            MenuItem
                            {
                                text: i18n("Date")
                                checked: currentBrowser.sortBy === FB.FMList.DATE
                                checkable: true
                                autoExclusive: true

                                onTriggered:
                                {
                                    currentBrowser.sortBy = FB.FMList.DATE
                                }
                            }

                            MenuItem
                            {
                                text: i18n("Modified")
                                checked: currentBrowser.sortBy === FB.FMList.MODIFIED
                                checkable: true
                                autoExclusive: true

                                onTriggered:
                                {
                                    currentBrowser.sortBy = FB.FMList.MODIFIED
                                }
                            }

                            MenuItem
                            {
                                text: i18n("Size")
                                checked: currentBrowser.sortBy === FB.FMList.SIZE
                                checkable: true
                                autoExclusive: true

                                onTriggered:
                                {
                                    currentBrowser.sortBy = FB.FMList.SIZE
                                }
                            }

                            MenuItem
                            {
                                text: i18n("Name")
                                checked: currentBrowser.sortBy === FB.FMList.LABEL
                                checkable: true
                                autoExclusive: true

                                onTriggered:
                                {
                                    currentBrowser.sortBy = FB.FMList.LABEL
                                }
                            }
                        }

                        MenuItem
                        {
                            visible: !root.isWide
                            text: i18n("Search")
                            icon.name: "edit-find"
                            checkable: true
                            checked: currentBrowser ? currentBrowser.headBar.visible : false
                            onTriggered: currentBrowser.toggleSearchBar()
                        }

                        MenuSeparator {}

                        MenuItem
                        {
                            text: i18n("Shortcuts")
                            icon.name: "configure-shortcuts"
                            onTriggered:
                            {
                                var dialog = _shortcutsDialogComponent.createObject(root)
                                dialog.open()
                            }
                        }

                        MenuItem
                        {
                            text: i18n("Settings")
                            icon.name: "settings-configure"
                            onTriggered: openConfigDialog()
                        }

                        MenuItem
                        {
                            text: i18n("About")
                            icon.name: "documentinfo"
                            onTriggered: Maui.App.aboutDialog()
                        }
                    }
                }
            ]

            Component
            {
                id: _tabOverviewButtonComponent

                ToolButton
                {
                    display: ToolButton.IconOnly
                    onClicked: _browserView.browserList.openOverview()
                    Layout.alignment: Qt.AlignVCenter
                    height: Maui.Style.rowHeight
                    leftPadding: Maui.Style.space.small
                    rightPadding: Maui.Style.space.small
                    topPadding: 0
                    bottomPadding: 0

                    contentItem: RowLayout
                    {
                        spacing: Maui.Style.space.small

                        Maui.Icon
                        {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: Maui.Style.iconSizes.small
                            Layout.preferredHeight: Maui.Style.iconSizes.small
                            source: "view-grid"
                            color: Maui.Theme.textColor
                        }

                        ToolButton
                        {
                            Layout.alignment: Qt.AlignVCenter
                            text: _browserView.browserList.count
                            display: ToolButton.TextOnly
                            font.bold: true
                            font.pointSize: Maui.Style.fontSizes.small
                            ToolTip.visible: false
                            onClicked: {}

                            background: Rectangle
                            {
                                color: Maui.Theme.alternateBackgroundColor
                                radius: Maui.Style.radiusV
                            }
                        }
                    }

                    ToolTip.delay: 1000
                    ToolTip.timeout: 5000
                    ToolTip.visible: hovered
                    ToolTip.text: i18n("Show tabs")
                }
            }

            headBar.middleContent: Loader
            {
                id: _headBarMiddleLoader

                asynchronous: true

                Layout.fillWidth: true
                Layout.minimumWidth: 100
                Layout.maximumWidth: _stackView.depth > 1 ? 500 : -1
                Layout.alignment: Qt.AlignCenter

                sourceComponent: (_stackView.depth > 1 || !root.currentBrowser) ? _overviewSearchComponent : _pathBarComponent
            }

            Component
            {
                id: _pathBarComponent

                Item
                {
                    implicitHeight: _pathBar.implicitHeight
                    readonly property alias pathBar: _pathBar

                    OpacityAnimator on opacity
                    {
                        from: 0
                        to: 1
                        duration: Maui.Style.units.longDuration
                        running: parent.visible
                    }

                    PathBar
                    {
                        id: _pathBar

                        anchors.centerIn: parent
                        width: _pageLayout.split ? parent.width : Math.min(parent.width, implicitWidth)

                        url: currentBrowser.currentPath

                        onPathChanged: (path) => currentBrowser.openFolder(path)

                        onHomeClicked: currentBrowser.openFolder(FB.FM.homePath())
                        onPlaceClicked: (path) => currentBrowser.openFolder(path)

                        onPlaceRightClicked: (path) =>
                                             {
                                                 _pathBarmenu.path = path
                                                 _pathBarmenu.show()
                                             }

                        Maui.ContextualMenu
                        {
                            id: _pathBarmenu
                            property url path

                            MenuItem
                            {
                                text: i18n("Edit Path")
                                icon.name: "document-edit"
                                onTriggered: _pathBar.showEntryBar()
                            }

                            MenuItem
                            {
                                text: i18n("Bookmark")
                                icon.name: "bookmark-new"
                                onTriggered: currentBrowser.bookmarkFolder([_pathBarmenu.path])
                            }

                            MenuItem
                            {
                                text: i18n("Open in new tab")
                                icon.name: "tab-new"
                                onTriggered: openTab(_pathBarmenu.path)
                            }

                            MenuItem
                            {
                                visible: root.currentTab.count === 1
                                text: i18n("Open in Split View")
                                icon.name: "view-split-left-right"
                                onTriggered: currentTab.split(_pathBarmenu.path, Qt.Horizontal)
                            }
                        }
                    }
                }
            }

            Component
            {
                id: _overviewSearchComponent

                Maui.SearchField
                {
                    placeholderText: i18n("Search for files")
                    onAccepted:
                    {
                        currentBrowser.search(text)

                        if(_stackView.depth > 1)
                            _stackView.pop()
                    }
                }
            }

            StackView
            {
                id: _stackView
                anchors.fill: parent
                clip: false
                Keys.enabled: true
                Keys.forwardTo: currentItem
                background: null

                initialItem: BrowserView
                {
                    id: _browserView
                    visible: StackView.status !== StackView.Inactive
                    flickable: currentBrowser.flickable
                }

                Loader
                {
                    id: _homeViewComponent
                    asynchronous: true
                    visible: StackView.status !== StackView.Inactive
                    active: StackView.status !== StackView.Inactive || item

                    sourceComponent: HomeView {}

                    BusyIndicator
                    {
                        running: parent.status === Loader.Loading
                        anchors.centerIn: parent
                    }
                }
            }
        }
    }

    Component.onCompleted:
    {
        settings.sidebarSections = settings.sidebarSectionsToString(settings.sidebarSections)

        if(settings.overviewStart)
        {
            root.openTab(FB.FM.homePath())

            _stackView.push(_homeViewComponent)
            return
        }

        if(initPaths.length)
        {
            for(var path of initPaths)
                root.openTab(path)
            return;
        }

        const tabs = settings.lastSession
        if(settings.restoreSession && tabs.length)
        {
            restoreSession(tabs)
            return
        }

        root.openTab(FB.FM.homePath())
    }

    function restoreBrowserFocus()
    {
        Qt.callLater(() => {
            if (root.currentBrowser)
                root.currentBrowser.forceActiveFocus()
        })
    }

    function toogleSplitView()
    {
        if(currentTab.count === 2)
            currentTab.pop()
        else
            currentTab.split(currentBrowser.currentPath, Qt.Horizontal)
    }

    function openConfigDialog()
    {
        var dialog = _configDialogComponent.createObject(root)
        dialog.open()
    }

    function closeTab(index)
    {
        _browserView.browserList.closeTab(index)
    }

    function openDirs(paths)
    {
        for(var path of paths)
            root.openTab(path)
    }


    function cleanNetworkAddress(address)
    {
        let value = String(address || "").trim()
        const schemeSeparator = value.indexOf("://")
        if (schemeSeparator >= 0)
            value = value.substring(schemeSeparator + 3)

        const credentialsSeparator = value.lastIndexOf("@")
        if (credentialsSeparator >= 0)
            value = value.substring(credentialsSeparator + 1)

        return value
    }

    function addNetworkServer(protocol, address, username)
    {
        const cleanAddress = root.cleanNetworkAddress(address)
        const servers = (appSettings.networkServers || []).slice()
        const existing = servers.findIndex((server) => server.protocol === protocol && root.cleanNetworkAddress(server.address) === cleanAddress)
        const entry = ({protocol: protocol, address: cleanAddress, username: username})

        if (existing >= 0)
            servers[existing] = entry
        else
            servers.push(entry)

        appSettings.networkServers = servers
    }

    function updateNetworkServer(original, updated)
    {
        const oldProtocol = original ? original.protocol : ""
        const oldAddress = original ? root.cleanNetworkAddress(original.address) : ""
        const oldUsername = original ? original.username : ""
        const newAddress = root.cleanNetworkAddress(updated.address)
        const servers = (appSettings.networkServers || []).slice()
        const displaced = servers.find((entry) => {
            const address = root.cleanNetworkAddress(entry.address)
            const isOldEntry = entry.protocol === oldProtocol && address === oldAddress
            return !isOldEntry && entry.protocol === updated.protocol && address === newAddress
        })
        const filteredServers = servers.filter((entry) => {
            const address = root.cleanNetworkAddress(entry.address)
            const isOldEntry = entry.protocol === oldProtocol && address === oldAddress
            const isNewEntry = entry.protocol === updated.protocol && address === newAddress
            return !isOldEntry && !isNewEntry
        })
        filteredServers.push({protocol: updated.protocol, address: newAddress, username: updated.username})
        appSettings.networkServers = filteredServers

        if (displaced && displaced.username)
            Index.NetworkPasswordManager.remove(displaced.protocol, root.cleanNetworkAddress(displaced.address), displaced.username)

        if (original && oldUsername && (oldProtocol !== updated.protocol || oldAddress !== newAddress || oldUsername !== updated.username))
            Index.NetworkPasswordManager.remove(oldProtocol, oldAddress, oldUsername)
    }

    function networkServerUrl(server)
    {
        const address = root.cleanNetworkAddress(server.address)
        return server.protocol + "://" + address
    }

    function openNetworkUrl(url, target = 0)
    {
        Qt.callLater(() => {
            if (target === 1)
                root.openTab(url)
            else if (target === 2)
                inx.openNewWindow(url)
            else
                root.currentBrowser.openFolder(url)
        })
    }

    function openTrackedNetworkServer(server)
    {
        const url = root.networkServerUrl(server)
        root.pendingNetworkServer = ({protocol: server.protocol, address: root.cleanNetworkAddress(server.address), username: server.username || "", rememberPassword: true, path: url})
        root.openNetworkUrl(url)
    }

    function openNetworkServer(server)
    {
        if (!server.username || Index.NetworkPasswordManager.prepareStored(server.protocol, root.cleanNetworkAddress(server.address), server.username))
            root.openTrackedNetworkServer(server)
        else
            root.openNetworkDialog(server, true)
    }

    function openNetworkServerInNewTab(server)
    {
        if (!server.username || Index.NetworkPasswordManager.prepareStored(server.protocol, root.cleanNetworkAddress(server.address), server.username))
            root.openNetworkUrl(root.networkServerUrl(server), 1)
        else
            root.openNetworkDialog(server, true, 1)
    }

    function openNetworkServerInNewWindow(server)
    {
        if (!server.username || Index.NetworkPasswordManager.prepareStored(server.protocol, root.cleanNetworkAddress(server.address), server.username))
            root.openNetworkUrl(root.networkServerUrl(server), 2)
        else
            root.openNetworkDialog(server, true, 2)
    }

    function disconnectNetworkServer(server)
    {
        const dialog = _disconnectDialogComponent.createObject(root, ({'server': server}))
        dialog.open()
    }

    function removeNetworkServer(server)
    {
        const cleanAddress = root.cleanNetworkAddress(server.address)
        const servers = (appSettings.networkServers || []).filter((entry) => entry.protocol !== server.protocol || root.cleanNetworkAddress(entry.address) !== cleanAddress)
        appSettings.networkServers = servers
        if (server.username)
            Index.NetworkPasswordManager.remove(server.protocol, root.cleanNetworkAddress(server.address), server.username)

        if (root.currentBrowser.isRemoteConnection && String(root.currentBrowser.currentPath).includes(server.address))
            root.currentBrowser.openFolder("remote:/")
    }

    function handleNetworkAuthenticationFailure(path)
    {
        const pendingServer = root.pendingNetworkServer
        if (pendingServer && pendingServer.username)
        {
            Index.NetworkPasswordManager.remove(pendingServer.protocol, root.cleanNetworkAddress(pendingServer.address), pendingServer.username)
            root.pendingNetworkServer = null
            root.initialNetworkRefreshBasePath = ""
            _initialNetworkRefreshTimer.stop()
            return
        }

        const currentPath = String(path).replace(/\/+$/, "")
        const server = (appSettings.networkServers || []).find((entry) => {
            const serverPath = root.networkServerUrl(entry).replace(/\/+$/, "")
            return currentPath === serverPath || currentPath.startsWith(serverPath + "/")
        })

        if (server && server.username)
            Index.NetworkPasswordManager.remove(server.protocol, root.cleanNetworkAddress(server.address), server.username)
    }

    function openNetworkDialog(server, credentialsOnly = false, openTarget = 0, editServer = false)
    {
        const dialog = _networkDialogComponent.createObject(root, server ? {
            initialProtocol: server.protocol,
            initialAddress: root.cleanNetworkAddress(server.address),
            initialUsername: server.username,
            credentialsOnly: credentialsOnly,
            openTarget: openTarget,
            editServer: editServer,
            editingServer: server,
            initialRememberPassword: server && server.username
                                      && Index.NetworkPasswordManager.hasCredentials(server.protocol, root.cleanNetworkAddress(server.address), server.username)
        } : {openTarget: openTarget, editServer: editServer})
        dialog.open()
    }

    function openDisconnectDialog()
    {
        const dialog = _disconnectDialogComponent.createObject(root)
        dialog.open()
    }

    function openTab(path, path2 = "")
    {
        if(path)
        {
            if(_stackView.depth === 2)
                _stackView.pop()


            _browserView.browserList.addTab(_browserComponent, {'path': path, 'path2': path2}, false)
        }
    }

    function tagFiles(urls)
    {
        if(urls.length < 1)
        {
            return
        }

        if(root.tagsDialog)
        {
            root.tagsDialog.composerList.urls = urls
        }else
        {
           root.tagsDialog = _tagsDialogComponent.createObject(root, ({'composerList.urls' : urls}))
        }

        root.tagsDialog.open()
    }

    /**
     * Add the file urls to the selection
     **/
    function openWith(urls)
    {
        if(urls.length <= 0)
        {
            return
        }

        var dialog = _openWithDialogComponent.createObject(root, {'urls': urls})
        dialog.open()
    }

    /**
      *
      **/
    function shareFiles(urls)
    {
        if(urls.length <= 0)
        {
            return
        }

        Maui.Platform.shareFiles(urls)
    }

    function openPreview(url)
    {
        var dialog = _previewerComponent.createObject(root)
        dialog.previewer.setData(url)
        dialog.open()
        dialog.forceActiveFocus()
    }

    function restoreSession(tabs)
    {
        for(var i = 0; i < tabs.length; i++ )
        {
            const tab = tabs[i]

            if(tab.length === 2)
            {
                root.openTab(tab[0].path, tab[1].path)
            }else
            {
                root.openTab(tab[0].path)
            }
        }

        currentTabIndex = settings.lastTabIndex
    }

    /**
      * Remove or add a sidebar section
      */
    function toggleSection(section)
    {
        const value = Number(section)
        const sections = appSettings.normalizeSidebarSections(appSettings.sidebarSections)
        const order = appSettings.sidebarSectionOrder()
        const index = sections.indexOf(value)

        if (index >= 0)
        {
            sections.splice(index, 1)
        } else
        {
            let insertAt = sections.length
            const targetOrder = order.indexOf(value)

            for (let i = 0; i < sections.length; ++i)
            {
                if (order.indexOf(sections[i]) > targetOrder)
                {
                    insertAt = i
                    break
                }
            }

            sections.splice(insertAt, 0, value)
        }

        appSettings.sidebarSections = appSettings.sidebarSectionsToString(sections)
    }

    function isUrlOpen(url : string) : bool
    {
        return _browserView.isUrlOpen(url);
    }

    /**
      * Open menu in the menu button position
     */
    function openMainMenu()
    {
        if(_mainMenuLoader.item)
            _mainMenuLoader.item.open()
    }

    /**
      * Open menu in  the cursor position
      */
    function popupMainMenu()
    {
        if(_mainMenuLoader.item)
            _mainMenuLoader.item.popup()
    }

}
