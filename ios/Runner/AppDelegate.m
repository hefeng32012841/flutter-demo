#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#import <WebKit/WebKit.h>
@import AVFoundation;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
  [self enableWebViewDeveloperExtras];
  
  FlutterViewController* controller = (FlutterViewController*)self.window.rootViewController;

  FlutterMethodChannel* audioChannel = [FlutterMethodChannel methodChannelWithName:@"com.example.audio"
                                                                  binaryMessenger:controller.binaryMessenger];

  [audioChannel setMethodCallHandler:^(FlutterMethodCall* call, FlutterResult result) {
      if ([@"changeAudioOutput" isEqualToString:call.method]) {
          NSDictionary *arguments = call.arguments;
          NSString *output = arguments[@"output"];
          [self changeAudioOutput:output result:result];
      } else {
          result(FlutterMethodNotImplemented);
      }
  }];

  [self configureAudioSession];
  
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)enableWebViewDeveloperExtras {
  if (@available(iOS 17.0, *)) {
      [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"WebKitDeveloperExtras"];
      [[NSUserDefaults standardUserDefaults] synchronize];
  }
}

- (void)configureAudioSession {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];

    NSError *error = nil;
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                  withOptions:AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionAllowBluetoothA2DP
                        error:&error];
    [audioSession setMode:AVAudioSessionModeDefault error:&error];

    if (error) {
        NSLog(@"Failed to configure audio session: %@", error);
    }

    [audioSession setActive:YES error:&error];
}

- (void)changeAudioOutput:(NSString*)output result:(FlutterResult)result {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error = nil;

    [audioSession setActive:YES error:&error];
    if ([output isEqualToString:@"earpiece"]) {
        [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error];
    } else if ([output isEqualToString:@"speaker"]) {
        [audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
    }

    if (error) {
        result([FlutterError errorWithCode:@"UNAVAILABLE"
                                   message:@"Audio configuration error"
                                   details:error.localizedDescription]);
    } else {
        result(nil);
    }
}


@end
