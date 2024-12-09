
import Foundation

let AppName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
let AppBuild = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
let AppVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
let AppIdentifier = Bundle.main.bundleIdentifier!
