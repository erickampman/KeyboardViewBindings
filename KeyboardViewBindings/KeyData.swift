//
//  KeyData.swift
//  KeyboardViewBindingsDoc
//
//  Created by Eric Kampman on 12/25/16.
//  Copyright © 2016 Eric Kampman. All rights reserved.
//

import Cocoa

class KeyData: NSObject, NSCoding {

	required init?(coder aDecoder: NSCoder) {
		keys = aDecoder.decodeObject(forKey: keysKeyName) as! [Key]
		selectionIndexes = aDecoder.decodeObject(forKey: selectionIndexesKeyName) as! IndexSet
	}
	
	init(lowKey: String, keyCount: UInt8) {
		let lowNote = midiNotes[lowKey] ?? 60  // middle c
		keys = [Key]()
		for n in lowNote..<lowNote+keyCount {
			keys.append(Key(val: n))
		}
		selectionIndexes = IndexSet()
	}
	
	func encode(with aCoder: NSCoder) {
		aCoder.encode(keys, forKey: keysKeyName)
		aCoder.encode(selectionIndexes, forKey: selectionIndexesKeyName)
	}
	
	func initKeys() {
		for n: UInt8 in 0..<UInt8(keyCount) {
			keys.append(Key(val: n))
		}
	}
	
	dynamic var keys: [Key]!
	dynamic var selectionIndexes: IndexSet!

	let keysKeyName = "keys"
	let selectionIndexesKeyName = "selectionIndexes"
}
