'use strict';

var Thumbnails = {},
    emptyFn = function() {};

function options2Args(options) {
    if(!options.maxPixelSize) {
        options.maxPixelSize = 120;
    }

    if (!options.targetPath) {
        return [options.srcPath, options.maxPixelSize];
    } else {
        return [options.srcPath, options.targetPath, options.maxPixelSize];
    }
}

Thumbnails.PERSISTENCE = 1;
Thumbnails.TEMPERATE = 0;

Thumbnails.config = function(persistenceOrTemp) {
    cordova.exec(emptyFn, emptyFn, "Thumbnails", "config", [persistenceOrTemp]);
};

Thumbnails.thumbnail = function(srcPath, options, successFn, failFn) {
    if (typeof options === 'function') {
        failFn = successFn;
        successFn = options;
        options = {};
    }
    options = options || {};
    successFn = successFn || emptyFn;
    failFn = failFn || emptyFn;

    options.srcPath = srcPath;

    cordova.exec(successFn, failFn, "Thumbnails", "thumbnail", options2Args(options));
};

window.Thumbnails = Thumbnails;

module.exports = Thumbnails;
