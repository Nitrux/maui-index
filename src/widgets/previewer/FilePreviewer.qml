import QtQuick
import QtQuick.Layouts

import org.mauikit.controls as Maui

import org.mauikit.filebrowsing as FB
import org.mauikit.archiver as Arc

Item
{
    id: control
    focus: true
    implicitHeight: previewLayout.implicitHeight
    property url currentUrl: ""

    ListModel { id: infoModel }
    readonly property string title : String(iteminfo.label || "")
    property var iteminfo : ({})

    property bool isDir : false

    onCurrentUrlChanged:
    {
        iteminfo = FB.FM.getFileInfo(currentUrl)
        const resolvedMime = String(iteminfo.mime || "")
        const resolvedThumb = String(iteminfo.thumbnail || "")

        if (resolvedThumb.length === 0
                && (FB.FM.checkFileType(FB.FMList.VIDEO, resolvedMime)
                    || FB.FM.checkFileType(FB.FMList.AUDIO, resolvedMime)))
        {
            iteminfo.thumbnail = "image://thumbnailer/" + currentUrl
        }

        initModel()

        show()
    }

    ColumnLayout
    {
        id: previewLayout
        anchors.fill: parent

        spacing: Maui.Style.defaultSpacing

        Loader
        {
            id: previewLoader
            Layout.fillWidth: true
            Layout.preferredHeight: Maui.Style.units.gridUnit * 24
            Layout.topMargin: control.isDir ? Maui.Style.space.large : 0
            asynchronous: true
        }

        FB.TagsBar
        {
            Layout.fillWidth: true
            visible: count > 0
            allowEditMode: true
            list.urls: [control.currentUrl]
            list.strict: false

            onTagRemovedClicked: (index) => list.removeFromUrls(index)
            onTagsEdited: (tags) => list.updateToUrls(tags)
        }

        Maui.SectionGroup
        {
            Layout.fillWidth: true
            Layout.topMargin: Maui.Style.space.medium
            title: i18n("Details")
            description: i18n("File information")

            Flow
            {
                Layout.fillWidth: true
                spacing: Maui.Style.defaultSpacing

                Repeater
                {
                    model: infoModel
                    delegate: Maui.SectionItem
                    {
                        width: model.key === "Path" || model.key === "Symbolic Link"
                               ? parent.width
                               : Math.min(implicitWidth, parent.width / 2)
                        visible: model.value && String(model.value).length > 0
                        flat: false
                        label1.text: model.key
                        label2.text: model.value
                        label2.wrapMode: Text.WrapAnywhere
                        label2.elide: Text.ElideNone
                    }
                }
            }
        }

        FileProperties
        {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
            url: control.currentUrl
            spacing: parent.spacing
        }
    }

    function show()
    {
        control.isDir = iteminfo.isdir == "true"

        var source = "DefaultPreview.qml"
        if(FB.FM.checkFileType(FB.FMList.AUDIO, iteminfo.mime))
        {
            source = "AudioPreview.qml"
        }else if(FB.FM.checkFileType(FB.FMList.VIDEO, iteminfo.mime))
        {
            source = "VideoPreview.qml"
        }else if(FB.FM.checkFileType(FB.FMList.TEXT, iteminfo.mime))
        {
            source = "TextPreview.qml"
        }else if(FB.FM.checkFileType(FB.FMList.IMAGE, iteminfo.mime))
        {
            source = "ImagePreview.qml"
        }else if(FB.FM.checkFileType(FB.FMList.DOCUMENT, iteminfo.mime))
        {
            source = "DocumentPreview.qml"
        }else if(Arc.StaticArchive.isSupported(iteminfo.path))
        {
            source = "CompressedPreview.qml"
        }else if(FB.FM.checkFileType(FB.FMList.FONT, iteminfo.mime))
        {
            source = "FontPreviewer.qml"
        }else
        {
            source = "DefaultPreview.qml"
        }

        if(previewLoader.source == source)
        {
            return
        }
        previewLoader.source = source
    }

    function initModel()
    {
        infoModel.clear()
        // infoModel.append({key: "Name", value: iteminfo.label})
        infoModel.append({key: "Type", value: iteminfo.mime})
        infoModel.append({key: "Date", value: Qt.formatDateTime(new Date(iteminfo.date), "d MMM yyyy")})
        infoModel.append({key: "Modified", value: Qt.formatDateTime(new Date(iteminfo.modified), "d MMM yyyy")})
        infoModel.append({key: "Last Read", value: Qt.formatDateTime(new Date(iteminfo.lastread), "d MMM yyyy")})
        infoModel.append({key: "Owner", value: String(iteminfo.owner || "")})
        infoModel.append({key: "Group", value: String(iteminfo.group || "")})
        infoModel.append({key: "Size", value: Maui.Handy.formatSize(iteminfo.size)})
        infoModel.append({key: "Symbolic Link", value: displayPath(iteminfo.symlink)})
        infoModel.append({key: "Path", value: displayPath(iteminfo.path)})
        // infoModel.append({key: "Thumbnail", value: iteminfo.thumbnail})
        // infoModel.append({key: "Icon Name", value: iteminfo.icon})
    }

    function displayPath(path)
    {
        const value = String(path || "")

        if (value.startsWith("file://"))
            return decodeURIComponent(value.slice(7))

        return value
    }

    function setData(url)
    {
        control.currentUrl = url
    }
}
