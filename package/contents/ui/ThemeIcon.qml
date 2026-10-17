import QtQuick
import org.kde.kirigami as Kirigami

// Icon from the system icon theme, recolored the way Plasma does it.
Kirigami.Icon {
    property alias name: icon.source
    id: icon
    width: 16
    height: 16
}
