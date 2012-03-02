//
//  AppDelegate.m
//  iSugarCRM
//
//  Created by Ved Surtani on 23/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "JSONKit.h"
#import "RootViewController.h"
#import "OrderedDictionary.h"
#import "SugarCRMMetadataStore.h"
#import "WebserviceSession.h"
#import "DataObjectField.h"
#import "DataObjectMetadata.h"
#import "WebserviceMetadata.h"
#import "DBSession.h"
#import "DataObject.h"
#import "ListViewMetadata.h"
#import "SyncHandler.h"
#import "LoginViewController.h"
#import "DashboardController.h"
#import "ApplicationKeyStore.h"
#import "LoginUtils.h"
#import "SettingsStore.h"
#import "SyncSettingsViewController.h"

NSString * session=nil;

@interface AppDelegate ()
-(void)resetApp;
- (void) resignFirstResponderRec:(UIView*) view;
@end

@implementation AppDelegate
@synthesize window = _window;
@synthesize nvc;
@synthesize syncHandler;

int usernameLength,passwordLength;


#pragma mark UIApplicationDelegate methods

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    LoginViewController *lvc = [[LoginViewController alloc] init];
    if(![LoginUtils keyChainHasUserData])
    {
        self.window.rootViewController = lvc;
        [self.window makeKeyAndVisible];
        return YES;
    } else {
        [self showDashboardController];
        return YES;
    }
}
-(void)showDashboardController{
    //[self logout];
    DashboardController *dc = [[DashboardController alloc] init];
    dc.title = @"Modules";
    nvc = [[UINavigationController alloc] initWithRootViewController:dc];
    self.window.rootViewController = nvc;
    [self.window makeKeyAndVisible];
}

-(void)showSyncSettingViewController{
    SyncSettingsViewController *syncSettings = [[SyncSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    syncSettings.title = @"Sync Setup";
    nvc = [[UINavigationController alloc] initWithRootViewController:syncSettings];
    self.window.rootViewController = nvc;
    [self.window makeKeyAndVisible];
}

-(void)sync
{
    SugarCRMMetadataStore *sugarMetaDataStore = [SugarCRMMetadataStore sharedInstance];
    [sugarMetaDataStore configureMetadata];
    syncHandler = [[SyncHandler alloc] init];
    syncHandler.delegate = self;
    NSString *startDate = [SettingsStore objectForKey:kStartDateIdentifier];
    NSString *endDate = [SettingsStore objectForKey:kEndDateIdentifier];
    [syncHandler syncWithStartDate:startDate endDate:endDate];
}

-(BOOL)deleteDBData{
    SugarCRMMetadataStore *sugarMetaDataStore = [SugarCRMMetadataStore sharedInstance];
    bool deletionFailed = false;
    
    for(NSString *moduleName in sugarMetaDataStore.modulesSupported){
        DBSession *dbSession = [DBSession sessionWithMetadata:[sugarMetaDataStore dbMetadataForModule:moduleName]];
        if(![dbSession deleteAllRecordsInTable])
        {
            deletionFailed=true;
        }
    }
    return !deletionFailed;
}
-(void)logout
{
    NSMutableDictionary* restDataDictionary=[[OrderedDictionary alloc]init];
    [restDataDictionary setObject:session forKey:@"session"];
    NSMutableDictionary* urlParams=[[OrderedDictionary alloc] init];
    [urlParams setObject:@"logout" forKey:@"method"];
    [urlParams setObject:@"JSON" forKey:@"input_type"];
    [urlParams setObject:@"JSON" forKey:@"response_type"];
    [urlParams setObject:restDataDictionary forKey:@"rest_data"];
    NSString* urlString=[[NSString stringWithFormat:@"%@",[LoginUtils urlStringForParams:urlParams]] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    NSMutableURLRequest* request=[[NSMutableURLRequest alloc]initWithURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"POST"];  
    NSURLResponse* response = [[NSURLResponse alloc] init]; 
    NSError* error = nil;  
    NSData* logoutResponseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error]; 
    if (error) {
        NSLog(@"Error Logging Out!");
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Logout" message:@"Failed to Logout" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
        [alertView show];
        return;
    } 
    NSLog(@"logout response = %@",[logoutResponseData objectFromJSONData]);
    session = nil;
    [self resetApp];

}

-(void)resetApp{
    [self deleteDBData];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kAppAuthenticationState];
    LoginViewController *lvc = [[LoginViewController alloc] init];
    self.window.rootViewController =  lvc;
}

-(void) syncForModule:(NSString *)moduleName delegate:(id<SyncHandlerDelegate>)delegate
{
    syncHandler = [[SyncHandler alloc] init];
    syncHandler.delegate = delegate;
    [syncHandler syncForModule:moduleName];
}

-(void)syncHandler:(SyncHandler*)syncHandler failedWithError:(NSError*)error
{
    
}
-(void)syncComplete:(SyncHandler*)syncHandler
{
    
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    for (UIView * view in [_window subviews]){
        [self resignFirstResponderRec:view];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (void) resignFirstResponderRec:(UIView*) view {
    if ([view respondsToSelector:@selector(resignFirstResponder)]){
        [view resignFirstResponder];
    }
    
    for (UIView * subview in [view subviews]){
        [self resignFirstResponderRec:subview];
    }
}

@end
