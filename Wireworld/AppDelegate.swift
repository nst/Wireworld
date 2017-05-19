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
}
