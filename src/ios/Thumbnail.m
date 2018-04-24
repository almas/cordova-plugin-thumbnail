#import <Cordova/CDV.h>
#import "Thumbnail.h"
#import <CoreGraphics/CoreGraphics.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>

@implementation FileUtil

+ (NSURL *) applicationDataDirectory {
    NSFileManager* sharedFM = [NSFileManager defaultManager];
    NSArray* possibleURLs = [sharedFM URLsForDirectory:NSDocumentDirectory
                                             inDomains:NSUserDomainMask];
    NSURL* appSupportDir = nil;
    NSURL* appDirectory = nil;

    if ([possibleURLs count] > 0) {
        appSupportDir = [possibleURLs objectAtIndex:0];
    }

    if (appSupportDir) {
        NSString* appBundleID = [[NSBundle mainBundle] bundleIdentifier];
        appDirectory = [appSupportDir URLByAppendingPathComponent:appBundleID];
        NSError* theError = nil;
        if (![sharedFM createDirectoryAtURL:appDirectory withIntermediateDirectories:YES
                                 attributes:nil error:&theError]) {
            // Handle the error.
            return nil;
        }
    }

    return appDirectory;
}

+ (BOOL) createDirectoryAtURL: (NSURL *) directoryURL {
    NSFileManager* sharedFM = [NSFileManager defaultManager];
    NSError __autoreleasing* theError = nil;
    return ([sharedFM createDirectoryAtURL:directoryURL withIntermediateDirectories:YES
                                attributes:nil error:&theError]);
}

+ (BOOL) createDirectoryAtPath: (NSString *) directoryPath {
    NSFileManager* sharedFM = [NSFileManager defaultManager];
    NSError __autoreleasing* theError = nil;
    return ([sharedFM createDirectoryAtPath:directoryPath withIntermediateDirectories:YES
                                 attributes:nil error:&theError]);
}

+ (BOOL) createFileAtURL: (NSString *) fileURL {
    NSURL* url = [NSURL URLWithString: fileURL];
    return [self createFileAtPath: [url path]];
}

+ (BOOL) createFileAtPath: (NSString *) filePath {
    NSFileManager* sharedFM = [NSFileManager defaultManager];
    return ([sharedFM createFileAtPath: filePath contents:nil attributes:nil]);
}

+ (NSString *) uuid {
    CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
    NSString* uuidString = (NSString*)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuidObject));

    CFRelease(uuidObject);
    return uuidString;
}

@end

@implementation Thumbnail

+ (void) thumbnail:(NSString *)imageURL size:(CGFloat)maxSize toURL:(NSString *) toURL
{

    NSURL* _imageURL = [NSURL URLWithString: imageURL];

    UIImage *uiImage = [self thumbnailWithContentsOfURL:_imageURL maxPixelSize:maxSize];
    if(uiImage) {
        NSError *writeError = nil;
        [UIImageJPEGRepresentation(uiImage, 1.0) writeToFile:toURL options:NSDataWritingAtomic error:&writeError];
        if (writeError) {
            NSLog(@"Failed to write image: %@", writeError);
        }
    }
}

+ (UIImage *)thumbnailWithContentsOfURL:(NSURL *)URL maxPixelSize:(CGFloat)maxPixelSize
{
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)URL, NULL);
    if(imageSource == NULL) {
        NSLog(@"Can not read from source: %@", URL);
        return NULL;
    }

    NSDictionary *imageOptions = @{
                                   (NSString const *)kCGImageSourceCreateThumbnailFromImageIfAbsent : (NSNumber const *)kCFBooleanTrue,
                                   (NSString const *)kCGImageSourceThumbnailMaxPixelSize            : @(maxPixelSize),
                                   (NSString const *)kCGImageSourceCreateThumbnailWithTransform     : (NSNumber const *)kCFBooleanTrue
                                   };
    CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (__bridge CFDictionaryRef)imageOptions);
    CFRelease(imageSource);

    UIImage *result = [[UIImage alloc] initWithCGImage:thumbnail];
    CGImageRelease(thumbnail);

    return result;
}

@end

@implementation ThumbnailCordovaPlugin

- (void)thumbnail: (CDVInvokedUrlCommand*)command {
    [self.commandDelegate runInBackground:^{
        NSString* sourceURL = [command.arguments objectAtIndex:0];
        //        sourceURL = [sourceURL stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        NSString* targetURL = [self getTargetURL: command];
        CGFloat size = [self getMaxSize: command];

        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:targetURL]) {
            NSLog(@"Thumbnail file already exists %@", targetURL);
            return;
        }

        [FileUtil createFileAtURL: targetURL];
        [Thumbnail thumbnail:sourceURL size: size toURL:targetURL];

        CDVPluginResult* pluginResult = nil;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                         messageAsString:targetURL];

        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)config: (CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (CGFloat) getMaxSize: (CDVInvokedUrlCommand *) command {
    NSNumber* maxPixelSize = nil;
    if ([command.arguments count] == 2) {
        maxPixelSize = [command.arguments objectAtIndex:1];
    } else {
        maxPixelSize = [command.arguments objectAtIndex:2];
    }
    return [maxPixelSize floatValue];
}

- (NSString *) getTargetURL: (CDVInvokedUrlCommand *) command {
    NSString* targetURL;
    NSString* sourceURL = [command.arguments objectAtIndex:0];
    NSString* extname = [@"." stringByAppendingString:[sourceURL pathExtension]];

    if ([command.arguments count] == 2) {
        NSString* uuid = [FileUtil uuid];
        NSString* filename = [uuid stringByAppendingString:extname];
        NSURL* _targetURL = [[FileUtil applicationDataDirectory] URLByAppendingPathComponent:filename];
        targetURL = [_targetURL absoluteString];
    } else {
        targetURL = [command.arguments objectAtIndex:1];
    }

    targetURL = [targetURL stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    return targetURL;
}

@end
