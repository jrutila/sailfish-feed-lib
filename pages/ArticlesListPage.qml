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

    property string title
    property string streamId
    property int unreadCount
    readonly property string pageType: "articlesList"

    allowedOrientations: Orientation.Portrait | Orientation.Landscape

    SilicaListView {
        id: articlesListView

        property Item contextMenu

        anchors.fill: parent
        spacing: Theme.paddingMedium

        BusyIndicator {
            anchors.centerIn: parent
            running: feedAPI.busy
        }

        header: PageHeader {
            title: page.title
        }

        model: feedAPI.articlesListModel
        delegate: ListItem {
            id: articleItem

            property bool menuOpen: ((articlesListView.contextMenu != null) && (articlesListView.contextMenu.parent === articleItem))

            width: articlesListView.width
            contentHeight: menuOpen ? articlesListView.contextMenu.height + Theme.itemSizeExtraLarge : Theme.itemSizeExtraLarge

            Item {
                id: articleText

                anchors { top: parent.top; left: parent.left; right: articleVisual.left; leftMargin: Theme.paddingLarge; rightMargin: (articleVisual.width ? Theme.paddingSmall : 0) }

                GlassItem {
                    id: unreadIndicator

                    width: Theme.itemSizeExtraSmall
                    height: width
                    x: -(Theme.paddingLarge + (width / 2))
                    anchors.verticalCenter: articleTitle.verticalCenter
                    color: Theme.highlightColor
                    visible: (unread || unreadIndBusyAnimation.running)

                    ParallelAnimation {
                        id: unreadIndBusyAnimation

                        running: (busy && Qt.application.active)

                        SequentialAnimation {
                            loops: Animation.Infinite

                            NumberAnimation { target: unreadIndicator; property: "brightness"; to: 0.4; duration: 750 }
                            NumberAnimation { target: unreadIndicator; property: "brightness"; to: 1.0; duration: 750 }
                        }

                        SequentialAnimation {
                            loops: Animation.Infinite

                            NumberAnimation { target: unreadIndicator; property: "falloffRadius"; to: 0.075; duration: 750 }
                            NumberAnimation { target: unreadIndicator; property: "falloffRadius"; to: unreadIndicator.defaultFalloffRadius; duration: 750 }
                        }

                        onRunningChanged: {
                            if (!running) {
                                unreadIndicator.brightness = 1.0;
                                unreadIndicator.falloffRadius = unreadIndicator.defaultFalloffRadius;
                            }
                        }
                    }
                }

                Label {
                    id: articleTitle

                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    font.pixelSize: Theme.fontSizeMedium
                    truncationMode: TruncationMode.Fade
                    text: title
                    color: highlighted ? Theme.highlightColor : Theme.primaryColor
                }

                Label {
                    id: articleStreamTitle

                    anchors { top: articleTitle.bottom; left: parent.left; right: parent.right }
                    font.pixelSize: Theme.fontSizeExtraSmall
                    truncationMode: TruncationMode.Fade
                    horizontalAlignment: Text.AlignRight
                    text: streamTitle
                    color: highlighted ? Theme.highlightColor : Theme.primaryColor
                    visible: (feedAPI.streamIsTag(page.streamId) || feedAPI.streamIsCategory(page.streamId))
                }

                Label {
                    id: articleSummary

                    anchors { top: (articleStreamTitle.visible ? articleStreamTitle.bottom : articleTitle.bottom); left: parent.left; right: parent.right; }
                    clip: true
                    font.pixelSize: Theme.fontSizeExtraSmall
                    elide: Text.ElideRight
                    maximumLineCount: (articleStreamTitle.visible ? 2 : 3)
                    wrapMode: Text.WordWrap
                    text: summary
                    color: highlighted ? (unread ? Theme.highlightColor : Theme.secondaryHighlightColor) : (unread ? Theme.primaryColor : Theme.secondaryColor)
                    visible: summary && !taggingProgressBar.visible
                }

                ProgressBar {
                    id: taggingProgressBar

                    anchors { top: (articleStreamTitle.visible ? articleStreamTitle.bottom : articleTitle.bottom); left: parent.left; right: parent.right; }
                    visible: (tagging && Qt.application.active)
                    indeterminate: true
                }
            }

            Image {
                id: articleVisual

                anchors { top: parent.top; right: parent.right; rightMargin: Theme.paddingLarge }
                width: 0
                height: parent.height
                sourceSize.width: parent.height * 2
                sourceSize.height: parent.height * 2
                fillMode: Image.PreserveAspectCrop
                smooth: true
                clip: true
                source: imgUrl

                Behavior on width {
                    NumberAnimation { duration: 500 }
                }

                Connections {
                    target: page

                    onIsLandscapeChanged: {
                        if (page.isLandscape && (articleVisual.status === Image.Ready)) articleVisual.width = height;
                        else articleVisual.width = 0;
                    }
                }

                onStatusChanged: { if (page.isLandscape && (status === Image.Ready)) width = height; }
            }

            onClicked: {
                if (unread) {
                    feedAPI.markEntry(id, "markAsRead");
                    page.unreadCount--;
                }
                feedAPI.currentEntry = articlesListView.model.get(index);
                var nextItem = function() {
                    if (articlesListView.model.length >= index)
                    {
                        var model = articlesListView.model.get(index+1);
                        if (model.unread)
                        {
                            feedAPI.markEntry(model.id, "markAsRead");
                            page.unreadCount--;
                        }
                        return model;
                    } else {
                        console.log("Should fetch more stuff!!")
                    }
                }
                pageStack.push(Qt.resolvedUrl("ArticlePage.qml"), { 'nextItem': nextItem });
            }

            onPressAndHold: {
                if (!articlesListView.contextMenu) articlesListView.contextMenu = contextMenuComponent.createObject(articlesListView);
                articlesListView.contextMenu.modelIndex = index;
                articlesListView.contextMenu.articleId = id;
                articlesListView.contextMenu.articleUnread = unread;
                articlesListView.contextMenu.articleUrl = contentUrl;
                articlesListView.contextMenu.show(articleItem)
            }
        }

        section.property: "sectionLabel"
        section.delegate: SectionHeader { text: section }

        Component {
            id: contextMenuComponent

            ContextMenu {
                id: contextMenu

                property int modelIndex
                property string articleId
                property bool articleUnread
                property string articleUrl

                MenuItem {
                    text: (contextMenu.articleUnread ? qsTr("Mark as read") : qsTr("Keep unread"))
                    onClicked: {
                        feedAPI.markEntry(contextMenu.articleId, (contextMenu.articleUnread ? "markAsRead" : "keepUnread"));
                        if (contextMenu.articleUnread) page.unreadCount--;
                        else page.unreadCount++;
                    }
                }

                MenuItem {
                    visible: (!feedAPI.streamIsTag(page.streamId) && articlesListView.count && page.unreadCount && (contextMenu.modelIndex < (articlesListView.count - 1)))
                    text: qsTr("Mark this and below as read")
                    onClicked: remorsePopup.execute(qsTr("Marking articles as read"), function() { feedAPI.markFeedAsRead(streamId, contextMenu.articleId); })
                }

                MenuItem {
                    text: (feedAPI.streamIsTag(page.streamId) ? qsTr("Forget") : qsTr("Save for later"))
                    onClicked: feedAPI.markEntry(contextMenu.articleId, (feedAPI.streamIsTag(page.streamId) ? "markAsUnsaved" : "markAsSaved"));
                }

                MenuItem {
                    visible: (contextMenu.articleUrl ? true : false)
                    text: qsTr("Open original link")
                    onClicked: Qt.openUrlExternally(contextMenu.articleUrl)
                }
            }
        }

        PullDownMenu {
            MenuItem {
                visible: (!feedAPI.streamIsTag(page.streamId) && (articlesListView.count > 0))
                text: qsTr("Mark all as read")
                onClicked: remorsePopup.execute(qsTr("Marking all articles as read"), function() { feedAPI.markFeedAsRead(streamId, articlesListView.model.get(0).id); })
            }

            MenuItem {
                text: qsTr("Refresh feed")
                onClicked: feedAPI.getStreamContent(streamId)
            }
        }

        PushUpMenu {
            visible: (articlesListView.count > 0)

            MenuItem {
                visible: (feedAPI.continuation !== "")
                text: qsTr("More articles")
                onClicked: feedAPI.getStreamContent(streamId, true)
            }

            MenuItem {
                visible: !feedAPI.streamIsTag(page.streamId)
                text: qsTr("Mark all as read")
                onClicked: remorsePopup.execute(qsTr("Marking all articles as read"), function() { feedAPI.markFeedAsRead(streamId, articlesListView.model.get(0).id); })
            }

            MenuItem {
                visible: ((typeof articlesListView.quickScroll === "undefined") && (articlesListView.count > 10))
                text: qsTr("Back to the top")
                onClicked: articlesListView.scrollToTop();
            }
        }

        ViewPlaceholder {
            enabled: (!feedAPI.busy && articlesListView.count == 0)
            text: qsTr("No unread articles in this feed")
        }

        VerticalScrollDecorator { flickable: articlesListView }
    }

    RemorsePopup {
        id: remorsePopup
    }

    Connections {
        target: feedAPI

        onEntryUnsaved: {
            if (articlesListView.count && (index < articlesListView.count)) articlesListView.model.remove(index);
        }
    }

    Component.onCompleted: {
        feedAPI.getStreamContent(streamId)
    }

    Component.onDestruction: {
        feedAPI.articlesListModel.clear();
    }
}
