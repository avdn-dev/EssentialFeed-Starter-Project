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
        
        sut.load { _ in }
        store.completeRetrievalWith(with: feed.local, timestamp: lessThanSevenDaysOldTimestamp)
        
        #expect(store.receivedMessages == [.retrieve])
    }
    
    // MARK: Helpers
    private func makeSut(currentDate: @escaping () -> Date = Date.init, sourceLocation: SourceLocation = #_sourceLocation) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        sutTracker = MemoryLeakTracker(instance: sut, sourceLocation: sourceLocation)
        storeTracker = MemoryLeakTracker(instance: store, sourceLocation: sourceLocation)
        return (sut, store)
    }
    
    private func makeNsError() -> NSError { NSError(domain: "any error", code: 1) }
    
    private func makeUniqueImage() -> FeedImage { FeedImage(id: UUID(), description: nil, location: nil, url: makeUrl()) }
    
    private func makeUniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
        let models = [makeUniqueImage(), makeUniqueImage()]
        let local = models.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
        return (models, local)
    }
    
    private func makeUrl() -> URL { URL(string: "https://a-url.com")! }
}

private extension Date {
    func adding(days: Int) -> Date { Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)! }
    
    func adding(seconds: TimeInterval) -> Date { self.addingTimeInterval(seconds) }
}
