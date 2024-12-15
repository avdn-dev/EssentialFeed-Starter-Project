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
    private let store: FeedStore
    private let currentDate: () -> Date
    
    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
        store.deleteCachedFeed { [unowned self] error in
            if error == nil {
                store.insert(items, at: currentDate(), completion: completion)
            } else {
                completion(error)
            }
        }
    }
}

class FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    
    enum ReceivedMessage: Equatable {
        case deleteCachedFeed
        case insert([FeedItem], Date)
    }
    
    private(set) var receivedMessages = [ReceivedMessage]()
    
    private var deletionCompletions = [DeletionCompletion]()
    private var insertionCompletions = [InsertionCompletion]()
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCachedFeed)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
    func insert(_ items: [FeedItem], at timestamp: Date, completion: @escaping InsertionCompletion) {
        insertionCompletions.append(completion)
        receivedMessages.append(.insert(items, timestamp))
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
        insertionCompletions[index](error)
    }
    
    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](nil)
    }
}

final class CacheFeedUseCaseTests {
    private var sutTracker: MemoryLeakTracker<LocalFeedLoader>?
    private var storeTracker: MemoryLeakTracker<FeedStore>?
    
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
        let items = [makeUniqueItem(), makeUniqueItem()]
        
        sut.save(items) { _ in }
        
        #expect(store.receivedMessages == [.deleteCachedFeed])
    }
    
    @Test("Save does not request cache insertion on deletion error")
    func saveDoesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSut()
        let items = [makeUniqueItem(), makeUniqueItem()]
        let deletionError = makeNsError()
        
        sut.save(items) { _ in }
        store.completeDeletion(with: deletionError)
        
        #expect(store.receivedMessages == [.deleteCachedFeed])
    }
    
    @Test("Save requests cache insertion with timestamp on successful deletion")
    func saveRequestsCacheInsertionWithTimestampOnSuccessfulDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSut(currentDate: { timestamp })
        let items = [makeUniqueItem(), makeUniqueItem()]
        
        sut.save(items) { _ in }
        store.completeDeletionSuccessfully()
        
        #expect(store.receivedMessages == [.deleteCachedFeed, .insert(items, timestamp)])
    }
    
    @Test("Save fails on deletion error")
    func saveFailsOnDeletionError() async {
        let (sut, store) = makeSut()
        let items = [makeUniqueItem(), makeUniqueItem()]
        let deletionError = makeNsError()
        
        var receivedError: Error?
        
        await confirmation("Save completion") { completed in
            sut.save(items) { error in
                receivedError = error
                completed()
            }
            
            store.completeDeletion(with: deletionError)
        }
        
        #expect(receivedError as NSError? == deletionError)
    }
    
    @Test("Save fails on insertion error")
    func saveFailsOnInsertionError() async {
        let (sut, store) = makeSut()
        let items = [makeUniqueItem(), makeUniqueItem()]
        let insertionError = makeNsError()
        
        var receivedError: Error?
        
        await confirmation("Save completion") { completed in
            sut.save(items) { error in
                receivedError = error
                completed()
            }
            
            store.completeDeletionSuccessfully()
            store.completeInsertion(with: insertionError)
        }
        
        #expect(receivedError as NSError? == insertionError)
    }
    
    @Test("Save succeeds on successful cache insertion")
    func saveSucceedsOnSuccessfulCacheInsertion() async {
        let (sut, store) = makeSut()
        let items = [makeUniqueItem(), makeUniqueItem()]
        
        var receivedError: Error?
        
        await confirmation("Save completion") { completed in
            sut.save(items) { error in
                receivedError = error
                completed()
            }
            
            store.completeDeletionSuccessfully()
            store.completeInsertionSuccessfully()
        }
        
        #expect(receivedError == nil)
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
