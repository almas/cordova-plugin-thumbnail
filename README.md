# cordova-plugin-thumbnail

This plug-in implements the ability to generate image thumbnails for Cordova project. Support Android and iOS.

# Installation

```
cordova plugin add https://github.com/almas/cordova-plugin-thumbnail.git
```

# How to use

`Thumbnails.thumbnail(srcPath, width, height, [options,] successFn, ​​failFn)`

explain:

- `srcPath`: Image path. Supported path format: `file:///path/to/spot`.
- `width`: Width of thumbnail
- `height` Height of thumbnail
- `options` other configuration parameter objects
  - `toPath` Thumbnail storage path, if not specified, will randomly create a file to store the generated thumbnail.
- `successFn` Thumbnail generates a successful callback function
- `failFn` Thumbnail Generation Failed Callback Function

### Example: ###

```
Thumbnails.thumbnail(srcPath, width, height, function success(path) {
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
