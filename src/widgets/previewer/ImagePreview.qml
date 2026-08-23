import QtQuick
import QtQuick.Controls

import org.mauikit.controls as Maui

Loader
{
    asynchronous: true
    sourceComponent: iteminfo.mime === "image/gif" || iteminfo.mime === "image/avif" ? _animatedImgComponent : _imgComponent

    Component
    {
        id: _animatedImgComponent
        Maui.AnimatedImageViewer
        {
            source: currentUrl
        }
    }

    Component
    {
        id: _imgComponent
        Maui.ImageViewer
        {
            readonly property bool needsThumbnailDecoder: String(iteminfo.mime || "") === "image/webp"

            source: needsThumbnailDecoder ? (String(iteminfo.thumbnail || "") || currentUrl) : currentUrl
            sourceSize: needsThumbnailDecoder
                ? Qt.size(Math.max(1, width), Math.max(1, height))
                : Qt.size(-1, -1)
        }
    }
}



