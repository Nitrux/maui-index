// Copyright 2018-2020 Camilo Higuita <milo.h@aol.com>
// Copyright 2018-2020 Nitrux Latinoamericana S.C.
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls

import org.mauikit.controls as Maui
import org.mauikit.filebrowsing as FB

Maui.Page
{
    id: control

    Keys.enabled: true
    Keys.forwardTo: _browserList

    property alias selectionBar: _selectionBar
    property alias currentTabIndex : _browserList.currentIndex
    property alias currentTab : _browserList.currentItem
    property Browser currentSplit: currentTab ? currentTab.currentItem : null
    property alias browserList : _browserList

    floatingFooter: true
    headBar.visible: false
    background: null

    footer: Maui.SelectionBar
    {
        id: _selectionBar
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(((parent ? parent.width : 0) - (Maui.Style.space.medium * 2)), implicitWidth)

        maxListHeight: _browserList.height - (Maui.Style.contentMargins*2)

        display: ToolButton.IconOnly

        onVisibleChanged:
        {
            if(!visible)
            {
                root.selectionMode = false
            }
        }

        onUrisDropped: (uris) =>
                       {
                           for(var i in uris)
                           {
                               if(!FB.FM.fileExists(uris[i]))
                               continue;

                               const item = FB.FM.getFileInfo(uris[i])
                               _selectionBar.append(item.path, item)
                           }
                       }

        onExitClicked: clear()

        listDelegate: Maui.ListBrowserDelegate
        {
            isCurrentItem: false
            Maui.Theme.inherit: true
            width: ListView.view.width
            height: Maui.Style.iconSizes.big + Maui.Style.space.big
            imageSource: root.showThumbnails ? model.thumbnail : ""
            iconSource: model.icon
            label1.text: model.label
            label2.text: model.path
            label3.text: ""
            label4.text: ""
            checkable: true
            checked: true
            iconSizeHint: Maui.Style.iconSizes.big
            onToggled: _selectionBar.removeAtIndex(index)
            background: Item {}
            onClicked:
            {
                _selectionBar.selectionList.currentIndex = index
            }

            onPressAndHold: (mouse) => removeAtIndex(index)
        }

        Action
        {
            text: i18n("Rename")
            icon.name: "edit-rename"
            enabled: _selectionBar.count === 1
            onTriggered:
            {
                currentBrowser.renameItem()
            }
        }

        Action
        {
            text: i18n("Compress")
            icon.name: "utilities-file-archiver"
            onTriggered:
            {
               var dialog = _compressDialogComponent.createObject(root, ({'urls': selectionBar.uris}))
                dialog.open()
            }
        }

        Action
        {
            text: i18n("Tags")
            icon.name: "tag"
            onTriggered:
            {
                tagFiles(_selectionBar.uris)
            }
        }
    }

    Maui.TabView
    {
        id: _browserList
        anchors.fill: parent
        tabBar.margins: settings.floatyUI ? Maui.Style.contentMargins : 0
        tabBar.topMargin: Maui.Handy.isMobile ? Maui.Style.contentMargins  : 0
        showDefaultMenuEntries: false
        currentIndex : -1
        onNewTabClicked: openTab(currentBrowser ? currentBrowser.currentPath : FB.FM.homePath())
        onCloseTabClicked: (index) => closeTab(index)
        tabBar.showNewTabButton: false
        Keys.enabled: true
        Keys.forwardTo: currentTab ? [currentTab] : []
        background: null
        // tabBar.background: null

        tabViewButton: Maui.TabButton
        {
            id: _tabButton
            property Item tabView: _browserList
            // Keep a stable fallback index from the Repeater context.
            property int delegateIndex: (typeof index != "undefined" && index >= 0) ? index : -1
            readonly property int mindex:
                ((typeof _tabButton.TabBar.index !== "undefined" && _tabButton.TabBar.index >= 0)
                    ? _tabButton.TabBar.index
                    : (_tabButton.delegateIndex >= 0
                        ? _tabButton.delegateIndex
                        : ((typeof index !== "undefined" && index >= 0) ? index : -1)))
            // Force reevaluation of model-derived bindings after tab moves.
            readonly property int _modelPulse: _tabButton.tabView ? (_tabButton.tabView.currentIndex + _tabButton.tabView.count) : 0
            readonly property var tabInfo:
            {
                const _pulse = _tabButton._modelPulse
                const item = tabView && tabView.contentModel && mindex >= 0 ? tabView.contentModel.get(mindex) : null
                return item ? item.Maui.Controls : ({})
            }
            readonly property var _tabMenuActions:
            {
                const actions = [_detachTabAction]
                if (_tabButton.mindex > 0)
                    actions.push(_moveTabLeftAction)
                if (_tabButton.mindex >= 0 && _tabButton.mindex < (_tabButton.tabView.count - 1))
                    actions.push(_moveTabRightAction)
                return actions
            }

            autoExclusive: true
            width: tabView.mobile ? ListView.view.width : Math.max(160, Math.min(260, implicitWidth))
            checked: mindex === tabView.currentIndex
            text: tabInfo.title || ""
            icon.name: tabInfo.iconName || ""
            Maui.Controls.badgeText: tabInfo.badgeText
            Maui.Controls.status: tabInfo.status

            onClicked:
            {
                _browserList.setCurrentIndex(_tabButton.mindex)

                if(_browserList.currentItem)
                {
                    _browserList.currentItem.forceActiveFocus()
                }
            }

            onRightClicked:
            {
                if (_tabButton._tabMenuActions.length > 0)
                {
                    _tabMenu.show()
                }
            }
            onCloseClicked: _browserList.closeTabClicked(_tabButton.mindex)

            Action
            {
                id: _detachTabAction
                text: i18n("Detach Tab")
                onTriggered:
                {
                    const tabIndex = _tabButton.mindex
                    if (tabIndex < 0)
                        return

                    const tab = _browserList.contentModel.get(tabIndex)
                    const tabPath = tab && tab.browser && tab.browser.currentPath
                        ? tab.browser.currentPath
                        : (tab ? tab.path : "")

                    if (tabPath && inx.detachTabToNewWindow(tabPath))
                    {
                        closeTab(tabIndex)
                    }
                }
            }

            Action
            {
                id: _moveTabLeftAction
                text: i18n("Move Left")
                icon.name: "go-previous"
                onTriggered:
                {
                    const from = _tabButton.mindex
                    if (from > 0)
                        _browserList.moveTab(from, from - 1)
                }
            }

            Action
            {
                id: _moveTabRightAction
                text: i18n("Move Right")
                icon.name: "go-next"
                onTriggered:
                {
                    const from = _tabButton.mindex
                    if (from >= 0 && from < (_browserList.count - 1))
                        _browserList.moveTab(from, from + 1)
                }
            }

            Maui.ContextualMenu
            {
                id: _tabMenu

                Repeater
                {
                    model: _tabButton._tabMenuActions
                    delegate: MenuItem
                    {
                        action: modelData
                    }
                }
            }
        }

        tabBar.leftContent: [
            ToolButton
            {
                text: _browserList.count
                visible: _browserList.count > 1
                display: ToolButton.TextOnly
                font.bold: true
                font.pointSize: Maui.Style.fontSizes.small
                onClicked: _browserList.openOverview()

                background: Rectangle
                {
                    color: Maui.Theme.alternateBackgroundColor
                    radius: Maui.Style.radiusV
                }
            },

            ToolSeparator
            {
                visible: _browserList.count > 1
                topPadding: 10
                bottomPadding: 10
            }
        ]

        tabBar.rightContent: [
            ToolSeparator
            {
                visible: _browserList.count > 1
                topPadding: 10
                bottomPadding: 10
            },

            ToolButton
            {
                icon.name: "list-add"
                display: ToolButton.IconOnly
                onClicked: openTab(currentBrowser ? currentBrowser.currentPath : FB.FM.homePath())

                ToolTip.delay: 1000
                ToolTip.timeout: 5000
                ToolTip.visible: hovered
                ToolTip.text: i18n("New tab")
            }
        ]

    }

    function isUrlOpen(url : string) : bool
    {
        for(var i = 0; i < browserList.count; i++)
        {
            var tab = browserList.contentModel.get(i)
            for(var j = 0; j < tab.count; j++)
            {
                var view = tab.model.get(j)
                if(url === view.currentPath)
                {
                    return true;
                }
            }
        }

        return false;
    }
}
