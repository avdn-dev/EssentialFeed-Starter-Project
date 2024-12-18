//
//  FeedStoreSpecs+TestHelpers.swift
//  EssentialFeedTests
//
//  Created by Anh Nguyen on 18/12/2024.
//

import EssentialFeed
import Foundation
import Testing

extension FailableFeedStore {
    func expect(_ sut: FeedStore, toRetrieve expectedResult: RetrieveCachedFeedResult, sourceLocation: SourceLocation = #_sourceLocation) async {
        await confirmation("Retrieve completion") { completed in
            await withCheckedContinuation { continuation in
                sut.retrieve { retrievedResult in
                    switch (expectedResult, retrievedResult) {
                    case (.empty, .empty), (.failure, .failure):
                        break
                    case let (.found(expectedFeed, expectedTimestamp), .found(retrievedFeed, retrievedTimestamp)):
                        #expect(retrievedFeed == expectedFeed, sourceLocation: sourceLocation)
                        #expect(retrievedTimestamp == expectedTimestamp, sourceLocation: sourceLocation)
                    default:
                        Issue.record("Expected to retrieve \(expectedResult), got \(retrievedResult) instead", sourceLocation: sourceLocation)
                    }
                    
                    continuation.resume()
                    completed()
                }
            }
        }
    }
    
    func expect(_ sut: FeedStore, toRetrieveTwice expectedResult: RetrieveCachedFeedResult, sourceLocation: SourceLocation = #_sourceLocation) async {
        await expect(sut, toRetrieve: expectedResult)
        await expect(sut, toRetrieve: expectedResult)
    }
    
    @discardableResult
    func insert(_ cache: (feed: [LocalFeedImage], timestamp: Date), to sut: FeedStore) async -> Error? {
        var insertionError: Error?
        
        await confirmation("Insert completion") { completed in
            await withCheckedContinuation { continuation in
                sut.insert(cache.feed, at: cache.timestamp) { receivedInsertionError in
                    insertionError = receivedInsertionError
                    continuation.resume()
                    completed()
                }
            }
        }
        
        return insertionError
    }
    
    func deleteCache(from sut: FeedStore) async -> Error? {
        var deletionError: Error?
        
        await confirmation("Delete completion") { completed in
            await withCheckedContinuation { continuation in
                sut.deleteCachedFeed { receivedDeletionError in
                    deletionError = receivedDeletionError
                    continuation.resume()
                    completed()
                }
            }
        }
        
        return deletionError
    }
}
