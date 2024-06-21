#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#import <WebKit/WebKit.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
  [self enableWebViewDeveloperExtras];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)enableWebViewDeveloperExtras {
  if (@available(iOS 17.0, *)) {
      [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"WebKitDeveloperExtras"];
      [[NSUserDefaults standardUserDefaults] synchronize];
  }
}

@end
