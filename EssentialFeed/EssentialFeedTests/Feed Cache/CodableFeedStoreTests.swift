//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Anh Nguyen on 17/12/2024.
//

import EssentialFeed
import Testing

class CodableFeedStore {
    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        completion(.empty)
    }
}

final class CodableFeedStoreTests {
    @Test("Retrieve delivers nothing on empty cache")
    func retrieveDeliversNothingOnEmptyCache() async {
        let sut = CodableFeedStore()
        
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
        let sut = CodableFeedStore()
        
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
}
