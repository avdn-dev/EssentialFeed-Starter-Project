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
        store.deleteCachedFeed()
    }
}

class FeedStore {
    var deleteCachedFeedCallCount = 0
    
    func deleteCachedFeed() {
        deleteCachedFeedCallCount = 1
    }
}

struct CacheFeedUseCaseTests {
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
    
    // MARK: Helpers
    private func makeSut() -> (sut: LocalFeedLoader, store: FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        return (sut, store)
    }
    
    private func makeUniqueItem() -> FeedItem { FeedItem(id: UUID(), description: nil, location: nil, imageUrl: makeUrl()) }
    
    private func makeUrl() -> URL { URL(string: "https://a-url.com")! }
}
