import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QtMultimedia

import org.mauikit.controls as Maui

Maui.Page
{
    id: control
    property alias player : player
    headBar.visible: false
    background: null

    MediaPlayer
    {
        id: player
        source: currentUrl
        autoPlay: appSettings.autoPlayPreviews
        loops: 3
        audioOutput: AudioOutput {}
        videoOutput: _videoOutput

        onSourceChanged:
        {
            console.log("[Index][VideoPreview] source changed", source)
        }

        onMediaStatusChanged:
        {
            console.log("[Index][VideoPreview] mediaStatus", mediaStatus, "duration=", duration, "seekable=", seekable)
        }

        onPlaybackStateChanged:
        {
            console.log("[Index][VideoPreview] playbackState", playbackState, "position=", position)
        }

        onErrorOccurred: (error, errorString) =>
        {
            console.log("[Index][VideoPreview] error", error, errorString)
        }
    }

    VideoOutput
    {
        id: _videoOutput
        anchors.fill: parent
        // This preview is often loaded in a plain Loader (not a StackView), so keep video output visible.
        visible: control.visible
        fillMode: VideoOutput.PreserveAspectFit

        Component.onCompleted:
        {
            console.log("[Index][VideoPreview] VideoOutput ready", "width=", width, "height=", height)
        }
    }

    Connections
    {
        target: player
        function onMetaDataChanged()
        {
            console.log("[Index][VideoPreview] metadata changed", player.metaData.value(MediaMetaData.VideoCodec), player.metaData.value(MediaMetaData.Resolution))
            infoModel.append({key: "Title", value: player.metaData.value(MediaMetaData.Title)})
            infoModel.append({key: "Author", value: player.metaData.value(MediaMetaData.Author)})
            infoModel.append({key: "Audio Codec", value: player.metaData.value(MediaMetaData.AudioCodec)})
            infoModel.append({key: "Video Codec", value: player.metaData.value(MediaMetaData.VideoCodec)})
            infoModel.append({key: "Copyright", value: player.metaData.value(MediaMetaData.Copyright)})
            infoModel.append({key: "Duration", value: player.metaData.value(MediaMetaData.Duration)})
            infoModel.append({key: "Framerate", value: player.metaData.value(MediaMetaData.VideoFrameRate)})
            infoModel.append({key: "Year", value: player.metaData.value(MediaMetaData.Date)})
            infoModel.append({key: "Resolution", value: player.metaData.value(MediaMetaData.Resolution)})
        }
    }

    ToolButton
    {
        visible: player.playbackState == MediaPlayer.StoppedState
        anchors.centerIn: parent
        icon.color: "transparent"
        flat: true
        icon.width: Maui.Style.iconSizes.huge
        icon.name: iteminfo.icon
    }

    focus: true
    Keys.onSpacePressed: player.playbackState == MediaPlayer.PlayingState ? player.pause() : player.play()
    Keys.onLeftPressed: player.position = Math.max(0, player.position - 5000)
    Keys.onRightPressed: player.position = player.position + 5000

    RowLayout
    {
        anchors.fill: parent

        MouseArea
        {
            Layout.fillWidth: true
            Layout.fillHeight: true
            onDoubleClicked: player.position = Math.max(0, player.position - 5000)
        }

        MouseArea
        {
            Layout.fillWidth: true
            Layout.fillHeight: true
            onClicked: player.playbackState === MediaPlayer.PlayingState ? player.pause() : player.play()
        }

        MouseArea
        {
            Layout.fillWidth: true
            Layout.fillHeight: true
            onDoubleClicked: player.position = player.position + 5000
        }
    }

    footBar.visible: true
    footBar.background: null

    footBar.leftContent: ToolButton
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
    footBar.middleContent : Slider
    {
        id: _slider
        Layout.fillWidth: true
        orientation: Qt.Horizontal
        enabled: player.seekable
        from: 0
        to: 1000
        value: player.duration > 0 ? (1000 * player.position) / player.duration : 0

        onMoved: if (player.duration > 0) player.position = ((_slider.value / 1000) * player.duration)
    }
}
