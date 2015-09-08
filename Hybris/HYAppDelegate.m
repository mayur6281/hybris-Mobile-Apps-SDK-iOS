//
// HYAppDelegate.m
// [y] hybris Platform
//
// Copyright (c) 2000-2013 hybris AG
// All rights reserved.
//
// This software is the confidential and proprietary information of hybris
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with hybris.
//

#import "HYCategoryManager.h"
#import "HYProductDetailViewController.h"
#import "HYOrderDetailViewController.h"
#import "HYStoreSearchViewController.h"
#import <HockeySDK/HockeySDK.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>
#import <Security/Security.h>
#import "KeychainItemWrapper.h"

#import "ALAlertBanner.h"

#import "BeaconsService.h"
#import "HYWebViewController.h"
#import "HYTabBarController.h"




#define IOS8 [[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0

@interface HYAppDelegate () <BITHockeyManagerDelegate, BITUpdateManagerDelegate, BITCrashManagerDelegate, UIAlertViewDelegate>
{
    
    
    NSDictionary *dict_promotions;
    
    NSMutableArray *arr_bodystring;
    NSMutableArray *arr_promotiontype;
    NSMutableArray *arr_producturl;

    int Promotionindex;
}

@property (assign, nonatomic) BOOL free;

/**
 *  Register an object for network activity notifications.
 *  The object being registered should make use of calls to HYConnectionStartedNotification and HYConnectionStoppedNotification.
 *  This method can safely be called more than once.
 *  @param object The objectto register.
 */
- (void)registerNetworkActivityIndicatorForObject:(id)object;


/**
 *  Unregister an object for network activity notifications.
 *  This method can safely be called more than once.
 *  @param object The object to unregister.
 */
- (void)unregisterNetworkActivityIndicatorForObject:(id)object;


/**
 *  Load the defaults from NSUserDefaults.
 *
 *  This method uses the default settings from the Settings bundle. It is in this bundle you should set the default
 *  behaviour of an app.
 */
- (void)loadApplicationDefaults;


/**
 *  Load the system settings form the config dictionary settings.plist.
 *
 *  This is used for settings not appropriate for NSUserDefaults
 */
- (void)loadSystemSettings;


/**
 *  Load the webservice url from NSUserDefaults.
 *
 *  This method uses the default settings from the Settings bundle and sets the webservice url to use according to the settings
 */
- (void)loadWebserviceUrl;

#ifndef DEBUG
/**
 * Uncaught exception handler
 */
static void uncaughtExceptionHandler(NSException *exception);
#endif

/**
 * Facebook handler
 */
- (void)sessionStateChanged:(FBSession *)session
   state                   :(FBSessionState)state
   error                   :(NSError *)error;


/**
 * Facebook block
 */
@property (nonatomic, strong) NSVoidBlock facebookCompletionBlock;

/**
 * name of the site (catalog) which the product data is loaded from
 */
@property (nonatomic, strong) NSString *site;

@end

@implementation HYAppDelegate


#pragma mark - Custom getters and setters

- (void)setIsLoggedIn:(BOOL)isLoggedIn {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults setValue:[NSNumber numberWithBool:isLoggedIn] forKey:@"user_logged_in"];
    [userDefaults synchronize];
}


- (BOOL)isLoggedIn {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    return [[userDefaults valueForKey:@"user_logged_in"] boolValue];
}


- (void)setUsername:(NSString *)username {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if (![username isEmpty]) {
        [userDefaults setValue:username forKey:@"logged_in_username"];
        [userDefaults synchronize];
    }
}


- (NSString *)username {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    return [userDefaults valueForKey:@"logged_in_username"];
}



#pragma mark - Preset App

- (void)resetCategories {
    [self loadWebserviceUrl];
    
    NSString *site = [[NSUserDefaults standardUserDefaults] stringForKey:@"web_services_site_url_suffix_preference"];
    
    // reset
    if (![self.site isEqualToString:site]) {
        if (self.site != nil) {
            [[NSNotificationCenter defaultCenter] postNotificationName:HYSiteChangedNotification object:nil];
        }
        
        self.site = site;
        
        if ([[site substringFromIndex:[site length] - 1] isEqualToString:@"/"]) {
            site = [site substringToIndex:[site length] - 1];
        }
        
        NSString *plistFileName = [NSString stringWithFormat:@"categories.%@", site];
        NSURL *pathToCategoriesPlist = [[self applicationPrivateDocumentsDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", plistFileName]];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:[[pathToCategoriesPlist filePathURL] path]]) {
            NSError *error;
            
            [[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:plistFileName ofType:@"plist"]
                                                    toPath:[[pathToCategoriesPlist filePathURL] path] error:&error];
        }
        
        NSURL *url = [NSURL fileURLWithPath:[[pathToCategoriesPlist filePathURL] path]];
        
        [HYCategoryManager reloadCategoriesFromPlist:url];
    }
    self.categoriesReady = YES;
}


- (void)loadApplicationDefaults {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *defaultsDictionary =
    [NSDictionary dictionaryWithContentsOfFile:[[[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"] stringByAppendingPathComponent:
                                                @"Root.plist"]];
    NSArray *preferences = [defaultsDictionary objectForKey:@"PreferenceSpecifiers"];
    NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];
    
    for (NSDictionary *prefSpecification in preferences) {
        NSString *key = [prefSpecification objectForKey:@"Key"];
        
        if (key) {
            [defaultsToRegister setObject:[prefSpecification objectForKey:@"DefaultValue"] forKey:key];
        }
    }
    
    [userDefaults setValue:@"1" forKey:@"keep_me_logged_in"]; //for refreshing tokens
    [userDefaults registerDefaults:defaultsToRegister];
    [userDefaults synchronize];
}


- (void)loadSystemSettings {
    NSURL *pathToSettingsPlist = [[self applicationPrivateDocumentsDirectory] URLByAppendingPathComponent:@"settings.plist"];
    NSError *error;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[[pathToSettingsPlist filePathURL] path]]) {
        [[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"settings" ofType:@"plist"]
                                                toPath:[[pathToSettingsPlist filePathURL] path] error:&error];
    } else {
        [[NSFileManager defaultManager] removeItemAtPath:[[pathToSettingsPlist filePathURL] path] error:&error];
        [[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"settings" ofType:@"plist"]
                                                toPath:[[pathToSettingsPlist filePathURL] path] error:&error];
    }
    
    NSURL *url = [NSURL fileURLWithPath:[[pathToSettingsPlist filePathURL] path]];
    self.configDictionary = [PListSerialisation dataFromPlistAtPath:url];
}


- (void)loadWebserviceUrl {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if ([userDefaults boolForKey:@"web_services_use_specific_base_url_preference"] && [[userDefaults stringForKey:@"web_services_specific_base_url_preference"] length] > 0) {
        [userDefaults setValue:[userDefaults stringForKey:@"web_services_specific_base_url_preference"] forKey:@"web_services_base_url_preference"];
    } else {
        [userDefaults setValue:[userDefaults stringForKey:@"web_services_predefined_base_url_preference"] forKey:@"web_services_base_url_preference"];
    }
    
    [userDefaults synchronize];
}



#pragma mark - Application life cycle

// TODO get code for init an app
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
  #ifndef DEBUG
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
#endif
    
    [[BITHockeyManager sharedHockeyManager] configureWithBetaIdentifier:@"BETA_IDENTIFIER"
                                                         liveIdentifier:nil
                                                               delegate:self];
    [[BITHockeyManager sharedHockeyManager] startManager];
    
    // Load the app's defaults
    [self loadApplicationDefaults];
    
    // Additional User level settings
    [self loadSystemSettings];
    
    // Set the locale info - this will get overrriden if the user logs in
    //    NSString *language = [[NSLocale currentLocale] objectForKey: NSLocaleLanguageCode];
    //    [[NSUserDefaults standardUserDefaults] setValue:language forKey:@"web_services_language_preference"];
    
    // This causes a problem with OCC as currency codes to not match up
    //    NSString *currency = [[NSLocale currentLocale] objectForKey: NSLocaleCurrencyCode];
    //    [[NSUserDefaults standardUserDefaults] setValue:currency forKey:@"web_services_currency_preference"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Link the content fetcher to the network activity indicator
    [self registerNetworkActivityIndicatorForObject:[HYWebService shared]];
    
    // This sets up the default Facets
    [self resetCategories];
    
    // UI Setup
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        [self.window setTintColor:UIColor_appTint];
    }
    
    // Tab bar
    UIImage *tabBarBackground = [[UIImage imageNamed:@"tabBarBackground.png"]
                                 resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    [[UITabBar appearance] setBackgroundImage:tabBarBackground];

    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        [[UITabBar appearance] setSelectedImageTintColor:UIColor_highlightTint];
        [[UITabBar appearance] setTintColor:UIColor_tabTint];
    }
    
    // Navigation bar
    UIImage *navigationBarBackground = [[UIImage imageNamed:@"navigationBar.png"]
                                        resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    [[UINavigationBar appearance] setBackgroundImage:navigationBarBackground forBarMetrics:UIBarMetricsDefault];
    
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        // Navigation bar buttons
        [[UIBarButtonItem appearance] setTintColor:[UIColor colorWithRed:39.0/255.0 green:53.0/255.0 blue:70.0/255.0 alpha:1.0]];
    }
        
    // Search bar
    UIImage *searchBackground = [[UIImage imageNamed:@"searchbar-background.png"]
                                 resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    [[UISearchBar appearance] setBackgroundImage:searchBackground];
    
    // Reachability
    Reachability *reachability = [Reachability reachabilityWithHostname:@"www.google.com"];
    reachability.reachableOnWWAN = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    [reachability startNotifier];
    
    if (IOS8) {
        // add user notification
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }

    self.free = YES;

    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"8492E75F-4FD6-469D-B132-043FE94921D8"];
    [[BeaconsService sharedBeaconsService] startRangingBeaconsWithUUID:uuid identifier:@"com.accenture.region" rangingBeaconsHandler:^(NSArray *beacons, NSError *error) {
        if (beacons && beacons.count > 0) {
            if (self.free) {
                CLBeacon *beacon=[beacons firstObject];
                //find nearest beacon
                for (CLBeacon *beaconItem in beacons) {
                    if(beaconItem.proximity == CLProximityImmediate){
                        beacon=beaconItem;
                        break;
                    }
                }
                if(beacon!=nil && self.free) {
                self.free = NO;
                NSString *url = [self getGetURLByBeacon];
                NSData *jsonData = [self getJSONDataOfBeacon:beacon];                
                
                [[HYWebService shared] fetchItemWithURL:url inputData:jsonData withCompletionBlock:^(NSData *data, NSError *error) {
                    if (data) {
                        NSError *jsonError;
                       
                      /*
                       //Offline Testing
                        NSString* str ={
                            @"{\"promotions\": [{\"promotionType\": \"Percentage discount\",\"description\": \"All branded reflective clothing and shoes at low prices to enhance your fitness\",\"endDate\": \"2099-01-01T00:00:00+05:30\",\"code\": \"JoggersDiscount30\"},{\"promotionType\": \"Percentage discount\",\"description\": \"All branded reflective Health equipments and supplements to beautify your fitness regime\",\"endDate\": \"2099-01-01T00:00:00+05:30\",\"code\": \"WorkoutDiscount50\"}],\"response\": \"User Record updated successfully.\",\"welcomeMessage\": \"Exciting deals waiting for you\"}"
                        };
                        
                        NSData *objectData = [str dataUsingEncoding:NSUTF8StringEncoding];
                        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:objectData
                                                                             options:NSJSONReadingMutableContainers
                                                                               error:&jsonError];
                       
                       */
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
                        
                    dict_promotions=dict;
                        
                    NSLog(@"dict_promotions FROM HYBRIS %@",dict_promotions);

                    NSString *strWelcome = [dict objectForKey:@"welcomeMessage"];
                    NSMutableArray *promotions = [dict objectForKey:@"promotions"];
                    for (NSDictionary * promotion in promotions)
                    {
                        NSString *description = [promotion objectForKey:@"description"];
                        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                ALAlertBanner *banner = [ALAlertBanner alertBannerForView:self.window
                                                                                    style:ALAlertBannerStyleNotify
                                                                                 position:ALAlertBannerPositionUnderNavBar
                                                                                    title:strWelcome subtitle:description
                                                                              tappedBlock:^(ALAlertBanner *alertBanner) {
                                                                                  [alertBanner hide];
                                                                                  //show alert dialog
                                                                                  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(nil, @"Error alert box title") message:strWelcome delegate:self cancelButtonTitle:NSLocalizedString(@"Dismiss", @"OK button") otherButtonTitles:@"Click here for promotions",nil];
                                                                                  [alert show];
                                                                                  alert.tag=22;
                                                                                  /*
                                                                                   HYWebViewController *webViewController = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"WebViewController"];
                                                                                   NSString *url = [NSString stringWithFormat:@"%@%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"web_services_base_url_preference"], @"/bncstorefront/electronics/en/Open-Catalogue/Cameras/Film-cameras/FUN-Flash-Single-Use-Camera%2C-27%2B12-pic/p/779841?site=electronics"];
                                                                                   webViewController.urlString = url;
                                                                                   if ([self.window.rootViewController isKindOfClass:[HYTabBarController class]])
                                                                                   {
                                                                                   
                                                                                   UIViewController *nav = ((HYTabBarController *)(self.window.rootViewController)).selectedViewController;
                                                                                   [(HYNavigationViewController *)nav pushViewController:webViewController animated:YES];
                                                                                   }*/
                                                                              }];
                                banner.secondsToShow = 8;
                                banner.showAnimationDuration = .25f;
                                banner.hideAnimationDuration = .2f;
                                
                                [banner show];
                            });
                            
                            
                         
                            /*
                             NSString *url = [NSString stringWithFormat:@"%@%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"web_services_base_url_preference"], @"/bncwebservices/v1/"];
                             url = [url stringByAppendingPathComponent:@"electronics/CustomerStoreLogin"];
                             url = [url stringByAppendingPathComponent:@"8492E75F-4FD6-469D-B132-043FE94921D8"];
                             url = [url stringByAppendingPathComponent:@"Chiba"];
                             
                             if (self.isLoggedIn) {
                             url = [url stringByAppendingPathComponent:self.username];
                             } else {
                             url = [url stringByAppendingPathComponent:[self identifierForDevice]];
                             }
                             
                             NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
                             NSOperationQueue *queue = [[NSOperationQueue alloc] init];
                             
                             [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
                             [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse* response, NSData* data, NSError* connectionError) {
                             
                             [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                             
                             if (!connectionError) {
                             NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                             dispatch_async(dispatch_get_main_queue(), ^{
                             ALAlertBanner *banner = [ALAlertBanner alertBannerForView:self.window
                             style:ALAlertBannerStyleNotify
                             position:ALAlertBannerPositionUnderNavBar
                             title:@""
                             subtitle:message
                             tappedBlock:^(ALAlertBanner *alertBanner) {
                             [alertBanner hide];
                             }];
                             banner.secondsToShow = 8;
                             banner.showAnimationDuration = .25f;
                             banner.hideAnimationDuration = .2f;
                             
                             [banner show];
                             });
                             }
                             }];*/
                        } else {
                            UILocalNotification *notification = [[UILocalNotification alloc] init];
                            notification.soundName = UILocalNotificationDefaultSoundName;
                            //notification.alertBody = [strWelcome stringByAppendingString:description];
                            notification.alertBody = strWelcome ;
                            notification.applicationIconBadgeNumber = [UIApplication sharedApplication].applicationIconBadgeNumber + 1;
                            notification.timeZone = [NSTimeZone systemTimeZone];
                            notification.fireDate = [NSDate date];
                            
                            if (self.isLoggedIn) {
                                notification.userInfo = @{@"username": self.username, @"uuid": @"8492E75F-4FD6-469D-B132-043FE94921D8",@"welcomemsg": strWelcome};
                            } else {
                                notification.userInfo = @{@"username": [self identifierForDevice], @"uuid": @"8492E75F-4FD6-469D-B132-043FE94921D8",@"welcomemsg": strWelcome};
                            }
                            
                            [[UIApplication sharedApplication] scheduleLocalNotification:notification];
                        }
                    }
                    
                }
                
            }];
                    
                }
                __weak typeof(self) weak_self = self;
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15* 60 * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
                    weak_self.free = YES;
                });
            }
        }
    }];
    
    return YES;
}


#pragma mark- Alert Body Description

-(void)ShowBeaconPromotionAlert
{
    UIAlertView *alertView;
    if ([arr_bodystring count]!=0) {
    
     if (Promotionindex ==[arr_bodystring count]-1) {
        alertView= [[UIAlertView alloc] initWithTitle:[arr_promotiontype objectAtIndex:Promotionindex]
                                              message:[arr_bodystring objectAtIndex:Promotionindex] delegate:self cancelButtonTitle:@"Done" otherButtonTitles:@"Dismiss",@"Previous",@"Go to Product",nil];
    }
    
    else
    {
        alertView = [[UIAlertView alloc] initWithTitle:[arr_promotiontype objectAtIndex:Promotionindex]
                                               message:[arr_bodystring objectAtIndex:Promotionindex] delegate:self cancelButtonTitle:@"Next Promotion" otherButtonTitles:@"Dismiss",@"Previous",@"Go to Product",nil];
    }
    
    [alertView show];
    alertView.tag=222;
    }
}

-(void)GetPromotiondataFromResponse
{
    arr_bodystring=[NSMutableArray array];
    arr_promotiontype=[NSMutableArray array];
    arr_producturl=[NSMutableArray array];
    Promotionindex=0;
    
    NSMutableArray *promotions = [dict_promotions objectForKey:@"promotions"];
    
    NSString*str_promotionType;
    NSString *str_bodystring;
    NSString *str_productUrl;

    for (NSDictionary * promotion in promotions)
    {
        str_bodystring=[NSString stringWithFormat:@"%@ Code: %@",[promotion objectForKey:@"description"],[promotion objectForKey:@"code"]];
        str_promotionType=[promotion objectForKey:@"promotionType"];
        str_productUrl=[promotion objectForKey:@"productUrl"];
    
        
        [arr_bodystring addObject:str_bodystring];
        [arr_promotiontype addObject:str_promotionType];
        [arr_producturl addObject:str_productUrl];

        
    }
    NSLog(@"arr_Promotion String %@",arr_bodystring);
    NSLog(@"arr_promotionType %@",arr_promotiontype);
    NSLog(@"arr_producturl %@",arr_producturl);

  UIAlertView  *alertView= [[UIAlertView alloc] initWithTitle:[arr_promotiontype objectAtIndex:Promotionindex]
                                          message:[arr_bodystring objectAtIndex:Promotionindex] delegate:self cancelButtonTitle:@"Next Promotion" otherButtonTitles:@"Dismiss",nil];
    [alertView show];
    alertView.tag=222;
    Promotionindex++;


}
#pragma mark- Alert Delegates for Redirecting to Product Page

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
   if (alertView.tag==22)
   {
       switch (buttonIndex) {
           case 0:
               NSLog(@"Dismiss promotion 22");
               break;
           case 1:
               NSLog(@"Next Promotionn 22");
               
               [self GetPromotiondataFromResponse];
               break;
               
           default:
               break;
       }
   }
   else if (alertView.tag==222)
        
    {
        switch (buttonIndex) {
            case 0:
            {
                NSLog(@"Next Promotionn");
                if (Promotionindex!=[arr_bodystring count]-1)
                {
                    Promotionindex++;
                    
                    [self ShowBeaconPromotionAlert];
                }
            }
                break;
            case 1:
            {
                NSLog(@"Dismiss promotion");
                Promotionindex=0;
            }
                break;
            case 2:
            {
                NSLog(@"Previous promotion");
                if (Promotionindex!=0) {
                    Promotionindex--;
                    [self ShowBeaconPromotionAlert];
                }
            }
                break;
                case 3:
            {
                NSLog(@"Product Page");
                
                NSLog(@"str_producturl is %@",[arr_producturl objectAtIndex:Promotionindex]);
                if (Promotionindex!=0) {

                if ([arr_producturl objectAtIndex:Promotionindex]!=nil && ![[arr_producturl objectAtIndex:Promotionindex] isEqualToString:@""]) {
                    
                    HYWebViewController *webViewController = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"WebViewController"];
                    NSString *url = [NSString stringWithFormat:@"%@/%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"web_services_base_url_preference"], [arr_producturl objectAtIndex:Promotionindex]];
                    
                    NSLog(@"PRODUCTURL FOR REDIRECTION is %@",url);

                    //NSString *url = [NSString stringWithFormat:@"%@%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"web_services_base_url_preference"], @"/bncstorefront/electronics/en/Open-Catalogue/Cameras/Film-cameras/FUN-Flash-Single-Use-Camera%2C-27%2B12-pic/p/779841?site=electronics"];
                    webViewController.urlString = url;
                    if ([self.window.rootViewController isKindOfClass:[HYTabBarController class]])
                    {
                        NSLog(@"Successful entry");
                        UIViewController *nav = ((HYTabBarController *)(self.window.rootViewController)).selectedViewController;
                        [(HYNavigationViewController *)nav pushViewController:webViewController animated:YES];
                    }
                }
                Promotionindex=0;
                }
            }
            
            default:
                break;
        }
    }
        else
    {
    }
}


- (void)reachabilityChanged:(NSNotification*)notification {
    Reachability * reachability = [notification object];
    
    if([reachability isReachable]) {
        logInfo(@"Reachable");
    }
    else {
        logInfo(@"Not Reachable");
    }
    
    if ([[self visibleViewController] respondsToSelector:@selector(reachabilityChanged:)]) {
        [[self visibleViewController] performSelector:@selector(reachabilityChanged:) withObject:reachability];
    }
}



- (void)applicationWillResignActive:(UIApplication *)application {
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    [self unregisterNetworkActivityIndicatorForObject:[HYWebService shared]];
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    [self registerNetworkActivityIndicatorForObject:[HYWebService shared]];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];

}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background,
    // optionally refresh the user interface.
    
    // Clean up aborted facebook connections
    if (FBSession.activeSession.state == FBSessionStateCreatedOpening) {
        [FBSession.activeSession close];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self resetCategories];
}


- (void)applicationWillTerminate:(UIApplication *)application {
    [self unregisterNetworkActivityIndicatorForObject:[HYWebService shared]];
    [FBSession.activeSession close];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    
    if (notification.userInfo) {
        NSString *username = notification.userInfo[@"username"];
        NSString *uuid = notification.userInfo[@"uuid"];
        NSString *strWelcome = notification.userInfo[@"welcomemsg"];

        
        if (username && uuid) {
            NSString *url = [NSString stringWithFormat:@"%@%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"web_services_base_url_preference"], @"/bncwebservices/v1/"];
            url = [url stringByAppendingPathComponent:@"electronics/CustomerStoreLogin"];
            url = [url stringByAppendingPathComponent:uuid];
            url = [url stringByAppendingPathComponent:@"Chiba"];
            url = [url stringByAppendingPathComponent:username];
            
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
            NSOperationQueue *queue = [[NSOperationQueue alloc] init];
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse* response, NSData* data, NSError* connectionError) {
                
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                
                if (!connectionError) {
//                    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                           ALAlertBanner *banner = [ALAlertBanner alertBannerForView:self.window
//                                                                            style:ALAlertBannerStyleNotify
//                                                                         position:ALAlertBannerPositionUnderNavBar
//                                                                            title:@"" subtitle:message
//                                                                      tappedBlock:^(ALAlertBanner *alertBanner) {
//                                                                          [alertBanner hide];
                    
                                                                          UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(nil, @"Error alert box title") message:strWelcome delegate:self cancelButtonTitle:NSLocalizedString(@"Dismiss", @"OK button") otherButtonTitles:@"Click here for promotions",nil];
                                                                          [alert show];
                                                                          alert.tag=22;
//                                                                      }];
//                        banner.secondsToShow = 8;
//                        banner.showAnimationDuration = .25f;
//                        banner.hideAnimationDuration = .2f;
//                        
//                        [banner show];
  //                 });
                }
            }];
        }
    }
}

- (NSString *)identifierForDevice {
    KeychainItemWrapper *keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:@"UUID" accessGroup:nil];
    NSDictionary *data = [keychainItem objectForKey:(__bridge id)kSecValueData];
    
    if (!data || data.count == 0) {
        data = [NSDictionary dictionaryWithObject:[[[UIDevice currentDevice] identifierForVendor] UUIDString]
                                           forKey:@"uuid"];
        
        [keychainItem setObject:data forKey:(__bridge id)kSecValueData];
    }
    
    return data[@"uuid"];
}

#pragma mark - Helper Methods

#ifndef DEBUG
static void uncaughtExceptionHandler(NSException *exception) {
    logError(@"App crashed for exception: %@/ %@", exception, [exception callStackSymbols]);
    
    if ([[NSThread currentThread] isEqual:[NSThread mainThread]]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Application Problem", @"Crash alert title")
                                                        message:NSLocalizedString(
                                                                                  @"Sorry we have to close the app because an unknown error has occurred. We have logged this error and if this happens frequently you should look out for an app update.",
                                                                                  @"Friendly crash alert copy")
                                                       delegate:[[UIApplication sharedApplication] delegate] cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", @"OK button"), nil];
        [alert show];
        
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:5.0]];
    }
}
#endif


- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


- (NSURL *)applicationPrivateDocumentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryDirectory = [paths objectAtIndex:0];
    
    libraryDirectory = [libraryDirectory stringByAppendingPathComponent:@"Private Documents"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:libraryDirectory]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:libraryDirectory
                                  withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return [NSURL fileURLWithPath:libraryDirectory isDirectory:YES];
}


/// Responsible for returning the visible view controller
- (UIViewController *)visibleViewController {
    UIViewController *vc = self.window.rootViewController;
    
    while (vc.presentedViewController != nil) {
        if ([vc respondsToSelector:@selector(presentedViewController)]) {
            vc = ((UINavigationController *)vc).presentedViewController;
        }
        
        if ([vc respondsToSelector:@selector(selectedViewController)]) {
            vc = ((UITabBarController *)vc).selectedViewController;
        }
        
        if ([vc respondsToSelector:@selector(visibleViewController)]) {
            vc = ((UINavigationController *)vc).visibleViewController;
        }
    }
    
    return vc;
}


- (void)registerNetworkActivityIndicatorForObject:(id)object {
    id activityIndicator = [SDNetworkActivityIndicator sharedActivityIndicator];
    
    // Remove observer in case it was previously added
    [self unregisterNetworkActivityIndicatorForObject:object];
    
    [[NSNotificationCenter defaultCenter] addObserver:activityIndicator
                                             selector:@selector(startActivity)
                                                 name:HYConnectionStartedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:activityIndicator
                                             selector:@selector(stopActivity)
                                                 name:HYConnectionStoppedNotification object:nil];
}


- (void)unregisterNetworkActivityIndicatorForObject:(id)object {
    id activityIndicator = [SDNetworkActivityIndicator sharedActivityIndicator];
    
    [[NSNotificationCenter defaultCenter] removeObserver:activityIndicator name:HYConnectionStartedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:activityIndicator name:HYConnectionStoppedNotification object:nil];
}


+ (HYAppDelegate *)sharedDelegate {
    return (HYAppDelegate *)[[UIApplication sharedApplication] delegate];
}


- (void)alertWithError:(NSError *)error
{
    NSString *errorMsg;
    NSString *str_header;
    
    if ([error.userInfo objectForKey:@"message"]) {
        errorMsg = [error.userInfo objectForKey:@"message"];
        str_header=@"Error";
    }
    else if ([error.userInfo objectForKey:@"detailMessage"]) {
        errorMsg = [error.userInfo objectForKey:@"detailMessage"];
        str_header=@"Error";

        
    }
    else if ([error.userInfo objectForKey:@"welcomeMessage"]) {
        
        NSMutableArray *promotions = [error.userInfo objectForKey:@"promotions"];
        
        for (NSDictionary * promotion in promotions)
        {
            errorMsg = [promotion objectForKey:@"description"];
        }

       str_header=[error.userInfo objectForKey:@"welcomeMessage"];

    }
    else {
        errorMsg = error.localizedDescription;
        str_header=@"Error";

    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(str_header, @"Error alert box title") message:errorMsg delegate:self cancelButtonTitle:NSLocalizedString(@"OK", @"OK button") otherButtonTitles:nil];
    [alert show];
}


#pragma mark - Facebook Delegate Methods

- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState)state
                      error:(NSError *)error {
    switch (state) {
        case FBSessionStateOpen: {
            if (!error) {
                // We have a valid session
                NSLog(@"User session found");
            }
        }
            break;
        case FBSessionStateClosed:
        case FBSessionStateClosedLoginFailed: {
            [FBSession.activeSession closeAndClearTokenInformation];
        }
            break;
        default: {
        }
            break;
    }
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:FBSessionStateChangedNotification
     object:session];
    
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedString(@"ErrorMessage", @"Error alert title")
                                  message:error.localizedDescription
                                  delegate:nil
                                  cancelButtonTitle:NSLocalizedString(@"OK", @"OK button")
                                  otherButtonTitles:nil];
        [alertView show];
    }
    
    if (state == FBSessionStateOpen && self.facebookCompletionBlock) {
        _facebookCompletionBlock();
        self.facebookCompletionBlock = nil;
    }
}


- (BOOL)openSessionWithAllowLoginUI:(BOOL)allowLoginUI completionBlock:(NSVoidBlock)completionBlock {
    self.facebookCompletionBlock = completionBlock;
    NSArray *permissions = [[NSArray alloc] initWithObjects:
                            @"publish_actions",@"requestNewReadPermissions",
                            nil];
    return [FBSession openActiveSessionWithPublishPermissions:permissions
                                              defaultAudience:FBSessionDefaultAudienceFriends
                                                 allowLoginUI:allowLoginUI
                                            completionHandler:^(FBSession *session,
                                                                FBSessionState state,
                                                                NSError *error) {
                                                [self sessionStateChanged:session
                                                                    state:state
                                                                    error:error];
                                            }];
}

// Required where SSO is not available
- (BOOL) application:(UIApplication *)application
             openURL:(NSURL *)url
   sourceApplication:(NSString *)sourceApplication
          annotation:(id)annotation {    
    return [FBSession.activeSession handleOpenURL:url];
}



#pragma mark - HockeyApp delegate methods

- (NSString *)customDeviceIdentifierForUpdateManager:(BITUpdateManager *)updateManager {
    return nil;
}

#pragma mark - Promotional message
- (NSString*)getGetURLByBeacon
{
    NSString *hostURL = [[NSUserDefaults standardUserDefaults] stringForKey:@"web_services_specific_base_url_preference"];
    NSString *contentURL = @"/bncwebservices/v1/electronics/performBeaconFunction";
    return [hostURL stringByAppendingString:contentURL];
}

- (NSData*)getJSONDataOfBeacon:(CLBeacon*)beacon
{
    NSNumberFormatter* numberFormatter = [[NSNumberFormatter alloc] init];
    NSString *strMajor = [numberFormatter stringFromNumber:beacon.major];
    NSString *strMinor = [numberFormatter stringFromNumber:beacon.minor];
    NSString *strUUID = beacon.proximityUUID.UUIDString;
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:strUUID, @"beaconId", strMajor, @"majorId", strMinor, @"minorId",[[[UIDevice currentDevice] identifierForVendor] UUIDString],@"deviceId",@"Chiba", @"storeId", nil];

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
    //remove new line formatter
    NSString* json= [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    json = [json stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    NSLog(@"%@",json);
    jsonData = [json dataUsingEncoding:NSUTF8StringEncoding];
    
    return jsonData;
}
@end
