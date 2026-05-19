import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls as Maui
import org.mauikit.terminal as Term

Term.ColorSchemesPage
{
    currentColorScheme: appSettings.terminalColorScheme

    onCurrentColorSchemeChanged: appSettings.terminalColorScheme = currentColorScheme
}
