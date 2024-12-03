//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Anh Nguyen on 3/12/2024.
//

import Foundation
import Testing

class RemoteFeedLoader {
    let client: HTTPClient
    let url: URL
    
    init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    func load() {
        client.get(from: url)
    }
}

protocol HTTPClient {
    func get(from url: URL)
}

struct RemoteFeedLoaderTests {
    @Test("Initialised feed loader does not request data")
    func initialisedFeedLoaderDoesntRequestData() {
        let (_, client) = makeSUT()
        
        #expect(client.requestedURL == nil)
    }
    
    @Test("Feed loader loads request data from URL")
    func feedLoaderRequestsDataFromUrl() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load()
        
        #expect(client.requestedURL == url)
    }
    
    // MARK: Helpers
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var requestedURL: URL?
        
        func get(from url: URL) {
            requestedURL = url
        }
    }
}
