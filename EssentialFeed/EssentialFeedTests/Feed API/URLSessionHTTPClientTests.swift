//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Anh Nguyen on 12/12/2024.
//

import Foundation
import Testing
import EssentialFeed

// Serialised due to illegal continuation occuring on multiple threads when tests run in parallel
@Suite(.serialized)
final class URLSessionHTTPClientTests {
    private var sutTracker: MemoryLeakTracker<URLSessionHTTPClient>?
    
    init() {
        URLProtocolStub.startInterceptingRequests()
    }
    
    deinit {
        URLProtocolStub.stopInterceptingRequests()
        sutTracker?.verifyDeallocation()
    }
    
    @Test("Get from URL performs GET request")
    func getFromUrlPerformsGetRequestWithUrl() async {
        let url = makeUrl()
        
        await confirmationWithCheckedContinuation("Request completion") { completed in
            URLProtocolStub.observeRequests { request in
                #expect(request.url == url)
                #expect(request.httpMethod == "GET")
                completed()
            }
            
            makeSut().get(from: url) { _ in }
        }
    }
    
    @Test("Get from URL fails on request error")
    func getFromUrlFailsOnRequestError() async {
        let requestError = makeNsError()
        let receivedError = await resultErrorFor(data: nil, response: nil, error: requestError) as? NSError
        
        #expect(receivedError?.domain == requestError.domain)
        #expect(receivedError?.code == requestError.code)
    }
    
    @Test("Get from URL fails on all invalid combinations values")
    func getFromUrlFailsOnAllInvalidRepresentationCases() async {
        #expect(await resultErrorFor(data: nil, response: nil, error: nil) != nil)
        #expect(await resultErrorFor(data: nil, response: makeNonHttpUrlResponse(), error: nil) != nil)
        #expect(await resultErrorFor(data: makeData(), response: nil, error: nil) != nil)
        #expect(await resultErrorFor(data: makeData(), response: nil, error: makeNsError()) != nil)
        #expect(await resultErrorFor(data: nil, response: makeNonHttpUrlResponse(), error: makeNsError()) != nil)
        #expect(await resultErrorFor(data: nil, response: makeHttpUrlResponse(), error: makeNsError()) != nil)
        #expect(await resultErrorFor(data: makeData(), response: makeNonHttpUrlResponse(), error: makeNsError()) != nil)
        #expect(await resultErrorFor(data: makeData(), response: makeHttpUrlResponse(), error: makeNsError()) != nil)
        #expect(await resultErrorFor(data: makeData(), response: makeNonHttpUrlResponse(), error: nil) != nil)
    }
    
    @Test("Get from URL succeeds on HTTPURLResponse with data")
    func getFromUrlSucceedsOnHttpUrlResponseWithData() async {
        let data = makeData()
        let response = makeHttpUrlResponse()
        
        let receivedValues = await resultValuesFor(data: data, response: response, error: nil)
        
        #expect(receivedValues?.data == data)
        #expect(receivedValues?.response.url == response.url)
        #expect(receivedValues?.response.statusCode == response.statusCode)
    }
    
    @Test("Get from URL succeeds with empty data on HTTPURLResponse with nil data")
    func getFromUrlSucceedsWithEmptyDataOnHttpUrlResponseWithNilData() async {
        let response = makeHttpUrlResponse()
        let receivedValues = await resultValuesFor(data: nil, response: response, error: nil)
        
        let emptyData = Data()
        
        #expect(receivedValues?.data == emptyData)
        #expect(receivedValues?.response.url == response.url)
        #expect(receivedValues?.response.statusCode == response.statusCode)
    }
    
    // MARK: Helpers
    private func makeSut(sourceLocation: SourceLocation = #_sourceLocation) -> HTTPClient {
        let sut = URLSessionHTTPClient()
        sutTracker = MemoryLeakTracker(instance: sut, sourceLocation: sourceLocation)
        return sut
    }
    
    private func makeData() -> Data { Data("any data".utf8) }
    
    private func makeHttpUrlResponse() -> HTTPURLResponse { HTTPURLResponse(url: makeUrl(), statusCode: 200, httpVersion: nil, headerFields: nil)! }
    
    private func makeNonHttpUrlResponse() -> URLResponse { URLResponse(url: makeUrl(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil) }
    
    private func resultValuesFor(data: Data?, response: URLResponse, error: Error?, sourceLocation: SourceLocation = #_sourceLocation) async -> (data: Data, response: HTTPURLResponse)? {
        let result = await resultFor(data: data, response: response, error: error)
        
        switch result {
        case let .success(data, response):
            return (data, response)
        default:
            Issue.record("Expected success, got \(result) instead", sourceLocation: sourceLocation)
            return nil
        }
    }
    
    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, sourceLocation: SourceLocation = #_sourceLocation) async -> Error? {
        let result = await resultFor(data: data, response: response, error: error, sourceLocation: sourceLocation)
        
        switch result {
        case let .failure(error):
            return error
        default:
            Issue.record("Expected success, failure \(result) instead", sourceLocation: sourceLocation)
            return nil
        }
    }
    
    private func resultFor(data: Data?, response: URLResponse?, error: Error?, sourceLocation: SourceLocation = #_sourceLocation) async -> HTTPClientResult {
        URLProtocolStub.stub(data: data, response: response, error: error)
        
        var receivedResult: HTTPClientResult!
        
        await confirmationWithCheckedContinuation("Load completion", sourceLocation: sourceLocation) { completed in
            makeSut().get(from: makeUrl()) { result in
                receivedResult = result
                completed()
            }
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
        
        override class func canInit(with request: URLRequest) -> Bool { true }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
        
        override func startLoading() {
            if let requestObserver = URLProtocolStub.requestObserver {
                client?.urlProtocolDidFinishLoading(self)
                return requestObserver(request)
            }
            
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
