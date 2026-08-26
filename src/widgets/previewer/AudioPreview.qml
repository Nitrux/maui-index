import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QtMultimedia

import org.mauikit.controls as Maui

Item
{
    id: control

    property alias player: player
    property string metaArtworkUrl: ""
    readonly property string fileArtworkUrl: String(iteminfo.thumbnail || "")
    readonly property string defaultAudioIcon: "audio-x-generic"
    readonly property string defaultCoverSource: "qrc:/assets/cover_64x64.svg"
    readonly property bool fileArtworkFromThumbnailer: control.fileArtworkUrl.startsWith("image://thumbnailer/")
    readonly property bool fileArtworkProbeFailed: control.fileArtworkFromThumbnailer
        && (_artworkProbe.status === Image.Error
            || (_artworkProbe.status === Image.Ready && _artworkProbe.paintedWidth <= 0 && _artworkProbe.paintedHeight <= 0))
    readonly property string artworkSource: (() =>
                                            {
                                                if (control.metaArtworkUrl.length > 0)
                                                    return control.metaArtworkUrl

                                                if (control.fileArtworkUrl.length > 0 && !control.fileArtworkProbeFailed)
                                                    return control.fileArtworkUrl

                                                return control.defaultCoverSource
                                            })()

    Image
    {
        id: _artworkProbe
        visible: false
        asynchronous: true
        source: control.fileArtworkUrl
        sourceSize.width: 256
        sourceSize.height: 256
        cache: false
    }

    MediaPlayer
    {
        id: player
        source: currentUrl
        autoPlay: appSettings.autoPlayPreviews
        property string title: String(player.metaData.value(MediaMetaData.Title) || "")

        audioOutput: AudioOutput {}

        onSourceChanged:
        {
            control.metaArtworkUrl = ""
        }

        onTitleChanged:
        {
            infoModel.clear()
            appendInfoEntry("Title", player.metaData.value(MediaMetaData.Title))
            appendInfoEntry("Artist", player.metaData.value(MediaMetaData.AlbumArtist))
            appendInfoEntry("Album", player.metaData.value(MediaMetaData.AlbumTitle))
            appendInfoEntry("Author", player.metaData.value(MediaMetaData.Author))
            appendInfoEntry("Codec", player.metaData.value(MediaMetaData.AudioCodec))
            appendInfoEntry("Copyright", player.metaData.value(MediaMetaData.Copyright))
            appendInfoEntry("Duration", formatDuration(player.metaData.value(MediaMetaData.Duration)))
            appendInfoEntry("Track", player.metaData.value(MediaMetaData.TrackNumber))
            appendInfoEntry("Year", player.metaData.value(MediaMetaData.Date))
            appendInfoEntry("Genre", player.metaData.value(MediaMetaData.Genre))
        }

        onMetaDataChanged: control.updateMetaArtworkUrl()
        onDurationChanged: control.updateDurationInfo()
    }

    ColumnLayout
    {
        anchors.centerIn: parent
        width: Math.min(parent.width, 200)
        spacing: Maui.Style.space.medium

        Item
        {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Layout.preferredHeight: 200
            Layout.preferredWidth: 200

            Maui.IconItem
            {
                height: parent.height
                width: parent.width
                iconSizeHint: height
                iconSource: String(iteminfo.icon || control.defaultAudioIcon)
                imageSource: control.artworkSource
            }
        }

        Maui.ListItemTemplate
        {
            Layout.fillWidth: true
            label1.text: String(player.metaData.value(MediaMetaData.Title) || "")
            label1.font.weight: Font.DemiBold
            label1.font.pointSize: Maui.Style.fontSizes.big

            label2.text: String(player.metaData.value(MediaMetaData.AlbumArtist) || player.metaData.value(MediaMetaData.AlbumTitle) || "")
        }

        RowLayout
        {
            Layout.fillWidth: true

            ToolButton
            {
                icon.name: player.playbackState === MediaPlayer.PlayingState ? "media-playback-pause" : "media-playback-start"
                onClicked:
                {
                    if(player.playbackState === MediaPlayer.PlayingState)
                        player.pause()
                    else
                        player.play()
                }
            }

            Slider
            {
                id: _slider
                Layout.fillWidth: true
                orientation: Qt.Horizontal
                enabled: player.seekable
                from: 0
                to: 1000
                value: (1000 * player.position) / player.duration
                onMoved: player.position = ((_slider.value / 1000) * player.duration)
            }
        }
    }

    function updateMetaArtworkUrl()
    {
        var resolved = ""
        const keys = player.metaData.keys()

        for (var i = 0; i < keys.length; i++)
        {
            const key = keys[i]
            const keyName = String(player.metaData.metaDataKeyToString(key) || "")
            if (keyName.indexOf("CoverArtUrl") === -1 && keyName.indexOf("ThumbnailUrl") === -1)
                continue

            const value = String(player.metaData.value(key) || "")
            if (value.startsWith("file:") || value.startsWith("qrc:") || value.startsWith("http:") || value.startsWith("https:") || value.startsWith("data:image/"))
            {
                resolved = value
                break
            }
        }

        if (control.metaArtworkUrl !== resolved)
        {
            control.metaArtworkUrl = resolved
        }
    }

    function appendInfoEntry(key, rawValue)
    {
        const value = rawValue === undefined || rawValue === null ? "" : String(rawValue)
        infoModel.append({key: key, value: value})
    }
    function updateDurationInfo()
    {
        if (player.duration <= 0)
            return

        const value = formatDuration(player.duration)
        for (var i = 0; i < infoModel.count; ++i)
        {
            if (infoModel.get(i).key !== "Duration")
                continue

            infoModel.setProperty(i, "value", value)
            return
        }

        infoModel.append({key: "Duration", value: value})
    }

    function formatDuration(milliseconds)
    {
        const value = Number(milliseconds)
        return isNaN(value) || value <= 0 ? "" : Maui.Handy.formatTime(Math.floor(value / 1000))
    }
}
