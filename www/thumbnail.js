'use strict';

var Thumbnails = {},
    emptyFn = function() {};

function optionsToThumbnailArgs(options) {
    if (!options.targetPath) {
        return [options.srcPath, options.width, options.height];
    } else {
        return [options.srcPath, options.targetPath, options.width, options.height];
    }
}

Thumbnails.PERSISTENCE = 1;
Thumbnails.TEMPERATE = 0;

Thumbnails.config = function(persistenceOrTemp) {
    cordova.exec(emptyFn, emptyFn, "Thumbnails", "config", [persistenceOrTemp]);
};

Thumbnails.thumbnail = function(srcPath, width, height, options, successFn, failFn) {
    if (typeof options === 'function') {
        failFn = successFn;
        successFn = options;
        options = {};
    }
    options = options || {};
    successFn = successFn || emptyFn;
    failFn = failFn || emptyFn;

    options.width = width;
    options.height = height;
    options.srcPath = srcPath;

    cordova.exec(successFn, failFn, "Thumbnails", "thumbnail", optionsToThumbnailArgs(options));
};

window.Thumbnails = Thumbnails;

module.exports = Thumbnails;
