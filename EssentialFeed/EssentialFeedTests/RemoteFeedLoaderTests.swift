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
        
        sut.load()
        
        #expect(client.requestedUrls == [url])
    }
    
    @Test("Feed loader loading twice requests data from URL twice")
    func feedLoaderRequestsDataFromUrlTwice() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load()
        sut.load()
        
        #expect(client.requestedUrls == [url, url])
    }
    
    // MARK: Helpers
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var requestedUrls = [URL]()
        
        func get(from url: URL) {
            requestedUrls.append(url)
        }
    }
}
