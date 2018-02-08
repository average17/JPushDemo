//
//  ViewController.swift
//  Demo
//
//  Created by 陈主昕 on 2018/2/1.
//  Copyright © 2018年 average. All rights reserved.
//

import UIKit
import UserNotifications

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
                    let alertController = UIAlertController(title: "消息推送已关闭", message: "想要及时获取消息。点击“设置”，开启通知。", preferredStyle: .alert)
                    
                    let cancelAction = UIAlertAction(title:"取消", style: .cancel, handler:nil)
                    
                    let settingsAction = UIAlertAction(title:"设置", style: .default, handler: {
                        (action) -> Void in
                        let url = URL(string: UIApplicationOpenSettingsURLString)
                        if let url = url, UIApplication.shared.canOpenURL(url) {
                            if #available(iOS 10, *) {
                                UIApplication.shared.open(url, options: [:], completionHandler: {
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

