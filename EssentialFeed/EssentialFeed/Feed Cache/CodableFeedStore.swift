//
//  CodableFeedStore.swift
//  EssentialFeed
//
//  Created by Anh Nguyen on 18/12/2024.
//

import Foundation

public class CodableFeedStore: FeedStore {
    private let storeUrl: URL
    private let queue = DispatchQueue(label: "\(CodableFeedStore.self)Queue", qos: .userInitiated, attributes: .concurrent)
    
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
    
    public init(storeUrl: URL) {
        self.storeUrl = storeUrl
    }
    
    public func retrieve(completion: @escaping RetrievalCompletion) {
        let storeUrl = self.storeUrl
        
        queue.async {
            guard let data = try? Data.init(contentsOf: storeUrl) else {
                completion(.success(.none))
                return
            }
            
            let decoder = JSONDecoder()
            completion(Result {
                let cache = try decoder.decode(Cache.self, from: data)
                return CachedFeed(feed: cache.localFeed, timestamp: cache.timestamp)
            })
        }
    }
    
    public func insert(_ feed: [LocalFeedImage], at timestamp: Date, completion: @escaping InsertionCompletion) {
        let storeUrl = self.storeUrl
        
        queue.async(flags: .barrier) {
            completion(Result {
                let encoder = JSONEncoder()
                let cache = Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp)
                let encoded = try encoder.encode(cache)
                try encoded.write(to: storeUrl)
                return
            })
        }
    }
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        let storeUrl = self.storeUrl
        
        queue.async(flags: .barrier) {
            guard FileManager.default.fileExists(atPath: storeUrl.path) else {
                completion(.success(()))
                return
            }
            
            completion(Result {
                try FileManager.default.removeItem(at: storeUrl)
                return
            })
        }
    }
}
