//
//  MemoryLeakTracker.swift
//  EssentialFeedTests
//
//  Created by Anh Nguyen on 14/12/2024.
//

import Testing

struct MemoryLeakTracker<T: AnyObject> {
    weak var instance: T?
    var sourceLocation: SourceLocation
    
    func verifyDeallocation() {
        #expect(instance == nil, "Expected \(instance) to be deallocated", sourceLocation: sourceLocation)
    }
}
