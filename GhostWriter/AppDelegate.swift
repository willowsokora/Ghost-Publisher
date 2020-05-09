//
//  AppDelegate.swift
//  GhostWriter
//
//  Created by Jacob Sokora on 4/19/20.
//  Copyright © 2020 Jacob Sokora. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {



	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
		if let blogURL = UserDefaults.standard.string(forKey: "blogURL"),
			let blogTitle = UserDefaults.standard.string(forKey: "blogTitle"),
			let blogUser = UserDefaults.standard.string(forKey: "blogUser"),
			let sessionCookie = UserDefaults.standard.string(forKey: "sessionCookie"),
			let sessionExpires = UserDefaults.standard.value(forKey: "sessionExpires") as? Date {
				AuthManager.instance.session = Session(user: blogUser, blogURL: blogURL, blogTitle: blogTitle, sessionCookie: sessionCookie, expires: sessionExpires)
		}
		return true
	}

	// MARK: UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		// Called when a new scene session is being created.
		// Use this method to select a configuration to create the new scene with.
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
		// Called when the user discards a scene session.
		// If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
		// Use this method to release any resources that were specific to the discarded scenes, as they will not return.
	}


}

