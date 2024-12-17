//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Anh Nguyen on 17/12/2024.
//

import EssentialFeed
import Foundation
import Testing

class CodableFeedStore {
    private let storeUrl: URL
    
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date
        
        var localFeed: [LocalFeedImage] { feed.map(\.local) }
    }
    
    private struct CodableFeedImage: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL
        
        init(_ image: LocalFeedImage) {
            id = image.id
            description = image.description
            location = image.location
            url = image.url
        }
        
        var local: LocalFeedImage { LocalFeedImage(id: id, description: description, location: location, url: url)}
    }
    
    init(storeUrl: URL) {
        self.storeUrl = storeUrl
    }
    
    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        guard let data = try? Data.init(contentsOf: storeUrl) else {
            completion(.empty)
            return
        }
        
        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)
        completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
        
    }
    
    func insert(_ feed: [LocalFeedImage], at timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let encoder = JSONEncoder()
        let cache = Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp)
        let encoded = try! encoder.encode(cache)
        try! encoded.write(to: storeUrl)
        completion(nil)
    }
}

@Suite(.serialized)
final class CodableFeedStoreTests {
    private var sutTracker: MemoryLeakTracker<CodableFeedStore>?
    
    init() {
        setupEmptyStoreState()
    }
    
    deinit {
        undoStoreSideEffects()
        sutTracker?.verifyDeallocation()
    }
    
    @Test("Retrieve delivers nothing on empty cache")
    func retrieveDeliversNothingOnEmptyCache() async {
        let sut = makeSut()
        
        await expect(sut, toRetrieve: .empty)
    }
    
    @Test("Retrieve delivers nothing on empty cache twice with no side effect")
    func retrieveDeliversNothingOnEmptyCacheTwice() async {
        let sut = makeSut()
        
        await expect(sut, toRetrieveTwice: .empty)
    }
    
    @Test("Retrieve after insert into empty cache returns initially inserted values")
    func retrieveAfterInsertDeliversInsertedValues() async {
        let feed = makeUniqueImageFeed().local
        let timestamp = Date()
        let sut = makeSut()
        
        await insert((feed, timestamp), to: sut)
        
        await expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
    }
    
    @Test("Retrieve after insert into empty cache returns initially inserted values with no side effect")
    func retrieveAfterInsertDeliversInsertedValuesTwice() async {
        let feed = makeUniqueImageFeed().local
        let timestamp = Date()
        let sut = makeSut()
        
        await insert((feed, timestamp), to: sut)
        
        await expect(sut, toRetrieveTwice: .found(feed: feed, timestamp: timestamp))
    }
    
    // MARK: Helpers
    private func makeSut(sourceLocation: SourceLocation = #_sourceLocation) -> CodableFeedStore {
        let storeUrl = makeTestStoreUrl()
        let sut = CodableFeedStore(storeUrl: storeUrl)
        sutTracker = MemoryLeakTracker(instance: sut, sourceLocation: sourceLocation)
        return sut
    }
    
    private func makeTestStoreUrl() -> URL { FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appending(path: "\(type(of: self)).store") }
    
    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }
    
    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: makeTestStoreUrl())
    }
    
    private func expect(_ sut: CodableFeedStore, toRetrieve expectedResult: RetrieveCachedFeedResult, sourceLocation: SourceLocation = #_sourceLocation) async {
        await confirmation("Retrieve completion") { completed in
            sut.retrieve { retrievedResult in
                switch (expectedResult, retrievedResult) {
                case (.empty, .empty):
                    break
                case let (.found(expectedFeed, expectedTimestamp), .found(retrievedFeed, retrievedTimestamp)):
                    #expect(retrievedFeed == expectedFeed, sourceLocation: sourceLocation)
                    #expect(retrievedTimestamp == expectedTimestamp, sourceLocation: sourceLocation)
                default:
                    Issue.record("Expected to retrieve \(expectedResult), got \(retrievedResult) instead", sourceLocation: sourceLocation)
                }
                
                completed()
            }
        }
    }
    
    private func expect(_ sut: CodableFeedStore, toRetrieveTwice expectedResult: RetrieveCachedFeedResult, sourceLocation: SourceLocation = #_sourceLocation) async {
        await expect(sut, toRetrieve: expectedResult)
        await expect(sut, toRetrieve: expectedResult)
    }
    
    private func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: CodableFeedStore) async {
        await confirmation("Insert completion") { completed in
            sut.insert(cache.feed, at: cache.timestamp) { insertionError in
                #expect(insertionError == nil)
                completed()
            }
        }
    }
}
