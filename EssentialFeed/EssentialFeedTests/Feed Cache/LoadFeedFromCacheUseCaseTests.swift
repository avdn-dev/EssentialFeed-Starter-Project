//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Anh Nguyen on 16/12/2024.
//

import EssentialFeed
import Foundation
import Testing

final class LoadFeedFromCacheUseCaseTests {
    private var sutTracker: MemoryLeakTracker<LocalFeedLoader>?
    private var storeTracker: MemoryLeakTracker<FeedStoreSpy>?
    
    deinit {
        sutTracker?.verifyDeallocation()
        storeTracker?.verifyDeallocation()
    }
    
    @Test("LocalFeedLoader does not message store upon initialisation")
    func initialiserDoesNotMessageStore() {
        let (_, store) = makeSut()
        
        #expect(store.receivedMessages == [])
    }
    
    @Test("Load requests cache retrieval")
    func loadRequestsCacheRetrieval() {
        let (sut, store) = makeSut()
        
        sut.load { _ in }
        
        #expect(store.receivedMessages == [.retrieve])
    }
    
    @Test("Load fails on retrieval error")
    func loadFailsOnRetrievalError() async {
        let (sut, store) = makeSut()
        let retrievalError = makeNsError()
        
        var receivedError: Error?
        await confirmation("Load completion") { completed in
            sut.load { result in
                switch result {
                case let .failure(error):
                    receivedError = error
                default:
                    Issue.record("Expected failure, got \(result) instead")
                }
                completed()
            }
             
            store.completeRetrieval(with: retrievalError)
        }
        
        #expect(receivedError as? NSError == retrievalError)
    }
    
    // MARK: Helpers
    private func makeSut(currentDate: @escaping () -> Date = Date.init, sourceLocation: SourceLocation = #_sourceLocation) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        sutTracker = MemoryLeakTracker(instance: sut, sourceLocation: sourceLocation)
        storeTracker = MemoryLeakTracker(instance: store, sourceLocation: sourceLocation)
        return (sut, store)
    }
    
    private func makeNsError() -> NSError { NSError(domain: "any error", code: 1) }
}

