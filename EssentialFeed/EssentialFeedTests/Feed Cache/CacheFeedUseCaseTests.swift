//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Anh Nguyen on 15/12/2024.
//

import Testing
import EssentialFeed
import Foundation

class LocalFeedLoader {
    let store: FeedStore
    
    init(store: FeedStore) {
        self.store = store
    }
    
    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed { [unowned self] error in
            if error == nil {
                self.store.insert(items)
            }
        }
    }
}

class FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    var deleteCachedFeedCallCount = 0
    var insertCallCount = 0
    
    private var deletionCompletions = [DeletionCompletion]()
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        deleteCachedFeedCallCount = 1
        deletionCompletions.append(completion)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
    func insert(_ items: [FeedItem]) {
        insertCallCount += 1
    }
}

final class CacheFeedUseCaseTests {
    private var sutTracker: MemoryLeakTracker<LocalFeedLoader>?
    private var storeTracker: MemoryLeakTracker<FeedStore>?
    
    deinit {
        sutTracker?.verifyDeallocation()
        storeTracker?.verifyDeallocation()
    }
    
    @Test("LocalFeedLoader initialiser does not delete cache")
    func initialiserDoesNotDeleteCache() {
        let (_, store) = makeSut()
        
        #expect(store.deleteCachedFeedCallCount == 0)
    }
    
    @Test("Save requests cache deletion")
    func saveRequestsCacheDeletion() {
        let (sut, store) = makeSut()
        let items = [makeUniqueItem(), makeUniqueItem()]
        
        sut.save(items)
        
        #expect(store.deleteCachedFeedCallCount == 1)
    }
    
    @Test("Save does not request cache insertion on deletion error")
    func saveDoesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSut()
        let items = [makeUniqueItem(), makeUniqueItem()]
        let deletionError = makeNsError()
        
        sut.save(items)
        store.completeDeletion(with: deletionError)
        
        #expect(store.insertCallCount == 0)
    }
    
    @Test("Save requests cache insertion on successful deletion")
    func saveRequestsCacheInsertionOnSuccessfulDeletion() {
        let (sut, store) = makeSut()
        let items = [makeUniqueItem(), makeUniqueItem()]
        
        sut.save(items)
        store.completeDeletionSuccessfully()
        
        #expect(store.insertCallCount == 1)
    }
    
    // MARK: Helpers
    private func makeSut(sourceLocation: SourceLocation = #_sourceLocation) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        sutTracker = MemoryLeakTracker(instance: sut, sourceLocation: sourceLocation)
        storeTracker = MemoryLeakTracker(instance: store, sourceLocation: sourceLocation)
        return (sut, store)
    }
    
    private func makeUniqueItem() -> FeedItem { FeedItem(id: UUID(), description: nil, location: nil, imageUrl: makeUrl()) }
    
    private func makeUrl() -> URL { URL(string: "https://a-url.com")! }
    
    private func makeNsError() -> NSError { NSError(domain: "any error", code: 1) }
}
