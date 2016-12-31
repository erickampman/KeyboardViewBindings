//
//  KVBWindowController.swift
//  KeyboardViewBindingsDoc
//
//  Created by Eric Kampman on 12/14/16.
//  Copyright © 2016 Eric Kampman. All rights reserved.
//

import Cocoa

class KVBWindowController: NSWindowController {

	override var windowNibName: String? {
		return "KVBWindowController"
	}
	
	override func windowDidLoad() {
		super.windowDidLoad()
		
		let viewController = KVBViewController()
		let doc = self.document as! Document
		viewController.representedObject = doc.keys
		
		// It's critical that representedObject be set up
		// before assigning contentViewController, or 
		// bindings won't be set up correctly.
		contentViewController = viewController
		
		viewController.finalSetup()
 	}
}
