//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Anh Nguyen on 16/12/2024.
//

import Foundation

public final class LocalFeedLoader: FeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date

    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
}

public extension LocalFeedLoader {
    typealias SaveResult = Error?
    
    func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] cacheDeletionError in
            guard let self else { return }
            
            if let cacheDeletionError {
                completion(cacheDeletionError)
            } else {
                cache(feed, with: completion)
            }
        }
    }
    
    private func cache(_ feed: [FeedImage], with completion: @escaping (SaveResult) -> Void) {
        store.insert(feed.toLocal(), at: currentDate()) { [weak self] cacheInsertionError in
            guard self != nil else { return }
            
            completion(cacheInsertionError)
        }
    }
}

public extension LocalFeedLoader {
    typealias LoadResult = FeedLoader.Result
    
    func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve { [weak self] result in
            guard let self else { return }
            
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .success(.found(feed, timestamp)) where FeedCachePolicy.validate(timestamp, against: currentDate()):
                completion(.success(feed.toModels()))
            case .success:
                completion(.success([]))
            }
        }
    }
}

public extension LocalFeedLoader {
    func validateCache() {
        store.retrieve { [weak self] result in
            guard let self else { return }

            switch result {
            case .failure:
                store.deleteCachedFeed { _ in }
            case let .success(.found(_, timestamp)) where !FeedCachePolicy.validate(timestamp, against: currentDate()):
                store.deleteCachedFeed { _ in }
            case .success:
                break
            }
        }
    }
}

private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        return map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
    }
}

private extension Array where Element == LocalFeedImage {
    func toModels() -> [FeedImage] {
        return map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
    }
}
