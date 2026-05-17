import QtQuick
import org.mauikit.documents as Poppler

Poppler.PDFViewer
{
    id: control

    // FilePreviewer/PreviewerWindow already shows the title, so avoid duplicating it here.
    headBar.visible: false
    // In Index preview mode we don't want PDFViewer's own search/footer controls.
    showSearchControls: false
    footBar.visible: false

    path : currentUrl

    Component.onCompleted:
    {
        console.log("[Index][DocumentPreview] init", "url=", currentUrl, "path=", path)
    }

    onPathChanged:
    {
        console.log("[Index][DocumentPreview] path changed", path)
    }
}
