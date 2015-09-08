//
//  HYCommonFunctions.m
//  Hybris
//
//  Created by Mayur.Chakor on 30/07/15.
//  Copyright (c) 2015 Red Ant. All rights reserved.
//

#import "HYCommonFunctions.h"
static HYCommonFunctions *sharedObject = nil;

@implementation HYCommonFunctions
- (id)init
{
    return self;
}
+ (HYCommonFunctions *)getInstance
{
    if (sharedObject == nil)
    {
        sharedObject = [[HYCommonFunctions alloc] init];
    }
    
    return sharedObject;
}

#pragma mark - Image Path Methods

- (NSString*)documentsPathForFileName:(NSString*)name
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    
    paths = nil;
    
    return [documentsPath stringByAppendingPathComponent:name];
}



- (NSString*)mediaPathForDirectory:(NSString*)directory FileName:(NSString*)name
{
    NSError *error;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *mediaDirPath = [documentsDirectory stringByAppendingPathComponent:@"/Media"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:mediaDirPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:mediaDirPath withIntermediateDirectories:NO attributes:nil error:&error];
    }
    
    NSArray *directoryNames = [directory componentsSeparatedByString:@"/"];
    
    NSString *dataPath = mediaDirPath;
    
    for (NSString *directoryName in directoryNames) {
        
        dataPath = [dataPath stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@", directoryName]];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
            
            [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error];
        }
    }
    
    paths = nil;
    documentsDirectory = nil;
    
    return [dataPath stringByAppendingPathComponent:name];
}
#pragma mark - Image Resizing Methods

- (void)resizeAndStoreImages:(UIImage*)img Options:(NSArray*)options
{
    UIImage *chosenImage = img;
    NSData *imageData = UIImageJPEGRepresentation(chosenImage, 1.0);
    
    for (NSDictionary *dict in options) {
        
        NSString *imgNameWithPath = [dict objectForKey:@"namewithpath"];
        
        int resizedImgMaxHeight = [[dict objectForKey:@"heightwidth"] intValue];
        int resizedImgMaxWidth = [[dict objectForKey:@"heightwidth"] intValue];
        
        NSData *resizedImageData;
        
        if (chosenImage.size.height > chosenImage.size.width && chosenImage.size.height > resizedImgMaxHeight) { // portrait
            
            int width = (chosenImage.size.width / chosenImage.size.height) * resizedImgMaxHeight;
            CGRect rect = CGRectMake( 0, 0, width, resizedImgMaxHeight);
            UIGraphicsBeginImageContext(rect.size);
            [chosenImage drawInRect:rect];
            UIImage *pic1 = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            resizedImageData = UIImageJPEGRepresentation(pic1, [[dict objectForKey:@"quality"] floatValue]);
            
            pic1 = nil;
            
        } else if (chosenImage.size.width > chosenImage.size.height && chosenImage.size.width > resizedImgMaxWidth) { // landscape
            
            int height = (chosenImage.size.height / chosenImage.size.width) * resizedImgMaxWidth;
            CGRect rect = CGRectMake( 0, 0, resizedImgMaxWidth, height);
            UIGraphicsBeginImageContext(rect.size);
            [chosenImage drawInRect:rect];
            UIImage *pic1 = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            resizedImageData = UIImageJPEGRepresentation(pic1, [[dict objectForKey:@"quality"] floatValue]);
            
            pic1 = nil;
            
        } else {
            
            if (chosenImage.size.height > resizedImgMaxHeight) {
                
                int width = (chosenImage.size.width / chosenImage.size.height) * resizedImgMaxHeight;
                CGRect rect = CGRectMake( 0, 0, width, resizedImgMaxHeight);
                UIGraphicsBeginImageContext(rect.size);
                [chosenImage drawInRect:rect];
                UIImage *pic1 = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                resizedImageData = UIImageJPEGRepresentation(pic1, [[dict objectForKey:@"quality"] floatValue]);
                
                pic1 = nil;
                
            } else {
                
                resizedImageData = imageData;
            }
        }
        
        [resizedImageData writeToFile:imgNameWithPath atomically:YES];
        NSLog(@"Path %@", imgNameWithPath);
        
        //        if ([[dict objectForKey:@"type"] intValue] == mainImage) {
        //
        //            [resizedImageData writeToFile:[self documentsPathForFileName:imgName] atomically:YES];
        //            NSLog(@"Path %@", [self documentsPathForFileName:imgName]);
        //
        //        } else if ([[dict objectForKey:@"type"] intValue] == thumbImage) {
        //
        //            [resizedImageData writeToFile:[self documentsPathForThumbFileName:imgName] atomically:YES];
        //            NSLog(@"Path %@", [self documentsPathForThumbFileName:imgName]);
        //        }
    }
}

#pragma mark - Data to Base64 Method

- (NSString*)base64forData:(NSData*)theData
{
    const uint8_t* input = (const uint8_t*)[theData bytes];
    NSInteger length = [theData length];
    
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;
    
    NSInteger i;
    for (i=0; i < length; i += 3) {
        NSInteger value = 0;
        NSInteger j;
        for (j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        NSInteger theIndex = (i / 3) * 4;
        output[theIndex + 0] =                    table[(value >> 18) & 0x3F];
        output[theIndex + 1] =                    table[(value >> 12) & 0x3F];
        output[theIndex + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[theIndex + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] ;
}

#pragma mark - Remove File At Path

- (BOOL)removeFileAtPathOnce:(NSString*)filePath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSError *error;
    BOOL success = [fileManager removeItemAtPath:filePath error:&error];
    
    return success;
}



@end
