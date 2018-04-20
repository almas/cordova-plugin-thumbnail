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

+ (void) thumbnail:(NSString *)imageURL size:(CGSize)size toURL:(NSString *) toURL
{
    CIContext *context = [CIContext contextWithOptions:nil];
    NSURL* _imageURL = [NSURL URLWithString: imageURL];
    CIImage *image = [CIImage imageWithContentsOfURL:_imageURL];
    CIImage *outputImage = [self thumbnailToCIImage:image size:size];
    CGImageRef cgimg = [context createCGImage:outputImage fromRect:[outputImage extent]];

    [self cgImageWriteToFile:cgimg urlStr: toURL];
    CGImageRelease(cgimg);
}

+ (CIImage *) thumbnailToCIImage:(CIImage *)image size:(CGSize)size
{

    CIFilter *filter = [CIFilter filterWithName: @"CILanczosScaleTransform"];
    struct CGSize originalSize = [image extent].size;
    float scale = fminf((float) size.width / originalSize.width, (float) size.height / originalSize.height);

    [filter setValue:image forKey:@"inputImage"];
    [filter setValue: [NSNumber numberWithFloat: scale] forKey:@"inputScale"];
    [filter setValue: @1.0f forKey:@"inputAspectRatio"];
    CIImage *outputImage = [filter outputImage];
    return outputImage;
}

+ (UIImage *) thumbnailToUIImage:(NSString *) imageURL size:(CGSize)size
{
    CIContext *context = [CIContext contextWithOptions:nil];
    NSURL *_imageURL = [NSURL URLWithString: imageURL];
    CIImage *image = [CIImage imageWithContentsOfURL: _imageURL];
    CIImage *outputImage = [self thumbnailToCIImage:image size:size];
    CGImageRef cgimg = [context createCGImage:outputImage fromRect:[outputImage extent]];
    UIImage * thumbnail = [UIImage imageWithCGImage: cgimg];
    CGImageRelease(cgimg);
    return (thumbnail);
}

+ (BOOL) cgImageWriteToFile: (CGImageRef) image urlStr:(NSString *)urlStr
{
    CFURLRef url = (__bridge CFURLRef)[NSURL URLWithString:urlStr];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
    if (!destination) {
        NSLog(@"Failed to create CGImageDestination for %@", urlStr);
        return NO;
    }

    CGImageDestinationAddImage(destination, image, nil);

    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"Failed to write image to %@", urlStr);
    }

    CFRelease(destination);

    return YES;
}
@end

@implementation ThumbnailCordovaPlugin

- (void)thumbnail: (CDVInvokedUrlCommand*)command {
    [self.commandDelegate runInBackground:^{
        NSString* sourceURL = [command.arguments objectAtIndex:0];
        NSString* targetURL = [self getTargetURL: command];
        CGSize size = [self getSize: command];

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

- (CGSize) getSize: (CDVInvokedUrlCommand *) command {
    NSNumber* width = nil;
    NSNumber* height = nil;
    if ([command.arguments count] == 3) {
        width = [command.arguments objectAtIndex:1];
        height = [command.arguments objectAtIndex:2];
    } else {
        width = [command.arguments objectAtIndex:2];
        height = [command.arguments objectAtIndex:3];
    }
    return CGSizeMake([width floatValue], [height floatValue]);
}

- (NSString *) getTargetURL: (CDVInvokedUrlCommand *) command {
    NSString* targetURL;
    NSString* sourceURL = [command.arguments objectAtIndex:0];
    NSString* extname = [@"." stringByAppendingString:[sourceURL pathExtension]];

    if ([command.arguments count] == 3) {
        NSString* uuid = [FileUtil uuid];
        NSString* filename = [uuid stringByAppendingString:extname];
        NSURL* _targetURL = [[FileUtil applicationDataDirectory] URLByAppendingPathComponent:filename];
        targetURL = [_targetURL absoluteString];
    } else {
        targetURL = [command.arguments objectAtIndex:1];
    }

    return targetURL;
}

@end
