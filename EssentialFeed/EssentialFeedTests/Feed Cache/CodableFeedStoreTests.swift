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
    private let storeUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appending(path: "image-feed.store")
    
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

final class CodableFeedStoreTests {
    init() {
        let storeUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appending(path: "image-feed.store")
        try? FileManager.default.removeItem(at: storeUrl)
    }
    
    deinit {
        let storeUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appending(path: "image-feed.store")
        try? FileManager.default.removeItem(at: storeUrl)
    }
    
    @Test("Retrieve delivers nothing on empty cache")
    func retrieveDeliversNothingOnEmptyCache() async {
        let sut = makeSut()
        
        await confirmation("Retrieve completion") { completed in
            sut.retrieve { result in
                switch result {
                case .empty:
                    break
                default:
                    Issue.record("Expected empty result, got \(result) instead")
                }
                
                completed()
            }
        }
    }
    
    @Test("Retrieve delivers nothing on empty cache twice with no side effect")
    func retrieveDeliversNothingOnEmptyCacheTwice() async {
        let sut = makeSut()
        
        await confirmation("Retrieve completion") { completed in
            sut.retrieve { firstResult in
                sut.retrieve { secondResult in
                    switch (firstResult, secondResult) {
                    case (.empty, .empty):
                        break
                    default:
                        Issue.record("Expected empty result twice, got \(firstResult) and \(secondResult) instead")
                    }
                    
                    completed()
                }
            }
        }
    }
    
    @Test("Retrieve after insert into empty cache returns initially inserted values")
    func retrieveAfterInsertDeliversInsertedValues() async {
        let feed = makeUniqueImageFeed().local
        let timestamp = Date()
        let sut = makeSut()
        
        await confirmation("Retrieve completion") { completed in
            sut.insert(feed, at: timestamp) { insertionError in
                #expect(insertionError == nil)
                
                sut.retrieve { retrieveResult in
                    switch (retrieveResult) {
                    case let .found(retrievedFeed, retrievedTimestamp):
                        #expect(retrievedFeed == feed)
                        #expect(retrievedTimestamp == timestamp)
                    default:
                        Issue.record("Expected found result with feed \(feed) and timestamp \(timestamp), got \(retrieveResult)")
                    }
                    
                    completed()
                }
            }
        }
    }
    
    // MARK: Helpers
    private func makeSut() -> CodableFeedStore {
        return CodableFeedStore()
    }
}
