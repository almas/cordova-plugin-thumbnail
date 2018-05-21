# cordova-plugin-thumbnail

This plug-in implements the ability to generate image thumbnails for Cordova project. Support Android and iOS.

# Installation

```
cordova plugin add https://github.com/almas/cordova-plugin-thumbnail.git
```

# How to use

`Thumbnails.thumbnail(srcPath, [options,] successCallbackFn, ​​failCallbackFn)`

### Explanation:

- `srcPath`: Image path. Supported path format: `file:///path/to/spot`.
- `options` other configuration parameter objects
  - `maxPixelSize`: Maximum width or height of thumbnail in pixels (default value: 120)
  - `targetPath` Thumbnail path. If not specified, will randomly create a file to store the generated thumbnail.
  - `compression` The quality of the resulting image, expressed as a value from 0 to 100. The value 0 represents the maximum compression (or lowest quality) while the value 100 represents the least compression (or best quality). (default value: 90)
- `successCallbackFn` Thumbnail generates a successful callback function
- `failCallbackFn` Thumbnail Generation Failed Callback Function

### Example:

```
var options = {
        maxPixelSize: 100,
        targetPath: 'file:///path/to/file'
    };

Thumbnails.thumbnail('file:///path/source/file', options, function success(path) {
    console.log ("thumbnails generated at path:" + path);
}, function fail(error) {
    console.error(error);
});
```

## Android specific configuration:

You need to add the following configuration in the `config.xml` file:

```
<preference name="AndroidPersistentFileLocation" value="Internal" />
```
