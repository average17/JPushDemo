# JPushDemo

需要导入JPush框架，可以使用cocoapod导入，也可以手动导入

# 环境配置
配置环境可以参考极光推送的官方文档：

[iOS 证书设置指南](https://docs.jiguang.cn/jpush/client/iOS/ios_cer_guide/)

[iOS SDK 集成指南](https://docs.jiguang.cn/jpush/client/iOS/ios_guide_new/)

[iOS SDK API](https://docs.jiguang.cn/jpush/client/iOS/ios_api/)

# 使用说明

待环境配置好了之后，就可以进入极光推送开始推送消息了

[极光推送首页](https://www.jiguang.cn/?hmsr=品专3&hmpl=标题&hmcu=&hmkw=&hmci=)

推送使用示例如下：

![发送通知](https://github.com/average17/JPushDemo/blob/master/screenshots/Snip20180208_2.png)

![自定义消息](https://github.com/average17/JPushDemo/blob/master/screenshots/Snip20180208_3.png)

# 代码转换
因为极光推送文档里的环境配置使用的是OC代码，如果对OC不熟悉的话，可以参考以下翻译成Swift的代码，如果你是OC大牛，那就忽略这里

## 添加头文件
因为极光推送的框架JPush是OC写的框架，Swift不能直接使用，所以需要创建一个桥接文件，会创建桥接文件的直接复制代码即可，不会创建桥接文件的，并且工程下没有OC文件(.m文件的)可以直接File->New->File->Objective-C File，然后任意输入一个文件名，这时会提示你是否自动创建桥接文件，选择是，就会创建一个桥接文件了，然后我们把下面的代码复制到xxx-Bridging-Header文件中
```
// 引入JPush功能所需头文件
#import "JPUSHService.h"
// iOS10注册APNs所需头文件
#ifdef NSFoundationVersionNumber_iOS_9_x_Max
#import <UserNotifications/UserNotifications.h>
#endif
// 如果需要使用idfa功能所需要引入的头文件（可选）
#import <AdSupport/AdSupport.h>
```

## 添加Delegate
为AppDelegate添加Delegate。

参考代码:
```
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, JPUSHRegisterDelegate {

}
```

## 添加初始化代码

### 添加初始化APNs代码
请将以下代码添加到func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
```
let entity = JPUSHRegisterEntity()
entity.types = 1 << 0 | 1 << 1 | 1 << 2
JPUSHService.register(forRemoteNotificationConfig: entity, delegate: self)
```

### 添加初始化JPush代码
请将以下代码添加到func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
```
let advertisingId = ASIdentifierManager.shared().advertisingIdentifier.uuidString
JPUSHService.setup(withOption: launchOptions, appKey: "a8cc62546a2407102cf484b6", channel: "App Store", apsForProduction: false, advertisingIdentifier: advertisingId)
```
(参数说明请看文档)

### 注册APNs成功并上报DeviceToken
请在AppDelegate.swift实现该回调方法并添加回调方法中的代码
```
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    //注册 DeviceToken
    JPUSHService.registerDeviceToken(deviceToken)
}
```

### 实现注册APNs失败接口（可选）
```
func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        //可选
        NSLog("did Fail To Register For Remote Notifications With Error: \(error)")
    }
}
```

### 添加处理APNs通知回调方法
请在AppDelegate.swift实现该回调方法并添加回调方法中的代码
```
// MARK: JPUSHRegisterDelegate
// iOS 10 Support
func jpushNotificationCenter(_ center: UNUserNotificationCenter!, willPresent notification: UNNotification!, withCompletionHandler completionHandler: ((Int) -> Void)!) {
    let userInfo = notification.request.content.userInfo
    if notification.request.trigger is UNPushNotificationTrigger {
        JPUSHService.handleRemoteNotification(userInfo)
    }
    // 需要执行这个方法，选择是否提醒用户，有Badge、Sound、Alert三种类型可以选择设置
    completionHandler(Int(UNNotificationPresentationOptions.alert.rawValue))
}

// iOS 10 Support
func jpushNotificationCenter(_ center: UNUserNotificationCenter!, didReceive response: UNNotificationResponse!, withCompletionHandler completionHandler: (() -> Void)!) {
    let userInfo = response.notification.request.content.userInfo
    if response.notification.request.trigger is UNPushNotificationTrigger {
        JPUSHService.handleRemoteNotification(userInfo)
    }
    // 系统要求执行这个方法
    completionHandler()
}

func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    JPUSHService.handleRemoteNotification(userInfo)
    completionHandler(UIBackgroundFetchResult.newData)
}
```

## 添加处理JPush自定义消息回调方法
在iOS SDK集成指南中并没有直接给出处理JPush自定义消息的回调方法，需要你自己到API中去寻找，这里，我直接把它抽出来写在下面

### 功能说明
1、只有在前端运行的时候才能收到自定义消息的推送。

2、从jpush服务器获取用户推送的自定义消息内容和标题以及附加字段等。

### 实现方法
请将以下代码添加到func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
```
NotificationCenter.default.addObserver(self, selector: #selector(networkDidReceiveMessage(notification:)), name: NSNotification.Name.jpfNetworkDidReceiveMessage, object: nil)
```
实现回调方法 networkDidReceiveMessage
```
@objc func networkDidReceiveMessage(notification: Notification) {
    let userInfo = notification.userInfo
    if let extras = userInfo?["extras"] as? Dictionary<String, String> {
        NSLog("extras: \(extras)")
    }
    // 将自定义消息的内容转换成本地推送
    if let con = userInfo?["content"] as? String {
        //设置推送内容
        let content = UNMutableNotificationContent()
        content.body = con
        
        //设置通知触发器
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.01, repeats: false)
        
        //设置请求标识符
        let requestIdentifier = "com.average.Demo"
        
        //设置一个通知请求
        let request = UNNotificationRequest(identifier: requestIdentifier,
                                            content: content, trigger: trigger)
        
        //将通知请求添加到发送中心
        UNUserNotificationCenter.current().add(request) { error in
            if error == nil {
                print("Time Interval Notification scheduled: \(requestIdentifier)")
            }
        }
    }
}
```
这里我跟官方的处理方式不同，官方的API中，获取到content和extras之后直接打印出来，我这里只输出extras，而将content作为本地推送的消息body推送出去，有关本地推送的相关知识，可以参考这篇博客

[Swift - UserNotifications框架使用详解2（发送本地通知）](http://www.hangge.com/blog/cache/detail_1851.html)

还有朋友对AppDelegate.swift中的
```
UNUserNotificationCenter.current()
    .requestAuthorization(options: [.alert, .sound, .badge]) {
        (accepted, error) in
        if !accepted {
            print("用户不允许消息通知。")
        }
}
```
和ViewController.swift中的
```
// 判断权限
UNUserNotificationCenter.current().getNotificationSettings {
    settings in
    switch settings.authorizationStatus {
    // 已获取到通知权限
    case .authorized:
        break
    // 还未获取权限
    case .notDetermined:
        //请求授权
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) {
                (accepted, error) in
                if !accepted {
                    print("用户不允许消息通知。")
                }
        }
    // 用户关闭通知权限
    case .denied:
        DispatchQueue.main.async(execute: { () -> Void in
            let alertController = UIAlertController(title: "消息推送已关闭",
                                                    message: "想要及时获取消息。点击“设置”，开启通知。",
                                                    preferredStyle: .alert)
            
            let cancelAction = UIAlertAction(title:"取消", style: .cancel, handler:nil)
            
            let settingsAction = UIAlertAction(title:"设置", style: .default, handler: {
                (action) -> Void in
                let url = URL(string: UIApplicationOpenSettingsURLString)
                if let url = url, UIApplication.shared.canOpenURL(url) {
                    if #available(iOS 10, *) {
                        UIApplication.shared.open(url, options: [:],
                                                  completionHandler: {
                                                    (success) in
                        })
                    } else {
                        UIApplication.shared.openURL(url)
                    }
                }
            })
            
            alertController.addAction(cancelAction)
            alertController.addAction(settingsAction)
            
            self.present(alertController, animated: true, completion: nil)
        })
    }
}
```
感兴趣，想要仔细了解，也可以参考下面这篇博客

[Swift - UserNotifications框架使用详解1（基本介绍，权限的申请与判断）](http://www.hangge.com/blog/cache/detail_1845.html)
