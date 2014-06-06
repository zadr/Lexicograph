#import "LXLexicographApplication.h"

#import "LXViewController.h"

@implementation LXLexicographApplication
- (BOOL) application:(UIApplication *) application didFinishLaunchingWithOptions:(NSDictionary *) launchOptions {
	_window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	_window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[LXViewController alloc] init]];

	[_window makeKeyAndVisible];

	return YES;
}
@end
