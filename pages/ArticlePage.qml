/*
  Copyright (C) 2014 Luca Donaggio
  Contact: Luca Donaggio <donaggio@gmail.com>
  All rights reserved.

  You may use this file under the terms of MIT license
*/

import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    property string title: ""
    property string originalContent: ""
    property string content: ""
    property string contentUrl: ""
    property ListModel galleryModel: ListModel {}
    readonly property string pageType: "articleContent"

    function update() {
        if (feedly.currentEntry !== null) {
            title = feedly.currentEntry.title;
            originalContent = feedly.currentEntry.content;
            // Clean article content and extract image urls
            var tmpContent = feedly.currentEntry.content;
            galleryModel.clear();
            if (tmpContent) {
                var findImgUrls = new RegExp("<img[^>]+src\s*=\s*(?:\"|')(.+?)(?:\"|')", "gi");
                var tmpMatch;
                while ((tmpMatch = findImgUrls.exec(tmpContent)) !== null) {
                    if(tmpMatch[1]) galleryModel.append({ "imgUrl": tmpMatch[1] });
                }
                var stripImgTag = new RegExp("<img[^>]*>", "gi");
                var normalizeSpaces = new RegExp("\\s+", "g");
                tmpContent = tmpContent.replace(stripImgTag, " ").replace(normalizeSpaces, " ").trim();
            }
            content = tmpContent;
            contentUrl = feedly.currentEntry.contentUrl;
            var articleInfoProp = { "title": feedly.currentEntry.title,
                                    "author": feedly.currentEntry.author,
                                    "updated": new Date(feedly.currentEntry.updated),
                                    "streamTitle": feedly.currentEntry.streamTitle };
            pageContainer.pushAttached(Qt.resolvedUrl("ArticleInfoPage.qml"), articleInfoProp);
        } else {
            title = "";
            originalContent = "";
            content = "";
            contentUrl = "";
            galleryModel.clear();
            pageContainer.popAttached();
        }
    }

    allowedOrientations: Orientation.Portrait | Orientation.Landscape

    SilicaFlickable {
        id: articleView

        anchors.fill: parent
        contentHeight: header.height + articleContainer.height

        PageHeader {
            id: header

            title: page.title
        }

        Column {
            id: articleContainer

            anchors.top: header.bottom
            width: parent.width
            clip: true
            spacing: Theme.paddingSmall

            SlideshowView {
                id: articleGalleryView

                width: parent.width - (2 * Theme.paddingLarge)
                height: (Theme.itemSizeExtraLarge * 2)
                anchors.horizontalCenter: parent.horizontalCenter
                itemWidth: width
                itemHeight: height
                clip: true
                visible: (count > 0)

                model: page.galleryModel
                delegate: Image {
                    id: articleVisual

                    property bool _removed: false

                    width: articleGalleryView.width
                    height: articleGalleryView.height
                    fillMode: Image.Pad
                    smooth: true
                    clip: true
                    source: ((typeof model.imgUrl !== "undefined") ? model.imgUrl : "")

                    function removeFromModel() {
                        if (!_removed) {
                            _removed = true;
                            parent.model.remove(index);
                        }
                    }

                    BusyIndicator {
                        anchors.centerIn: parent
                        size: BusyIndicatorSize.Medium
                        running: (parent.status === Image.Loading)
                        visible: running
                    }

                    onStatusChanged: { if (status === Image.Error) removeFromModel(); }

                    onPaintedWidthChanged: {
                        if (paintedWidth > width) fillMode = Image.PreserveAspectFit;
                        if ((paintedWidth > 0) && (paintedWidth <= Theme.iconSizeSmall)) removeFromModel();
                    }

                    onPaintedHeightChanged: {
                        if (paintedHeight > height) fillMode = Image.PreserveAspectFit;
                        if ((paintedHeight > 0) && (paintedHeight <= Theme.iconSizeSmall)) removeFromModel();
                    }
                }
            }

            Label {
                id: articleContent

                readonly property string _linkStyle: "<style>a:link { color: " + Theme.highlightColor + "; }</style>"

                width: parent.width - (2 * Theme.paddingLarge)
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignJustify
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.Wrap
                textFormat: Text.RichText
                text: _linkStyle + page.content;

                onLinkActivated: Qt.openUrlExternally(link)

                onWidthChanged: {
                    // This is needed as a workaround for the following bug:
                    // if textFormat === Text.RichText text does not reflow when width changes
                    if (page.content) {
                        text = "";
                        text = _linkStyle + page.content;
                    }
                }
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

    SilicaFlickable {
        id: articleImageContainer

        anchors.fill: parent
        visible: false
        contentWidth: parent.width
        contentHeight: parent.height

        PinchArea {
            id: articleImagePinchArea

            width: Math.max(articleImageContainer.contentWidth, articleImageContainer.width)
            height: Math.max(articleImageContainer.contentHeight, articleImageContainer.height)

            onPinchStarted: {
                articleImageContainer.interactive = false;
            }

            onPinchUpdated: {
                // Adjust content position due to drag
                articleImageContainer.contentX += (pinch.previousCenter.x - pinch.center.x);
                articleImageContainer.contentY += (pinch.previousCenter.y - pinch.center.y);
                // Resize content
                var scale = (1.0 + pinch.scale - pinch.previousScale);
                var updatedWidth = (articleImageContainer.contentWidth * scale);
                var updatedHeight = (articleImageContainer.contentHeight * scale);
                if (((articleImage.paintedWidth * scale) <= articleImage.sourceSize.width) || ((articleImage.paintedHeight * scale) <= articleImage.sourceSize.height))
                    articleImageContainer.resizeContent(updatedWidth, updatedHeight, pinch.center);
            }

            onPinchFinished: {
                // Check if lower image size boundary has been crossed
                if ((articleImageContainer.contentWidth < articleImageContainer.width) || (articleImageContainer.contentHeight < articleImageContainer.height)) {
                    articleImageContainer.contentWidth = articleImageContainer.width;
                    articleImageContainer.contentHeight = articleImageContainer.height;
                }
                // Move its content within bounds.
                articleImageContainer.returnToBounds()
                articleImageContainer.interactive = true;
            }

            Image {
                id: articleImage

                width: articleImageContainer.contentWidth
                height: articleImageContainer.contentHeight
                clip: true
                smooth: true
                fillMode: Image.PreserveAspectFit
                source: ((galleryModel.count && (typeof galleryModel.get(0).imgUrl !== "undefined")) ? galleryModel.get(0).imgUrl : "")

                function _adjustImageAspect() {
                    // Reset image container size
                    articleImageContainer.contentWidth = articleImageContainer.width;
                    articleImageContainer.contentHeight = articleImageContainer.height;
                    // Compute aspect ratio
                    var imgRatio = (paintedWidth / sourceSize.width);
                    if (imgRatio < 1) {
                        fillMode = Image.PreserveAspectFit;
                        articleImagePinchArea.enabled = true;
                    } else {
                        fillMode = Image.Pad;
                        articleImagePinchArea.enabled = false;
                    }
                }

                BusyIndicator {
                    anchors.centerIn: parent

                    size: BusyIndicatorSize.Large
                    running: (parent.status === Image.Loading)
                    visible: running
                }

                Connections {
                    target: page
                    onOrientationChanged: { if (articleImage.status === Image.Ready) articleImage._adjustImageAspect(); }
                }

                onStatusChanged: {
                    if (status === Image.Ready) _adjustImageAspect();
                }
            }
        }

        ScrollDecorator {
            flickable: articleImageContainer
        }
    }

    Connections {
        target: feedly

        onCurrentEntryChanged: page.update();
    }

    onStatusChanged: {
        if (status === PageStatus.Active) update();
    }

    states: [
        State {
            name: "oneImageOnly"
            when: ((content === "") && (galleryModel.count === 1))

            PropertyChanges {
                target: articleView
                visible: false
            }

            PropertyChanges {
                target: articleImageContainer
                visible: true
            }

            PropertyChanges {
                target: page
                showNavigationIndicator: ((articleImageContainer.contentWidth <= articleImageContainer.width) && (articleImageContainer.contentHeight <= articleImageContainer.height))
                backNavigation: page.showNavigationIndicator
                forwardNavigation: page.showNavigationIndicator
            }
        }
    ]
}
