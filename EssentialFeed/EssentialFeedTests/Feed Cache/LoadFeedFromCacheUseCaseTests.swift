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
    
    @Test("Load requests cache retrieval")
    func loadRequestsCacheRetrieval() {
        let (sut, store) = makeSut()
        
        sut.load { _ in }
        
        #expect(store.receivedMessages == [.retrieve])
    }
    
    @Test("Load fails on retrieval error")
    func loadFailsOnRetrievalError() async {
        let (sut, store) = makeSut()
        let retrievalError = makeNsError()
        
        await expect(sut, toCompleteWith: .failure(retrievalError)) {
            store.completeRetrieval(with: retrievalError)
        }
    }
    
    @Test("Load delivers no images when cache is empty")
    func loadDeliversNoImagesOnEmptyCache() async throws {
        let (sut, store) = makeSut()
        
        await expect(sut, toCompleteWith: .success([])) {
            store.completeRetrievalWithEmptyCache()
        }
    }
    
    @Test("Load delivers cached images when cache is less than seven days old")
    func loadDeliversCachedImagesOnLessThanSevenDaysOldCache() async {
        let feed = makeUniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        let (sut, store) = makeSut(currentDate: { fixedCurrentDate })
        
        await expect(sut, toCompleteWith: .success(feed.models)) {
            store.completeRetrievalWith(with: feed.local, timestamp: lessThanSevenDaysOldTimestamp)
        }
    }
    
    @Test("Load delivers no images when cache is seven days old")
    func loadDeliversNoImagesOnSevenDaysOldCache() async {
        let feed = makeUniqueImageFeed()
        let fixedCurrentDate = Date()
        let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
        let (sut, store) = makeSut(currentDate: { fixedCurrentDate })
        
        await expect(sut, toCompleteWith: .success([])) {
            store.completeRetrievalWith(with: feed.local, timestamp: sevenDaysOldTimestamp)
        }
    }
    
    @Test("Load delivers no images when cache is more than seven days old")
    func loadDeliversNoImagesOnMoreThanSevenDaysOldCache() async {
        let feed = makeUniqueImageFeed()
        let fixedCurrentDate = Date()
        let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
        let (sut, store) = makeSut(currentDate: { fixedCurrentDate })
        
        await expect(sut, toCompleteWith: .success([])) {
            store.completeRetrievalWith(with: feed.local, timestamp: sevenDaysOldTimestamp)
        }
    }
    
    @Test("Load has no side effects on retrieval error")
    func loadHasNoSideEffectOnCacheOnRetrievalError() async {
        let (sut, store) = makeSut()
        
        sut.load { _ in }
        store.completeRetrieval(with: makeNsError())
        
        #expect(store.receivedMessages == [.retrieve])
    }
    
    @Test("Load has no side effects on empty cache")
    func loadHasNoSideEffectOnEmptyCacheOnRetrievalError() async {
        let (sut, store) = makeSut()
        
        sut.load { _ in }
        store.completeRetrievalWithEmptyCache()
        
        #expect(store.receivedMessages == [.retrieve])
    }
    
    @Test("Load has no side effect on cache when it is less than seven days old")
    func loadHasNoSideEffectOnLessThanSevenDaysOldCache() async {
        let feed = makeUniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        let (sut, store) = makeSut(currentDate: { fixedCurrentDate })
        
        sut.load { _ in }
        store.completeRetrievalWith(with: feed.local, timestamp: lessThanSevenDaysOldTimestamp)
        
        #expect(store.receivedMessages == [.retrieve])
    }
    
    @Test("Load has no side effect on cache when it is seven days old")
    func loadHasNoSideEffectOnSevenDaysOldCache() async {
        let feed = makeUniqueImageFeed()
        let fixedCurrentDate = Date()
        let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
        let (sut, store) = makeSut(currentDate: { fixedCurrentDate })
        
        sut.load { _ in }
        store.completeRetrievalWith(with: feed.local, timestamp: sevenDaysOldTimestamp)
        
        #expect(store.receivedMessages == [.retrieve])
    }
    
    @Test("Load has no side effect on cache when it is more than seven days old")
    func loadHasNoSideEffectOnMoreThanSevenDaysOldCache() async {
        let feed = makeUniqueImageFeed()
        let fixedCurrentDate = Date()
        let moreThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: -1)
        let (sut, store) = makeSut(currentDate: { fixedCurrentDate })
        
        sut.load { _ in }
        store.completeRetrievalWith(with: feed.local, timestamp: moreThanSevenDaysOldTimestamp)
        
        #expect(store.receivedMessages == [.retrieve])
    }
    
    @Test("Load does not deliver result after SUT has been deallocated")
    func loadDoesNotDeliverResultAfterSutDeallocation() async {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedResults = [LocalFeedLoader.LoadResult]()
        sut?.load { receivedResults.append($0) }
        
        sut = nil
        store.completeRetrievalWithEmptyCache()
        
        #expect(receivedResults.isEmpty)
    }
    
    // MARK: Helpers
    private func makeSut(currentDate: @escaping () -> Date = Date.init, sourceLocation: SourceLocation = #_sourceLocation) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        sutTracker = MemoryLeakTracker(instance: sut, sourceLocation: sourceLocation)
        storeTracker = MemoryLeakTracker(instance: store, sourceLocation: sourceLocation)
        return (sut, store)
    }
    
    private func expect(_ sut: LocalFeedLoader, toCompleteWith expectedResult: LocalFeedLoader.LoadResult, when action: () -> Void, sourceLocation: SourceLocation = #_sourceLocation) async {
        await confirmation("Load completion") { loaded in
            sut.load { receivedResult in
                switch (receivedResult, expectedResult ) {
                case let (.success(receivedImages), .success(expectedImages)):
                    #expect(receivedImages == expectedImages, sourceLocation: sourceLocation)
                case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                    #expect(receivedError == expectedError, sourceLocation: sourceLocation)
                default:
                    Issue.record("Expected result \(expectedResult), got \(receivedResult) instead", sourceLocation: sourceLocation)
                }
                
                loaded()
            }
             
            action()
        }
    }
}
