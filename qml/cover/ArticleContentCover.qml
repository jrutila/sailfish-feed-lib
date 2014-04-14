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

    Label {
        id: labelTitle

        anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: Theme.paddingSmall; leftMargin: Theme.paddingSmall; rightMargin: Theme.paddingSmall }
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        maximumLineCount: 6
        elide: Text.ElideRight
        text: "\"" + pageStack.currentPage.title + "\""
    }
}