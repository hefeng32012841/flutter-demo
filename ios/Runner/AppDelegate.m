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
    [audioSession setCategory:AVAudioSessionCategoryPlayback
                  withOptions:AVAudioSessionCategoryOptionMixWithOthers
                  // withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
                        error:&error];
    [audioSession setMode:AVAudioSessionModeVoiceChat error:&error];

    if (error) {
        NSLog(@"Failed to configure audio session: %@", error);
    }

    [audioSession setActive:YES error:&error];
    [self switchToEarPiece];
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

- (void)switchToEarPiece {
    NSError *error = nil;
    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error];
    if (error) {
        NSLog(@"切换到耳机时出错: %@", error.localizedDescription);
    } else {
        NSLog(@"已切换到耳机");
    }
}


@end
