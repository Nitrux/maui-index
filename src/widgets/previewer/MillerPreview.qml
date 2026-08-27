import QtQuick
import QtQuick.Layouts

import org.mauikit.controls as Maui
import org.mauikit.filebrowsing as FB
import org.maui.index as Index

ColumnLayout
{
    id: control

    property url currentUrl: ""
    property var iteminfo: ({})
    readonly property string title: String(iteminfo.label || "")
    readonly property bool isDir: iteminfo.isdir == "true"

    implicitHeight: previewLayout.implicitHeight

    ListModel
    {
        id: infoModel
    }

    Index.DirInfo
    {
        id: directoryInfo
        onSizeChanged: control.updateDirectorySize()
    }

    onCurrentUrlChanged:
    {
        iteminfo = FB.FM.getFileInfo(currentUrl)
        directoryInfo.url = control.isDir ? currentUrl : ""
        initModel()
        _preview.setData(currentUrl)
    }

    ColumnLayout
    {
        id: previewLayout
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Maui.Style.space.medium

        Maui.SectionHeader
        {
            Layout.fillWidth: true
            text1: control.title
            text2: i18n("File preview")
            label2.wrapMode: Text.Wrap
        }

        Rectangle
        {
            id: previewCard
            Layout.fillWidth: true
            Layout.leftMargin: Maui.Style.space.small
            Layout.rightMargin: Maui.Style.space.small
            color: Maui.Theme.alternateBackgroundColor
            radius: Maui.Style.radiusV
            border.color: Maui.Theme.backgroundColor
            border.width: 1
            implicitHeight: previewCardLayout.implicitHeight + Maui.Style.contentMargins * 2

            ColumnLayout
            {
                id: previewCardLayout
                anchors.fill: parent
                anchors.margins: Maui.Style.contentMargins
                spacing: Maui.Style.space.small

                Maui.SectionHeader
                {
                    id: previewHeader
                    Layout.fillWidth: true
                    text1: i18n("Preview")
                    text2: String(iteminfo.mime || "")
                    label2.wrapMode: Text.Wrap
                }

                FilePreviewer
                {
                    id: _preview
                    Layout.fillWidth: true
                    Layout.bottomMargin: previewHeader.implicitHeight + previewCardLayout.spacing
                    compact: true
                }
            }
        }

        Rectangle
        {
            id: detailsCard
            Layout.fillWidth: true
            Layout.leftMargin: Maui.Style.space.small
            Layout.rightMargin: Maui.Style.space.small
            visible: infoModel.count > 0
            color: Maui.Theme.alternateBackgroundColor
            radius: Maui.Style.radiusV
            border.color: Maui.Theme.backgroundColor
            border.width: 1
            implicitHeight: detailsCardLayout.implicitHeight + Maui.Style.contentMargins * 2

            ColumnLayout
            {
                id: detailsCardLayout
                anchors.fill: parent
                anchors.margins: Maui.Style.contentMargins
                spacing: Maui.Style.space.small

                Maui.SectionHeader
                {
                    Layout.fillWidth: true
                    text1: i18n("Details")
                    text2: i18n("File information")
                    label2.wrapMode: Text.Wrap
                }

                Flow
                {
                    Layout.fillWidth: true
                    spacing: Maui.Style.space.small

                    Repeater
                    {
                        model: infoModel
                        delegate: Maui.FlexSectionItem
                        {
                            Layout.fillWidth: true
                            width: model.key === "Path"
                                   ? parent.width
                                   : Math.min(implicitWidth, parent.width / 2)
                            visible: model.value && String(model.value).length > 0
                            flat: true
                            label1.text: model.key
                            label2.text: model.value
                            label2.wrapMode: Text.Wrap
                            label2.elide: Text.ElideNone
                        }
                    }
                }
            }
        }
    }

    function initModel()
    {
        infoModel.clear()
        infoModel.append({key: "Type", value: String(iteminfo.mime || "")})
        infoModel.append({key: "Modified", value: iteminfo.modified ? Qt.formatDateTime(new Date(iteminfo.modified), "d MMM yyyy") : ""})
        infoModel.append({key: control.isDir ? "Contents Size" : "Size", value: control.isDir ? "" : Maui.Handy.formatSize(iteminfo.size)})
        infoModel.append({key: "Path", value: displayPath(iteminfo.path)})
    }

    function updateDirectorySize()
    {
        if (!control.isDir)
            return

        for (var i = 0; i < infoModel.count; ++i)
        {
            if (infoModel.get(i).key !== "Contents Size")
                continue

            infoModel.setProperty(i, "value", directoryInfo.sizeString)
            return
        }
    }

    function displayPath(path)
    {
        const value = String(path || "")
        return value.startsWith("file://") ? decodeURIComponent(value.slice(7)) : value
    }

    function setData(url)
    {
        control.currentUrl = url
    }
}
