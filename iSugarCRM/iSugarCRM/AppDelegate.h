//
//  AppDelegate.h
//  iSugarCRM
//
//  Created by Ved Surtani on 23/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RootViewController.h"
#import "SyncHandler.h"
@class ViewController;
@interface AppDelegate : UIResponder <UIApplicationDelegate,SyncHandlerDelegate>
@property (strong) SyncHandler *syncHandler;
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *nvc;
-(void)sync;
-(void)syncForModule:(NSString*) moduleName delegate:(id<SyncHandlerDelegate>) delegate;
-(void)showDashboardController;
-(void)showSyncSettingViewController;
-(BOOL)deleteDBData;
-(void)logout;
@end
