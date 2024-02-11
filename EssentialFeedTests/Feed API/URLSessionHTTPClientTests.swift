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
        taskMaker.stub(url: url, task: taskMaker.dataTask(with: url) { data, response, _ in
            if let data = data, let response = response as? HTTPURLResponse {
                completion(.success(data, response))
            } else {
                completion(.failure(.invalidData))
            }
        })
        resumeCount += 1
        taskMaker.onResume(resumeCount)
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    func test_getFromURL_resumesDataTaskWithURL() {
        var resumeCounter = 0
        let expectation = expectation(description: "Wait for data task to finish")
        let url = URL(string: "http://any-url.com")!
        let sessionSpy = URLSessionWrapper(session: URLSession(configuration: .default), onResume: { count in
            resumeCounter = count
        })
        sessionSpy.stub(url: url, task: sessionSpy.currentTask)
        let sut = URLSessionHTTPClient(taskMaker: sessionSpy)
        sut.get(from: url) { result in
            expectation.fulfill()
        }
        wait(for: [expectation])
        XCTAssertEqual(resumeCounter, 1)
    }
    
    private class URLSessionWrapper: DataTaskMaking {
        var session: URLSession!
        var onResume: (Int) -> Void
        var currentTask: URLSessionDataTask
        private var stubs = [URL: URLSessionDataTask]()
        
        init(session: URLSession!, onResume: @escaping (Int) -> Void = { _ in }) {
            self.session = session
            self.onResume = onResume
            self.currentTask = session.dataTask(with: URL(string: "http://any-url.com")!) { _, _, _ in }
        }
        
        func stub(url: URL, task: URLSessionDataTask) {
            stubs[url] = task
        }
        
        func dataTask(with url: URL, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            guard let task = stubs[url] else {
                return session.dataTask(with: url, completionHandler: completionHandler)
            }
            
            return task
        }
    }
}

public protocol DataTaskMaking {
    var session: URLSession! { get set }
    var onResume: (Int) -> Void { get set }
    var currentTask: URLSessionDataTask { get set }
    func stub(url: URL, task: URLSessionDataTask)
    func dataTask(with url: URL, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
}
