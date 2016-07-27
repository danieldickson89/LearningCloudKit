//
//  ConversationController.swift
//  LearningCloudKit
//
//  Created by Daniel Dickson on 7/27/16.
//  Copyright © 2016 Daniel Dickson. All rights reserved.
//

import Foundation
import CloudKit
import UIKit

class ConversationController {
    
    static let sharedController = ConversationController()
    
    func setupCloudKitSubscription() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if userDefaults.boolForKey("subscribed") == false {
            let predicate = NSPredicate(format: "TRUEPREDICATE", argumentArray: nil)
            let subscription = CKSubscription(recordType: "Conversation", predicate: predicate, options: CKSubscriptionOptions.FiresOnRecordCreation)
            
            let notificationInfo = CKNotificationInfo()
            notificationInfo.alertLocalizationKey = "New Conversation"
            notificationInfo.shouldBadge = true
            notificationInfo.soundName = UILocalNotificationDefaultSoundName
            
            subscription.notificationInfo = notificationInfo
            
            let publicData = CKContainer.defaultContainer().publicCloudDatabase
            publicData.saveSubscription(subscription) { (subscription, error) in
                if error != nil {
                    print(error?.localizedDescription)
                } else {
                    userDefaults.setBool(true, forKey: "subscribed")
                    userDefaults.synchronize()
                }
            }
        }
    }
}