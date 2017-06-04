//
//  AppDelegate.swift
//  Wireworld
//
//  Created by nst on 12.05.17.
//  Copyright © 2017 Nicolas Seriot. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        checkForUpdates()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func clearDocumentAction(sender: Any) {
        guard let document : Document = NSApplication.shared().mainWindow?.windowController?.document as? Document else { return }
        document.clearAction(sender: sender)
    }
    
    @IBAction func saveImageAction(sender: NSMenuItem?) {
        guard let document : Document = NSApplication.shared().mainWindow?.windowController?.document as? Document else { return }
        document.saveImageAction(sender: sender)
    }
    
    func checkForUpdates() {
        
        let url = URL(string:"http://www.seriot.ch/wireworld/wireworld.json")
        
        URLSession.shared.dataTask(with: url!) { (optionalData, response, error) in
            
            DispatchQueue.main.async {
                
                guard let data = optionalData,
                    let optionalDict = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String:AnyObject],
                    let d = optionalDict,
                    let latestVersionString = d["latest_version_string"] as? String,
                    let latestVersionURL = d["latest_version_url"] as? String
                    else {
                        return
                }
                
                print("-- latestVersionString: \(latestVersionString)")
                print("-- latestVersionURL: \(latestVersionURL)")
                
                guard let currentVersionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else { return }
                
                let needsUpdate = currentVersionString < latestVersionString
                
                print("-- needsUpdate: \(needsUpdate)")
                if needsUpdate == false { return }
                
                let a = NSAlert()
                a.messageText = "ECAExplorer \(latestVersionString) is Available"
                a.informativeText = "Please download it and replace the current version.";
                a.addButton(withTitle: "Download")
                a.addButton(withTitle: "Cancel")
                a.alertStyle = .critical
                
                let modalResponse = a.runModal()
                
                if modalResponse == NSAlertFirstButtonReturn {
                    if let downloadURL = URL(string:latestVersionURL) {
                        NSWorkspace.shared().open(downloadURL)
                    }
                }
            }
            }.resume()
    }
}
