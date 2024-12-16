//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Anh Nguyen on 16/12/2024.
//

import EssentialFeed
import Foundation
import Testing

final class LoadFeedFromCacheUseCaseTests {
    private var sutTracker: MemoryLeakTracker<LocalFeedLoader>?
    private var storeTracker: MemoryLeakTracker<FeedStoreSpy>?
    
    deinit {
        sutTracker?.verifyDeallocation()
        storeTracker?.verifyDeallocation()
    }
    
    @Test("LocalFeedLoader does not message store upon initialisation")
    func initialiserDoesNotMessageStore() {
        let (_, store) = makeSut()
        
        #expect(store.receivedMessages == [])
    }
    
    // MARK: Helpers
    private func makeSut(currentDate: @escaping () -> Date = Date.init, sourceLocation: SourceLocation = #_sourceLocation) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        sutTracker = MemoryLeakTracker(instance: sut, sourceLocation: sourceLocation)
        storeTracker = MemoryLeakTracker(instance: store, sourceLocation: sourceLocation)
        return (sut, store)
    }
}
