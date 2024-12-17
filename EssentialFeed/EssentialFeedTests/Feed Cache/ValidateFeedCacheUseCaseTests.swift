//
//  ValidateFeedCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Anh Nguyen on 17/12/2024.
//

import EssentialFeed
import Foundation
import Testing

final class ValidateFeedCacheUseCaseTests {
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
    
    @Test("Validation deletes cache on retrieval error")
    func validateDeletesCacheOnRetrievalError() async {
        let (sut, store) = makeSut()
        
        sut.validateCache()
        store.completeRetrieval(with: makeNsError())
        
        #expect(store.receivedMessages == [.retrieve, .deleteCachedFeed])
    }
    
    @Test("Validation does not delete cache on empty cache")
    func validateDeletesCacheOnEmptyCache() async {
        let (sut, store) = makeSut()
        
        sut.validateCache()
        store.completeRetrievalWithEmptyCache()
        
        #expect(store.receivedMessages == [.retrieve])
    }
    
    @Test("Validation has no side effect on cache when it is less than seven days old")
    func validateHasNoSideEffectOnLessThanSevenDaysOldCache() async {
        let feed = makeUniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        let (sut, store) = makeSut(currentDate: { fixedCurrentDate })
        
        sut.validateCache()
        store.completeRetrievalWith(with: feed.local, timestamp: lessThanSevenDaysOldTimestamp)
        
        #expect(store.receivedMessages == [.retrieve])
    }
    
    @Test("Validation deletes cache when it is seven days old")
    func validateDeletesSevenDaysOldCache() async {
        let feed = makeUniqueImageFeed()
        let fixedCurrentDate = Date()
        let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
        let (sut, store) = makeSut(currentDate: { fixedCurrentDate })
        
        sut.validateCache()
        store.completeRetrievalWith(with: feed.local, timestamp: sevenDaysOldTimestamp)
        
        #expect(store.receivedMessages == [.retrieve, .deleteCachedFeed])
    }
    
    @Test("Validation deletes cache when it is more than seven days old")
    func validateDeletesMoreThanSevenDaysOldCache() async {
        let feed = makeUniqueImageFeed()
        let fixedCurrentDate = Date()
        let moreThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
        let (sut, store) = makeSut(currentDate: { fixedCurrentDate })
        
        sut.validateCache()
        store.completeRetrievalWith(with: feed.local, timestamp: moreThanSevenDaysOldTimestamp)
        
        #expect(store.receivedMessages == [.retrieve, .deleteCachedFeed])
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
