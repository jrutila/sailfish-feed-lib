/*
  Copyright (C) 2014 Luca Donaggio
  Contact: Luca Donaggio <donaggio@gmail.com>
  All rights reserved.

  You may use this file under the terms of MIT license

  Feedly API wrapper
*/

.pragma library

var _isInitialized = false;
var _apiCallBaseUrl;

/*
 * Initialize API
 */
function init(useTest) {
    if (!_isInitialized) {
        _apiCallBaseUrl = _apiCallBack(useTest)
        //_apiCalls = provider.apiCalls;
        //_redirectUri = provider.redirectUri;
        _isInitialized = true;
    }
}

function getUrl(method, param, accessToken)
{
    var apiUrl = _apiCalls[method].url;
    var mp = apiUrl.match(/:\w+/g)

    for (var m in mp)
    {
        apiUrl = apiUrl.replace(mp[m], param[mp[m].substring(1)]);
        //delete param[mp[m].substring(1)];
    }

    var url = _apiCalls[method].protocol + "://" + _apiCallBaseUrl + apiUrl;

    if (((_apiCalls[method].method === "GET") || (_apiCalls[method].method === "DELETE")) && (param !== null)) {
        if ((_apiCalls[method].method === "GET") && (typeof param === "object")) {
            var queryString = [];
            for (var p in param) {
                if (param.hasOwnProperty(p)) {
                    if (Object.prototype.toString.call(param[p]) == '[object Array]')
                    {
                        for (var v in param[p])
                            queryString.push(encodeURIComponent(p) + "=" + encodeURIComponent(param[p][v]));
                    } else
                        queryString.push(encodeURIComponent(p) + "=" + encodeURIComponent(param[p]));
                }
            }
            url += ("?" + queryString.join("&"));
        } else url += ("/" + encodeURIComponent(param));
    }
    return url;
}

/*
 * Make a call to API method "method" passing input parameters "param" and acces token "accessToken"
 * Callback function "callback" will be called after a response has been received
 */
function call(method, param, callback, accessToken) {
    var xhr = new XMLHttpRequest();
    // TODO: Clone here
    var callParam = param;
    var url = getUrl(method, param, accessToken);

    // Timeout is not implemented yet in this version of the XMLHttplRequest object
    xhr.timeout = 10000;
    xhr.ontimeout = function() {
        console.log("API call timeout");
    }
    xhr.open(_apiCalls[method].method, url, true);
    if (accessToken) xhr.setRequestHeader("Authorization", "Bearer " + accessToken);
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            var tmpResp;
            if (xhr.responseText) {
                try {
                    tmpResp = JSON.parse(xhr.responseText);
                } catch (exception) {
                    // Not a valid JSON response
                    tmpResp = null;
                }
            }
            var retObj = { "status": xhr.status, "response": tmpResp, "callMethod": method, "callParams": callParam };
            // DEBUG
             //console.log(JSON.stringify(retObj));
            callback(retObj);
            delete xhr;
        }
    }
    if ((_apiCalls[method].method === "POST") && (param !== null) && (typeof param === "object")) {
        //xhr.setRequestHeader("Content-Type", "application/json");
        xhr.setRequestHeader("Content-type","application/x-www-form-urlencoded");
        var queryString = [];
        for (var p in param) {
            if (param.hasOwnProperty(p)) {
                queryString.push(encodeURIComponent(p) + "=" + encodeURIComponent(param[p]));
            }
        }
        var post = queryString.join("&");
        console.log(post)
        xhr.send(post);
    } else xhr.send();
}
