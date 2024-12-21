//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Anh Nguyen on 15/12/2024.
//

import Testing
import EssentialFeed
import Foundation

final class CacheFeedUseCaseTests {
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
    
    @Test("Save requests cache deletion")
    func saveRequestsCacheDeletion() {
        let (sut, store) = makeSut()
        
        sut.save(makeUniqueImageFeed().models) { _ in }
        
        #expect(store.receivedMessages == [.deleteCachedFeed])
    }
    
    @Test("Save does not request cache insertion on deletion error")
    func saveDoesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSut()
        let deletionError = makeNsError()
        
        sut.save(makeUniqueImageFeed().models) { _ in }
        store.completeDeletion(with: deletionError)
        
        #expect(store.receivedMessages == [.deleteCachedFeed])
    }
    
    @Test("Save requests cache insertion with timestamp on successful deletion")
    func saveRequestsCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSut(currentDate: { timestamp })
        let feed = makeUniqueImageFeed()
        
        sut.save(feed.models) { _ in }
        store.completeDeletionSuccessfully()
        
        #expect(store.receivedMessages == [.deleteCachedFeed, .insert(feed.local, timestamp)])
    }
    
    @Test("Save fails on deletion error")
    func saveFailsOnDeletionError() async {
        let (sut, store) = makeSut()
        let deletionError = makeNsError()
        
        await expect(sut, toCompleteWithResult: .failure(deletionError)) {
            store.completeDeletion(with: deletionError)
        }
    }
    
    @Test("Save fails on insertion error")
    func saveFailsOnInsertionError() async {
        let (sut, store) = makeSut()
        let insertionError = makeNsError()
        
        await expect(sut, toCompleteWithResult: .failure(insertionError)) {
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        }
    }
    
    @Test("Save succeeds on successful cache insertion")
    func saveSucceedsOnSuccessfulCacheInsertion() async {
        let (sut, store) = makeSut()
        
        await expect(sut, toCompleteWithResult: .success(())) {
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        }
    }
    
    @Test("Save does not deliver deletion error after SUT has been deallocated")
    func saveDoesNotDeliverDeletionErrorAfterSutDeallocation() async {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedResults = [LocalFeedLoader.SaveResult]()
        sut?.save(makeUniqueImageFeed().models) { receivedResults.append($0) }
        
        sut = nil
        store.completeDeletion(with: makeNsError())
        
        #expect(receivedResults.isEmpty)
    }
    
    @Test("Save does not deliver insertion error after SUT has been deallocated")
    func saveDoesNotDeliverInsertionErrorAfterSutDeallocation() async {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var receivedResults = [LocalFeedLoader.SaveResult]()
        sut?.save(makeUniqueImageFeed().models) { receivedResults.append($0) }
        
        store.completeDeletionSuccessfully()
        sut = nil
        store.completeInsertion(with: makeNsError())
        
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
    
    private func expect(_ sut: LocalFeedLoader, toCompleteWithResult expectedResult: LocalFeedLoader.SaveResult, when action: () -> Void, sourceLocation: SourceLocation = #_sourceLocation) async {
        var receivedResult: LocalFeedLoader.SaveResult!
        
        await withCheckedContinuation { continuation in
            sut.save(makeUniqueImageFeed().models) { result in
                receivedResult = result
                continuation.resume()
            }
            
            action()
        }
        
        switch (receivedResult, expectedResult) {
        case (.success, .success):
            break
        case let (.failure(receivedError), .failure(expectedError)):
            #expect(receivedError as NSError == expectedError as NSError, sourceLocation: sourceLocation)
        default:
            Issue.record("Expected result \(expectedResult), got \(receivedResult!) instead", sourceLocation: sourceLocation)
        }
    }
}
