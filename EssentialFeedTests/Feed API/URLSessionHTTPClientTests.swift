//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Joffrey Mann on 2/6/24.
//

import XCTest
@testable import EssentialFeed

class URLSessionHTTPClient: HTTPClient {
    private let masking: DataTaskMaking
    
    fileprivate init(masking: DataTaskMaking) {
        self.masking = masking
    }
    
    func get(from url: URL, completion: @escaping (EssentialFeed.HTTPClientResult) -> Void) {
        let task = masking.dataTask(with: url) { data, response, _ in
            if let data = data, let response = response as? HTTPURLResponse {
                completion(.success(data, response))
            } else {
                completion(.failure(.invalidData))
            }
        }
        
        task.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    func test_getFromURL_createDataTaskWithURL() {
        let expectation = expectation(description: "Wait for data task to finish")
        let url = URL(string: "http://any-url.com")!
        let sessionSpy = URLSessionWrapper(URLSession(configuration: .default))
        let sut = URLSessionHTTPClient(masking: sessionSpy)
        sut.get(from: url) { result in
            expectation.fulfill()
        }
        wait(for: [expectation])
        XCTAssertEqual(sessionSpy.receivedURLs, [url])
    }
    
    private class URLSessionWrapper: DataTaskMaking {
        var session: URLSession!
        
        var receivedURLs = [URL]()
        
        
        init(_ session: URLSession, receivedURLs: [URL] = [URL]()) {
            self.session = session
            self.receivedURLs = receivedURLs
        }
        
        public func dataTask(
            with url: URL,
            completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
        ) -> URLSessionDataTask {
            receivedURLs.append(url)
            return session.dataTask(with: url, completionHandler: completionHandler)
        }
    }

    private class FakeURLSessionDataTask {
        let session: URLSession
        let url: URL
        
        init(session: URLSession, url: URL) {
            self.session = session
            self.url = url
        }
        
        func dataTask(completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            
            return session.dataTask(with: url, completionHandler: completionHandler)
        }
    }
}

public protocol DataTaskMaking {
    var session: URLSession! { get set }
    func dataTask(
        with url: URL,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTask
}
