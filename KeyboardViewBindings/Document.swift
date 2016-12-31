//
//  Document.swift
//  KeyboardViewBindingsDoc
//
//  Created by Eric Kampman on 12/14/16.
//  Copyright © 2016 Eric Kampman. All rights reserved.
//

import Cocoa

let keyCount = 12
let whiteKeyCount = 7
let lowKey = "C4"

class Document: NSDocument {
	
	override init() {
		super.init()
	}
	
	override class func autosavesInPlace() -> Bool {
		return true
	}
	
	override func makeWindowControllers() {
		let windowController = KVBWindowController()
		//		windowController.document = self		// this is a no-no
		addWindowController(windowController)
		initKeys()
	}
	
	func initKeys() {
		for n: UInt8 in 0..<UInt8(keyCount) {
			keys.append(Key(val: n))
		}
	}
	
	// MARK: - Archiving
	override func data(ofType typeName: String) throws -> Data {
		windowControllers[0].window!.endEditing(for: nil)
		
		return NSKeyedArchiver.archivedData(withRootObject: keys)
	}
	
	override func read(from data: Data, ofType typeName: String) throws {
		//		isDefault = false
		keys = NSKeyedUnarchiver.unarchiveObject(with: data) as! [Key]
		
		for key in keys {
			key.undoManager = undoManager
		}
	}
	
	// MARK: - Cleanup
	override func close() {
		removeObservers()
		super.close()
	}
	
	// MARK: - KVO
	/*
	func startObservingObject(item: ObservablePropertiesListing) {
	for keyName in item.observableProperties() {
	item.addObserver(self, forKeyPath: keyName,
	options: .old, context: &documentContext)
	}
	}
	func stopObservingObject(item: ObservablePropertiesListing) {
	for keyName in item.observableProperties() {
	item.removeObserver(self, forKeyPath: keyName,
	context: &documentContext)
	}
	}
	*/
	
	func addObservers() {
		if !isObserving {
			for key in keys {
				startObservingObject(item: key, context: &documentContext)
			}
			isObserving = true
		}
	}
	func removeObservers() {
		if isObserving {
			isObserving = false
			for key in keys {
				stopObservingObject(item: key, context: &documentContext)
			}
		}
	}
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
	{
		if context != &documentContext {
			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
			return
		}
		
		if keyPath != nil && object != nil && change != nil {
			var oldValue: AnyObject? = change![NSKeyValueChangeKey.oldKey] as AnyObject?
			if oldValue is NSNull {
				oldValue = nil
			}
			
			let undo: UndoManager = undoManager!
			Swift.print("oldValue = \(oldValue), keyPath = \(keyPath)")
			(undo.prepare(withInvocationTarget: object!) as AnyObject).setValue(oldValue, forKeyPath: keyPath!)
		}
	}
	
	private var isObserving = false
	
	dynamic var keys = [Key]() {
		willSet {
			Swift.print("keys: willSet \(newValue)")
			removeObservers()
		}
		didSet {
			Swift.print("keys: didSet \(oldValue)")
			addObservers()
		}
	}
}

private var documentContext: Int = 0
