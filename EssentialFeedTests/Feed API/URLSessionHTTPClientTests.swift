//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Joffrey Mann on 2/6/24.
//

import XCTest
@testable import EssentialFeed

class URLSessionHTTPClient: HTTPClient {
    private var taskMaker: DataTaskMaking
    private var resumeCount = 0
    
    
    fileprivate init(taskMaker: DataTaskMaking) {
        self.taskMaker = taskMaker
    }
    
    func get(from url: URL, completion: @escaping (EssentialFeed.HTTPClientResult) -> Void) {
        let task = taskMaker.session.dataTask(with: url) { data, response, _ in
            if let data = data, let response = response as? HTTPURLResponse {
                completion(.success(data, response))
            } else {
                completion(.failure(.invalidData))
            }
        }
        task.resume()
        resumeCount += 1
        taskMaker.onResume(resumeCount)
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    func test_getFromURL_createDataTaskWithURL() {
        let expectation = expectation(description: "Wait for data task to finish")
        let url = URL(string: "http://any-url.com")!
        let sessionSpy = URLSessionWrapper( session: URLSession(configuration: .default))
        let sut = URLSessionHTTPClient(taskMaker: sessionSpy)
        sut.get(from: url) { result in
            sessionSpy.receivedURLs.append(url)
            expectation.fulfill()
        }
        wait(for: [expectation])
        XCTAssertEqual(sessionSpy.receivedURLs, [url])
    }
    
    func test_getFromURL_resumesDataTaskWithURL() {
        var resumeCounter = 0
        let expectation = expectation(description: "Wait for data task to finish")
        let url = URL(string: "http://any-url.com")!
        let sessionSpy = URLSessionWrapper(session: URLSession(configuration: .default), onResume: { count in
            resumeCounter = count
        })
        let sut = URLSessionHTTPClient(taskMaker: sessionSpy)
        sut.get(from: url) { result in
            sessionSpy.receivedURLs.append(url)
            expectation.fulfill()
        }
        wait(for: [expectation])
        XCTAssertEqual(resumeCounter, 1)
    }
    
    private class URLSessionWrapper: DataTaskMaking {
        var session: URLSession!
        var onResume: (Int) -> Void
        var receivedURLs = [URL]()
        
        init(session: URLSession!, onResume: @escaping (Int) -> Void = { _ in }, receivedURLs: [URL] = [URL]()) {
            self.session = session
            self.onResume = onResume
            self.receivedURLs = receivedURLs
        }
    }
}

public protocol DataTaskMaking {
    var session: URLSession! { get set }
    var onResume: (Int) -> Void { get set }
}
