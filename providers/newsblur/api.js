.pragma library

Qt.include("../../lib/api.js")

var _redirectUri = "urn:ietf:wg:oauth:2.0:oob";
var _apiCalls = {
    "auth": { "method": "GET", "protocol": "https", "url": "auth/auth?response_type=code&scope=https://cloud.feedly.com/subscriptions&redirect_uri=" + _redirectUri + "&client_id=" },
    "authRefreshToken": { "method": "POST", "protocol": "https", "url":  "auth/token" },
    "subscriptions": { "method": "GET", "protocol": "http", "url": "reader/feeds" },
    "markers": { "method": "POST", "protocol": "http", "url": "markers" },
    "markersCounts": { "method": "GET", "protocol": "http", "url": "markers/counts" },
    "streamContent": { "method": "GET", "protocol": "http", "url": "streams/contents" },
    "entries": { "method": "GET", "protocol": "http", "url": "entries" },
    "searchFeed": { "method": "GET", "protocol": "http", "url": "search/feeds" },
    "updateSubscription": { "method": "POST", "protocol": "https", "url": "subscriptions"},
    "unsubscribe": { "method": "DELETE", "protocol": "https", "url": "subscriptions"},
    "categories": { "method": "GET", "protocol": "http", "url": "categories" }
}

var _apiCallBack = function(useTest) {
    if (useTest) return "dev.newsblur.com/";
    return "newsblur.com";
}
