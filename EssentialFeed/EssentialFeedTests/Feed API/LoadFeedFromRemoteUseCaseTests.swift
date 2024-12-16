//
//  LoadFeedFromRemoteUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Anh Nguyen on 3/12/2024.
//

import Foundation
import Testing
import EssentialFeed

final class LoadFeedFromRemoteUseCaseTests {
    private var sutTracker: MemoryLeakTracker<RemoteFeedLoader>?
    private var clientTracker: MemoryLeakTracker<HTTPClientSpy>?
    
    deinit {
        sutTracker?.verifyDeallocation()
        clientTracker?.verifyDeallocation()
    }
    
    @Test("Initialised feed loader does not request data")
    func initialisedFeedLoaderDoesntRequestData() {
        let (_, client) = makeSUT()
        
        #expect(client.requestedUrls.isEmpty)
    }
    
    @Test("Feed loader loads requests data from URL")
    func feedLoaderRequestsDataFromUrl() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        
        #expect(client.requestedUrls == [url])
    }
    
    @Test("Feed loader loading twice requests data from URL twice")
    func feedLoaderRequestsDataFromUrlTwice() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        sut.load { _ in }
        
        #expect(client.requestedUrls == [url, url])
    }
    
    @Test("Feed loader delivers connectivity error on client error")
    func feedLoaderDeliversConnectivityErrorOnClientError() async {
        let (sut, client) = makeSUT()
        
        await expect(sut, toCompleteWithResult: failure(.connectivity)) {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        }
    }
    
    @Test("Feed loader delivers error on non 200 HTTP response", arguments: [199, 201, 300, 400, 500])
    func feedLoaderDeliversErrorOnNon200HttpResponse(statusCode code: Int) async {
        let (sut, client) = makeSUT()
        
        await expect(sut, toCompleteWithResult: failure(.invalidData)) {
            let json = self.makeItemsJson([])
            client.complete(withStatusCode: code, data: json)
        }
    }
    
    @Test("Feed loader delivers error on 200 HTTP response with invalid JSON")
    func feedLoaderDeliversErrorOn200HttpResponseWithInvalidJson() async {
        let (sut, client) = makeSUT()
        
        await expect(sut, toCompleteWithResult: failure(.invalidData)) {
            let invalidJson = "invalid json".data(using: .utf8)!
            client.complete(withStatusCode: 200, data: invalidJson)
        }
    }
    
    @Test("Feed loader delivers no items on 200 HTTP response with empty JSON list")
    func feedLoaderDeliversNoItemsOn200HttpResponseWithEmptyJson() async {
        let (sut, client) = makeSUT()
        
        await expect(sut, toCompleteWithResult: .success([])) {
            let emptyListJson = self.makeItemsJson([])
            client.complete(withStatusCode: 200, data: emptyListJson)
        }
    }
    
    @Test("Feed loader delivers items on 200 HTTP response with JSON items")
    func feedLoaderDeliversItemsOn200HttpResponseWithJson() async {
        let (sut, client) = makeSUT()
        
        let item1 = makeItem(id: UUID(), imageUrl: URL(string: "http://a-url.com")!)
        
        let item2 = makeItem(id: UUID(), description: "a description", location: "a location", imageUrl: URL(string: "http://another-url.com")!)
        
        let items = [item1.model, item2.model]
        
        await expect(sut, toCompleteWithResult: .success(items)) {
            let json = self.makeItemsJson([item1.json, item2.json])
            client.complete(withStatusCode: 200, data: json)
        }
    }
    
    @Test("Feed loader delivers no items after sut instance has been deallocated")
    func feedLoaderDeliversNoItemsAfterSutInstanceDeallocated() {
        var sut: RemoteFeedLoader?
        let client: HTTPClientSpy
        (sut, client) = makeSUT()
        
        var capturedResults = [RemoteFeedLoader.Result]()
        sut?.load { capturedResults.append($0) }
        
        sut = nil
        client.complete(withStatusCode: 200, data: makeItemsJson([]))
        
        #expect(capturedResults.isEmpty)
        
    }
    
    // MARK: Helpers
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!, sourceLocation: SourceLocation = #_sourceLocation) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        sutTracker = MemoryLeakTracker(instance: sut, sourceLocation: sourceLocation)
        clientTracker = MemoryLeakTracker(instance: client, sourceLocation: sourceLocation)
        return (sut, client)
    }
    
    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageUrl: URL) -> (model: FeedImage, json: [String: Any]) {
        let item = FeedImage(id: id, description: description, location: location, url: imageUrl)
        let json = ["id": item.id.uuidString, "description": item.description, "location": item.location, "image": item.url.absoluteString].compactMapValues { $0 }
    
        return (item, json)
    }
    
    private func makeItemsJson(_ items: [[String: Any]]) -> Data {
        let itemsJson = ["items": items]
        return try! JSONSerialization.data(withJSONObject: itemsJson)
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWithResult expectedResult: RemoteFeedLoader.Result, when action: @escaping () -> Void, sourceLocation: SourceLocation = #_sourceLocation) async {
            await confirmation("Load completion") { loaded in
                sut.load { receivedResult in
                    switch (receivedResult, expectedResult) {
                    case let (.success(receivedItems), .success(expectedItems)): #expect(receivedItems == expectedItems, sourceLocation: sourceLocation)
                    case let (.failure(receivedError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)): #expect(receivedError == expectedError, sourceLocation: sourceLocation)
                    default:
                        Issue.record("Expected \(expectedResult), got \(receivedResult) instead", sourceLocation: sourceLocation)
                    }
                    
                    loaded()
                }
                
                action()
        }
    }
    
    private func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
        .failure(error)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        var requestedUrls: [URL] {
            messages.map { $0.url }
        }
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(url: messages[index].url, statusCode: code, httpVersion: nil, headerFields: nil)!
            messages[index].completion(.success(data, response))
        }
    }
}
