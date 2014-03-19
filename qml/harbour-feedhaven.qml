import QtQuick 2.0
import Sailfish.Silica 1.0
import "components"

ApplicationWindow {
    id: main

    initialPage: Qt.resolvedUrl("pages/FeedsListPage.qml")
    cover: Qt.resolvedUrl("cover/CoverPage.qml")

    Feedly {
        id: feedly
    }

    Component.onCompleted: {
        if (!feedly.refreshToken) pageStack.push(Qt.resolvedUrl("pages/SignInPage.qml"));
        else if (!feedly.accessToken || (feedly.expires < (Date.now() + 3600000))) feedly.getAccessToken();
    }
}