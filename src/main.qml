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

    readonly property alias selectionBar : _browserView.selectionBar
    readonly property alias pathBar: _headBarMiddleLoader.item

    readonly property alias currentTab : _browserView.currentTab
    readonly property alias currentSplit : _browserView.currentSplit
    readonly property FB.FileBrowser currentBrowser : currentSplit.browser

    readonly property alias appSettings : settings

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

    function ensureFooterBarHeight(reason)
    {
        if (!_pageLayout || !_pageLayout.split || _pageLayout.splitIn !== ToolBar.Footer)
            return

        const footerContainer = _pageLayout.footerContainer
        const footerContainerChild = resolveFooterContainerChild()
        const footerBar = resolveFooterBar()
        if (!footerBar)
            return

        const pathBarItem = root.pathBar
        const pathBarHeight = pathBarItem && pathBarItem.height !== undefined ? pathBarItem.height : -1
        const pathBarImplicitHeight = pathBarItem && pathBarItem.implicitHeight !== undefined ? pathBarItem.implicitHeight : -1
        const headBarHeight = _pageLayout.headBar && _pageLayout.headBar.height !== undefined ? _pageLayout.headBar.height : -1
        const headBarImplicitHeight = _pageLayout.headBar && _pageLayout.headBar.implicitHeight !== undefined ? _pageLayout.headBar.implicitHeight : -1
        const fallbackHeight = Maui.Style.toolBarHeight
        const targetHeight = Math.max(fallbackHeight, headBarHeight, headBarImplicitHeight, pathBarHeight, pathBarImplicitHeight)
        const footerContainerCurrentHeight = footerContainer && footerContainer.height !== undefined ? footerContainer.height : -1
        const preferredHeight = footerBar.preferredHeight !== undefined ? footerBar.preferredHeight : -1
        const implicitHeight = footerBar.implicitHeight !== undefined ? footerBar.implicitHeight : -1
        const currentHeight = footerBar.height !== undefined ? footerBar.height : -1

        if (footerContainer && footerContainer.forceLayout)
            footerContainer.forceLayout()

        if (footerContainerCurrentHeight !== targetHeight || preferredHeight !== targetHeight || implicitHeight !== targetHeight || currentHeight !== targetHeight)
        {
            if (footerContainer && footerContainer.implicitHeight !== undefined && footerContainer.implicitHeight !== targetHeight)
                footerContainer.implicitHeight = targetHeight

            if (footerContainer && footerContainer.height !== undefined && footerContainer.height !== targetHeight)
                footerContainer.height = targetHeight

            if (footerContainerChild && footerContainerChild.implicitHeight !== undefined && footerContainerChild.implicitHeight !== targetHeight)
                footerContainerChild.implicitHeight = targetHeight

            if (footerContainerChild && footerContainerChild.height !== undefined && footerContainerChild.height !== targetHeight)
                footerContainerChild.height = targetHeight

            if (footerBar.preferredHeight !== undefined && footerBar.preferredHeight !== targetHeight)
                footerBar.preferredHeight = targetHeight

            if (footerBar.implicitHeight !== undefined && footerBar.implicitHeight !== targetHeight)
                footerBar.implicitHeight = targetHeight

            if (footerBar.height !== undefined && footerBar.height !== targetHeight)
                footerBar.height = targetHeight

        }
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

        property int viewType : FB.FMList.LIST_VIEW
        property int listSize : 0 // s-m-l-x-xl
        property int gridSize : 3 // s-m-l-x-xl

        property var lastSession : [[({'path': FB.FM.homePath()})]]
        property int lastTabIndex : 0

        property bool quickSidebarSection : true
        property var sidebarSections : [
            FB.FMList.BOOKMARKS_PATH,
            FB.FMList.REMOTE_PATH,
            FB.FMList.REMOVABLE_PATH,
            FB.FMList.DRIVES_PATH]


        property alias sideBarWidth : _sideBarView.sideBar.preferredWidth

        property bool dirConf : true
        property bool syncTerminal: true
        property bool previewerWindow: !Maui.Handy.isMobile
        property bool autoPlayPreviews: true
        property bool terminalFollowsColorScheme: true
        property string terminalColorScheme: "Maui-Dark"
        property string terminalExecutable: "/usr/bin/station"
        property bool showActionsBar: true
        property string lastUsedTag
        property bool floatyUI : root.isWide
        property bool windowTranslucency : true
    }

    Settings
    {
        id: sortSettings
        category: "Sorting"
        property bool foldersFirst: true
        property int sortBy: FB.FMList.MODIFIED
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
        checkable: true
        onTriggered: toogleSplitView()
    }

    Action
    {
        id: _showTerminalAction
        text: i18n("Terminal")
        enabled: currentTab && currentTab.currentItem ? currentTab.currentItem.supportsTerminal : false
        icon.name: "dialog-scripts"
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

            onTagsReady: (tags) =>
                         {
                             if(tags.length === 1)
                             {
                                 _openTagAction.tag = tags[0]
                                 _taggedNotification.dispatch()
                             }

                             settings.lastUsedTag = tags[0]
                         }
        }
    }

    Component
    {
        id: _openWithDialogComponent
        FB.OpenWithDialog { onClosed: destroy() }
    }

    Component
    {
        id: _configDialogComponent
        SettingsDialog { onClosed: destroy()}
    }

    Component
    {
        id: _shortcutsDialogComponent
        ShortcutsDialog { onClosed: destroy()}
    }

    Component
    {
        id: _extractDialogComponent

        Arc.ExtractDialog
        {
            destination:  currentBrowser.currentPath
            onClosed: destroy()
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
            onClosed: destroy()
        }
    }

    Component
    {
        id: _previewerComponent

        PreviewerDialog
        {
            onClosed: destroy()
        }
    }

    Component
    {
        id: _previewerWindowComponent
        PreviewerWindow
        {
            onClosing: destroy()
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
        Maui.Theme.colorSet: Maui.Theme.View

        background: null

        sideBar.autoShow: true
        sideBar.floats: sideBar.collapsed
        sideBar.autoHide: true
        sideBarContent: PlacesSideBar
        {
            id: placesSidebar
            focus: false
            focusPolicy: Qt.NoFocus
            anchors.fill: parent
            anchors.margins: settings.floatyUI ? Maui.Style.contentMargins : 0
            anchors.rightMargin: 0
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

            headBar.visible: true
            headBar.forceCenterMiddleContent: true
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

            leftContent:  [

                Loader
                {
                    id: _sidebarToggleLoader
                    asynchronous: true
                    active: _sideBarView.sideBar.collapsed || !_sideBarView.sideBar.visible
                    visible: active

                    sourceComponent: ToolButton
                    {
                        icon.name: _sideBarView.sideBar.visible ? "sidebar-collapse" : "sidebar-expand"
                        onClicked: _sideBarView.sideBar.toggle()
                        checked: _sideBarView.sideBar.visible
                        ToolTip.delay: 1000
                        ToolTip.timeout: 5000
                        ToolTip.visible: hovered
                        ToolTip.text: i18n("Toggle sidebar")
                    }
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
                    asynchronous: true
                    active: _stackView.depth === 1 && !!root.currentBrowser
                    visible: active

                    sourceComponent: Maui.ToolActions
                    {
                        autoExclusive: false
                        checkable: false
                        display: ToolButton.IconOnly

                        Action
                        {
                            icon.name: "go-previous"
                            onTriggered : currentBrowser.goBack()
                        }

                        Action
                        {
                            icon.name: "go-next"
                            onTriggered : currentBrowser.goForward()
                        }
                    }
                },

                Loader
                {
                    id: _viewTypeActionsLoader
                    asynchronous: true
                    active: _stackView.depth === 1 && !!root.currentBrowser
                    visible: active

                    sourceComponent: Maui.ToolActions
                    {
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
                                    currentBrowser.viewType = FB.FMList.LIST_VIEW
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
                                    currentBrowser.viewType = FB.FMList.ICON_VIEW
                                }
                            }
                        }
                    }
                }
            ]

            rightContent: [

                Loader
                {
                    id: _searchToggleLoader
                    asynchronous: true
                    active: _stackView.depth === 1 && !!root.currentBrowser
                    visible: active

                    sourceComponent: ToolButton
                    {
                        icon.name: "edit-find"
                        checked: currentBrowser.headBar.visible
                        checkable: true
                        onClicked: currentBrowser.toggleSearchBar()
                    }
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
                                text: i18n("Bookmark")
                                icon.name: "bookmark-new"
                                onTriggered: currentBrowser.bookmarkFolder([_pathBarmenu.path])
                            }

                            MenuItem
                            {
                                text: i18n("Open in New Tab")
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
        if(appSettings.previewerWindow)
        {
            var previewer = _previewerWindowComponent.createObject(root)
            previewer.previewer.setData(url)
            previewer.forceActiveFocus()

        }else
        {
            var dialog = _previewerComponent.createObject(root)
            dialog.previewer.setData(url)
            dialog.open()
            dialog.forceActiveFocus()
        }
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
        placesSidebar.list.toggleSection(section)
        appSettings.sidebarSections = placesSidebar.list.groups
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
