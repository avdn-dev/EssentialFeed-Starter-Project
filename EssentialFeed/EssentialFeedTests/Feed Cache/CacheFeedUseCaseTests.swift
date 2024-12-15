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
    let currentDate: () -> Date
    
    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed { [unowned self] error in
            if error == nil {
                store.insert(items, at: currentDate())
            }
        }
    }
}

class FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    var deleteCachedFeedCallCount = 0
    var insertCallCount = 0
    var insertions = [(items: [FeedItem], timestamp: Date)]()
    
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
    
    func insert(_ items: [FeedItem], at timestamp: Date) {
        insertCallCount += 1
        insertions.append((items, timestamp))
        
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
    
    @Test("Save requests cache insertion with timestamp on successful deletion")
    func saveRequestsCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSut(currentDate: { timestamp })
        let items = [makeUniqueItem(), makeUniqueItem()]
        
        sut.save(items)
        store.completeDeletionSuccessfully()
        
        #expect(store.insertions.count == 1)
        #expect(store.insertions.first?.items == items)
        #expect(store.insertions.first?.timestamp == timestamp)
    }
    
    // MARK: Helpers
    private func makeSut(currentDate: @escaping () -> Date = Date.init, sourceLocation: SourceLocation = #_sourceLocation) -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        sutTracker = MemoryLeakTracker(instance: sut, sourceLocation: sourceLocation)
        storeTracker = MemoryLeakTracker(instance: store, sourceLocation: sourceLocation)
        return (sut, store)
    }
    
    private func makeUniqueItem() -> FeedItem { FeedItem(id: UUID(), description: nil, location: nil, imageUrl: makeUrl()) }
    
    private func makeUrl() -> URL { URL(string: "https://a-url.com")! }
    
    private func makeNsError() -> NSError { NSError(domain: "any error", code: 1) }
}
