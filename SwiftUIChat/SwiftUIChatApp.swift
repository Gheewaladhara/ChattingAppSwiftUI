//
//  SwiftUIChatApp.swift
//  SwiftUIChat
//
//  Created by GHEEWALA DHARA on 30/05/24.
//

import SwiftUI
import FirebaseCore


//class AppDelegate: NSObject, UIApplicationDelegate {
//  func application(_ application: UIApplication,
//                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
//    FirebaseApp.configure()
//
//    return true
//  }
//}


@main
struct SwiftUIChatApp: App {
    
    var body: some Scene {
        WindowGroup {

           MainMessageView()
           
        }
    }
}
