//
//  MyTableViewController.swift
//  LearningCloudKit
//
//  Created by Daniel Dickson on 7/25/16.
//  Copyright © 2016 Daniel Dickson. All rights reserved.
//

import UIKit
import CloudKit
import AVFoundation

class MyTableViewController: UITableViewController {

    var conversations: [CKRecord] = []
    var refresh: UIRefreshControl!
    var addAlertSaveAction: UIAlertAction?
    //var player: AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        refresh = UIRefreshControl()
        refresh.attributedTitle = NSAttributedString(string: "Pull to load conversations")
        refresh.addTarget(self, action: #selector(MyTableViewController.loadData), forControlEvents: .ValueChanged)
        self.tableView.addSubview(refresh)
        
        ConversationController.sharedController.setupCloudKitSubscription()
        
        dispatch_async(dispatch_get_main_queue()) { 
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MyTableViewController.loadData), name: "performReload", object: nil)
            //NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MyTableViewController.playSound), name: "playTheSound", object: nil)
        }
        
        loadData()
        //playSound()
    }
    
    func loadData() {
        let publicData = CKContainer.defaultContainer().publicCloudDatabase
        let query = CKQuery(recordType: "Conversation", predicate: NSPredicate(format: "TRUEPREDICATE", argumentArray: nil))
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        publicData.performQuery(query, inZoneWithID: nil) { (results: [CKRecord]?, error: NSError?) -> Void in
            if let conversations = results {
                self.conversations = conversations
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.tableView.reloadData()
                    self.refresh.endRefreshing()
                    self.view.layoutSubviews()
                })
            }
        }
    }
    
//    func playSound() {
//        
//        if let url = NSBundle.mainBundle().URLForResource("NotificationSound", withExtension: "m4a") {
//            //let url = NSURL(fileURLWithPath: path)
//            do {
//                player = try AVAudioPlayer(contentsOfURL: url, fileTypeHint: nil)
//                guard let player = player else { return }
//                
//                //player.prepareToPlay()
//                player.play()
//            } catch let error as NSError {
//                print("We made it to the Catch statment \(error.description)")
//            }
//        } else {
//            print("Couldn't find the sound file")
//        }
//    }
    
    // This function will enable our 'Send' button in our alert when the text has at least one character
    func handleTextFieldDidChangeNotification(notification: NSNotification) {
        let textField = notification.object as? UITextField
        
        addAlertSaveAction!.enabled = textField!.text?.utf16.count >= 1
    }
    
    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        if conversations.count == 0 {
            return cell
        }
        let conversation = conversations[indexPath.row]
        if let conversationContent = conversation["content"] as? String {
            let dateFormat = NSDateFormatter()
            dateFormat.dateFormat = "M-d-yyy h:mm a"
            dateFormat.timeZone = NSTimeZone.localTimeZone()
            let dateString = dateFormat.stringFromDate(conversation.creationDate!)
            
            cell.textLabel?.text = conversationContent
            cell.detailTextLabel?.text = dateString
        }

        return cell
    }
    
    @IBAction func sendMessage(sender: AnyObject) {
        
        let alert = UIAlertController(title: "New Conversation", message: "Enter a title", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler { (textField: UITextField) -> Void in
            textField.placeholder = "New Conversation"
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MyTableViewController.handleTextFieldDidChangeNotification(_:)), name: UITextFieldTextDidChangeNotification, object: textField)
        }
        
        // We'll use this when we tap "Cancel" or "Send" since we won't need it unless the alert is currently being presented
        func removeTextFieldObserver() {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UITextFieldTextDidChangeNotification, object: alert.textFields)
        }
        
        let sendAction = UIAlertAction(title: "Send", style: .Default, handler: { (action: UIAlertAction) in
            let textField = alert.textFields!.first!
            if textField.text != "" {
                removeTextFieldObserver()
                let newConversation = CKRecord(recordType: "Conversation")
                newConversation["content"] = textField.text
                
                let publicData = CKContainer.defaultContainer().publicCloudDatabase
                publicData.saveRecord(newConversation, completionHandler: { (record: CKRecord?, error: NSError?) -> Void in
                    if error == nil {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.tableView.beginUpdates()
                            self.conversations.insert(newConversation, atIndex: 0)
                            let indexPath = NSIndexPath(forRow: 0, inSection: 0)
                            self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Top)
                            self.tableView.endUpdates()
                        })
                    } else {
                        print(error)
                    }
                })
            }
        })
        // Initially disable our 'Send' button
        sendAction.enabled = false
        // Set our sendAction to toggle enabled/disabled state when the text is changed
        self.addAlertSaveAction = sendAction
        
        alert.addAction(sendAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel) { action in
            removeTextFieldObserver()
            })
        
        self.presentViewController(alert, animated: true, completion: nil)
    }

    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            let conversation = conversations[indexPath.row]
            let publicData = CKContainer.defaultContainer().publicCloudDatabase
            publicData.deleteRecordWithID(conversation.recordID, completionHandler: { (record, error) in
                if let error = error {
                    print(error)
                } else {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.loadData()
                    })
                }
            })
        }
    }
 


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
