import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls as Maui
import org.mauikit.filebrowsing as FB

Maui.SettingsDialog
{
    id: control

    Maui.SectionGroup
    {
        title: i18n("Behaviour")
        //        description: i18n("Configure the app plugins and behavior.")

        Maui.FlexSectionItem
        {
            label1.text:  i18n("Save Session")
            label2.text: i18n("Save and restore tabs.")

            Switch
            {
                checkable: true
                checked:  settings.restoreSession
                onToggled: settings.restoreSession = !settings.restoreSession
            }
        }

        Maui.FlexSectionItem
        {
            label1.text:  i18n("Dynamic Preferences")
            label2.text: i18n("Save custom preferences per directory, otherwise use the default preferences.")

            Switch
            {
                checkable: true
                checked:  settings.dirConf
                onToggled: settings.dirConf = !settings.dirConf
            }
        }
    }

    Maui.SectionGroup
    {
        title: i18n("Previews")
        //        description: i18n("Configure the app plugins and behavior.")

        Maui.FlexSectionItem
        {
            enabled: !Maui.Handy.isMobile
            label1.text: i18n("Open in Window")
            label2.text: i18n("Show the file previews in a new window.")

            Switch
            {
                checkable: true
                checked:  appSettings.previewerWindow
                onToggled: appSettings.previewerWindow = !appSettings.previewerWindow
            }
        }

        Maui.FlexSectionItem
        {
            label1.text:  i18n("Autoplay")
            label2.text: i18n("Auto start playing audio and video file previews.")

            Switch
            {
                checkable: true
                checked:  appSettings.autoPlayPreviews
                onToggled: appSettings.autoPlayPreviews = !appSettings.autoPlayPreviews
            }
        }

        Maui.FlexSectionItem
        {
            label1.text:  i18n("Prefer Preview")
            label2.text: i18n("Open files in a preview mode instead of opening them in a dedicated application.")

            Switch
            {
                checkable: true
                checked:  appSettings.previewFiles
                onToggled: appSettings.previewFiles = !appSettings.previewFiles
            }
        }
    }

    Maui.SectionGroup
    {
        title: i18n("Browsing & Navigation")

        Maui.FlexSectionItem
        {
            label1.text: i18n("Thumbnails")
            label2.text: i18n("Show previews of images, videos and PDF files.")

            Switch
            {
                checkable: true
                checked:  settings.showThumbnails
                onToggled: settings.showThumbnails = ! settings.showThumbnails
            }
        }

        Maui.FlexSectionItem
        {
            label1.text:  i18n("View Type")
            label2.text: i18n("Default view type.")

            Maui.ToolActions
            {
                autoExclusive: true
                expanded: true
                display: ToolButton.IconOnly

                Action
                {
                    text: i18n("List")
                    icon.name: "view-list-details"
                    checked: appSettings.viewType === FB.FMList.LIST_VIEW
                    checkable: true
                    onTriggered:
                    {
                        appSettings.viewType = FB.FMList.LIST_VIEW
                    }
                }

                Action
                {
                    text: i18n("Grid")
                    icon.name: "view-list-icons"
                    checked:  appSettings.viewType === FB.FMList.ICON_VIEW
                    checkable: true

                    onTriggered:
                    {
                        appSettings.viewType = FB.FMList.ICON_VIEW
                    }
                }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text:  i18n("Sort")
            label2.text: i18n("Default sorting value.")

            ComboBox
            {
                implicitWidth: Math.max(Maui.Style.units.gridUnit * 7, contentItem.implicitWidth + leftPadding + rightPadding)
                model: [
                    i18n("Type"),
                    i18n("Date"),
                    i18n("Modified"),
                    i18n("Size"),
                    i18n("Name")
                ]
                currentIndex: switch(sortSettings.sortBy)
                              {
                              case FB.FMList.MIME: return 0
                              case FB.FMList.DATE: return 1
                              case FB.FMList.MODIFIED: return 2
                              case FB.FMList.SIZE: return 3
                              case FB.FMList.LABEL: return 4
                              default: return 2
                              }

                onActivated: (index) =>
                {
                    switch(index)
                    {
                    case 0:
                        sortSettings.sortBy = FB.FMList.MIME
                        break
                    case 1:
                        sortSettings.sortBy = FB.FMList.DATE
                        break
                    case 2:
                        sortSettings.sortBy = FB.FMList.MODIFIED
                        break
                    case 3:
                        sortSettings.sortBy = FB.FMList.SIZE
                        break
                    case 4:
                        sortSettings.sortBy = FB.FMList.LABEL
                        break
                    }
                }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Folders First")
            label2.text: i18n("Show folders before files when sorting.")

            Switch
            {
                checkable: true
                checked: sortSettings.foldersFirst
                onToggled: sortSettings.foldersFirst = checked
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Group")
            label2.text: i18n("Group items by the selected sorting mode.")

            Switch
            {
                checkable: true
                checked: sortSettings.group
                onToggled: sortSettings.group = checked
            }
        }
    }

    Maui.SectionGroup
    {
        title: i18n("Interface")
        //        description: i18n("Configure the app UI.")

        Maui.FlexSectionItem
        {
            label1.text: i18n("Grid Items Size")
            label2.text: i18n("Size of the grid view.")

            Maui.ToolActions
            {
                expanded: true
                autoExclusive: true
                display: ToolButton.TextOnly

                //                currentIndex: appSettings.gridSize

                //                Action
                //                {
                //                    text: i18n("S")
                //                    onTriggered: appSettings.gridSize = 0
                //                }

                Action
                {
                    text: i18n("M")
                    checked: appSettings.gridSize === 1
                    onTriggered: appSettings.gridSize = 1
                }

                Action
                {
                    text: i18n("L")
                    checked: appSettings.gridSize === 2
                    onTriggered: appSettings.gridSize = 2
                }

                Action
                {
                    text: i18n("X")
                    checked: appSettings.gridSize === 3
                    onTriggered: appSettings.gridSize = 3
                }

                Action
                {
                    text: i18n("XL")
                    checked: appSettings.gridSize === 4
                    onTriggered: appSettings.gridSize = 4
                }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("List Items Size")
            label2.text: i18n("Size of the list view.")

            Maui.ToolActions
            {
                expanded: true
                autoExclusive: true
                display: ToolButton.TextOnly

                Action
                {
                    text: i18n("S")
                    onTriggered: appSettings.listSize = 0
                    checked: appSettings.listSize === 0
                }

                Action
                {
                    text: i18n("M")
                    onTriggered: appSettings.listSize = 1
                    checked: appSettings.listSize === 1
                }

                Action
                {
                    text: i18n("L")
                    onTriggered: appSettings.listSize = 2
                    checked: appSettings.listSize === 2
                }

                Action
                {
                    text: i18n("X")
                    onTriggered: appSettings.listSize = 3
                    checked: appSettings.listSize === 3
                }
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Overview")
            label2.text: i18n("Use overview mode as default on launch.")

            Switch
            {
                checked:  appSettings.overviewStart
                onToggled: appSettings.overviewStart = !appSettings.overviewStart
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Actions Bar")
            label2.text: i18n("Show the actions bar in the main view. Otherwise it will be shown in the application menu.")

            Switch
            {
                checked:  appSettings.showActionsBar
                onToggled: appSettings.showActionsBar = !appSettings.showActionsBar
            }
        }
    }

    Maui.SectionGroup
    {
        title: i18n("Terminal")
        description: i18n("Embedded terminal options.")
        Maui.FlexSectionItem
        {
            label1.text:  i18n("Sync Terminal")
            label2.text: i18n("Sync the terminal current working directory to the browser location.")

            Switch
            {
                checkable: true
                checked:  settings.syncTerminal
                onToggled: settings.syncTerminal = !settings.syncTerminal
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Adaptive Color Scheme")
            label2.text: i18n("Colors based on the current style.")

            Switch
            {
                checked: appSettings.terminalFollowsColorScheme
                onToggled: appSettings.terminalFollowsColorScheme = !appSettings.terminalFollowsColorScheme
            }
        }

        Maui.FlexSectionItem
        {
            label1.text: i18n("Color Scheme")
            label2.text: i18n("Change the color scheme of the terminal.")
            enabled: !appSettings.terminalFollowsColorScheme

            ToolButton
            {
                checkable: true
                icon.name: "go-next"
                onToggled:
                {
                    var component = Qt.createComponent("TerminalColorSchemes.qml");
                    var page = component.createObject(control);
                    control.addPage(page)
                }
            }
        }
    }

    Maui.FlexSectionItem
    {
        label1.text: i18n("Quick places")
        label2.text: i18n("Access to standard locations.")

        ToolButton
        {
            checkable: true
            icon.name: "go-next"
            onToggled: control.addPage(_sidebarPlacesComponent)
        }
    }


    Component
    {
        id: _sidebarPlacesComponent

        Maui.SettingsPage
        {
            title: i18n("Places")

            Maui.SectionGroup
            {
                title: i18n("Places")
                //                description: i18n("Toggle sidebar sections.")

                Maui.FlexSectionItem
                {
                    label1.text: i18n("Quick places")
                    label2.text: i18n("Access to standard locations.")

                    Switch
                    {
                        checkable: true
                        checked: appSettings.quickSidebarSection
                        onToggled: appSettings.quickSidebarSection = !appSettings.quickSidebarSection
                    }
                }

                Maui.FlexSectionItem
                {
                    label1.text: i18n("Bookmarks")
                    label2.text: i18n("Access to standard locations.")

                    Switch
                    {
                        checkable: true
                        checked: appSettings.sidebarSections.indexOf(FB.FMList.BOOKMARKS_PATH) >= 0
                        onToggled:
                        {
                            toggleSection(FB.FMList.BOOKMARKS_PATH)
                        }
                    }
                }

                Maui.FlexSectionItem
                {
                    label1.text: i18n("Remote")
                    label2.text: i18n("Access to network locations.")

                    Switch
                    {
                        checkable: true
                        checked: appSettings.sidebarSections.indexOf(FB.FMList.REMOTE_PATH)>= 0
                        onToggled:
                        {
                            toggleSection(FB.FMList.REMOTE_PATH)
                        }
                    }
                }

                Maui.FlexSectionItem
                {
                    label1.text: i18n("Removable")
                    label2.text: i18n("Access to USB sticks and SD Cards.")

                    Switch
                    {
                        checkable: true
                        checked: appSettings.sidebarSections.indexOf(FB.FMList.REMOVABLE_PATH)>= 0
                        onToggled:
                        {
                            toggleSection(FB.FMList.REMOVABLE_PATH)
                        }
                    }
                }

                Maui.FlexSectionItem
                {
                    label1.text: i18n("Devices")
                    label2.text: i18n("Access drives.")

                    Switch
                    {
                        checkable: true
                        checked: appSettings.sidebarSections.indexOf(FB.FMList.DRIVES_PATH)>= 0
                        onToggled:
                        {
                            toggleSection(FB.FMList.DRIVES_PATH)
                        }
                    }
                }
            }
        }
    }
}
