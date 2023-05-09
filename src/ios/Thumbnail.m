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

+ (void) thumbnail:(NSString *)imageURL size:(CGFloat)maxSize toURL:(NSString *) toURL compression:(CGFloat) compressionQuality
{

    NSURL* _imageURL = [NSURL URLWithString: imageURL];

    UIImage *uiImage = [self thumbnailWithContentsOfURL:_imageURL maxPixelSize:maxSize];
    if(uiImage) {
        NSError *writeError = nil;
        [UIImageJPEGRepresentation(uiImage, compressionQuality) writeToFile:toURL options:NSDataWritingAtomic error:&writeError];
        if (writeError) {
            NSLog(@"Failed to write image: %@", writeError);
        }
    }
}

+ (UIImage *)thumbnailWithContentsOfURL:(NSURL *)URL maxPixelSize:(CGFloat)maxPixelSize
{
    NSData *data = [NSData dataWithContentsOfURL:URL];
    UIImage* image = [[UIImage alloc]initWithData:data];
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)URL, NULL);
    CGFloat scale = [[UIScreen mainScreen] scale]; // Get the screen scale

    if(imageSource == NULL) {
        NSLog(@"Can not read from source: %@", URL);
        return NULL;
    }
    
    
    CFDictionaryRef props = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
    NSDictionary *properties = (NSDictionary*)CFBridgingRelease(props);

    if (!properties) {
        NSLog(@"No properties");
    }

    double heightInPixel = [[properties objectForKey:@"PixelHeight"] doubleValue];
    double widthInPixel = [[properties objectForKey:@"PixelWidth"]doubleValue];
    NSNumber *orientation = [properties objectForKey:@"Orientation"];
    
    double heightInPoint = heightInPixel / (double)(image.scale);
    double widthInPoint = widthInPixel / (double)(image.scale);
    
    double ratio = MIN(widthInPoint/maxPixelSize, heightInPoint/maxPixelSize);
    
    double thumbnailHeight = (heightInPoint/ratio) / scale;
    double thumbnailWidth = (widthInPoint/ratio) / scale;
    
    CGSize newSize;
    if ([orientation isEqualToNumber:@6]) {
        newSize = CGSizeMake(thumbnailHeight, thumbnailWidth);
    }
    else {
        newSize = CGSizeMake(thumbnailWidth, thumbnailHeight);
    }
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}

@end

@implementation ThumbnailCordovaPlugin

- (void)thumbnail: (CDVInvokedUrlCommand*)command {
    [self.commandDelegate runInBackground:^{
        NSString* sourceURL = [command.arguments objectAtIndex:0];
        //        sourceURL = [sourceURL stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        NSString* targetURL = [self getTargetURL: command];
        CGFloat size = [self getMaxSize: command];

        NSNumber* compressionPercent = nil;
        if ([command.arguments count] == 2) {
            compressionPercent = [command.arguments objectAtIndex:2];
        } else {
            compressionPercent = [command.arguments objectAtIndex:3];
        }
        CGFloat compressionQuality = [compressionPercent floatValue] / 100;

        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:targetURL]) {
            NSLog(@"Thumbnail file already exists %@", targetURL);
            return;
        }

        [FileUtil createFileAtURL: targetURL];
        [Thumbnail thumbnail:sourceURL size: size toURL:targetURL compression: compressionQuality];

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
