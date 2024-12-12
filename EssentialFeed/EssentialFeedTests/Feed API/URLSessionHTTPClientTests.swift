//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Anh Nguyen on 12/12/2024.
//

import Foundation
import Testing
import EssentialFeed

private extension Duration {
    static var sleepTime: Self { .milliseconds(20) }
}

@Suite(.serialized)
class URLSessionHTTPClientTests {
    init() {
        URLProtocolStub.startInterceptingRequests()
    }
    
    deinit {
        URLProtocolStub.stopInterceptingRequests()
    }
    
    @Test("Get from URL performs GET request")
    func getFromUrlPerformsGetRequestWithUrl() async {
        let url = anyUrl()
        
        await confirmation("Request completion") { completed in
            URLProtocolStub.observeRequests { request in
                #expect(request.url == url)
                #expect(request.httpMethod == "GET")
                
                completed()
            }
            
            makeSut().get(from: url) { _ in }
            
            // The Confirmation API does not wait until confirmation has occured while XCTest fulfillments do
            try? await Task.sleep(for: .sleepTime)
        }
    }
    
    @Test("Get from URL fails on request error")
    func getFromUrlFailsOnRequestError() async {
        let requestError = anyNsError()
        let receivedError = await resultErrorFor(data: nil, response: nil, error: requestError) as? NSError
        
        #expect(receivedError?.domain == requestError.domain)
        #expect(receivedError?.code == requestError.code)
    }
    
    @Test("Get from URL fails on all invalid combinations values")
    func getFromUrlFailsOnAllInvalidRepresentationCases() async {
        #expect(await resultErrorFor(data: nil, response: nil, error: nil) != nil)
        #expect(await resultErrorFor(data: nil, response: anyNonHttpUrlResponse(), error: nil) != nil)
        #expect(await resultErrorFor(data: anyData(), response: nil, error: nil) != nil)
        #expect(await resultErrorFor(data: anyData(), response: nil, error: anyNsError()) != nil)
        #expect(await resultErrorFor(data: nil, response: anyNonHttpUrlResponse(), error: anyNsError()) != nil)
        #expect(await resultErrorFor(data: nil, response: anyHttpUrlResponse(), error: anyNsError()) != nil)
        #expect(await resultErrorFor(data: anyData(), response: anyNonHttpUrlResponse(), error: anyNsError()) != nil)
        #expect(await resultErrorFor(data: anyData(), response: anyHttpUrlResponse(), error: anyNsError()) != nil)
        #expect(await resultErrorFor(data: anyData(), response: anyNonHttpUrlResponse(), error: nil) != nil)
    }
    
    @Test("Get from URL succeeds on HTTPURLResponse with data")
    func getFromUrlSucceedsOnHttpUrlResponseWithData() async {
        let data = anyData()
        let response = anyHttpUrlResponse()
        
        let receivedValues = await resultValuesFor(data: data, response: response, error: nil)
        
        #expect(receivedValues?.data == data)
        #expect(receivedValues?.response.url == response.url)
        #expect(receivedValues?.response.statusCode == response.statusCode)
    }
    
    @Test("Get from URL succeeds with empty data on HTTPURLResponse with nil data")
    func getFromUrlSucceedsWithEmptyDataOnHttpUrlResponseWithNilData() async {
        let response = anyHttpUrlResponse()
        let receivedValues = await resultValuesFor(data: nil, response: response, error: nil)
        
        let emptyData = Data()
        
        #expect(receivedValues?.data == emptyData)
        #expect(receivedValues?.response.url == response.url)
        #expect(receivedValues?.response.statusCode == response.statusCode)
    }
    
    // MARK: Helpers
    private func makeSut() -> HTTPClient { URLSessionHTTPClient() }
    
    private func anyUrl() -> URL { URL(string: "https://a-url.com")! }
    
    private func anyData() -> Data? { "any data".data(using: .utf8) }
    
    private func anyNsError() -> NSError { NSError(domain: "any error", code: 1) }
    
    private func anyHttpUrlResponse() -> HTTPURLResponse { HTTPURLResponse(url: anyUrl(), statusCode: 200, httpVersion: nil, headerFields: nil)! }
    
    private func anyNonHttpUrlResponse() -> URLResponse { URLResponse(url: anyUrl(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil) }
    
    private func resultValuesFor(data: Data?, response: URLResponse, error: Error?, sourceLocation: SourceLocation = #_sourceLocation) async -> (data: Data, response: HTTPURLResponse)? {
        let result = await resultFor(data: data, response: response, error: error)
        
        switch result {
        case let .success(data, response):
            return (data, response)
        default:
            #expect(Bool(false), Comment("Expected success, got \(result) instead"), sourceLocation: sourceLocation)
            return nil
        }
    }
    
    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, sourceLocation: SourceLocation = #_sourceLocation) async -> Error? {
        let result = await resultFor(data: data, response: response, error: error)
        
        switch result {
        case let .failure(error):
            return error
        default:
            #expect(Bool(false), Comment("Expected failure, got \(result) instead"), sourceLocation: sourceLocation)
            return nil
        }
    }
    
    private func resultFor(data: Data?, response: URLResponse?, error: Error?, sourceLocation: SourceLocation = #_sourceLocation) async -> HTTPClientResult {
        URLProtocolStub.stub(data: data, response: response, error: error)
        
        var receivedResult: HTTPClientResult!
        await confirmation("Load completion", sourceLocation: sourceLocation) { completed in
            makeSut().get(from: anyUrl()) { result in
                receivedResult = result
                
                completed()
            }
            
            try? await Task.sleep(for: .sleepTime)
        }
        
        return receivedResult
        
    }
    
    private class URLProtocolStub: URLProtocol {
        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?
        
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }
        
        static func observeRequests(observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            requestObserver?(request)
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
        
        override func startLoading() {
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() { }
    }
}
