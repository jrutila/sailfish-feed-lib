/*
  Copyright (C) 2014 Luca Donaggio
  Contact: Luca Donaggio <donaggio@gmail.com>
  All rights reserved.

  You may use this file under the terms of MIT license
*/

import QtQuick 2.0
import Sailfish.Silica 1.0
import "../../provider" as Provider

Page {
    id: page

    readonly property string pageType: "feedsList"

    allowedOrientations: Orientation.Portrait | Orientation.Landscape

    SilicaListView {
        id: feedsListView

        property Item contextMenu

        anchors.fill: parent

        BusyIndicator {
            anchors.centerIn: parent
            running: feedAPI.busy && !pageStack.busy
        }

        header: PageHeader {
            title: qsTr("Your feeds")
        }

        model: feedAPI.feedsListModel
        delegate: ListItem {
            id: feedItem

            width: feedsListView.width
            contentHeight: unreadCount > 0 ? Theme.itemSizeSmall : 0
            enabled: !busy && unreadCount
            visible: unreadCount

            menu:
            ContextMenu {
                id: contextMenu

                property Item visualParent
                property string feedId
                property string feedTitle
                property string feedImgUrl
                property string feedLang
                property var feedCategories

                MenuItem {
                    enabled: false
                    text: qsTr("Manage feed")
                    onClicked: pageStack.push(Qt.resolvedUrl("../dialogs/UpdateFeedDialog.qml"), { "feedId": feedId, "title": feedTitle, "imgUrl": feedImgUrl, "lang": feedLang, "categories": feedCategories })
                }

                MenuItem {
                    enabled: false
                    text: qsTr("Unsubscribe")
                    onClicked: visualParent.unsubscribe();
                }
            }

            function unsubscribe() {
                remorseItem.execute(feedItem, qsTr("Unsubscribing"));
            }

            Provider.FeedItem {
                id: feedDataContainer
            }

            RemorseItem {
                id: remorseItem

                onTriggered: { feedAPI.unsubscribe(id); }
            }

            BusyIndicator {
                anchors.centerIn: parent

                visible: busy
                size: BusyIndicatorSize.Medium
                running: (visible && Qt.application.active)
            }

            onClicked: {
                if ((unreadCount > 0) || feedAPI.streamIsTag(id)) pageStack.push(Qt.resolvedUrl("ArticlesListPage.qml"), { "title": title, "streamId": id, "unreadCount": unreadCount });
            }
        }

        section.property: "category"
        section.delegate: SectionHeader { text: section }

        PullDownMenu {
            MenuItem {
                text: qsTr("About")
                onClicked: pageStack.push(Qt.resolvedUrl("../../provider/AboutPage.qml"))
            }

            MenuItem {
                text: (feedAPI.signedIn ? qsTr("Sign out") : qsTr("Sign in"))
                onClicked: {
                    if (feedAPI.signedIn) feedAPI.revokeRefreshToken();
                    else pageStack.push(Qt.resolvedUrl("SignInPage.qml"));
                }
            }

            MenuItem {
                text: qsTr("Add feed")
                enabled: false
                visible: feedAPI.signedIn
                onClicked: pageStack.push(Qt.resolvedUrl("FeedSearchPage.qml"))
            }

            MenuItem {
                text: qsTr("Refresh feeds")
                visible: feedAPI.signedIn
                onClicked: feedAPI.getSubscriptions()
            }
        }

        ViewPlaceholder {
            enabled: (!feedAPI.busy && feedsListView.count == 0)
            text: (feedAPI.signedIn ? qsTr("Feeds list not available") : qsTr("Please sign in"))
        }

        VerticalScrollDecorator {
            flickable: feedsListView
        }

    }
}


