//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Anh Nguyen on 3/12/2024.
//

import Foundation
import Testing
import EssentialFeed

struct RemoteFeedLoaderTests {
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
    func feedLoaderDeliversConnectivityErrorOnClientError() {
        let (sut, client) = makeSUT()
        
        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load { capturedErrors.append($0) }
        
        let clientError = NSError(domain: "Test", code: 0)
        client.complete(with: clientError)
        
        #expect(capturedErrors == [.connectivity])
    }
    
    @Test("Feed loader delivers error on non 200 HTTP response", arguments: [199, 201, 300, 400, 500])
    func feedLoaderDeliversErrorOnNon200HttpResponse(statusCode code: Int) {
        let (sut, client) = makeSUT()
        
        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load { capturedErrors.append($0) }
        
        client.complete(withStatusCode: code)
        
        #expect(capturedErrors == [.invalidData])
    }
    
    // MARK: Helpers
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
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
        
        func complete(withStatusCode code: Int, at index: Int = 0) {
            let response = HTTPURLResponse(url: messages[index].url, statusCode: code, httpVersion: nil, headerFields: nil)!
            messages[index].completion(.success(response))
        }
    }
}
