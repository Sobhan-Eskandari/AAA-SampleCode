//
//  AppDelegate.swift
//  PassengerApp
//
//  Created by ADMIN on 04/05/17.
//  Copyright © 2017 V3Cube. All rights reserved.
//

import UIKit
import GoogleMaps
import AVFoundation
import GoogleSignIn    
import FirebaseAnalytics
import Firebase
import IQKeyboardManagerSwift
//import FBSDKCoreKit
import Bagel
import UserNotifications


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SINManagedPushDelegate    {

    var window: UIWindow?
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
    var push:SINManagedPush!
    var refreshRequired = true
    var fcmDeviceToken = ""
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        GeneralFunctions.saveValue(key: "APP_IS_IN_BACKGROUND", value: false as AnyObject)
        GeneralFunctions.saveValue(key: "REFRESH_APP", value: false as AnyObject)
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        
        /* SET FONTFAMILY */
        GeneralFunctions.saveValue(key: "FONTFAMILY", value: Utils.getFontWeightList(familyName: Utils.fontFname) as AnyObject)
        UIFont.overrideDefaultTypography()
        /* */
        registerForLocalNotification(on: application)
        
        // Override point for customization after application launch.
        GeneralFunctions.saveValue(key: "SERVERURL", value: CommonUtils.webServer as AnyObject)
        
    
        // For UFX Provider
        GeneralFunctions.removeValue(key: "UFX_PROVIDER_FLOW_ADDRESS_DETAIS")
        if(GeneralFunctions.isKeyExistInUserDefaults(key: "UFXCartData") == true){
            GeneralFunctions.saveValue(key: "UFXCartData", value: [[NSDictionary]]() as AnyObject)
        }
        
        Configurations.setAppLocal()
        
        //SDImageCache.shared().clearMemory()
        //SDImageCache.shared().clearDisk()
        
        GeneralFunctions.saveValue(key: "SINCHCALLING", value: false as AnyObject)
        if Configurations.isDevelopmentMode() == true{
            self.push = Sinch.managedPush(with: SINAPSEnvironment.development)
        }else{
            self.push = Sinch.managedPush(with: SINAPSEnvironment.production)
        }
        self.push.delegate = self
        self.push.setDesiredPushTypeAutomatically()
        self.push.registerUserNotificationSettings()
        
        GeneralFunctions.saveValue(key: Utils.SERVICE_CATEGORY_ID, value: "" as AnyObject)
        GeneralFunctions.saveValue(key: Utils.IS_WALLET_AMOUNT_UPDATE_KEY, value: "false" as AnyObject)
        
        if launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] != nil {
            //            (GeneralFunctions()).setError(uv: Application.window!.rootViewController!, title: "", content: "From Push")
            let userInfo = launchOptions?[UIApplication.LaunchOptionsKey.remoteNotification] as! [AnyHashable : Any]
            
            let notification = userInfo["aps"] as? NSDictionary
            
            if(notification?.get("body") != "" && (notification!.get("body")).getJsonDataDict().get("MsgType") == "CHAT"){
                
               
                if(Application.window != nil && Application.window?.rootViewController != nil){
                    
                    if(GeneralFunctions.getVisibleViewController(Application.window!.rootViewController) != nil && GeneralFunctions.getVisibleViewController(Application.window!.rootViewController)!.className != "ChatUV"){
                        GeneralFunctions.saveValue(key: "OPEN_MSG_SCREEN", value: notification!.get("body") as AnyObject)
                    }
                }
                
            }else if (notification?.getObj("alert"))?.get("loc-key") == "SIN_INCOMING_CALL_DISPLAY_NAME"{
                
                if GeneralFunctions.getMemberd() != "" {
                    SinchCalling.getInstance().initSinchClient()
                    let result:SINNotificationResult = SINPushHelper.queryPushNotificationPayload(userInfo)
                    if result.isCall(){
                        GeneralFunctions.saveValue(key: "SINCHCALLING", value: true as AnyObject)
                        
                        SinchCalling.getInstance().client.relayRemotePushNotification(userInfo)
                    }
                }
                
            }else if(notification?.get("body") != "" && ((notification!.get("body")).getJsonDataDict().get("MsgType") == "TripCancelledByDriver" || (notification!.get("body")).getJsonDataDict().get("Message") == "TripCancelledByDriver" || (notification!.get("body")).getJsonDataDict().get("Message") == "TripEnd" || (notification!.get("body")).getJsonDataDict().get("MsgType") == "TripEnd")){
                
                if(Application.window != nil && Application.window?.rootViewController != nil){
                    
                    if(GeneralFunctions.getVisibleViewController(Application.window!.rootViewController) != nil && GeneralFunctions.getVisibleViewController(Application.window!.rootViewController)!.className != "RatingUV"){
                        GeneralFunctions.saveValue(key: "OPEN_RATING_SCREEN", value: "\((notification!.get("body")).getJsonDataDict().get("iTripId"))" as AnyObject)
                    }
                }
                
            }
            
        }
        
    
        Configurations.setAppThemeNavBar()
        
//        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.toolbarDoneBarButtonItemText = (GeneralFunctions()).getLanguageLabel(origValue: "Done", key: "LBL_DONE")
        IQKeyboardManager.shared.disabledToolbarClasses.append(MessagesViewController.self)
        IQKeyboardManager.shared.disabledDistanceHandlingClasses.append(MessagesViewController.self)
        

        
        Analytics.setAnalyticsCollectionEnabled(true)
        
        FirebaseApp.configure()
        
//        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        
        LocalNotification.registerForLocalNotification(on: UIApplication.shared)
        GeneralFunctions.registerRemoteNotification()
        
       
        //import Bagel
        #if targetEnvironment(simulator)
        Bagel.start()
        #endif
        
        UIViewController.swizzlePresent()
        
        return true
    }
    
//    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
//        
//       
//        return ApplicationDelegate.shared.application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
//    }
    

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        let isGoogleUrl = url.scheme != nil && url.scheme!.hasPrefix("com.googleusercontent.apps")
        
        if(isGoogleUrl){
            GIDSignIn.sharedInstance()?.handle(url)
           
        }
        
       return false
        
    }
  
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
//        AppEvents.activateApp()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        GeneralFunctions.saveValue(key: "APP_IS_IN_BACKGROUND", value: true as AnyObject)
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIMinimumKeepAliveTimeout)
        
        GeneralFunctions.postNotificationSignal(key: Utils.appBGNotificationKey, obj: self)
        
//        UIControl().sendAction(Selector(("_performMemoryWarning")), to: UIApplication.shared, for: nil)
//        UIControl().sendAction(Selector(("_performMemoryWarning")), to: UIApplication.shared, for: nil)
        
    }
    
    func registerBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    func endBackgroundTask() {
        Utils.printLog(msgData: "Background task ended.")
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = UIBackgroundTaskIdentifier.invalid
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
        GeneralFunctions.saveValue(key: "APP_IS_IN_BACKGROUND", value: false as AnyObject)
        
        UIControl().sendAction(Selector(("_performMemoryWarning")), to: UIApplication.shared, for: nil)
        UIControl().sendAction(Selector(("_performMemoryWarning")), to: UIApplication.shared, for: nil)
        
        registerBackgroundTask()
        
        GeneralFunctions.postNotificationSignal(key: Utils.appFGNotificationKey, obj: self)

    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        //******* REFRESH UI
        GeneralFunctions.saveValue(key: "APP_IS_IN_BACKGROUND", value: false as AnyObject)
        if(GeneralFunctions.isKeyExistInUserDefaults(key: "REFRESH_APP") && GeneralFunctions.getValue(key: "REFRESH_APP") as! Bool == true){
            
            var viewController = Application.window != nil ? (Application.window!.rootViewController != nil ? (Application.window!.rootViewController!) : nil) : nil
            
            if(viewController != nil){
                viewController = GeneralFunctions.getVisibleViewController(viewController, isCheckAll: true)
                GeneralFunctions.saveValue(key: "REFRESH_APP", value: false as AnyObject)
                let userProfileJsonDict = (GeneralFunctions.getValue(key: Utils.USER_PROFILE_DICT_KEY) as! String).getJsonDataDict()
                let _ = OpenMainProfile(uv: viewController!, userProfileJson: userProfileJsonDict.convertToJson(), window: window!)
            }
        }
        //*******
        
        GeneralFunctions.postNotificationSignal(key: Utils.appFGNotificationKey, obj: self)
        
        Utils.resetAppNotifications()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        GeneralFunctions.postNotificationSignal(key: Utils.releaseAllTaskObserverKey, obj: self)
        GeneralFunctions.postNotificationSignal(key: ConfigPubNub.removeInst_key, obj: self)
        GeneralFunctions.postNotificationSignal(key: ConfigSCConnection.removeSCInst_key, obj: self)
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()

        // FCM TOKEN
        Messaging.messaging().token { fcmToken, error in
            if let error = error {
                print("Error fetching FCM registration token: \(error)")
            } else if let fcmToken = fcmToken {
                // FCM TOKEN
                self.push.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
                
                GeneralFunctions.saveValue(key: "APNID", value: token as AnyObject)
                
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Utils.apnIDNotificationKey), object: nil, userInfo: ["body":token, "FCMToken": fcmToken])
            }
        }
        
        // FCM TOKEN
        
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("ErrorInReg:\(error)")
        if(UIDevice().type == .simulator){
            let token = "simulator_demo_1234"
             GeneralFunctions.saveValue(key: "APNID", value: token as AnyObject)
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Utils.apnIDNotificationKey), object: nil, userInfo: ["body":token, "FCMToken": token])
        }
    }
    

    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let actionIdentifier = response.actionIdentifier
        
        switch actionIdentifier {
            case UNNotificationDismissActionIdentifier: // Notification was dismissed by user
                // Do something
                completionHandler()
            case UNNotificationDefaultActionIdentifier: // App was opened from notification
                // Do something
                if let dict = response.notification.request.content.userInfo as NSDictionary? as! [String:Any]? {
                    if dict["isRemoteNotif"] != nil {
                        handleRemoteNotif(response: response)
                    } else {
                        handleLocalNotif(response: response)
                    }
                }
                completionHandler()
            default:
                completionHandler()
        }
    }
    
    func handleLocalNotif(response:UNNotificationResponse) {
        if let dictInfo = response.notification.request.content.userInfo as NSDictionary?,let dict = dictInfo as? [String:Any] {
            print(dict)
            if let message = dict["Message"] as? String {
                if message == "sendNotificationToUser" {
                    openRideDetailPage(userInfo: dict)
                } else if message == "YourRequestConfirmFromDriver" ||
                            message == "CancelDriverDestination" ||
                            message == "your_request_Declined_from_Driver"
                {
                    openBooking()
                }
            }
        }
    }
    
    func handleRemoteNotif(response:UNNotificationResponse) {
        if let dict = response.notification.request.content.userInfo as NSDictionary? as! [String:Any]? {
            print(dict)
            
            if let message = dict["Message"] as? String {
                if message == "sendNotificationToUser" {
                    UFXHomeUV.openPageFromNotif = .rideDetail
                    UFXHomeUV.rideDetailUserInfo = dict
                } else if message == "YourRequestConfirmFromDriver" ||
                            message == "CancelDriverDestination" ||
                            message == "your_request_Declined_from_Driver" {
                    UFXHomeUV.openPageFromNotif = .booking
                    NotificationCenter.default.post(name: .didReceiveNotifInfo, object: nil,userInfo: ["booking": []])
                }
                if message == "CabRequestAccepted" {
                    UFXHomeUV.openPageFromNotif = .map
                    NotificationCenter.default.post(name: .didReceiveNotifInfo, object: nil,userInfo: ["map": []])
                }
            }
            
        }
    }
    
    func openRideDetailPage(userInfo:[String:Any]) {
        let rideInfoVC = GeneralFunctions.instantiateViewController(pageName: "rideInfoVC", storyBoardName: "Main") as! RideInfoViewController
        let cabInfo = userInfo
        let driverInfo = cabInfo["driver_info"] as? [String:Any]

        rideInfoVC.isShowingFromNotif = true
        rideInfoVC.passengerCount = Int(cabInfo["SeatsNumber"] as! String)
        rideInfoVC.providerDetails = (driverInfo!["id"] as! String,cabInfo["idriverdestinations"] as! String)
        if let controller = window?.rootViewController {
            controller.showDetailViewController(rideInfoVC, sender: controller)
        }
    }
    
    func openBooking() {
        let rideOrderHistoryTabUV = GeneralFunctions.instantiateViewController(pageName: "RideOrderHistoryTabUV") as! RideOrderHistoryTabUV
        //        rideOrderHistoryTabUV.homeTabBar = self.homeTabBar
        rideOrderHistoryTabUV.isFromViewProfile = false
        rideOrderHistoryTabUV.isDirectPush = true
        rideOrderHistoryTabUV.isShowingFromNotif = true
        rideOrderHistoryTabUV.isFromUFXCheckOut = false
        if let controller = window?.rootViewController {
            controller.showDetailViewController(rideOrderHistoryTabUV, sender: controller)
        }
    }
    
    func openMapPage() {
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        
        let mainScreenVC = storyboard.instantiateViewController(withIdentifier: "MainScreenUV") as! MainScreenUV
        

        self.window?.rootViewController = mainScreenVC
        
        DispatchQueue.main.asyncAfter(wallDeadline: .now() + 0.5) {
            mainScreenVC.configureAssignedDriver(isAppRestarted: true)
        }
    }
    
    func pushtoVCWith(id:String) {
        if let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: id) as? RideInfoViewController {
            if let window = self.window, let rootViewController = window.rootViewController {
                var currentController = rootViewController
                while let presentedController = currentController.presentedViewController {
                    currentController = presentedController
                }
                currentController.present(controller, animated: true, completion: nil)
            }
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        print("userInfo:PUSH:\(userInfo)")
        let notification = userInfo["aps"] as? NSDictionary
        
        if(notification == nil || notification?.get("body") == ""){
            return
        }
        
        if((notification!["body"] as? NSDictionary) != nil){
            let jsonDic = notification!["body"] as! NSDictionary
            
            FireTripStatusMessges().fireTripMsg(jsonDic.convertToJson(), false)
        }else if((notification!["body"] as? String) != nil){
            let jsonData = notification!["body"] as! String
            
            FireTripStatusMessges().fireTripMsg(jsonData, false)
        }
        
    }
    
    func managedPush(_ managedPush: SINManagedPush!, didReceiveIncomingPushWithPayload payload: [AnyHashable : Any]!, forType pushType: String!) {
        if(GeneralFunctions.getMemberd() != "") {
            let result:SINNotificationResult = SINPushHelper.queryPushNotificationPayload(payload)
            if result.isCall(){
                SinchCalling.getInstance().initSinchClient()
                if self.refreshRequired == true{
                    GeneralFunctions.saveValue(key: "SINCHCALLING", value: true as AnyObject)
                }
                SinchCalling.getInstance().client.relayRemotePushNotification(payload)
            }
        }
    }
    
}

extension AppDelegate: UNUserNotificationCenterDelegate,MessagingDelegate {
    
    func registerForLocalNotification(on application:UIApplication) {
        
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            (granted, error) in
            //Parse errors and track state
        }
        application.registerForRemoteNotifications()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        if let dict = notification.request.content.userInfo as NSDictionary? as! [String:Any]? {
            if dict["isRemoteNotif"] != nil {
                completionHandler(.alert)
            }
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
    }
    
}


