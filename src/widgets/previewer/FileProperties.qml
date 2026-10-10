import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.mauikit.controls as Maui
import org.maui.index as Index


ColumnLayout
{
    id: control

    property alias url : _permissions.url

    Index.FileProperties
    {
        id: _permissions
    }

    Index.Permission
    {
        id: _ownerPermissions
        url: control.url
        user: Index.Permission.OWNER
    }

    Index.Permission
    {
        id: _groupPermissions
        url: control.url
        user: Index.Permission.GROUP
    }

    Index.Permission
    {
        id: _otherPermissions
        url: control.url
        user: Index.Permission.OTHER
    }

    Rectangle
    {
        id: permissionsCard
        Layout.fillWidth: true
        color: Maui.Theme.alternateBackgroundColor
        radius: Maui.Style.radiusV
        border.color: Maui.Theme.backgroundColor
        border.width: 1
        implicitHeight: permissionsLayout.implicitHeight + Maui.Style.contentMargins * 2

        ColumnLayout
        {
            id: permissionsLayout
            anchors.fill: parent
            anchors.margins: Maui.Style.contentMargins
            spacing: Maui.Style.space.small

            Maui.SectionHeader
            {
                Layout.fillWidth: true
                text1: i18n("Permissions")
                text2: i18n("Set file permissions to access this file")
                label2.wrapMode: Text.Wrap
            }

            Flow
            {
                Layout.fillWidth: true
                spacing: Maui.Style.space.small

                Maui.FlexSectionItem
                {
                    Layout.fillWidth: true
                    width: parent.width
                    flat: true
                    label1.text: i18n("Owner")
                    label2.wrapMode: Text.Wrap

                    Maui.ToolActions
                    {
                        Layout.fillWidth: true
                        autoExclusive: false
                        checkable: false

                        Action
                        {
                            text: i18n("Read")
                            checked: _ownerPermissions.read
                            onTriggered: _ownerPermissions.read = !_ownerPermissions.read
                        }

                        Action
                        {
                            text: i18n("Write")
                            checked: _ownerPermissions.write
                        }

                        Action
                        {
                            text: i18n("Execute")
                            checked: _ownerPermissions.execute
                        }
                    }
                }

                Maui.FlexSectionItem
                {
                    Layout.fillWidth: true
                    width: parent.width
                    flat: true
                    label1.text: i18n("Group")
                    label2.wrapMode: Text.Wrap

                    Maui.ToolActions
                    {
                        Layout.fillWidth: true
                        autoExclusive: false
                        checkable: false

                        Action
                        {
                            text: i18n("Read")
                            checked: _groupPermissions.read
                        }

                        Action
                        {
                            text: i18n("Write")
                            checked: _groupPermissions.write
                        }

                        Action
                        {
                            text: i18n("Execute")
                            checked: _groupPermissions.execute
                        }
                    }
                }

                Maui.FlexSectionItem
                {
                    Layout.fillWidth: true
                    width: parent.width
                    flat: true
                    label1.text: i18n("Everyone")
                    label2.wrapMode: Text.Wrap

                    Maui.ToolActions
                    {
                        Layout.fillWidth: true
                        autoExclusive: false
                        checkable: false

                        Action
                        {
                            text: i18n("Read")
                            checked: _otherPermissions.read
                        }

                        Action
                        {
                            text: i18n("Write")
                            checked: _otherPermissions.read
                        }

                        Action
                        {
                            text: i18n("Execute")
                            checked: _otherPermissions.execute
                        }
                    }
                }
            }
        }
    }

    Rectangle
    {
        id: ownershipCard
        Layout.fillWidth: true
        color: Maui.Theme.alternateBackgroundColor
        radius: Maui.Style.radiusV
        border.color: Maui.Theme.backgroundColor
        border.width: 1
        implicitHeight: ownershipLayout.implicitHeight + Maui.Style.contentMargins * 2

        ColumnLayout
        {
            id: ownershipLayout
            anchors.fill: parent
            anchors.margins: Maui.Style.contentMargins
            spacing: Maui.Style.space.small

            Maui.SectionHeader
            {
                Layout.fillWidth: true
                text1: i18n("Ownership")
                text2: i18n("Set file ownership.")
                label2.wrapMode: Text.Wrap
            }

            Flow
            {
                Layout.fillWidth: true
                spacing: Maui.Style.space.small

                Maui.FlexSectionItem
                {
                    Layout.fillWidth: true
                    width: parent.width
                    flat: true
                    label1.text: i18n("Owner")
                    label2.text: _permissions.owner
                    label2.wrapMode: Text.Wrap
                }

                Maui.FlexSectionItem
                {
                    Layout.fillWidth: true
                    width: parent.width
                    flat: true
                    label1.text: i18n("Group")
                    label2.text: _permissions.group
                    label2.wrapMode: Text.Wrap
                }
            }
        }
    }
}
