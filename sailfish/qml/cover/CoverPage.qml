/*
    Quickddit - Reddit client for mobile phones
    Copyright (C) 2014  Dickson Leong

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see [http://www.gnu.org/licenses/].
*/

import QtQuick 2.0
import Sailfish.Silica 1.0

// TODO: redesign cover page
CoverBackground {
    id: coverBackground

    Image {
        source: "./background.png"
        anchors {
            left: parent.left
            leftMargin: - (width / 3)
            top: parent.top
            topMargin: - (height / 4)
        }
        fillMode: Image.PreserveAspectFit
        opacity: 0.2
    }

    CoverPlaceholder {
        text: pageStack.currentPage.title || ""
    }

    CoverActionList {
        enabled: typeof pageStack.currentPage.refresh === 'function'
        CoverAction {
            iconSource: "image://theme/icon-cover-refresh"
            onTriggered: {
                appWindow.activate();
                pageStack.currentPage.refresh();
            }
        }
    }
}
