//
//  KVBViewController.swift
//  KeyboardViewBindingsDoc
//
//  Created by Eric Kampman on 12/14/16.
//  Copyright © 2016 Eric Kampman. All rights reserved.
//

import Cocoa

class KVBViewController: NSViewController {

	override var nibName: String? {
		return "KVBViewController"
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do view setup here.
		
	}
	
	// post-setting representedObject
	func finalSetup() {
		keyboardView.lowKey = lowKey
		keyboardView.whiteKeyCount = Int32(whiteKeyCount)
		
		bindKeyboardView()
		keyboardView.finalSetup()
	}
	
	override func viewWillDisappear() {
		unbindKeyboardView()
		super.viewWillDisappear()
	}

	func bindKeyboardView() {
		guard keyboardViewBound == false else {
			return
		}
		keyboardView.bind(KEYS_BINDING_NAME, to: keysController, withKeyPath: "arrangedObjects", options: nil)
		keyboardView.bind(SELECTION_BINDING_NAME, to: keysController, withKeyPath: "selection", options: nil)
		keyboardView.bind(SELECTED_BINDING_NAME, to: keysController, withKeyPath: "selection.selected", options: nil)
		keyboardViewBound = true
	}
	func unbindKeyboardView() {
		guard keyboardViewBound == true else {
			return
		}
		
		keyboardView.unbind(KEYS_BINDING_NAME)
		keyboardView.unbind(SELECTION_BINDING_NAME)
		keyboardView.unbind(SELECTED_BINDING_NAME)
		keyboardViewBound = false
	}
	
	dynamic var keys: [Key]? {
		return representedObject as? [Key]
	}

	var keyboardViewBound = false
	@IBOutlet weak var keyboardView: KeyboardView!
	@IBOutlet var keysController: NSArrayController!
	
}
