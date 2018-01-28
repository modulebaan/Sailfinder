/*
*   This file is part of Sailfinder.
*
*   Sailfinder is free software: you can redistribute it and/or modify
*   it under the terms of the GNU General Public License as published by
*   the Free Software Foundation, either version 3 of the License, or
*   (at your option) any later version.
*
*   Sailfinder is distributed in the hope that it will be useful,
*   but WITHOUT ANY WARRANTY; without even the implied warranty of
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*   GNU General Public License for more details.
*
*   You should have received a copy of the GNU General Public License
*   along with Sailfinder.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtWebKit 3.0

Page {
    property string fbToken
    property bool logout

    id: page

    onFbTokenChanged: {
        if(fbToken.length > 0) {
            tinderLogin.visible = true
            api.login(fbToken)
        }
        else {
            tinderLogin.visible = false
        }
    }

    Connections {
        target: api
        onAuthenticatedChanged: {
            if(api.authenticated) {
                console.debug("Tinder token successfully retrieved")
                pageStack.replace(Qt.resolvedUrl("../pages/MainPage.qml"))
            }
        }
    }

    Connections {
        target: app
        onNetworkStatusChanged: {
            if(app.networkStatus) {
                console.debug("Network recovered, reloading webview")
                webview.reload()
            }
        }
    }

    SilicaWebView {
        property real devicePixelRatio: {
            if (Screen.width <= 540) {
                return 1.5;
            }
            else if (Screen.width > 540 && Screen.width <= 768) {
                return 2.0;
            }
            else {
                return 3.0;
            }
        }

        id: webview

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        clip: true
        experimental.preferences.javascriptEnabled: true
        experimental.preferences.navigatorQtObjectEnabled: true
        experimental.preferences.developerExtrasEnabled: true
        experimental.userStyleSheets: Qt.resolvedUrl("../css/facebook.css")
        experimental.userScripts: [Qt.resolvedUrl("../js/facebook.js")]
        experimental.customLayoutWidth: page.width / devicePixelRatio
        experimental.overview: true
        experimental.userAgent: app.fbUserAgent
        experimental.onMessageReceived: {
            var msg = JSON.parse(message.data);
            switch(msg.type) {
            case 0: // FB_TOKEN
                console.debug("Successfully retrieved Facebook access token: " + msg.data);
                fbToken = msg.data;
                errorFacebookLogin.enabled = false;
                opacity = 0.0;
                break;
            case 1: // ERROR
                console.error("Can't retrieve Facebook access token: " + msg.data);
                fbToken = "";
                errorFacebookLogin.enabled = true;
                opacity = 1.0;
                break;
            case 42: // DEBUG
                console.debug(msg.data);
                break;
            }
        }
        url: app.fbAuthUrl
        Component.onCompleted: {
            if(logout) {
                console.debug("Clearing cookies due logout")
                webview.experimental.deleteAllCookies();
                webview.reload()
            }
        }

        Behavior on opacity { FadeAnimation {} }

        ViewPlaceholder {
            id: errorFacebookLogin
            //% "Oops!"
            text: qsTrId("sailfinder-oops")
            //% "Something went wrong, please try again later"
            hintText: qsTrId("sailfinder-error")
        }
    }

    BusyIndicator {
        id: tinderLogin
        size: BusyIndicatorSize.Large
        anchors.centerIn: parent
        visible: false
        running: Qt.application.active && visible
    }

    Label {
        anchors { top: tinderLogin.bottom; topMargin: Theme.paddingMedium; horizontalCenter: parent.horizontalCenter }
        visible: tinderLogin.visible
        //% "Logging in"
        text: qsTrId("sailfinder-logging-in")
    }
}

