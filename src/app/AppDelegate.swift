
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    let session = AppSession()

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        Log.i("\(AppName) v\(AppVersion).\(AppBuild) started", launchOptions)
        session.start()
        return true
    }

    // Lifecycle

    func applicationWillEnterForeground(_ application: UIApplication) {
        Log.i("\(AppName) will return from background")
        session.resume()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        Log.i("\(AppName) did become active")
    }

    func applicationWillResignActive(_ application: UIApplication) {
        Log.i("\(AppName) will become inactive")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        Log.i("\(AppName) did enter background")
        session.pause()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        Log.i("\(AppName) will terminate")
    }

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        Log.w("\(AppName) received memory warning")
    }

    // Security

    func applicationProtectedDataWillBecomeUnavailable(_ application: UIApplication) {
        Log.i("\(AppName) can't access protected data")
    }

    func applicationProtectedDataDidBecomeAvailable(_ application: UIApplication) {
        Log.i("\(AppName) can access protected data")
    }

    // Links

    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        Log.i("\(AppName) received URL", options[.sourceApplication], url)
        session.didReceiveProvisioningURL(url)
        return true
    }
}
