/* global Promise */

'use strict';
module.exports = (function() {

    // the key/value cache; should hold only serializable keys/values
    var cache;

    function Storage() {}

    if (typeof(window) !== 'undefined' && window.localStorage) {
        cache = window.localStorage;
    } else {
        // mock in-memory storage
        Storage.prototype.setItem = function(key, value) {
            this[key] = value;
        };
        Storage.prototype.getItem = function(key) {
            return this[key];
        };

        Storage.prototype.removeItem = function(key) {
            delete this[key];
        };
        Storage.prototype.clear = function() {
            Object.keys(this).forEach(function(key) {
                delete this[key];
            }.bind(this));
        };

        cache = new Storage();
    }

    // promises providing values for keys. Used to handle parallel gets per key.
    var promises = {};

    function get(key, fetchCallback) {
        var promise, value = cache.getItem(key);
        if (value) {
            delete promises[key]; // we don't need the promise anymore
            return Promise.resolve(JSON.parse(value));
        }
        promise = promises[key];
        if (promise) {
            return promise;
        }
        promise = fetchCallback().then(function(newValue) {
            cache.setItem(key, JSON.stringify(newValue));
            return newValue;
        });
        promises[key] = promise;
        return promise;
    }

    function getSync(key) {
        var value = cache.getItem(key);
        return value && JSON.parse(value);
    }

    function storeSync(key, value) {
        cache.setItem(key, JSON.stringify(value));
    }

    function removeByPrefix(prefix) {
        var rPromises = [];
        Object.keys(cache).forEach(function(key) {
            if (prefix.test(key)) {
                rPromises.push(remove(key));
            }
        });
        Object.keys(promises).forEach(function(key) {
            if (prefix.test(key)) {
                delete promises[key];
            }
        });
        return Promise.all(rPromises);
    }

    function remove(key) {
        if (arguments.length <= 0) {
            return Promise.reject();
        }
        if (typeof(key) === 'string') {
            cache.removeItem(key);
        } else if (key instanceof RegExp) {
            removeByPrefix(key);
        }
        delete promises[key];
        return Promise.resolve();
    }

    function clear() {
        cache.clear();
        promises = {};
    }

    return {
        get: get,
        getSync: getSync,
        storeSync: storeSync,
        remove: remove,
        clear: clear // use with caution; clears all success callbacks, too!
    };
}());
