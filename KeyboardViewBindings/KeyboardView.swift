 //
//  KeyboardView.swift
//  KeyboardView
//
//  Created by Eric Kampman on 9/10/16.
//  Copyright © 2016 Eric Kampman. All rights reserved.
//

import Cocoa

public let KEYS_BINDING_NAME = "keys"
public let SELECTION_BINDING_NAME = "selection"
public let SELECTED_BINDING_NAME = "selected"
public let SELECTION_INDEXES_NAME = "selectionIndexes"

public let DEFAULT_LOW_KEY = "C4"
public let DEFAULT_WHITE_KEY_COUNT = Int32(8)

typealias StringObjectDictionary = [String:Any]
typealias BindingDictionary = [String:StringObjectDictionary]

public struct KeyRect {
	let rect:	CGRect
	let key:	UInt8
	let index:	UInt8
}

@objc(KeyboardView)
open class KeyboardView: NSView {
	
	override open class func initialize() {
		exposeBinding(KEYS_BINDING_NAME)
		exposeBinding(SELECTION_BINDING_NAME)
		exposeBinding(SELECTED_BINDING_NAME)
		exposeBinding(SELECTION_INDEXES_NAME)
	}
	
	// low key MUST be white
	public init(frame frameRect: NSRect, lowKey: String, keyCount: Int32) {
		self.lowKey = lowKey
		self.whiteKeyCount = keyCount
		
		super.init(frame: frameRect)
		
		constructKeyRects()
		initBindingInfo()
	}
	
	override public init(frame frameRect: NSRect) {
		self.lowKey = DEFAULT_LOW_KEY
		self.whiteKeyCount = DEFAULT_WHITE_KEY_COUNT
		
		super.init(frame: frameRect)
		constructKeyRects()
		initBindingInfo()
	}
	
	required public init?(coder: NSCoder) {
		self.lowKey = DEFAULT_LOW_KEY
		self.whiteKeyCount = DEFAULT_WHITE_KEY_COUNT
		
		super.init(coder: coder)
		constructKeyRects()
		initBindingInfo()
	}
	
	func finalSetup() {
		startObservingKeys()
	}

	deinit {
		stopObservingKeys()
	}
	
	// MARK: - KVO
	func startObservingKeys() {
		if !isObservingKeys {
			guard let keys = keys as? [Key] else {
				return
			}
			for key in keys {
				startObservingObject(item: key, context: &keyboardViewContext)
			}
			isObservingKeys = true
		}
	}
	func stopObservingKeys() {
		if isObservingKeys {
			guard let keys = keys as? [Key] else {
				return
			}
			for key in keys {
				stopObservingObject(item: key, context: &keyboardViewContext)
			}
			isObservingKeys = false
		}
	}
	
	// MARK: - Binding
	func initBindingInfo() {
		bindingInfo = [:]
		bindingInfo[KEYS_BINDING_NAME] = emptyDictionary
		bindingInfo[SELECTION_BINDING_NAME] = emptyDictionary
		bindingInfo[SELECTED_BINDING_NAME] = emptyDictionary
		bindingInfo[SELECTION_INDEXES_NAME] = emptyDictionary
	}
	
//	override func bind(_ binding: String, to observable: Any, withKeyPath keyPath: String, options: [String : Any]? = nil) {}

	override open func bind(_ binding: String, to observable: Any, withKeyPath keyPath: String, options: [String : Any]?)
	{
		//		Swift.print("!!!!!keyboardView -- bind entrypoint \(binding)")
		//		Swift.print("!!!!!  \(self) observing \(observable) with keypath \(keyPath)")
		for (key, value) in bindingInfo {
			if binding == key {
				if value.count != 0	{ // i.e. is this an 'empyDictionary'?'
					unbind(key)
				}
				
				let options = options ?? emptyDictionary
				
				let bindingsData: StringObjectDictionary = [
					NSObservedObjectKey : observable,
					NSObservedKeyPathKey : keyPath,
					NSOptionsKey : options
				]
				bindingInfo[binding] = bindingsData
				
				(observable as AnyObject).addObserver(self, forKeyPath: keyPath, options: [.old,.new], context: &keyboardViewContext)
				
				return
			}
		}
		super.bind(binding, to: observable, withKeyPath: keyPath, options: options)
	}
	
	override open func unbind(_ binding: String) {
		//		Swift.print("!!!! keyboardView -- unbind \(binding) for \(self)")
		for (key, value) in bindingInfo {
			// if key matches and value is not emptyDictionary
			if key == binding && value.count != 0 {
				let observed = value[NSObservedObjectKey]
				if let obs = observed {
					let keyPath = value[NSObservedKeyPathKey] as! String!
					(obs as AnyObject).removeObserver(self, forKeyPath: keyPath!)
					bindingInfo[key] = emptyDictionary
				} else {
					Swift.print("Called unbind on unbound key")
				}
				needsDisplay = true
				return
			}
		}
		super.unbind(binding)
		needsDisplay = true // ?
	}
	
//	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {}

	override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		
		if context != &keyboardViewContext {
			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
			return
		}
		
		needsDisplay = true
/*		UNDO is handled by the document. We just need to make sure we 'see' the results of undo.
		
		//-----------------------------
		if let change = change {
			for (key, _) in change {
				Swift.print("observeValueForKeyPath keypath: \(keyPath) key: \(key)")
			}
		}
		//-----------------------------
		
		guard change != nil && object != nil && keyPath != nil else {
			return
		}
		
		var oldValue: AnyObject? = change![NSKeyValueChangeKey.oldKey] as AnyObject?
		if oldValue is NSNull {
			oldValue = nil
		}
		if let undo = undoManager {
			(undo.prepare(withInvocationTarget: object!) as AnyObject).setValue(oldValue,
			                                                   forKeyPath: keyPath!)
		}
*/
	}
	
    override open func draw(_ dirtyRect: CGRect) {
        super.draw(dirtyRect)
		
		NSColor.black.setStroke()
		for r in whiteKeyRects {
			if keyIsSelected(keyIndex: r.index) {
				selectedKeyColor.setFill()
			}
			else {
				whiteKeyColor.setFill()
			}
			NSBezierPath.fill(r.rect)
			NSBezierPath.stroke(r.rect)
		}
		NSColor.black.setStroke()
		for r in blackKeyRects {
			if keyIsSelected(keyIndex: r.index) {
				selectedKeyColor.setFill()
			}
			else {
				blackKeyColor.setFill()
			}
			NSBezierPath.fill(r.rect)
			NSBezierPath.stroke(r.rect)
		}
    }
	
	private func whiteKeyDimensions() -> CGSize {
		let r = bounds.insetBy(dx: 1, dy: 1)
		return CGSize(width: r.width / CGFloat(whiteKeyCount), height: r.height)
	}

	private func blackKeyDimensions() -> CGSize {
		let r = whiteKeyDimensions()
		return CGSize(width: r.width * 0.7, height: r.height * 0.6)
	}
	
	private func isBlack(key: UInt8) -> Bool {
		switch (key % 12) {
		case 1,3,6,8,10:
			return true
		default:
			return false
		}
	}
	
	// from previous key x value
	private func blackKeyXOffset(keyIndex: Int32) -> CGFloat? {
		let whiteDim = whiteKeyDimensions()
		let blackDim = blackKeyDimensions()
		let perfectX = whiteDim.width - blackDim.width / 2.0
		let adjustX = 0.1 * perfectX
		
		switch keyIndex % 12 {
		case 1:		// C#
			return perfectX - adjustX
		case 3:		// D#
			return perfectX + adjustX
		case 6:		// F#
			return perfectX - adjustX
		case 8:		// G#
			return perfectX
		case 10:	// A#
			return perfectX + adjustX
		default:
			return nil	// key is white
		}
	}
	private func blackKeyYOffset() -> CGFloat {
		return whiteKeyDimensions().height * 0.4
	}
	
	private func constructKeyRects() {
		whiteKeyRects = []
		blackKeyRects = []
		guard let firstKey = midiNotes[lowKey] else {
			return
		}
		
		var curWhiteOrigin = bounds.origin
		var count = whiteKeyCount
		let blackY = blackKeyYOffset()
		let blackDim = blackKeyDimensions()
		let whiteDim = whiteKeyDimensions()
		
		var keysDone = UInt8(0)
		var index = UInt8(0)
		while count > 0 {
			let key = firstKey + keysDone
			if isBlack(key: key) {
				let r = CGRect(x: curWhiteOrigin.x + blackKeyXOffset(keyIndex: Int32(key))!,
				               y: blackY,
				               width: blackDim.width,
				               height: blackDim.height)
				blackKeyRects.append(KeyRect(rect: r, key: key, index: index))
			} else {
				let r = CGRect(x: curWhiteOrigin.x,
				               y: curWhiteOrigin.y,
				               width: whiteDim.width,
				               height: whiteDim.height)
				
				whiteKeyRects.append(KeyRect(rect: r, key: key, index: index))
				count -= 1
			}
			if !isBlack(key: key + 1) {
				curWhiteOrigin.x += whiteDim.width
			}
			keysDone += 1
			index += 1
		}
	}

	func pointToKeyIndex(point: NSPoint) -> UInt8? {
		guard NSPointInRect(point, bounds) else {
			return nil
		}
		if let k = self.blackKeyRects.first(where: {
			NSPointInRect(point, $0.rect)
		}) {
			return k.index
		} else {
			if let k = self.whiteKeyRects.first(where: {
				NSPointInRect(point, $0.rect)
			}) {
				return k.index
			}
		}
		return nil
	}
/*
	override func mouseDown(_ theEvent: NSEvent) {
		let lPt = self.convert(theEvent.locationInWindow, from:nil)
		if let k = self.blackKeyRects.first(where: {
			NSPointInRect(lPt, $0.rect)
		}) {
			Swift.print("Black: \(k.key)")
		} else {
			if let k = self.whiteKeyRects.first(where: {
				NSPointInRect(lPt, $0.rect)
			}) {
				Swift.print("White: \(k.key)")
			}
		}
		
	}
	override func mouseDragged(_ theEvent: NSEvent) {
		
	}
	override func mouseUp(_ theEvent: NSEvent) {
	}
*/
	// MARK: - Mouse
	override open func mouseDown(with theEvent: NSEvent) {
		let lPt = self.convert(theEvent.locationInWindow, from:nil)
		let keyIndex = pointToKeyIndex(point: lPt)
		
		startKeyIndex = keyIndex
		Swift.print("!!! mouseDown keyIndex: \(keyIndex)")
		
		if keyIndex != nil {
			let undo = undoManager!
			if undo.groupingLevel > 0 {
				undo.endUndoGrouping()
			}
			undo.beginUndoGrouping()
			isUndoGrouping = true
			Swift.print("UNDO GROUPING")
			currentlySelecting = !keyIsSelected(keyIndex: keyIndex!)
			setKeySelected(keyIndex: keyIndex!, selected: currentlySelecting)
		}
	}
	
	override open func mouseDragged(with theEvent: NSEvent) {
		guard startKeyIndex != nil else {
			return
		}
		
		let lPt = self.convert(theEvent.locationInWindow, from:nil)
		guard NSPointInRect(lPt, bounds) else {
			return
		}
		if let keyIndex = pointToKeyIndex(point: lPt), let cki = startKeyIndex {
			if keyIsSelected(keyIndex: cki) != keyIsSelected(keyIndex: keyIndex) {
				setKeySelected(keyIndex: keyIndex, selected: currentlySelecting)
			}
		}
	}
	
	override open func mouseUp(with theEvent: NSEvent) {
		//		let lPt = self.convertPoint(theEvent.locationInWindow, fromView:nil)
		//		let keyIndex = pointToKeyIndex(lPt)
		
		startKeyIndex = nil
		currentlySelecting = false // doesn't matter, I suppose
		
		if isUndoGrouping {
			undoManager!.endUndoGrouping()
			isUndoGrouping = false
			Swift.print("END UNDO GROUPING")
		}
	}

	func keyIsSelected(keyIndex: UInt8) -> Bool {
		guard let keys = keys else {
			return false
		}
		guard keyIndex >= 0 &&
			keyIndex < UInt8(keys.count) else
		{
			return false
		}
		let key = keys.object(at: Int(keyIndex)) as! Key
		return key.selected
	}
	
	func setKeySelected(keyIndex: UInt8, selected: Bool) {
		guard let keys = keys else {
			return
		}
		guard keyIndex >= 0 &&
			keyIndex < keysCount else
		{
			return
		}
		let key = keys.object(at: Int(keyIndex)) as! Key
		if key.selected != selected {
			key.selected = selected
			needsDisplay = true
		}
	}
	
	public dynamic var lowKey: String {
		didSet {
			constructKeyRects()
			needsDisplay = true
		}
	}
	public dynamic var whiteKeyCount: Int32 {
		didSet {
			constructKeyRects()
			needsDisplay = true
		}
	}
	
	override open func infoForBinding(_ binding: String) -> [String : Any]? {
		if let info = bindingInfo[binding] {
			if info.count != 0 {
				return info
			} else {
				// then it's empty dictionary
				return nil
			}
		}
		return super.infoForBinding(binding) as [String : Any]?
	}
	public dynamic var keysContainer: NSArrayController? {
		get {
			if let dict = infoForBinding(KEYS_BINDING_NAME) {
				return dict[NSObservedObjectKey] as? NSArrayController
			}
			return nil
		}
	}
	public dynamic var keysKeyPath: String? {
		get {
			if let dict = infoForBinding(KEYS_BINDING_NAME) {
				return dict[NSObservedKeyPathKey] as? String
			}
			return nil
		}
	}
	@IBInspectable public dynamic var keys: NSArray? {
		get {
			if keysContainer != nil && keysKeyPath != nil {
				return keysContainer!.value(forKeyPath: keysKeyPath!) as? NSArray
			}
			return nil
		}
	}
	public dynamic var selectionIndexes: IndexSet? {
		get {
			if let keys = keys {
				var ret = IndexSet()
				for i in 0..<keys.count {
					let key = keys[i] as! Key
					if key.selected {
						ret.insert(i)
					}
				}
				return ret
			}
			return nil
		}
	}
	
	open dynamic var keysCount: UInt8 {
		get {
			return UInt8(blackKeyRects.count + whiteKeyRects.count)
		}
	}
	
	open dynamic var firstKeyIndex: UInt8 {
		get {
			return whiteKeyRects[0].key
		}
	}
	
/*
	// MARK: - First Responder
	open override var acceptsFirstResponder: Bool { return true }
	
	open override func becomeFirstResponder() -> Bool {
		return true
	}
	open override func resignFirstResponder() -> Bool {
		return true
	}
	
*/
	
	/* XXX This makes assumptions about the mapping between the array and the contained
	 * keys. Might not be a good idea. The alternative is to search the whiteKeyRects
	 * and blackKeyRects, which seems worse.
	func keyIndexToZeroBasedIndex(index: UInt8) -> UInt8? {
		guard index >= firstKeyIndex else {
			return nil
		}
		return index - firstKeyIndex
	}
	*/
	
	// MARK: - Properties, etc
	
	var whiteKeyRects = [KeyRect]()
	var blackKeyRects = [KeyRect]()
	
	var bindingInfo = BindingDictionary()
	var boundInited = false
	let emptyDictionary = StringObjectDictionary()
	
	private var startKeyIndex = UInt8?.none
	//	private var currentKeyClicked = Bool?.None
	private var currentlySelecting = Bool(false)
	private var isUndoGrouping = Bool(false)
	
	private var isObservingKeys = false
	
	let selectedKeyColor = NSColor(calibratedRed: 0.4, green: 0.4, blue: 1.0, alpha: 1.0)
	let whiteKeyColor = NSColor.white
	let blackKeyColor = NSColor.gray
}

private var keyboardViewContext: Int = 0

