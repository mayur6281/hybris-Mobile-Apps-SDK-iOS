 //
// HYProfileViewController.m
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

#import "HYProfileViewController.h"
#import "HYLoginViewController.h"
#import "HYAddressListViewController.h"
#import "HYArrayViewController.h"
#import "HYChangePasswordViewController.h"
#import "HYChangeEmailViewController.h"
#import "HYProfileDetailViewController.h"
#import "JawboneService.h"

//healthkit
#import "AccHealthDataRegister.h"
#import "NSSet+HealthKitPermission.h"
#import "HKHealthStore+SampleType.h"
#import "AccHealthDataOuter.h"

#import "ALAlertBanner.h"


/// Define the cell ordering
typedef enum {
    HYOrderHistoryCell = 0,
    HYAddressBookCell = 1,
    HYPaymentDetailsCell = 2,
    HYUpdateProfileCell = 3,
    HYChangeEmailCell = 4,
    HYChangePasswordCell = 5,
    HYHealthKitCell = 6,
    HYGeolocationCell = 7,
    HYUploadPhotoCell = 8,


    
} HYLoggedInCellPosition;

//NSString *const kAPIExplorerID = @"2oscoof9Jn4";
//NSString *const kAPIExplorerSecret = @"ab889cb872d35f05f3ae1218b5e9790f6739292f";

@interface HYProfileViewController ()
{
    NSMutableArray *arr_bodystring;
    NSMutableArray *arr_promotiontype;
    
    int Promotionindex;
}

//For Geolocation.

@property (nonatomic, strong) CLLocationManager *locationManager;


@property (nonatomic, strong) NSDictionary *profile;
@property (nonatomic) BOOL viewAppeared;
@property (nonatomic, strong) JawboneService *jawboneService;

//healthkit
@property (nonatomic, strong) NSData *healthData;

- (void)updateHeaderView;

@end


@implementation HYProfileViewController

@synthesize latitude = _latitude;
@synthesize longitude = _longitude;

- (void)viewDidLoad {
    [super viewDidLoad];

    _viewAppeared = NO;
    self.profileNameLabel.text = @"";
    self.profileNameLabel.font = UIFont_headerFooterFont;
    self.profileNameLabel.textColor = [UIColor whiteColor];
    self.profileEmailLabel.text = @"";
    self.profileEmailLabel.font = UIFont_smallBoldFont;
    self.profileEmailLabel.textColor = [UIColor whiteColor];
    self.notLoggedInLabel.textColor = [UIColor whiteColor];

    self.title = NSLocalizedString(@"Account", nil);
    
    [self initLeftBarButton:NO];
    
    self.jawboneService = [JawboneService sharedService];
    
    [self.jawboneService validateSessionWithCompletion:^(UPSession *session, NSError *error) {
        
        if (session != nil)
        {
            [self initLeftBarButton:YES];
        }
    }];
}

- (void)initLeftBarButton:(BOOL)isLogin
{
    UIBarButtonItem *jawboneButton;
    if (isLogin) {
        jawboneButton =
        [[UIBarButtonItem alloc] initWithTitle:@"UP Logout" style:UIBarButtonItemStylePlain target:self action:@selector(jawboneLogoutButtonClicked)];
    }else {
        jawboneButton =
        [[UIBarButtonItem alloc] initWithTitle:@"UP Login" style:UIBarButtonItemStylePlain target:self action:@selector(jawboneLoginButtonClicked)];
    }
    
    self.navigationItem.leftBarButtonItem = jawboneButton;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];    
    [self updateHeaderView];
    [self getHealthPermission];
    
    
    
}


- (void)viewDidUnload {
    [self setProfileNameLabel:nil];
    [self setProfileEmailLabel:nil];
    [self setLogInOutButton:nil];
    [self setNotLoggedInLabel:nil];
    [super viewDidUnload];
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([HYAppDelegate sharedDelegate].isLoggedIn) {
        return 2;
    }
    else {
        return 1;
    }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Common section
    if (section == 0) {
        return 0;
    }
    // Logged-in section
    else {
        return 9;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *MenuIdentifier = @"Hybris Menu Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MenuIdentifier];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MenuIdentifier];
    }

    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"disclosure.png"] highlightedImage:[UIImage imageNamed:@"disclosure-on.png"]];

    switch (indexPath.row) {
        case HYOrderHistoryCell: {
            cell.textLabel.text = NSLocalizedString(@"Order History", "Title for the view that shows the order history.");
        }
            break;
        case HYAddressBookCell: {
            cell.textLabel.text = NSLocalizedString(@"Address Book", "Title for the view that shows the users address book.");
        }
            break;
        case HYPaymentDetailsCell: {
            cell.textLabel.text = NSLocalizedString(@"Payment Details", "Title for the view that shows the users payment details.");
        }
            break;
        case HYUpdateProfileCell: {
            cell.textLabel.text = NSLocalizedString(@"Update Profile", "Title for the view to update the users profile.");
        }
            break;
        case HYChangeEmailCell: {
            cell.textLabel.text = NSLocalizedString(@"Change Email", "Title for the view to change the users email.");
        }
            break;
        case HYChangePasswordCell: {
            cell.textLabel.text = NSLocalizedString(@"Change Password", "Title for the view to change the users password.");
        }
            break;
            
        case HYHealthKitCell: {
            cell.textLabel.text = @"Health";
        }
            break;
        case HYGeolocationCell: {
            cell.textLabel.text = NSLocalizedString(@"Send Location", "Title for sending location of user.");
        }
            break;
        case HYUploadPhotoCell: {
            cell.textLabel.text = NSLocalizedString(@"Update Profile Picture", "Title for the view to Update Profile Picture of user.");
        }
            break;
        default: {
        }
        break;
    }

    return cell;
}


#pragma mark - Table view delegate methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch (indexPath.row) {
        case HYUpdateProfileCell:
        {
            HYProfileDetailViewController *vc = [[HYProfileDetailViewController alloc] initWithTitle:NSLocalizedString(@"Update Profile", "Title for the view to update the users profile.") values:self.profile];
            [self.navigationController pushViewController:vc animated:YES];
        }
        break;
        case HYChangePasswordCell:
        {
            HYChangePasswordViewController *vc = [[HYChangePasswordViewController alloc] initWithTitle:NSLocalizedString(@"Change Password", "Title for the view to change the users password.")];
            [self.navigationController pushViewController:vc animated:YES];
        }
        break;
        case HYChangeEmailCell: {
            HYChangeEmailViewController *vc = [[HYChangeEmailViewController alloc] initWithTitle:NSLocalizedString(@"Change Email", "Title for the view to change the users email.")];
            [self.navigationController pushViewController:vc animated:YES];
        }
        break;
        case HYAddressBookCell: {
            [self performSegueWithIdentifier:@"Show Address Segue" sender:self];
        }
        break;
        case HYPaymentDetailsCell: {
            [self performSegueWithIdentifier:@"Show Payment Segue" sender:self];
        }
        break;
        case HYOrderHistoryCell: {
            [self performSegueWithIdentifier:@"Show Order Segue" sender:self];
        }
        break;
        case HYHealthKitCell: {
            [self postURLWithData:[self getHealthURL]];
            

        }
            break;
        case HYGeolocationCell: {
            [self StartTrackingLocation];
        }
            break;
        case HYUploadPhotoCell: {
            //[self UploadPhoto];
            [self performSegueWithIdentifier:@"Show ProfilePic Segue" sender:self];

           
        }
            break;
        default: {
        }
        break;
    }
}


#pragma mark - Segue method

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Profile to Login Segue"]) {
        HYLoginViewController *vc = (HYLoginViewController *)((UINavigationController *)segue.destinationViewController).visibleViewController;
        vc.delegate = self;
    }
    else if ([segue.identifier isEqualToString:@"Show Address Segue"]) {
        HYAddressListViewController *vc = (HYAddressListViewController *)(UINavigationController *)segue.destinationViewController;
        vc.canSelectAddress = NO;
    }
    else if ([segue.identifier isEqualToString:@"Show Languages Segue"]) {
        HYArrayViewController *vc = (HYArrayViewController *)(UINavigationController *)segue.destinationViewController;
        [vc waitViewShow:YES];
        [[HYWebService shared] languagesWithCompletionBlock:^(NSArray *languages, NSError *error) {
                if (error) {
                    [[HYAppDelegate sharedDelegate] alertWithError:error];
                }
                else {
                    // Get the profile information
                    [[HYWebService shared] customerProfileWithCompletionBlock:^(NSDictionary *profileDictionary, NSError *error) {
                            if (error) {
                                [[HYAppDelegate sharedDelegate] alertWithError:error];
                            }
                            else {
                                vc.classType = NSStringFromClass ([NSDictionary class]);
                                vc.key = @"nativeName";
                                vc.details = languages;

                                // Find current language and select it
                                for (int i = 0; i < vc.details.count; i++) {
                                    if ([[[vc.details objectAtIndex:i] objectForKey:@"isocode"] isEqualToString:[[profileDictionary objectForKey:@"language"]
                                                objectForKey:@"isocode"]]) {
                                        vc.selectedItem = i;
                                        break;
                                    }
                                }
                            }
                        }];
                }
            }];
    }
    else if ([segue.identifier isEqualToString:@"Show Currencies Segue"]) {
        HYArrayViewController *vc = (HYArrayViewController *)(UINavigationController *)segue.destinationViewController;
        [vc waitViewShow:YES];
        [[HYWebService shared] currenciesWithCompletionBlock:^(NSArray *currencies, NSError *error) {
                if (error) {
                    [[HYAppDelegate sharedDelegate] alertWithError:error];
                }
                else {
                    // Get the profile information
                    [[HYWebService shared] customerProfileWithCompletionBlock:^(NSDictionary *profileDictionary, NSError *error) {
                            if (error) {
                                [[HYAppDelegate sharedDelegate] alertWithError:error];
                            }
                            else {
                                vc.classType = NSStringFromClass ([NSDictionary class]);
                                vc.key = @"name";
                                vc.details = currencies;

                                // Find current currency and select it
                                for (int i = 0; i < vc.details.count; i++) {
                                    if ([[[vc.details objectAtIndex:i] objectForKey:@"isocode"] isEqualToString:[[profileDictionary objectForKey:@"currency"]
                                                objectForKey:@"isocode"]]) {
                                        vc.selectedItem = i;
                                        break;
                                    }
                                }
                            }
                        }];
                }
            }];
    }
    else {
        [super prepareForSegue:segue sender:sender];
    }
}



#pragma mark - ModalViewControllerDelegate

- (void)requestDismissAnimated:(BOOL)animated sender:(id)sender {
    [self dismissModalViewControllerAnimated:animated];
}



#pragma mark - IB action methods

- (IBAction)login:(id)sender {
    if (![HYAppDelegate sharedDelegate].isLoggedIn) {
        [self performSegueWithIdentifier:@"Profile to Login Segue" sender:self];
    }
}


- (IBAction)logout:(id)sender {
    if ([HYAppDelegate sharedDelegate].isLoggedIn) {
        [[HYAppDelegate sharedDelegate] setIsLoggedIn:NO];
        [[HYAppDelegate sharedDelegate] setUsername:nil];

        [self updateHeaderView];
    }
}

- (void)jawboneLoginButtonClicked
{
    [self.jawboneService startSessionCompletion:^(UPSession *session, NSError *error) {
       
        if (session) {
            
            [self initLeftBarButton:YES];
        }else {
            [[[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
    }];
}

- (void)jawboneLogoutButtonClicked
{
    [self.jawboneService endCurrentSession];
    
    [self initLeftBarButton:NO];
}

#pragma mark - private methods

- (void)updateHeaderView {    
    self.notLoggedInLabel.text = NSLocalizedString(@"Not logged in", @"User not logged in message");
    
    if ([HYAppDelegate sharedDelegate].isLoggedIn) {
        UIBarButtonItem *logoutButton =
        [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringWithDefaultValue(@"Logout", nil, [NSBundle mainBundle], @"Logout", @"Logout button")
                                         style:UIBarButtonItemStylePlain target:self action:@selector(logout:)];
        self.navigationItem.rightBarButtonItem = logoutButton;
        [self waitViewShow:YES];
        
        [[HYWebService shared] customerProfileWithCompletionBlock:^(NSDictionary *dictionary, NSError *error) {
            [self waitViewShow:NO];
            
            if (error) {
                if ([[error.userInfo objectForKey:@"reason"] isEqualToString:@"Refresh Token Failed"]) {
                    [[HYAppDelegate sharedDelegate] setIsLoggedIn:NO];
                    self.profileNameLabel.text = @"";
                    self.profileEmailLabel.text = @"";
                    self.notLoggedInLabel.hidden = NO;
                    
                    UIBarButtonItem *loginButton =
                    [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringWithDefaultValue (@"Login", nil, [NSBundle mainBundle], @"Login", @"Login button")
                                                     style:UIBarButtonItemStylePlain target:self action:@selector(login:)];
                    self.navigationItem.rightBarButtonItem = loginButton;
                    [self.tableView reloadData];
                } else {
                    [[HYAppDelegate sharedDelegate] alertWithError:error];
                }
            }
            else {
                if ([HYAppDelegate sharedDelegate].isLoggedIn) {
                    self.profile = [NSDictionary dictionaryWithDictionary:dictionary];
                    self.profileEmailLabel.text = [_profile objectForKey:@"displayUid"];
                    self.profileNameLabel.text = [_profile objectForKey:@"name"];
                    self.notLoggedInLabel.hidden = YES;
                    [self.tableView reloadData];
                }
            }
        }];
    } else {
        self.profileNameLabel.text = @"";
        self.profileEmailLabel.text = @"";
        self.notLoggedInLabel.hidden = NO;
        
        UIBarButtonItem *loginButton =
        [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringWithDefaultValue (@"Login", nil, [NSBundle mainBundle], @"Login", @"Login button")
                                         style:UIBarButtonItemStylePlain target:self action:@selector(login:)];
        self.navigationItem.rightBarButtonItem = loginButton;
        [self.tableView reloadData];
    }
}

#pragma mark - Healthkit function
//healthkit permission
- (void)getHealthPermission
{
    self.healthStore = [[HKHealthStore alloc] init];
    NSSet *readSet = [NSSet setReadPermission];
    NSSet *writeSet = [NSSet setWritePermission];
    [self.healthStore requestAuthorizationToShareTypes:writeSet readTypes:readSet completion:^(BOOL success, NSError *error) {
        if (success)
        {
            //            [self.healthStore readAllRequiredType];
            AccHealthDataRegister *accRegister = [[AccHealthDataRegister alloc] initWithHealthStore:self.healthStore];
            [accRegister registAlldata:self];
        }
        else
        {
            NSLog(@"You didn't allow HealthKit to access these read/write data types. In your app, try to handle this error gracefully when a user decides not to provide access. The error was: %@. If you're using a simulator, try it on a device.", error);
            return ;
        }
    }];
}

//delegate deal with the data
- (void)FinishCollect
{
    NSInteger count = [[[AccHealthDataOuter shareInstance] dataArrays] count];
    NSLog(@"%@", [[AccHealthDataOuter shareInstance] dataArrays]);
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:[[AccHealthDataOuter shareInstance] dataArrays], @"HealthData", nil];
 
    NSLog(@"Total:%ld", (long)count);
    
    _healthData = [NSJSONSerialization dataWithJSONObject:dictionary
                                                  options:NSJSONWritingPrettyPrinted
                                                  error:nil];
   
}

- (void)postURLWithData:(NSString*)url
{ 
    // it is required to remove all new line chars from json
    NSString* json= [[NSString alloc] initWithData:_healthData encoding:NSUTF8StringEncoding];
   //json=@"{ \"HealthData\" : [ { \"Value\" : \"BE38A5BB-7974-4D3C-ADDA-A760096AF8ED\", \"type\" : \"customerId\" }, { \"Value\" : \"1\", \"type\" : \"HKCategoryTypeIdentifierSleepAnalysis\" }, { \"Value\" : \"165.346697\", \"type\" : \"HKQuantityTypeIdentifierBodyMass\" }, { \"Value\" : \"130.000000\", \"type\" : \"HKQuantityTypeIdentifierBodyMassIndex\" }, { \"Value\" : \"0.550000\", \"type\" : \"HKQuantityTypeIdentifierBodyFatPercentage\" }, { \"Value\" : \"150.000000\", \"type\" : \"HKQuantityTypeIdentifierHeartRate\" }, { \"Value\" : \"11332.401316\", \"type\" : \"HKQuantityTypeIdentifierBloodPressureDiastolic\" }, { \"Value\" : \"16931.940789\", \"type\" : \"HKQuantityTypeIdentifierBloodPressureSystolic\" }, { \"Value\" : \"3856.000000\", \"type\" : \"HKQuantityTypeIdentifierStepCount\" }, { \"Value\" : \"23.540000\", \"type\" : \"HKQuantityTypeIdentifierDistanceWalkingRunning\" }, { \"Value\" : \"0.055000\", \"type\" : \"HKQuantityTypeIdentifierDietaryCholesterol\" } ]}";
    
    json = [json stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    NSLog(@"%@",json);
    _healthData = [json dataUsingEncoding:NSUTF8StringEncoding];      
    
    [[HYWebService shared] postHealthDataForURL:url inputData:_healthData withCompletionBlock:^(NSDictionary *dict, NSError *error) {
        
        if (error) {
            [[HYAppDelegate sharedDelegate] alertWithError:error];
            
        }
        else
        {
        arr_bodystring=[NSMutableArray array];
        arr_promotiontype=[NSMutableArray array];
        Promotionindex=0;
        
        NSMutableArray *promotions = [dict objectForKey:@"promotions"];

        NSString*str_promotionType;
        NSString *str_bodystring;
        for (NSDictionary * promotion in promotions)
        {
            str_bodystring=[NSString stringWithFormat:@"%@ Code: %@",[promotion objectForKey:@"description"],[promotion objectForKey:@"code"]];
            str_promotionType=[promotion objectForKey:@"promotionType"];
            
            [arr_bodystring addObject:str_bodystring];
            [arr_promotiontype addObject:str_promotionType];
            
        }
        NSLog(@"arr_bodystring %@",arr_bodystring);
        NSLog(@"arr_promotiontype %@",arr_promotiontype);
        [self ShowHealthPromotionAlert];
        }
    }];
}

#pragma mark- Alert Body Description

-(void)ShowHealthPromotionAlert
{
    UIAlertView *alertView;
    if ([arr_bodystring count]!=0) {
        if (Promotionindex ==0) {
            
            alertView= [[UIAlertView alloc] initWithTitle:[arr_promotiontype objectAtIndex:Promotionindex]
                                                  message:[arr_bodystring objectAtIndex:Promotionindex] delegate:self cancelButtonTitle:@"Next Promotion" otherButtonTitles:@"Dismiss",nil];
        }
        else  if (Promotionindex ==[arr_bodystring count]-1) {
            alertView= [[UIAlertView alloc] initWithTitle:[arr_promotiontype objectAtIndex:Promotionindex]
                                                  message:[arr_bodystring objectAtIndex:Promotionindex] delegate:self cancelButtonTitle:@"Done" otherButtonTitles:@"Dismiss",@"Previous",nil];
        }
        
        else
        {
            alertView = [[UIAlertView alloc] initWithTitle:[arr_promotiontype objectAtIndex:Promotionindex]
                                                   message:[arr_bodystring objectAtIndex:Promotionindex] delegate:self cancelButtonTitle:@"Next Promotion" otherButtonTitles:@"Dismiss",@"Previous",nil];
        }
        
        [alertView show];
        alertView.tag=11;

    }
    
    }

-(void)ShowGeolocationPromotionAlert
{
    UIAlertView *alertView;
    if ([arr_bodystring count]!=0) {
    
    if ([arr_bodystring count] ==1) {
        alertView= [[UIAlertView alloc] initWithTitle:[arr_promotiontype objectAtIndex:Promotionindex]
                                              message:[arr_bodystring objectAtIndex:Promotionindex] delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
    }
    
   else if (Promotionindex ==0) {
        alertView= [[UIAlertView alloc] initWithTitle:[arr_promotiontype objectAtIndex:Promotionindex]
                                              message:[arr_bodystring objectAtIndex:Promotionindex] delegate:self cancelButtonTitle:@"Next Promotion" otherButtonTitles:@"Dismiss",nil];
    }
    else if (Promotionindex ==[arr_bodystring count]-1) {
        alertView= [[UIAlertView alloc] initWithTitle:[arr_promotiontype objectAtIndex:Promotionindex]
                                              message:[arr_bodystring objectAtIndex:Promotionindex] delegate:self cancelButtonTitle:@"Done" otherButtonTitles:@"Dismiss",@"Previous",nil];
    }
    
    else
    {
        alertView = [[UIAlertView alloc] initWithTitle:[arr_promotiontype objectAtIndex:Promotionindex]
                                               message:[arr_bodystring objectAtIndex:Promotionindex] delegate:self cancelButtonTitle:@"Next Promotion" otherButtonTitles:@"Dismiss",@"Previous",nil];
    }
    
    [alertView show];
    alertView.tag=33;
    }
}
- (NSString*)getHealthURL
{
    NSString *hostURL = [[NSUserDefaults standardUserDefaults] stringForKey:@"web_services_specific_base_url_preference"];
    
    //NSString *hostURL = [[NSUserDefaults standardUserDefaults] stringForKey:@"web_services_predefined_base_url_preference"];

    
    NSString *contentURL = @"/bncwebservices/v1/electronics/CustomerHealthData/saveCustomerHealthData";
    return [hostURL stringByAppendingString:contentURL];
}
#pragma mark- Alert Delegates for Redirecting to Product Page

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag==11)
        
    {
        switch (buttonIndex) {
            case 0:
            {
                NSLog(@"Next Promotion");
                if (Promotionindex!=[arr_bodystring count]-1)
                {
                    Promotionindex++;
                    
                    [self ShowHealthPromotionAlert];
                }
             }
                break;
            case 1:
            {
                NSLog(@"Cancel");
                Promotionindex=0;
            }
                break;
            case 2:
            {
                NSLog(@"Previous");
                if (Promotionindex!=0) {
                    Promotionindex--;
                    [self ShowHealthPromotionAlert];

                }

                
            }
                break;
                
            default:
                break;
        }
    }
    
    
    else if (alertView.tag==22)
    {
        switch (buttonIndex) {
            case 0:
                NSLog(@"Dismiss");
                break;
            case 1:
                NSLog(@"Next Promotion");
                [self ShowGeolocationPromotionAlert];
                break;
                
            default:
                break;
        }
    
    }
    else if (alertView.tag==33)
        
    {
        switch (buttonIndex) {
            case 0:
            {
                NSLog(@"Next Promotion");
                if (Promotionindex!=[arr_bodystring count]-1)
                {
                    Promotionindex++;
                    
                    [self ShowGeolocationPromotionAlert];
                }
            }
                break;
            case 1:
            {
                NSLog(@"Cancel");
                Promotionindex=0;
            }
                break;
            case 2:
            {
                NSLog(@"Previous");
                if (Promotionindex!=0) {
                    Promotionindex--;
                    [self ShowGeolocationPromotionAlert];
                    
                }
                
                
            }
                break;
                
            default:
                break;
        }
    }
}
//-(void)TestURl
//{
//    NSString *url = [NSString stringWithFormat:@"%@%@", [[NSUserDefaults standardUserDefaults] stringForKey:@"web_services_base_url_preference"], @"/bncwebservices/v1/"];
//    url = [url stringByAppendingPathComponent:@"electronics/CustomerStoreLogin"];
//    url = [url stringByAppendingPathComponent:@"8492E75F-4FD6-469D-B132-043FE94921D8"];
//    url = [url stringByAppendingPathComponent:@"Chiba"];
//    url = [url stringByAppendingPathComponent:@"swarnima.gupta@accenture.com"];
//    
//    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
//    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
//    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
//    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse* response, NSData* data, NSError* connectionError) {
//        
//        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
//        
//        if (!connectionError) {
//            NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//            dispatch_async(dispatch_get_main_queue(), ^{
//                ALAlertBanner *banner = [ALAlertBanner alertBannerForView:self.view
//                                                                    style:ALAlertBannerStyleNotify
//                                                                 position:ALAlertBannerPositionTop
//                                                                    title:@"" subtitle:message
//                                                              tappedBlock:^(ALAlertBanner *alertBanner) {
//                                                                  [alertBanner hide];
//                                                              }];
//                banner.secondsToShow = 8;
//                banner.showAnimationDuration = .25f;
//                banner.hideAnimationDuration = .2f;
//                
//                [banner show];
//            });
//        }
//    }];
//}

#pragma mark - GreetCustomer by sending GeolocationData

-(void)StartTrackingLocation
{
    if (self.locationManager == nil) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = LOCATION_ACCURACY;
    }
    
    
    [self startLocationUpdate];
}
- (void)SendGeolocation:(CGFloat)Latitude Longi:(CGFloat)Longitude
{
    NSLog(@"Location%f,%f",Latitude,Longitude);
    [self waitViewShow:YES];
    
    NSString *EmailID;
    
    if ([HYAppDelegate sharedDelegate].isLoggedIn) {
        EmailID = [HYAppDelegate sharedDelegate].username;
        //should try and renew access_token or logout the user
    }
    
    NSLocale *locale = [NSLocale currentLocale];
    NSString *countryCode = [locale objectForKey: NSLocaleCountryCode];
    
    NSString *countryName = [locale displayNameForKey: NSLocaleCountryCode
                                                value: countryCode];
    
    NSLog(@"Country Name %@",countryName);
    
    if ([[countryName lowercaseString]isEqualToString:@"united states"])
    {
        Latitude=37.78;
        Longitude=-122.41;
    }
    else if ([[countryName lowercaseString]isEqualToString:@"united kingdom"])
    {
        Latitude=51.50;
        Longitude=-0.12;
    }
    else if ([[countryName lowercaseString]isEqualToString:@"germany"])
    {
        Latitude=52.51;
        Longitude=13.38;
    }
    else if ([[countryName lowercaseString]isEqualToString:@"france"])
    {
        Latitude=48.85;
        Longitude=2.35;
    }
    else if ([[countryName lowercaseString]isEqualToString:@"australia"])
    {
        Latitude=-35.30;
        Longitude=149.12;
    }
    
    [[HYWebService shared] GreetCustomerWithLat:[NSString stringWithFormat:@"%.2f",Latitude] Longi:[NSString stringWithFormat:@"%.2f",Longitude] CustEmailId:EmailID completionBlock:^(NSDictionary *dict ,NSError *error) {
        
        arr_bodystring=[NSMutableArray array];
        arr_promotiontype=[NSMutableArray array];
        Promotionindex=0;
        NSString *str_header;

        
        if (error) {
            if ([error.userInfo objectForKey:@"welcomeMessage"]) {
                
                NSMutableArray *promotions = [error.userInfo objectForKey:@"promotions"];
                
                NSString*str_promotionType;
                NSString *str_bodystring;
                for (NSDictionary * promotion in promotions)
                {
                    str_bodystring=[NSString stringWithFormat:@"%@ Code: %@",[promotion objectForKey:@"description"],[promotion objectForKey:@"code"]];
                    str_promotionType=[promotion objectForKey:@"promotionType"];
                    
                    [arr_bodystring addObject:str_bodystring];
                    [arr_promotiontype addObject:str_promotionType];
                    
                }
                NSLog(@"arr_bodystring %@",arr_bodystring);

                str_header=[error.userInfo objectForKey:@"welcomeMessage"];
                
            }
            
            
            
        }
        else {
            NSMutableArray *promotions = [dict objectForKey:@"promotions"];
            NSLog(@"dfkjdsgfkjdsgkfsdfhdslfh");
            
            NSString*str_promotionType;
            NSString *str_bodystring;
            
            for (NSDictionary * promotion in promotions)
            {
                str_bodystring=[NSString stringWithFormat:@"%@ Code: %@",[promotion objectForKey:@"description"],[promotion objectForKey:@"code"]];
                str_promotionType=[promotion objectForKey:@"promotionType"];
                
                [arr_bodystring addObject:str_bodystring];
                [arr_promotiontype addObject:str_promotionType];
            }
            
            str_header=[error.userInfo objectForKey:@"welcomeMessage"];
         }
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(nil, @"Error alert box title") message:str_header delegate:self cancelButtonTitle:NSLocalizedString(@"Dismiss", @"OK button") otherButtonTitles:@"Click here for promotions",nil];
        [alert show];
        alert.tag=22;
        
        [self waitViewShow:NO];
    }];
}
#pragma mark - For Taking Geolocation


- (void)startLocationUpdate {
    
    self.didFindLocation = NO; // like this

    [self.locationManager startUpdatingLocation];
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyNearestTenMeters];


    [self performSelector:@selector(locationUpdateTimedOut) withObject:nil afterDelay:LOCATION_TIMEOUT];
}


- (void)locationUpdateTimedOut {
    [self.locationManager stopUpdatingLocation];
    

}

#pragma mark - Location service delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
    if (!self.didFindLocation) {
        self.didFindLocation = YES;
        [self.locationManager stopUpdatingLocation];
        
        // do the rest of your stuff
        
        CLLocation *currentLocation = newLocation;
        
        if (currentLocation != nil) {
            self.latitude =  currentLocation.coordinate.latitude;
            self.longitude = currentLocation.coordinate.longitude;
            [self SendGeolocation:self.latitude Longi:self.longitude];
        }
    }
 }


- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [self locationError:error];
}


- (void)locationError:(NSError *)error {
    [self.locationManager stopUpdatingLocation];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(locationUpdateTimedOut) object:nil];
    
    switch([error code])
    {
        case kCLErrorDenied:
            break;
        case kCLErrorNetwork: // general, network-related error
        default:
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error alert box title") message:NSLocalizedString(@"Unable to geolocate you.", @"Error message for location update that took too long.") delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK button") otherButtonTitles:nil];
            [alert show];
        }
            break;
    }
    
}




@end
