import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    property string title: ""
    property string author: ""
    property var updated: null
    property string imgUrl: ""
    property string content: ""
    property string contentUrl: ""

    SilicaFlickable {
        id: articleView

        anchors.fill: parent
        contentHeight: articleContainer.height
        visible: (feedly.currentEntry !== null)

        Column {
            id: articleContainer

            width: page.width - (2 * Theme.paddingLarge)
            x: Theme.paddingLarge
            spacing: Theme.paddingSmall

            PageHeader {
                title: page.title
            }

            Label {
                id: articleTitle

                width: parent.width
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Bold
                wrapMode: Text.WordWrap
                text: page.title
            }

            Label {
                id: articleAuthorDate

                width: parent.width
                font.pixelSize: Theme.fontSizeTiny
                text: qsTr("by %1, published on: %2").arg(page.author).arg(Qt.formatDateTime(page.updated))
            }

            Image {
                id: articleVisual

                width: parent.width
                height: (Theme.itemSizeExtraLarge * 2)
                fillMode: Image.PreserveAspectFit
                smooth: true
                clip: true
                source: page.imgUrl
                visible: (source != "")
                onPaintedHeightChanged: { if (paintedHeight < height) height = paintedHeight; }
            }

            Label {
                id: articleContent

                width: parent.width
                horizontalAlignment: Text.AlignJustify
                font.pixelSize: Theme.fontSizeExtraSmall
                wrapMode: Text.WordWrap
                textFormat: Text.RichText
                text: "<style>a:link { color: " + Theme.highlightColor + "; }</style>" + page.content;
            }
        }

        PullDownMenu {
            property bool showMenu: (page.contentUrl !== "")

            visible: showMenu

            MenuItem {
                text: qsTr("Open original link")
                onClicked: Qt.openUrlExternally(page.contentUrl);
            }
        }

        VerticalScrollDecorator { flickable: articleView }
    }

    Connections {
        target: feedly

        onCurrentEntryChanged: {
            if (feedly.currentEntry !== null) {
                title = feedly.currentEntry.title;
                author = feedly.currentEntry.author;
                updated = new Date(feedly.currentEntry.updated);
                imgUrl = feedly.currentEntry.imgUrl;
                content = feedly.currentEntry.content;
                contentUrl = feedly.currentEntry.contentUrl;
            }
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Activating) feedly.acquireStatusIndicator(page);
    }

    Component.onCompleted: {
        if (feedly.currentEntry !== null) {
            title = feedly.currentEntry.title;
            author = feedly.currentEntry.author;
            updated = new Date(feedly.currentEntry.updated);
            imgUrl = feedly.currentEntry.imgUrl;
            content = feedly.currentEntry.content;
            contentUrl = feedly.currentEntry.contentUrl;
        }
    }
}