//
//  MemoryLeakTracker.swift
//  EssentialFeedTests
//
//  Created by Anh Nguyen on 14/12/2024.
//

import Testing

internal struct MemoryLeakTracker<T: AnyObject> {
    internal weak var instance: T?
    internal var sourceLocation: SourceLocation
    
    internal func verifyDeallocation() {
        #expect(instance == nil, "Expected \(instance) to be deallocated", sourceLocation: sourceLocation)
    }
}
