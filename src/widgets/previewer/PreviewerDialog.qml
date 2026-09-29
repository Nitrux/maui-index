import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls as Maui

import org.mauikit.filebrowsing as FB

Maui.PopupPage
{
    id: control
    title: _previewer.title
    readonly property alias previewer : _previewer
    property FB.Fscrypt fscrypt: null
    hint: 1
    maxWidth: Maui.Style.units.gridUnit * 32
    maxHeight: implicitHeight
    focus: true

    page.headerMargins: Maui.Style.defaultPadding
    page.footerMargins: Maui.Style.defaultPadding
    page.floatingHeader: true

    onOpened: _previewer.forceActiveFocus()

    FilePreviewer
    {
        id: _previewer
        fscrypt: control.fscrypt
        Layout.fillWidth: true
        focus: true
        Keys.enabled: true
        Keys.onEscapePressed: (event) =>
                              {
                                  control.close()
                                  event.accepted= true
                              }
        Keys.onLeftPressed: _previousAction.trigger()
        Keys.onRightPressed: _nextAction.trigger()
    }
    
    footBar.rightContent: [
        ToolButton
        {
            icon.name: "document-open"
            display: AbstractButton.IconOnly
            focusPolicy: Qt.NoFocus
            ToolTip.visible: hovered
            ToolTip.text: i18n("Open")
            onClicked:
            {
                FB.FM.openUrl(_previewer.currentUrl)
            }
        }
    ]
    
    footBar.leftContent: Maui.ToolActions
    {
        checkable: false
        Action
        {
            id: _previousAction
            icon.name:"go-previous"
            shortcut: StandardKey.PreviousChild
            onTriggered:
            {
                currentBrowser.previousItem()
                _previewer.currentUrl = currentBrowser.currentFMModel.get(currentBrowser.currentIndex).url
            }
        }
        
        Action
        {
            id: _nextAction
            icon.name:"go-next"
            shortcut: StandardKey.NextChild

            onTriggered:
            {
                currentBrowser.nextItem()
                _previewer.currentUrl = currentBrowser.currentFMModel.get(currentBrowser.currentIndex).url
            }
        }
    }
    
    function forceActiveFocus()
    {
        _previewer.forceActiveFocus()
    }
}
