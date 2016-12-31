//
//  ObservablePropertiesListing.swift
//  KeyboardViewBindingsDoc
//
//  Created by Eric Kampman on 12/15/16.
//  Copyright © 2016 Eric Kampman. All rights reserved.
//

import Foundation


protocol ObservablePropertiesListing {
	func observableProperties() -> [String]
	
	func addObserver(_ observer: NSObject,
	                 forKeyPath keyPath: String,
	                 options: NSKeyValueObservingOptions,
	                 context: UnsafeMutableRawPointer?)
	func removeObserver(_ observer: NSObject,
	                    forKeyPath keyPath: String,
	                    context: UnsafeMutableRawPointer?)
}

extension NSObject {
	func startObservingObject(item: ObservablePropertiesListing,
	                          context: UnsafeMutableRawPointer?) {
		for keyName in item.observableProperties() {
			item.addObserver(self, forKeyPath: keyName,
			                 options: .old, context: context)
		}
	}
	func stopObservingObject(item: ObservablePropertiesListing,
	                         context: UnsafeMutableRawPointer?) {
		for keyName in item.observableProperties() {
			item.removeObserver(self, forKeyPath: keyName,
			                    context: context)
		}
	}
}
