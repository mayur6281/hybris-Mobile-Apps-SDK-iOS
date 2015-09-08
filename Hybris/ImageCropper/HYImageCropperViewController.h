//
//  HYImageCropperViewController.h
//  Hybris
//
//  Created by Mayur.Chakor on 28/07/15.
//  Copyright (c) 2015 Red Ant. All rights reserved.
//

#import <UIKit/UIKit.h>
@class HYImageCropperViewController;

@protocol HYImageCropperDelegate <NSObject>

- (void)imageCropper:(HYImageCropperViewController *)cropperViewController didFinished:(UIImage *)editedImage;
- (void)imageCropperDidCancel:(HYImageCropperViewController *)cropperViewController;

@end

@interface HYImageCropperViewController : UIViewController

@property (nonatomic, assign) NSInteger tag;
@property (nonatomic, assign) id<HYImageCropperDelegate> delegate;
@property (nonatomic, assign) CGRect cropFrame;

- (id)initWithImage:(UIImage *)originalImage cropFrame:(CGRect)cropFrame limitScaleRatio:(NSInteger)limitRatio;

@end


