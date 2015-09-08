//
//  HYCommonFunctions.h
//  Hybris
//
//  Created by Mayur.Chakor on 30/07/15.
//  Copyright (c) 2015 Red Ant. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface HYCommonFunctions : NSObject
+ (HYCommonFunctions *)getInstance;

- (NSString*)documentsPathForFileName:(NSString*)name;
- (NSString*)mediaPathForDirectory:(NSString*)directory FileName:(NSString*)name;
- (BOOL)removeFileAtPathOnce:(NSString*)filePath;

#pragma mark - Data to Base64 Method

- (NSString*)base64forData:(NSData*)theData;

- (void)resizeAndStoreImages:(UIImage *)img Options:(NSArray*)options;
@end
