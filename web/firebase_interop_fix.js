// This file provides JavaScript interop functionality for Firebase web packages

// Define PromiseJsImpl if it doesn't exist
if (typeof window.PromiseJsImpl === 'undefined') {
    window.PromiseJsImpl = Promise;
}

// Ensure firebase core interop methods are available
if (typeof window.dartify === 'undefined') {
    window.dartify = function (jsObject) {
        // Convert JS object to Dart-compatible object
        if (jsObject === null || jsObject === undefined) {
            return null;
        }

        // Handle arrays
        if (Array.isArray(jsObject)) {
            return jsObject.map(item => window.dartify(item));
        }

        // Handle objects
        if (typeof jsObject === 'object') {
            const result = {};
            for (const key in jsObject) {
                if (jsObject.hasOwnProperty(key)) {
                    result[key] = window.dartify(jsObject[key]);
                }
            }
            return result;
        }

        // Return primitive values as is
        return jsObject;
    };
}

if (typeof window.jsify === 'undefined') {
    window.jsify = function (dartObject, customJsify) {
        // Convert Dart object to JS-compatible object
        if (dartObject === null || dartObject === undefined) {
            return null;
        }

        // Handle arrays
        if (Array.isArray(dartObject)) {
            return dartObject.map(item => window.jsify(item, customJsify));
        }

        // Handle objects
        if (typeof dartObject === 'object') {
            const result = {};
            for (const key in dartObject) {
                if (dartObject.hasOwnProperty(key)) {
                    result[key] = window.jsify(dartObject[key], customJsify);
                }
            }
            return result;
        }

        // Return primitive values as is
        return dartObject;
    };
}

// Ensure handleThenable is available
if (typeof window.handleThenable === 'undefined') {
    window.handleThenable = function (promise) {
        if (!promise || typeof promise.then !== 'function') {
            return Promise.resolve(promise);
        }
        return promise;
    };
}

// Add Timestamp support
if (typeof window.Timestamp === 'undefined') {
    window.Timestamp = {
        now: function () {
            const now = new Date();
            return {
                seconds: Math.floor(now.getTime() / 1000),
                nanoseconds: 0
            };
        },
        fromDate: function (date) {
            return {
                seconds: Math.floor(date.getTime() / 1000),
                nanoseconds: 0
            };
        }
    };
}
