//
//  Key.swift
//  MIDIMorph
//
//  Created by Eric Kampman on 5/18/16.
//  Copyright © 2016 Eric Kampman. All rights reserved.
//

import Cocoa

let ALL_OCTAVES = UInt8(0x7f)

@objc(OctaveMap)
class OctaveMap: NSObject {
	
	init(name: String, octave: UInt8) {
		super.init()
		
		self.name = name
		self.octave = octave
	}
	var name: String = "XX"
	var octave: UInt8 = 0
	
}

class NoteNameMap: NSObject {
	init(name: String, value: UInt8) {
		super.init()
		
		self.name = name
		self.value = value
	}

	var name: String = "XX"
	var value: UInt8 = 0
}

@objc enum ChordType: Int32 {
	case Major = 0
	case Minor = 1
	case Diminished = 2
	case Augmented = 3
}

class ChordTypeMap: NSObject {
	init(name: String, type: ChordType) {
		super.init()
		
		self.name = name
		self.type = type
	}
	
	var name: String = "XX"
	var type: ChordType = .Major
}

func chordTypeToIntervals(chordType: ChordType) -> [Int]
{
	switch chordType {
	case .Major:
		return [4, 7]	// 0 is implied
	case .Minor:
		return [3, 7]	// ... ditto
	case .Diminished:
		return [3, 6]
	case .Augmented:
		return [4, 8]
	}
}

class Key : NSObject, NSCoding, ObservablePropertiesListing {
	
	override init() {
		selected = false
		val = DEFAULT_VAL
		min = DEFAULT_MIN
		max = DEFAULT_MAX
		scale = DEFAULT_SCALE
		super.init()
	}
	
	init(val: UInt8) {
		selected = false
		self.val = val
		min = DEFAULT_MIN
		max = DEFAULT_MAX
		scale = DEFAULT_SCALE
		
		super.init()
	}
	
	required init(coder aDecoder: NSCoder) {
		self.selected = aDecoder.decodeBool(forKey: selectedKeyName)
		var tmp = aDecoder.decodeInt32(forKey: valKeyName)
		self.val = UInt8(tmp)
		tmp = aDecoder.decodeInt32(forKey: minKeyName)
		self.min = UInt8(tmp)
		tmp = aDecoder.decodeInt32(forKey: maxKeyName)
		self.max = UInt8(tmp)
		self.scale = aDecoder.decodeDouble(forKey: scaleKeyName)
		super.init()
	}

	func encode(with aCoder: NSCoder) {
		aCoder.encode(selected, forKey: selectedKeyName)
		aCoder.encode(Int32(val), forKey: valKeyName)
		aCoder.encode(Int32(min), forKey: minKeyName)
		aCoder.encode(Int32(max), forKey: maxKeyName)
		aCoder.encode(scale, forKey: scaleKeyName)
	}

	weak var undoManager: UndoManager? {
		didSet {
//			if we have sub-objects that need undo mgmt, invoke that here
		}
	}
	
	func observableProperties() ->  [String] {
		return [
			selectedKeyName,
		]
	}
	
	override func setNilValueForKey(_ key: String) {
		Swift.print("Attempting to set Nil for key \(key)")
	}
	
	dynamic var selected = Bool(false) {
		willSet {
			Swift.print("key \(val) selection will change")
		}
		didSet {
			Swift.print("key \(val) selection did change")
		}
	}
	dynamic var val: UInt8	// MIDI Note number
	dynamic var min: UInt8  // min velocity
	dynamic var max: UInt8  // max velocity
	dynamic var scale: Double // scaling factor
	
	let selectedKeyName = "selected"
	let valKeyName = "val"
	let minKeyName = "min"
	let maxKeyName = "max"
	let scaleKeyName = "scale"
	
	let DEFAULT_VAL = UInt8(0)
	let DEFAULT_MIN = UInt8(0)
	let DEFAULT_MAX = UInt8(127)
	let DEFAULT_SCALE = Double(1.0)
}
