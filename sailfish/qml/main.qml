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
import harbour.quickddit.Core 1.0

ApplicationWindow {
    id: appWindow
    initialPage: Component { MainPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml");

    // Global busy indicator, it reads the 'busy' property from the current page
    DockedPanel {
        id: busyPanel
        width: parent.width
        height: busyIndicator.height + 2 * constant.paddingLarge
        open: pageStack.currentPage.hasOwnProperty('busy') ? pageStack.currentPage.busy : false
        dock: Dock.Bottom
        enabled: false

        BusyIndicator {
            id: busyIndicator
            anchors.centerIn: parent
            running: busyPanel.open
        }
    }

    // work around ugly animation of DockedPanel when orientation changes to portrait
    onOrientationChanged: {
        busyPanel._initialized = false
    }

    InfoBanner { id: infoBanner }

    // A collections of global utility functions
    QtObject {
        id: globalUtils

        property Component __openLinkDialogComponent: null

        function getMainPage() {
            return pageStack.find(function(page) { return page.objectName == "mainPage"; });
        }

        function previewableVideo(url) {
            if (/^https?:\/\/((i|m)\.)?gfycat\.com\//.test(url)) {
                return true
            } else if (/^https?:\/\/mediacru\.sh/.test(url)) {
                return true
            } else if (/^https?:\/\/\S+\.(mp4|avi|mkv|webm)/i.test(url)) {
                return true
            } else if (/^https?\:\/\/((i|m)\.)?imgur\.com\/.+\.gifv$/.test(url)) {
                return true;
            } else {
                return false
            }
        }

        function previewableImage(url) {
            // imgur url
            if (/^https?:\/\/((i|m)\.)?imgur\.com\//.test(url))
                return !(/^.*\.gifv$/.test(url));
            // direct image url with image format extension
            else if (/^https?:\/\/\S+\.(jpe?g|png|gif)/i.test(url))
                return true;
            else
                return false;
        }

        function redditLink(url) {
            if (/^https?:\/\/(\w+\.)?reddit.com(\/r\/\w+)?\/comments\/\w+/.test(url))
                return true;
            else if (/^https?:\/\/(\w+\.)?reddit.com\/r\/(\w+)\/?/.test(url))
                return true;
            return false
        }

        function openRedditLink(url) {
            if (/^https?:\/\/(\w+\.)?reddit.com(\/r\/\w+)?\/comments\/\w+/.test(url))
                pageStack.push(Qt.resolvedUrl("CommentPage.qml"), {linkPermalink: url});
             else if (/^https?:\/\/(\w+\.)?reddit.com\/r\/(\w+)\/?/.test(url)) {
                var subreddit = /^https?:\/\/(\w+\.)?reddit.com\/r\/(\w+)\/?/.exec(url)[2];
                var mainPage = pageStack.find(function(page) { return page.objectName == "mainPage"; });
                mainPage.refresh(subreddit);
                pageStack.pop(mainPage);
            } else
                infoBanner.alert(qsTr("Unsupported reddit url"));
        }

        function openImageViewPage(url) {
            if (/^https?:\/\/((i|m)\.)?imgur\.com/.test(url))
                pageStack.push(Qt.resolvedUrl("ImageViewPage.qml"), {imgurUrl: url});
            else if (/^https?:\/\/\S+\.(jpe?g|png|gif)/i.test(url))
                pageStack.push(Qt.resolvedUrl("ImageViewPage.qml"), {imageUrl: url});
            else
                infoBanner.alert(qsTr("Unsupported image url"));
        }

        function openVideoViewPage(url) {
            var match
            if ((/^https?:\/\/\S+\.(mp4|avi|mkv|webm)/i.test(url))) {
                pageStack.push(Qt.resolvedUrl("VideoViewPage.qml"), { videoUrl: url });
            } else if (/^https?:\/\/((i|m)\.)?gfycat.com\/.+/.test(url)) {
                match = /^https?\:\/\/gfycat\.com\/(.+?)$/.exec(url)
                if (match.length < 2) {
                    console.log("invalid gfycat url: " + url)
                    return
                }
                var xhr = new XMLHttpRequest()
                xhr.onreadystatechange = function() {
                    if (xhr.readyState == 4) {
                        var videoUrl = JSON.parse(xhr.responseText)["gfyItem"]["mp4Url"]
                        pageStack.push(Qt.resolvedUrl("VideoViewPage.qml"), { origUrl: url, videoUrl: videoUrl });
                    }
                }

                xhr.open("GET", "http://gfycat.com/cajax/get/" + match[1], true)
                xhr.send()
            } else if (/^https?:\/\/mediacru\.sh\/.+/.test(url)) {
                match = /^https?\:\/\/mediacru\.sh\/(.+?)$/.exec(url)
                if (match.length < 2) {
                    console.log("invalid mediacru.sh url: " + url)
                    return
                }
                pageStack.push(Qt.resolvedUrl("VideoViewPage.qml"), { origUrl: url, videoUrl: "https://mediacru.sh/" + match[1] + ".mp4" });
            } else if (/^https?:\/\/((i|m)\.)?imgur\.com\/.+/.test(url)) {
                match = /^https?\:\/\/(((i|m)\.)?imgur\.com)\/(.+?).gifv$/.exec(url)
                if (!match || match.length < 4) {
                    console.log("invalid imgur.com url: " + url)
                    return
                }
                pageStack.push(Qt.resolvedUrl("VideoViewPage.qml"), { origUrl: url, videoUrl: "https://" + match[1] + "/" + match[4] + ".mp4" });
            } else
                infoBanner.alert(qsTr("Unsupported video url"));
        }

        function openLink(url) {
            url = QMLUtils.toAbsoluteUrl(url);
            if (!url)
                return;

            if (previewableVideo(url))
                openVideoViewPage(url);
            else if (previewableImage(url))
                openImageViewPage(url);
            else if (redditLink(url))
                openRedditLink(url);
            else
                createOpenLinkDialog(url);
        }

        function openNonPreviewLink(url) {
            url = QMLUtils.toAbsoluteUrl(url);
            if (!url)
                return;

            if (redditLink(url))
                openRedditLink(url);
            else
                createOpenLinkDialog(url);
        }

        function createOpenLinkDialog(url) {
            pageStack.push(Qt.resolvedUrl("OpenLinkDialog.qml"), {url: url});
        }

        function createSelectionDialog(title, model, selectedIndex, onAccepted) {
            var p = {title: title, model: model, selectedIndex: selectedIndex}
            var dialog = pageStack.push(Qt.resolvedUrl("SelectionDialog.qml"), p);
            dialog.accepted.connect(function() { onAccepted(dialog.selectedIndex); })
        }
    }

    Constant { id: constant }
    AppSettings { id: appSettings }

    QuickdditManager {
        id: quickdditManager
        settings: appSettings
        onAccessTokenFailure: {
            if (code == 299 /* QNetworkReply::UnknownContentError */) {
                infoBanner.alert(qsTr("Please log in again"));
                pageStack.push(Qt.resolvedUrl("AppSettingsPage.qml"));
            } else {
                infoBanner.alert(errorString);
            }
        }
    }

    CaptchaManager {
        id: captchaManager
        manager: quickdditManager
    }
}
