//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Anh Nguyen on 12/12/2024.
//

import EssentialFeed
import Foundation
import XCTest

final class URLSessionHTTPClientTests: XCTestCase {
    override func setUp() {
        super.setUp()
        
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
        super.tearDown()
        
        URLProtocolStub.stopInterceptingRequests()
    }
    
    func getFromUrlPerformsGetRequestWithUrl() {
        let url = makeUrl()
        let exp = expectation(description: "Wait for request")
        
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        makeSut().get(from: url) { _ in }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func getFromUrlFailsOnRequestError() {
        let requestError = makeNsError()
        
        let receivedError = resultErrorFor(data: nil, response: nil, error: requestError) as? NSError
        
        XCTAssertEqual(receivedError?.domain, requestError.domain)
        XCTAssertEqual(receivedError?.code, requestError.code)
    }
    
    func getFromUrlFailsOnAllInvalidRepresentationCases() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: makeNonHttpUrlResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: makeData(), response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: makeData(), response: nil, error: makeNsError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: makeNonHttpUrlResponse(), error: makeNsError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: makeHttpUrlResponse(), error: makeNsError()))
        XCTAssertNotNil(resultErrorFor(data: makeData(), response: makeNonHttpUrlResponse(), error: makeNsError()))
        XCTAssertNotNil(resultErrorFor(data: makeData(), response: makeHttpUrlResponse(), error: makeNsError()))
        XCTAssertNotNil(resultErrorFor(data: makeData(), response: makeNonHttpUrlResponse(), error: nil))
    }
    
    func getFromUrlSucceedsOnHttpUrlResponseWithData() {
        let data = makeData()
        let response = makeHttpUrlResponse()
        
        let receivedValues = resultValuesFor(data: data, response: response, error: nil)
        
        XCTAssertEqual(receivedValues?.data, data)
        XCTAssertEqual(receivedValues?.response.url, response.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
    }
    
    func getFromUrlSucceedsWithEmptyDataOnHttpUrlResponseWithNilData() {
        let response = makeHttpUrlResponse()
        
        let receivedValues = resultValuesFor(data: nil, response: response, error: nil)
        
        let emptyData = Data()
        XCTAssertEqual(receivedValues?.data, emptyData)
        XCTAssertEqual(receivedValues?.response.url, response.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
    }
    
    // MARK: Helpers
    private func makeSut(file: StaticString = #file, line: UInt = #line) -> HTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func makeData() -> Data { Data("any data".utf8) }
    
    private func makeHttpUrlResponse() -> HTTPURLResponse { HTTPURLResponse(url: makeUrl(), statusCode: 200, httpVersion: nil, headerFields: nil)! }
    
    private func makeNonHttpUrlResponse() -> URLResponse { URLResponse(url: makeUrl(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil) }
    
    private func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Expected \(instance!) to be deallocated", file: file, line: line)
        }
    }
    
    private func resultValuesFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> (data: Data, response: HTTPURLResponse)? {
            let result = resultFor(data: data, response: response, error: error, file: file, line: line)

            switch result {
            case let .success((data, response)):
                return (data, response)
            default:
                XCTFail("Expected success, got \(result) instead", file: file, line: line)
                return nil
            }
        }

        private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> Error? {
            let result = resultFor(data: data, response: response, error: error, file: file, line: line)
            
            switch result {
            case let .failure(error):
                return error
            default:
                XCTFail("Expected failure, got \(result) instead", file: file, line: line)
                return nil
            }
        }
        
        private func resultFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> HTTPClient.Result {
            URLProtocolStub.stub(data: data, response: response, error: error)
            let sut = makeSut(file: file, line: line)
            let exp = expectation(description: "Wait for completion")
            
            var receivedResult: HTTPClient.Result!
            sut.get(from: makeUrl()) { result in
                receivedResult = result
                exp.fulfill()
            }
            
            wait(for: [exp], timeout: 1.0)
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
