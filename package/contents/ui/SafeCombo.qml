import QtQuick
import QtQuick.Controls

// A ComboBox whose list always stays inside the editor window, below the
// title bar. Inside a KWin-made window Qt cannot open lists outside of it,
// so without margins the list was cut off at the top edge.
ComboBox {
    id: cb
    property int topSpace: 46          // title bar plus some air
    popup.topMargin: topSpace
    popup.bottomMargin: 10
    popup.leftMargin: 10
    popup.rightMargin: 10
}
