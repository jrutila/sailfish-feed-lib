/*
  Copyright (C) 2014 Luca Donaggio
  Contact: Luca Donaggio <donaggio@gmail.com>
  All rights reserved.

  You may use this file under the terms of MIT license
*/

import QtQuick 2.0
import Sailfish.Silica 1.0

import "../providers/newsblur/"

Page {
    id: page

    readonly property string pageType: "feedsList"

    allowedOrientations: Orientation.Portrait | Orientation.Landscape

    SilicaListView {
        id: feedsListView

        property Item contextMenu

        anchors.fill: parent
        visible: !feedly.busy

        header: PageHeader {
            title: qsTr("Your feeds")
        }

        model: feedly.feedsListModel
        delegate: ListItem {
            id: feedItem

            property bool menuOpen: ((feedsListView.contextMenu != null) && (feedsListView.contextMenu.parent === feedItem))

            width: feedsListView.width
            contentHeight: menuOpen ? feedsListView.contextMenu.height + Theme.itemSizeSmall : Theme.itemSizeSmall
            enabled: !busy

            function unsubscribe() {
                remorseItem.execute(feedItem, qsTr("Unsubscribing"));
            }

            FeedItem {
                id: feedDataContainer
            }

            RemorseItem {
                id: remorseItem

                onTriggered: { feedly.unsubscribe(id); }
            }

            BusyIndicator {
                anchors.centerIn: parent

                visible: busy
                size: BusyIndicatorSize.Medium
                running: (visible && Qt.application.active)
            }

            onClicked: {
                if ((unreadCount > 0) || (id.indexOf("/tag/") > 0)) pageStack.push(Qt.resolvedUrl("ArticlesListPage.qml"), { "title": title, "streamId": id, "unreadCount": unreadCount });
            }

            onPressAndHold: {
                if (!busy && (id.indexOf("/category/") === -1) && (id.indexOf("/tag/") === -1)) {
                    if (!feedsListView.contextMenu) feedsListView.contextMenu = contextMenuComponent.createObject(feedsListView);
                    feedsListView.contextMenu.feedId = id;
                    feedsListView.contextMenu.feedTitle = title;
                    feedsListView.contextMenu.feedImgUrl = imgUrl;
                    feedsListView.contextMenu.feedLang = lang;
                    // Convert categories from QQmlListModel back to an Array object
                    var tmpCategories = [];
                    for (var i = 0; i < categories.count; i++) tmpCategories.push({ "id": categories.get(i).id, "label": categories.get(i).label });
                    feedsListView.contextMenu.feedCategories = tmpCategories;
                    feedsListView.contextMenu.visualParent = feedItem;
                    feedsListView.contextMenu.show(feedItem);
                }
            }
        }

        section.property: "category"
        section.delegate: SectionHeader { text: section }

        Component {
            id: contextMenuComponent

            ContextMenu {
                id: contextMenu

                property Item visualParent
                property string feedId
                property string feedTitle
                property string feedImgUrl
                property string feedLang
                property var feedCategories

                MenuItem {
                    text: qsTr("Manage feed")
                    onClicked: pageStack.push(Qt.resolvedUrl("../dialogs/UpdateFeedDialog.qml"), { "feedId": feedId, "title": feedTitle, "imgUrl": feedImgUrl, "lang": feedLang, "categories": feedCategories })
                }

                MenuItem {
                    text: qsTr("Unsubscribe")
                    onClicked: visualParent.unsubscribe();
                }
            }
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("About")
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }

            MenuItem {
                text: (feedly.signedIn ? qsTr("Sign out") : qsTr("Sign in"))
                onClicked: {
                    if (feedly.signedIn) feedly.revokeRefreshToken();
                    else pageStack.push(Qt.resolvedUrl("SignInPage.qml"));
                }
            }

            MenuItem {
                text: qsTr("Add feed")
                visible: feedly.signedIn
                onClicked: pageStack.push(Qt.resolvedUrl("FeedSearchPage.qml"))
            }

            MenuItem {
                text: qsTr("Refresh feeds")
                visible: feedly.signedIn
                onClicked: feedly.getSubscriptions()
            }
        }

        ViewPlaceholder {
            enabled: (feedsListView.count == 0)
            text: (feedly.signedIn ? qsTr("Feeds list not available") : qsTr("Please sign in"))
        }

        VerticalScrollDecorator {
            flickable: feedsListView
        }

    }
}


