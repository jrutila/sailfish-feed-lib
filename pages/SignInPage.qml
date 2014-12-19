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

    readonly property string pageType: "signIn"
    property string error

    allowedOrientations: Orientation.Portrait | Orientation.Landscape

    SilicaWebView {
        id: signInView

        anchors.fill: parent
        visible: !feedAPI.busy

        header: PageHeader {
            title: qsTr("Sign in")
        }
        url: feedAPI.getSignInUrl();

        ViewPlaceholder {
            id: errorPlaceholder

            enabled: false
            text: qsTr("Authentication error ") + error
        }

        onUrlChanged: {
            var authInfo = feedAPI.getAuthCodeFromUrl(url.toString());

            if (authInfo.authCode !== "") feedAPI.getAccessToken(authInfo.authCode);
            else if (authInfo.error) {
                error = authInfo.error;
                errorPlaceholder.enabled = true;
            }
        }

    }

    Connections {
        target: feedAPI

        onSignedInChanged: {
            if (feedAPI.signedIn) pageContainer.pop();
        }

        onError: errorPlaceholder.enabled = true;
    }
}





