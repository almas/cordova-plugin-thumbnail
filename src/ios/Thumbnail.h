#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>

@interface FileUtil : NSObject

+ (NSURL *) applicationDataDirectory;

@end

@interface Thumbnail : NSObject

+ (UIImage *) thumbnailToUIImage:(NSString *) imageURL size:(CGSize)size;
+ (void) thumbnail:(NSString *)imageURL size:(CGSize)size toURL:(NSString *) toURL;

@end

@interface ThumbnailCordovaPlugin : CDVPlugin

- (void)thumbnail: (CDVInvokedUrlCommand*)command;
- (void)config: (CDVInvokedUrlCommand*)command;

@end
