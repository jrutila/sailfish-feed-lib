/*
  Copyright (C) 2014 Luca Donaggio
  Contact: Luca Donaggio <donaggio@gmail.com>
  All rights reserved.

  You may use this file under the terms of MIT license
*/

import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    id: cover

    Image {
        x: -Theme.paddingLarge
        y: x
        source: "../../icons/cover-background.png"
    }

    Label {
        id: labelFeedTitle

        anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: Theme.paddingMedium; leftMargin: Theme.paddingMedium; rightMargin: Theme.paddingMedium }
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        maximumLineCount: 3
        elide: Text.ElideRight
        color: Theme.highlightColor
        text: (typeof pageStack.currentPage.title !== "undefined") ? pageStack.currentPage.title : ""
    }

    Item {
        anchors { top: labelFeedTitle.bottom; topMargin: Theme.paddingMedium; leftMargin: Theme.paddingLarge; rightMargin: Theme.paddingLarge }
        width: parent.width
        height: Theme.itemSizeSmall
        visible: (!labelLoading.visible && !labeNotSignedIn.visible)

        Label {
            id: labelUnreadNum

            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Theme.itemSizeSmall

            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            wrapMode: Text.NoWrap
            font.pixelSize: Theme.fontSizeExtraLarge
            text: (typeof pageStack.currentPage.unreadCount !== "undefined") ? pageStack.currentPage.unreadCount : ""
        }

        Label {
            id: labelUnreadText

            anchors.left: labelUnreadNum.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: Theme.paddingSmall

            verticalAlignment: Text.AlignVCenter
            font.pixelSize: Theme.fontSizeTiny
            text: qsTr("Unread\narticles")
        }
    }

    Label {
        id: labelLoading

        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: Theme.paddingMedium; rightMargin: Theme.paddingMedium }
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.NoWrap
        truncationMode: TruncationMode.Fade
        color: Theme.highlightColor
        text: qsTr("Updating ...")
        visible: feedly.busy

        SequentialAnimation on opacity {
            running: (parent.visible && (cover.status === Cover.Active))
            loops: Animation.Infinite

            NumberAnimation { to: 0; duration: 1000 }
            NumberAnimation { to: 1; duration: 1000 }
        }
    }

    Label {
        id: labeNotSignedIn

        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: Theme.paddingMedium; rightMargin: Theme.paddingMedium }
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        color: Theme.highlightColor
        text: qsTr("Not signed in")
        visible: (!feedly.signedIn && !feedly.busy)
    }

    CoverActionList {
        id: coverAction

        CoverAction {
            iconSource: "image://theme/icon-cover-refresh"
            onTriggered: feedly.getStreamContent(pageStack.currentPage.streamId)
        }
    }
}
