#import "VBAppDelegate.h"
#import "VBMainViewController.h"
#import "VBEngine.h"

@implementation VBAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:NO];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor blackColor];

    VBMainViewController *rootVC = [[VBMainViewController alloc] init];
    self.window.rootViewController = rootVC;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    VBEngine *engine = [VBEngine sharedEngine];
    if (engine.isRunning && !engine.backgroundEnabled) {
        [engine stop];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[VBEngine sharedEngine] stop];
}

@end
