//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Joffrey Mann on 2/6/24.
//

import XCTest
@testable import EssentialFeed

public struct DataTaskResult {
    let data: Data?
    let response: HTTPURLResponse?
    let error: RemoteFeedLoader.Error?
}

class URLSessionHTTPClient {
    private var session: URLSession
    private var onResume: (Int) -> Void
    private var resumeCount = 0
    
    
    fileprivate init(session: URLSession = .shared, onResume: @escaping (Int) -> Void = { _ in }) {
        self.session = session
        self.onResume = onResume
    }
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let data = data, let response = response as? HTTPURLResponse {
                completion(.success(data, response))
            } else if let error = error {
                completion(.failure(error))
            }
        }.resume()
        resumeCount += 1
        onResume(resumeCount)
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    func test_getFromURL_failsOnRequestError() {
        URLProtocolStub.startInterceptingRequests()
        let url = URL(string: "http://any-url.com")!
        let error = NSError(domain: "any error", code: 1)
        URLProtocolStub.stub(url: url, error: error)
        let sut = URLSessionHTTPClient()
        let expectation = expectation(description: "Wait for data task to finish")
        sut.get(from: url) { result in
            switch result {
            case let .failure(receivedError as NSError):
                XCTAssertEqual(receivedError.domain, error.domain)
            default:
                XCTFail("Expected failure with error \(error), got \(result) instead")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3)
        URLProtocolStub.stub(url: url, error: error)
    }
    
    private class URLProtocolStub: URLProtocol {
        var taskResult: DataTaskResult!
        private static var stubs = [URL: Stub]()
        
        private struct Stub {
            let error: Error?
        }
        
        static func stub(url: URL, error: Error?) {
            stubs[url] = Stub(error: error)
        }
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stubs = [:]
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            guard let url = request.url else { return false }
            
            return URLProtocolStub.stubs[url] != nil
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            guard let url = request.url, let stub = URLProtocolStub.stubs[url] else { return }
            
            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
}

public protocol HTTPSession {
    var task: URLSessionDataTask! { get set }
    var taskResult: DataTaskResult! { get set }
}
