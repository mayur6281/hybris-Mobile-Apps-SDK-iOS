//
//  HYChangeProfilePicViewController.m
//  Hybris
//
//  Created by Mayur.Chakor on 27/07/15.
//  Copyright (c) 2015 Red Ant. All rights reserved.
//

#import "HYChangeProfilePicViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import "HYCommonFunctions.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

#define KCLIENTID @"0aa6190f812341d2ad8b1a87464a517b"
#define KCLIENTSERCRET @"70ac6eb105ea45179c9d5e675d972dbf"
#define kREDIRECTURI @"https://www.google.co.in"
#define KAUTHURL @"https://api.instagram.com/oauth/authorize/"
#define kAPIURl @"https://api.instagram.com/v1/users/"
#define KACCESS_TOKEN @”access_token”


@interface HYChangeProfilePicViewController ()
{

    UIActionSheet *sheet_profilepic;

    __weak IBOutlet UIImageView *img_ProfilePic;
    
    HYCommonFunctions *commonFuncObj;
    NSString *mainImgName;
    
    NSString *str_profilepic;
    
    IBOutlet FBLoginView *loginView;


}

@end

@implementation HYChangeProfilePicViewController
- (void)viewDidLoad {
    [super viewDidLoad];
      //For getting static instance of Common function
    commonFuncObj = [HYCommonFunctions getInstance];
    
    self.title = NSLocalizedString(@"Profile Picture", "Title for the view that shows the users Profile Picture.");
    
    //For allowing users select profile pic by just tapping on it
    img_ProfilePic.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self  action:@selector(EditProfilePic:)];
    tapGesture.numberOfTapsRequired = 1;
    [tapGesture setDelegate:self];
    [img_ProfilePic addGestureRecognizer:tapGesture];

    //Actionsheet for choosing from Camera or gallery.
    sheet_profilepic = [[UIActionSheet alloc] initWithTitle:nil
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                     destructiveButtonTitle:nil
                                          otherButtonTitles:@"Take Photo", @"Choose Existing Photo",@"Import photo from Facebook",@"Import photo from Instagram", nil];
    sheet_profilepic.tag = 2;
    
    
    [[HYWebService shared]GetProfilePictureURL:[[HYAppDelegate sharedDelegate]username] completionBlock:^(NSDictionary *dict ,NSError *error) {
        
        NSLog(@"Dict is %@",[dict valueForKey:@"imagesList"]);
        
        NSString *str_url;
        NSString *hostURL = [[NSUserDefaults standardUserDefaults] stringForKey:@"web_services_base_url_preference"];
        
        for (NSString *obj in [dict objectForKey:@"imagesList"])
        {
            str_url=obj;
        }
        NSLog(@"str_url%@",str_url);
        if (str_url==nil || [str_url isEqualToString: @""])
        {
            [img_ProfilePic setImage:[UIImage imageNamed:@"img_profileplaceholder@2x.png"]];

        }
       else
    {

        NSString *imagepath=[NSString stringWithFormat:@"%@%@",hostURL,str_url];
        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imagepath]]];
        img_ProfilePic.image=image;
        
        
}
    }];
    
    [btn_fb addTarget:self action:@selector(fireFbLoginView) forControlEvents:UIControlEventTouchUpInside];

    loginView=[[FBLoginView alloc]init];
    loginView.frame = CGRectMake(-500, -500, 0, 0);
    loginView.hidden=YES;
    loginView.delegate=self;
    [self.view addSubview:loginView];
        // Do any additional setup after loading the view.
    
    
}
#pragma mark- Load Instagram View

-(void)FireInstagramView
{
    
    webview_instagram=[[UIWebView alloc]initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height-108)];
    webview_instagram.delegate=self;
    [self.view addSubview:webview_instagram];
    
    [webview_instagram sizeToFit];
    webview_instagram.scrollView.scrollEnabled = NO;
    
    NSString* urlString = [kBaseURL stringByAppendingFormat:kAuthenticationURL,kClientID,kRedirectURI];
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    

    [webview_instagram loadRequest:request];
}

- (void)Instagramlogout
{
    NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray* instagramCookies = [cookies cookiesForURL:[NSURL URLWithString:@"https://instagram.com/"]];
    
    for (NSHTTPCookie* cookie in instagramCookies)
    {
        [cookies deleteCookie:cookie];
    }
}
#pragma MARK- fetch the users Instagram info using access token

- (void) getUserInstagramWithAccessToken:(NSString*)accessToken
{
    NSString* userInfoUrl = [NSString stringWithFormat:@"%@/v1/users/self?access_token=%@", kInstagramAPIBaseURL,
                             accessToken];
    NSURL *url = [NSURL URLWithString:userInfoUrl];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    NSError *error = nil;
    NSHTTPURLResponse *response = nil;
    NSData *jsonData = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    NSDictionary *dict;
    if (jsonData) {
        
        NSError *jsonError;
        dict =
        [NSDictionary dictionaryWithDictionary:[NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments
                                                                                 error:&jsonError]];
        NSString *str_instagramurl=[[dict objectForKey:@"data"]valueForKey:@"profile_picture"];
        NSLog(@"str_instagramurl%@",str_instagramurl);
        NSURL *url = [NSURL URLWithString:str_instagramurl];

        UIImage *image = [UIImage imageWithData: [NSData dataWithContentsOfURL:url]];
        
        
        HYImageCropperViewController *imgCropperVC = [[HYImageCropperViewController alloc] initWithImage:image cropFrame:CGRectMake(0, 100.0f, self.view.frame.size.width, self.view.frame.size.width) limitScaleRatio:3.0];
        imgCropperVC.delegate = self;
        
        [self.navigationController pushViewController:imgCropperVC animated:YES];
        
        
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
        
        
    }
    else
    {
        [img_ProfilePic setImage:[UIImage imageNamed:@"img_profileplaceholder@2x.png"]];
        
        [[HYAppDelegate sharedDelegate] alertWithError:error];
    }
    
}

#pragma mark - WebView Delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString* urlString = [[request URL] absoluteString];
    NSURL *Url = [request URL];
    NSArray *UrlParts = [Url pathComponents];
    
    // runs a loop till the user logs in with Instagram and after login yields a token for that Instagram user
    // do any of the following here
    if ([UrlParts count] == 1)
    {
        NSRange tokenParam = [urlString rangeOfString: kAccessToken];
        if (tokenParam.location != NSNotFound)
        {
            NSString* token = [urlString substringFromIndex: NSMaxRange(tokenParam)];
            // If there are more args, don't include them in the token:
            NSRange endRange = [token rangeOfString: @"&"];
            
            if (endRange.location != NSNotFound)
                token = [token substringToIndex: endRange.location];
            
            if ([token length] > 0 )
            {
                NSLog(@"token%@",token);
                [self getUserInstagramWithAccessToken:token];
                
                [webview_instagram removeFromSuperview];
                [self waitViewShow:NO];
                 [self Instagramlogout];

                // call the method to fetch the user's Instagram info using access token
            }
        }
        else
        {
        }
        return NO;
    }
    return YES;
}

- (void) webViewDidStartLoad:(UIWebView *)webView
{
    [self waitViewShow:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self waitViewShow:NO];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [webview_instagram removeFromSuperview];
    [self waitViewShow:NO];
    [self Instagramlogout];
    
    //DLog(@"Code : %d \nError : %@",error.code, error.description);
    //Error : Error Domain=WebKitErrorDomain Code=102 "Frame load interrupted"
    if (error.code == 102)
        return;
    if (error.code == -1009 || error.code == -1005)
    {
        //        _completion(kNetworkFail,kPleaseCheckYourInternetConnection);
    }
    else
    {
        //        _completion(kError,error.description);
    }
    UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"Error" message:error.description delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles: nil];
    [alert show];
}

#pragma mark- Load Facebook View

-(void)fireFbLoginView{
    for(id object in loginView.subviews){
        if([[object class] isSubclassOfClass:[UIButton class]]){
            
            UIButton* button = (UIButton*)object;
            [button sendActionsForControlEvents:UIControlEventTouchUpInside];
        }
    }
}
- (IBAction)getwifiparameters:(id)sender
{
    
    [[HYAppDelegate sharedDelegate] openSessionWithAllowLoginUI:YES completionBlock:^{
        
               
        NSLog(@"Completed");
//        if (self.sharableObject && [self.sharableObject respondsToSelector:@selector(facebookPostFromViewController:)]) {
//            [self.sharableObject facebookPostFromViewController:self];
//        }
    }];
//
//            CFArrayRef myArray = CNCopySupportedInterfaces();
//            // Get the dictionary containing the captive network infomation
//            CFDictionaryRef captiveNtwrkDict = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(myArray, 0));
//            NSLog(@"Information of the network we're connected to: %@", captiveNtwrkDict);
//            NSDictionary *dict = (__bridge NSDictionary*) captiveNtwrkDict;
//    
//    NSLog(@"dict details: %@",dict);
//
//            NSString* ssid = [dict objectForKey:@"SSID"];
//            NSLog(@"network name: %@",ssid);
//    
//    
//    UIAlertView   *alertView = [[UIAlertView alloc] initWithTitle:ssid                                           message:[NSString stringWithFormat:@"my dictionary is %@", dict]
// delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss",nil];
//    [alertView show];
//


//        Reachability *reachability = [Reachability reachabilityForInternetConnection];
//        [reachability startNotifier];
//        
//        NetworkStatus status = [reachability currentReachabilityStatus];
//        
//        if(status == NotReachable)
//        {
//            //No internet
//        }
//        else if (status == ReachableViaWiFi)
//        {
//            //WiFi
//            
//            NSLog(@"Network is ");
//            
//        }
//        else if (status == ReachableViaWWAN)
//        {
//            //3G
//        }
   
}
- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    UILabel *titleView = (UILabel *)self.navigationItem.titleView;
    
    if (!titleView) {
        titleView = [[ViewFactory shared] make:[HYLabel class]];
        titleView.backgroundColor = [UIColor clearColor];
        titleView.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        titleView.font = UIFont_navigationBarFont;
        titleView.textColor = UIColor_inverseTextColor;
        self.navigationItem.titleView = titleView;
    }
    
    titleView.text = title;
    [titleView sizeToFit];
}
- (IBAction)EditProfilePic:(id)sender
{
    NSLog(@"Edit");
    
    [sheet_profilepic showInView:self.view];
}

#pragma mark - Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
            
        case 0: {
            
            [self startCameraControllerFromViewController: self
                                            usingDelegate: self];
            break;
        }
            
        case 1: {
            
            [self startMediaBrowserFromViewController: self
                                        usingDelegate: self mediaType:@"image"];
            break;
        }
        case 2: {
            
            NSLog(@"Facebook");
            [self fireFbLoginView];
            break;
        }
        case 3: {
            
            NSLog(@"Instagram");
            [self FireInstagramView];
            
            break;
        }

        default:
        {
            break;
        }

        
    }
    
}


#pragma mark - Image Video Picker Method

- (BOOL) startMediaBrowserFromViewController: (UIViewController*) controller usingDelegate: (id <UIImagePickerControllerDelegate,UINavigationControllerDelegate>) delegate mediaType:(NSString*)type {
    
    if (([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeSavedPhotosAlbum] == NO) || (delegate == nil) || (controller == nil))
        return NO;
    
    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
    mediaUI.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    
    // Displays saved pictures and movies, if both are available, from the
    // Camera Roll album.
    //mediaUI.mediaTypes =[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
    
    //    if ([type isEqualToString:@"video"])
    //        mediaUI.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
    
    if ([type isEqualToString:@"image"])
        mediaUI.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
    
    // Hides the controls for moving & scaling pictures, or for
    // trimming movies. To instead show the controls, use YES.
    mediaUI.allowsEditing = NO;
    
    mediaUI.delegate = delegate;
    
    [self presentViewController:mediaUI animated:YES completion:^{
        
    }];
    return YES;
}

#pragma mark - Show Camera Method

- (BOOL) startCameraControllerFromViewController: (UIViewController*) controller usingDelegate: (id <UIImagePickerControllerDelegate,UINavigationControllerDelegate>) delegate {
    
    if (([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO) || (delegate == nil) || (controller == nil)) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                        message:@"Camera module not available."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        
        return NO;
    }
    
    
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    // Displays a control that allows the user to choose picture or
    // movie capture, if both are available:
    //cameraUI.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
    cameraUI.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
    
    // Hides the controls for moving & scaling pictures, or for
    // trimming movies. To instead show the controls, use YES.
    cameraUI.allowsEditing = NO;
    cameraUI.delegate = delegate;
    [self presentViewController:cameraUI animated:YES completion:nil];
    return YES;
}

#pragma mark - Picker Delegate Method

- (void) imagePickerController: (UIImagePickerController *) picker didFinishPickingMediaWithInfo: (NSDictionary *) info {
    
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    UIImage *originalImage, *editedImage, *imageToUse;
    
    // Handle a still image picked from a photo album
    if (CFStringCompare ((CFStringRef) mediaType, kUTTypeImage, 0) == kCFCompareEqualTo) {
        
        editedImage = (UIImage *) [info objectForKey:
                                   UIImagePickerControllerEditedImage];
        originalImage = (UIImage *) [info objectForKey:
                                     UIImagePickerControllerOriginalImage];
        
        if (editedImage) {
            imageToUse = editedImage;
        } else {
            imageToUse = originalImage;
        }
        
    }
   // img_ProfilePic.image=imageToUse;
    
   HYImageCropperViewController *imgCropperVC = [[HYImageCropperViewController alloc] initWithImage:imageToUse cropFrame:CGRectMake(0, 100.0f, self.view.frame.size.width, self.view.frame.size.width) limitScaleRatio:3.0];
    imgCropperVC.delegate = self;
    
    [self.navigationController pushViewController:imgCropperVC animated:YES];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}
#pragma mark - Delegate Methods Of VPImageCropper

- (void)imageCropper:(HYImageCropperViewController *)cropperViewController didFinished:(UIImage *)editedImage
{
    mainImgName = @"User_Profile.jpg";
    NSMutableArray *options = [[NSMutableArray alloc] init];
    NSDictionary *tempDict = [NSDictionary dictionaryWithObjectsAndKeys: [commonFuncObj mediaPathForDirectory:@"/Profile" FileName:mainImgName], @"namewithpath", @"300", @"heightwidth", @"1.0", @"quality", nil];
    [options addObject:tempDict];
    [commonFuncObj resizeAndStoreImages:editedImage Options:options];
    
    UIImage * mainImage = [UIImage imageWithContentsOfFile:[commonFuncObj mediaPathForDirectory:@"/Profile" FileName:mainImgName]];
    NSData *mainImageData = UIImageJPEGRepresentation(mainImage, 1);
    NSString *base64OfMainImage = [commonFuncObj base64forData:mainImageData];
    
    [self CallCheckImageQualityWebserviceWithUrl:[self getImageQualityURL]ImageData:base64OfMainImage WithImage:mainImage];
}

- (void)imageCropperDidCancel:(HYImageCropperViewController *)cropperViewController
{
    
}
#pragma mark- Check Image Quality Webservice

- (NSString*)getImageQualityURL
{
    NSString *hostURL = @"https://demo.uis.accenture.com/MEVISV2.0/api";
    NSString *contentURL = @"/Biometric";
    return [hostURL stringByAppendingString:contentURL];
}
-(void)CallCheckImageQualityWebserviceWithUrl:(NSString *)str_url ImageData:(NSString *)Imagedata WithImage:(UIImage *)Img_Profile
{
    [self waitViewShow:YES];

    NSError *error;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    NSURL *url = [NSURL URLWithString:str_url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:30.0];
    
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPMethod:@"QUALITY"];
    NSString *authStr =@"\\clouduser:Demosuite2013##";
    NSData *authData = [authStr dataUsingEncoding:NSASCIIStringEncoding];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", [authData base64EncodedString]];
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    NSDictionary *dict = [[NSDictionary alloc]initWithObjectsAndKeys:@"Face_Face2D", @"Modality", @"Image", @"Type",Imagedata, @"Base64Data",nil];
    
    //NSData *postData = [NSKeyedArchiver archivedDataWithRootObject:dict];

    NSData *postData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    [request setHTTPBody:postData];
    
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        

        UIViewController *visibleViewController = self.navigationController.visibleViewController;

        if (error)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (visibleViewController==self)
                {
                    [img_ProfilePic setImage:[UIImage imageNamed:@"img_profileplaceholder@2x.png"]];

                    [[HYAppDelegate sharedDelegate] alertWithError:error];
                    [self waitViewShow:NO];

                }
                

            });


        }
        else
        {

        
        NSError *jsonError;
        NSDictionary *dict =
        [NSDictionary dictionaryWithDictionary:[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments
                                                                                 error:&jsonError]];
        
        NSLog(@"response%@",dict);
        
        NSMutableArray *arr_qualityres = [dict objectForKey:@"QualityDatas"];
        if ([arr_qualityres count]>0)
        {
            NSDictionary *dict_qualityScore=[arr_qualityres objectAtIndex:[arr_qualityres count]-1];
            
            NSString *str_quality=[dict_qualityScore objectForKey:@"QualityScore"];
            
            NSLog(@"str_quality%@",str_quality);
            
            NSString *str_threshold= [self GetImageThreshold];
            if (![str_threshold containsString:@"Error"])
            {
                if ([str_quality floatValue]>= [str_threshold floatValue])
                {
                    NSLog(@"PersistImage");
                    dispatch_async(dispatch_get_main_queue(), ^{

                       [self CallPersistImageWebserviceWithImageData:Imagedata WithImage:Img_Profile Quality:str_quality];
                        
                    });
                    
                    
                }
                else
                {
                    NSLog(@"Try Again");
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self waitViewShow:NO];

                        
                        [img_ProfilePic setImage:[UIImage imageNamed:@"img_profileplaceholder@2x.png"]];
                        
                        
                        if (visibleViewController==self)
                        {
                            UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"Error" message:@"The Image Quality is Low.Please try again" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:@"Try Again", nil];
                            [alert show];
                            alert.tag=11;
                        }
                        
                    });
                }

            }
            else
            {
                [self waitViewShow:NO];

                [img_ProfilePic setImage:[UIImage imageNamed:@"img_profileplaceholder@2x.png"]];
                
                if (visibleViewController==self)
                {
                    UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"Error" message:@"Unable to get Threshold Value." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                }
            
            }
  
            
        }
        else
        {

            dispatch_async(dispatch_get_main_queue(), ^{
                [img_ProfilePic setImage:[UIImage imageNamed:@"img_profileplaceholder@2x.png"]];

                [self waitViewShow:NO];

             UIViewController *visibleViewController = self.navigationController.visibleViewController;
                if (visibleViewController==self)
                {
                    UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"Error" message:@"The Image seems Invalid.Please try again" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:@"Try Again", nil];
                    [alert show];
                    alert.tag=11;
                }
              
            });
            
        }
        }
        
    }];
    
    [postDataTask resume];

}


#pragma mark-  Image Threshold Value Webservice

- (NSString*)getImageThresholdURL
{
    NSString *hostURL = [[NSUserDefaults standardUserDefaults] stringForKey:@"web_services_base_url_preference"];
    NSString *contentURL = @"/bncwebservices/v1/electronics/imageThreshold";
    return [hostURL stringByAppendingString:contentURL];
}
-(NSString *)GetImageThreshold
{
    NSURL *url = [NSURL URLWithString:[self getImageThresholdURL]];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    NSError *error = nil;
    NSHTTPURLResponse *response = nil;
    NSData *jsonData = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    NSDictionary *dict;
    if (jsonData) {
        
        NSError *jsonError;
        dict =
        [NSDictionary dictionaryWithDictionary:[NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments
                                                                                 error:&jsonError]];
        return [dict objectForKey:@"value"];
        
    }
    else
    {
        return [NSString stringWithFormat:@"Error %@",error];
    }
    
}


#pragma mark- Persist Image Webservice

- (NSString*)getPersistImageURL
{
    NSString *hostURL = [[NSUserDefaults standardUserDefaults] stringForKey:@"web_services_base_url_preference"];
    NSString *contentURL = @"/bncwebservices/v1/electronics/uploadCustomerImage";
    return [hostURL stringByAppendingString:contentURL];
}
-(void)CallPersistImageWebserviceWithImageData:(NSString *)Imagedata WithImage:(UIImage *)Img_Profile Quality:(NSString *)str_threshold
{
    //[self waitViewShow:YES];
    
    NSError *error;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    NSURL *url = [NSURL URLWithString:[self getPersistImageURL]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:30.0];
    
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPMethod:@"POST"];
    NSLog(@"sjkgdsakjd%@",[[HYAppDelegate sharedDelegate]username]);
    NSDictionary *dict = [[NSDictionary alloc]initWithObjectsAndKeys:[[HYAppDelegate sharedDelegate]username], @"customerId",str_threshold,@"qualityScore",Imagedata, @"imageInBase64",nil];
    NSData *postData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    [request setHTTPBody:postData];
    
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        
        
        UIViewController *visibleViewController = self.navigationController.visibleViewController;
        
        if (error)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (visibleViewController==self)
                {
                    [self waitViewShow:NO];
                    
                    [[HYAppDelegate sharedDelegate] alertWithError:error];
                    
                }
                
                
            });
            
            
        }
        else
        {
            //[self waitViewShow:NO];
            
            
            NSError *jsonError;
            NSDictionary *dict =
            [NSDictionary dictionaryWithDictionary:[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments
                                                                                     error:&jsonError]];
            
            NSLog(@"response%@",dict);
            
            NSString *str_response = [dict objectForKey:@"status"];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (visibleViewController==self)
                {
                    [self waitViewShow:NO];
                    
                    NSLog(@"str_response%@",str_response);
                    if ([[str_response lowercaseString] isEqualToString:@"success"])
                    {
                        [img_ProfilePic setImage:Img_Profile];
                        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"Success" message:@"Your profile image is persisted successfully." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                        [alert show];
                    }
                    else
                    {
                        [img_ProfilePic setImage:[UIImage imageNamed:@"img_profileplaceholder@2x.png"]];

                        UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"Error" message:@"Error occurred while persisting image." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                        [alert show];
                        
                    }
                    
                }
                
                
            });

            
            

        }
        
    }];
    
    [postDataTask resume];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark-Alert Delegates
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag==11)
    {
        if (buttonIndex==1)
        {
            [sheet_profilepic showInView:self.view];
        }
    }

}

#pragma mark - FBLoginViewDelegate

- (void)loginViewShowingLoggedInUser:(FBLoginView *)loginView
{
    [FBSession.activeSession closeAndClearTokenInformation];
    
}

- (void)loginViewFetchedUserInfo:(FBLoginView *)loginView
                            user:(id<FBGraphUser>)user {
    // here we use helper properties of FBGraphUser to dot-through to first_name and
    // id properties of the json response from the server; alternatively we could use
    // NSDictionary methods such as objectForKey to get values from the my json object
    NSDictionary *userData=(NSDictionary *)user;
    NSLog(@"userData%@",userData);
    
    //To get Profile Picture of Fb
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large", [userData valueForKey:@"id"]]];
    UIImage *image = [UIImage imageWithData: [NSData dataWithContentsOfURL:url]];
    HYImageCropperViewController *imgCropperVC = [[HYImageCropperViewController alloc] initWithImage:image cropFrame:CGRectMake(0, 100.0f, self.view.frame.size.width, self.view.frame.size.width) limitScaleRatio:3.0];
    imgCropperVC.delegate = self;
    [self.navigationController pushViewController:imgCropperVC animated:YES];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

    [FBSession.activeSession closeAndClearTokenInformation];
}
- (void)loginViewShowingLoggedOutUser:(FBLoginView *)loginView
{
    [FBSession.activeSession closeAndClearTokenInformation];
}

- (void)loginView:(FBLoginView *)loginView handleError:(NSError *)error {
    // see https://developers.facebook.com/docs/reference/api/errors/ for general guidance on error handling for Facebook API
    // our policy here is to let the login view handle errors, but to log the results
    NSLog(@"FBLoginView encountered an error=%@", error);
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
