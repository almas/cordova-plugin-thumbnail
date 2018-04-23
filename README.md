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
  - `width`: Width of thumbnail in pixels (default value: 120)
  - `height` Height of thumbnail in pixels (default value: 120)
  - `targetPath` Thumbnail storage path, if not specified, will randomly create a file to store the generated thumbnail.
- `successCallbackFn` Thumbnail generates a successful callback function
- `failCallbackFn` Thumbnail Generation Failed Callback Function

### Example:

```
var options = {
        width: 100,
        height: 80,
        targetPath: toPath
    }

Thumbnails.thumbnail(sourcePath, options, function success(path) {
    console.log ("thumbnails generated in:" + path);
}, function fail(error) {
    console.error(error);
});
```

## Android specific configuration:

You need to add the following configuration in the `config.xml` file:

```
<preference name="AndroidPersistentFileLocation" value="Internal" />
```
