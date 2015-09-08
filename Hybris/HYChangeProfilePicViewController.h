//
//  HYChangeProfilePicViewController.h
//  Hybris
//
//  Created by Mayur.Chakor on 27/07/15.
//  Copyright (c) 2015 Red Ant. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HYImageCropperViewController.h"


@interface HYChangeProfilePicViewController : UIViewController<UIActionSheetDelegate,HYImageCropperDelegate,UIGestureRecognizerDelegate,NSURLSessionDelegate,UIAlertViewDelegate,FBLoginViewDelegate,UIWebViewDelegate>
{

    __weak IBOutlet UIButton *btn_fb;
    UIWebView *webview_instagram;

}
- (IBAction)EditProfilePic:(id)sender;

@end
