import QtQuick
import org.mauikit.documents as Poppler

Poppler.PDFViewer
{
    id: control

    // FilePreviewer/PreviewerDialog already shows the title, so avoid duplicating it here.
    headBar.visible: false
    // In Index preview mode we don't want PDFViewer's own search/footer controls.
    showSearchControls: false
    footBar.visible: false

    path : currentUrl
}
