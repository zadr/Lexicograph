import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	@lazy var window = UIWindow(frame: UIScreen.mainScreen().bounds)

	func application(application: UIApplication, didFinishLaunchingWithOptions options: NSDictionary?) -> Bool {
		window.rootViewController = UINavigationController(rootViewController: ViewController(nibName: nil, nibBundle: nil))
		window.makeKeyAndVisible()
		return true
	}
}
