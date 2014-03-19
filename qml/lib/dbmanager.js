/*
 * Utility functions to acces Local Storage
 */

.import QtQuick.LocalStorage 2.0 as LS

function getDB() {
    var db;

    try {
        db = LS.LocalStorage.openDatabaseSync("FeedHavenDB", "1.0", "Feed Haven Data", 1000000);
        db.transaction(
           function(tx) {
               // Create authorizations table if it doesn't already exist
               tx.executeSql('CREATE TABLE IF NOT EXISTS auth(refreshToken VARCHAR(256), accessToken VARCHAR(256), expires INT UNSIGNED)');
           }
        );
    } catch (error) {
        console.log(error);
    }

    return db;
}

function saveAuthTokens(feedlyObj) {
    var db = getDB();

    if (typeof db == "object") {
        try {
            db.transaction(
                function(tx) {
                    // Delete previous auth tokens
                    tx.executeSql('DELETE FROM auth');
                    // Insert current auth tokens
                    tx.executeSql('INSERT INTO auth (refreshToken, accessToken, expires) VALUES (?, ?, ?)', [ feedlyObj.refreshToken, feedlyObj.accessToken, feedlyObj.expires ]);
                }
            );
        } catch (error) {
            console.log(error);
        }
    }
}

function getAuthTokens(feedlyObj) {
    var db = getDB();
    var hs = [];

    if (typeof db == "object") {
        try {
            db.readTransaction(
                function(tx) {
                    // Get auth tokens
                    var rs = tx.executeSql('SELECT * FROM auth LIMIT 1');
                    if (rs.rows.length > 0) {
                        feedlyObj.refreshToken = rs.rows.item(0).refreshToken;
                        feedlyObj.accessToken = rs.rows.item(0).accessToken;
                        feedlyObj.expires = rs.rows.item(0).expires;
                    }
                }
            );
        } catch (error) {
            console.log(error);
        }
    }

    return hs;
}