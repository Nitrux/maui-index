
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQml

import org.mauikit.controls as Maui

import org.mauikit.filebrowsing as FB
import org.mauikit.archiver as Arc

import ".."

Maui.ContextualMenu
{
    id: control
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    readonly property bool canBookmark: !control.isExec && control.isDir
    readonly property bool hasDirectoryActions: control.isDir
    readonly property url itemUrl: control.item && control.item.path ? control.item.path : ""
    readonly property bool canExtract: String(control.itemUrl).length > 0 && Arc.StaticArchive.isSupported(control.itemUrl)
    readonly property bool showDirectorySection: canBookmark || hasDirectoryActions
    readonly property bool isEncrypted: encryptionStatus === "encrypted_locked" || encryptionStatus === "encrypted_unlocked"
    readonly property bool isLocked: encryptionStatus === "encrypted_locked"
    readonly property bool isUnlocked: encryptionStatus === "encrypted_unlocked"
    readonly property var selectedUris: _browser.filterSelection(currentPath, control.item.path)

    /**
      *
      */
    property var item : ({})

    /**
      *
      */
    property int index : -1

    /**
      *
      */
    property bool isDir : false

    /**
      *
      */
    property bool isExec : false
    property string encryptionStatus: "unknown"
    property var activeUnlockDialog: null
    property bool actionInProgress: false
    property FB.Fscrypt fscrypt

    /**
      *
      */

    MenuItem
    {
        enabled: !control.isExec
        text: i18n("Select")
        icon.name: "edit-select"
        onTriggered:
        {
            _browser.addToSelection(control.item)
            if(Maui.Handy.isTouch)
                _browser.selectionMode = true
        }
    }

    MenuItem
    {
        id: openWithMenuItem
        enabled: !control.isExec
        text: i18n("Open with")
        icon.name: "document-open"

        onTriggered:
        {
            openWith(_browser.filterSelection(currentPath, control.item.path))
        }
    }

    MenuItem
    {
        enabled: !control.isExec && !control.isDir
        visible: enabled
        height: visible ? implicitHeight : -control.spacing
        text: i18n("Preview and Info")
        icon.name: "view-preview"
        onTriggered:
        {
            openPreview(control.item.path)
        }
    }

    MenuSeparator {}

    MenuItem
    {
        enabled: !control.isExec
        text: i18n("Rename")
        icon.name: "edit-rename"
        onTriggered:
        {
            currentBrowser.renameItem()
        }
    }

    MenuSeparator {}

    MenuItem
    {
        enabled: !control.isExec
        text: i18n("Copy")
        icon.name: "edit-copy"
        onTriggered:
        {
            currentBrowser.copy(control.selectedUris)
        }
    }

    MenuItem
    {
        enabled: !control.isExec
        text: i18n("Cut")
        icon.name: "edit-cut"
        onTriggered:
        {
            currentBrowser.cut(control.selectedUris)
        }
    }

    MenuItem
    {
        enabled: currentBrowser && currentBrowser.currentFMList && currentBrowser.currentFMList.clipboardHasContent
        text: i18n("Paste")
        icon.name: "edit-paste"
        onTriggered: _browser.paste()
    }

    MenuItem
    {
        enabled: !control.isExec
        text: i18n("Delete")
        icon.name: "edit-delete"
        onTriggered:
        {
            currentBrowser.remove(control.selectedUris)
        }
    }

    MenuSeparator
    {
        visible: showDirectorySection || canExtract
        height: visible ? implicitHeight : -control.spacing
    }

    MenuItem
    {
        enabled: canBookmark
        visible: enabled
        height: visible ? implicitHeight : -control.spacing
        text: i18n("Add Bookmark")
        icon.name: "bookmark-new"
        onTriggered:
        {
            _browser.bookmarkFolder([control.item.path])
        }
    }

    MenuSeparator
    {
        visible: hasDirectoryActions && canBookmark
        height: visible ? implicitHeight : -control.spacing
    }

    MenuItem
    {
        enabled: hasDirectoryActions
        visible: enabled
        height: visible ? implicitHeight : -control.spacing
        text: i18n("Open in New Tab")
        icon.name: "tab-new"
        onTriggered: root.openTab(control.item.path)
    }

    MenuItem
    {
        enabled: hasDirectoryActions
        visible: enabled
        height: visible ? implicitHeight : -control.spacing
        text: i18n("Open in New Window")
        icon.name: "window-new"
        onTriggered: inx.openNewWindow(control.item.path)
    }

    MenuItem
    {
        enabled: hasDirectoryActions && root.currentTab.count === 1
        visible: enabled
        height: visible ? implicitHeight : -control.spacing
        text: i18n("Open in Split View")
        icon.name: "view-split-left-right"
        onTriggered: root.currentTab.split(control.item.path, Qt.Horizontal)
    }

    MenuItem
    {
        enabled: control.isEncrypted && control.isUnlocked && !control.fscrypt.running
        visible: control.isEncrypted && control.isUnlocked
        height: visible ? implicitHeight : -control.spacing
        text: i18n("Lock directory")
        icon.name: "emblem-locked"
        onTriggered:
        {
            control.actionInProgress = true
            control.fscrypt.lockDirectory(control.itemUrl)
            control.close()
        }
    }

    MenuItem
    {
        enabled: control.isEncrypted && control.isLocked && !control.fscrypt.running
        visible: control.isEncrypted && control.isLocked
        height: visible ? implicitHeight : -control.spacing
        text: i18n("Unlock directory")
        icon.name: "emblem-unlocked"
        onTriggered: control.openUnlockDialog()
    }

    MenuItem
    {
        enabled: canExtract
        visible: enabled
        height: visible ? implicitHeight : -control.spacing
        text: i18n("Extract")
        icon.name: "archive-extract"
        onTriggered:
        {
            let props = ({ 'fileUrl': control.item.path,
                             'destination': currentBrowser.currentPath})
            var dialog = _extractDialogComponent.createObject(root, props)
            dialog.open()
        }
    }

    MenuSeparator
    {
        visible: hasDirectoryActions
        height: visible ? implicitHeight : -control.spacing
    }

    ColorsBar
    {
        id: colorBar
        padding: control.padding
        width: parent.width
        enabled: hasDirectoryActions
        visible: enabled
        height: visible ? implicitHeight : -control.spacing
        Binding on folderColor {
            value: control.item.icon
            restoreMode: Binding.RestoreBindingOrValue
        }

        onFolderColorPicked:
        {
            _browser.currentFMList.setDirIcon(control.index, color)
            control.close()
        }
    }

    Component
    {
        id: _unlockDialogComponent

        Maui.InfoDialog
        {
            id: _unlockDialog
            property url directory
            property string errorMessage: ""

            title: i18n("Unlock Directory")
            message: i18n("Enter the passphrase to unlock this directory.")
            standardButtons: Dialog.Apply | Dialog.Cancel
            template.iconVisible: false

            Maui.PasswordField
            {
                id: _unlockPassphrase
                enabled: !control.fscrypt.running
                Layout.fillWidth: true
                echoMode: TextInput.Password
                passwordMaskDelay: 0
                Maui.Controls.title: i18n("Passphrase")
                onTextChanged: _unlockDialog.updateButtons()
                onAccepted: _unlockDialog.submit()
            }

            Maui.Chip
            {
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? implicitHeight : -_unlockDialog.spacing
                visible: _unlockDialog.errorMessage.length > 0
                text: _unlockDialog.errorMessage
                color: Maui.Theme.negativeBackgroundColor
                label.horizontalAlignment: Text.AlignLeft
                label.wrapMode: Text.Wrap
            }

            onOpened:
            {
                updateButtons()
                _unlockPassphrase.forceActiveFocus()
            }

            onApplied: submit()

            function submit()
            {
                if (_unlockPassphrase.text.length === 0)
                {
                    errorMessage = i18n("Passphrase can not be empty.")
                    updateButtons()
                    return
                }

                errorMessage = ""
                control.fscrypt.unlockDirectory(directory, _unlockPassphrase.text)
                _unlockPassphrase.clear()
                updateButtons()
            }

            onRejected:
            {
                _unlockPassphrase.clear()
                if (control.fscrypt.running)
                    control.fscrypt.cancel()
                close()
            }

            Connections
            {
                target: control.fscrypt

                function onRunningChanged()
                {
                    _unlockDialog.updateButtons()
                }

                function onFinished(success, message)
                {
                    if (!_unlockDialog.visible)
                        return

                    if (success)
                    {
                        _browser.currentFMList.refresh()
                        notify("emblem-unlocked", i18n("Encryption"), i18n("Directory unlocked."))
                        _unlockDialog.close()
                    }
                    else
                    {
                        _unlockDialog.errorMessage = message
                        _unlockDialog.updateButtons()
                    }
                }
            }

            function updateButtons()
            {
                const applyButton = standardButton(Dialog.Apply)
                if (applyButton)
                    applyButton.enabled = _unlockPassphrase.text.length > 0 && !control.fscrypt.running

                const cancelButton = standardButton(Dialog.Cancel)
                if (cancelButton)
                    cancelButton.enabled = true
            }

            onClosed:
            {
                if (control.activeUnlockDialog === _unlockDialog)
                    control.activeUnlockDialog = null
                destroy()
            }
        }
    }

    Connections
    {
        target: control.fscrypt

        function onStatusChanged(directory, status)
        {
            if (String(directory) === String(control.itemUrl))
                control.encryptionStatus = status
        }

        function onFinished(success, message)
        {
            if (!control.actionInProgress || control.activeUnlockDialog)
                return

            control.actionInProgress = false
            if (success)
            {
                _browser.currentFMList.refresh()
                notify("emblem-locked", i18n("Encryption"), i18n("Directory locked."))
            }
            else
            {
                control.fscrypt.invalidateStatus(control.itemUrl)
                notify("dialog-error", i18n("Encryption"), message)
            }
        }
    }

    onClosed:
    {
        control.index = -1
    }

    function openUnlockDialog()
    {
        if (!isLocked || activeUnlockDialog)
            return

        activeUnlockDialog = _unlockDialogComponent.createObject(root, ({directory: itemUrl}))
        activeUnlockDialog.open()
    }

    function showFor(index)
    {
        control.item = _browser.currentFMList.get(index)
        if(item.path.startsWith("tags://") || item.path.startsWith("applications://"))
            return

        if(item)
        {
            control.index = index
            control.isDir = item.isdir == true || item.isdir == "true"
            control.isExec = item.executable == true || item.executable == "true"
            control.encryptionStatus = control.isDir ? control.fscrypt.cachedStatus(control.itemUrl) : "unknown"
            if (control.isDir)
                control.fscrypt.requestStatus(control.itemUrl)
            control.show()
        }
    }
}
