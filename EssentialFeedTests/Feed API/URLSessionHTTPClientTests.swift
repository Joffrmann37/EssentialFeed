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
    let error: Error?
}

class URLSessionHTTPClient: HTTPClient {
    private var task: URLSessionDataTask
    private var onResume: (Int) -> Void
    private var result: DataTaskResult
    private var resumeCount = 0
    
    
    fileprivate init(task: URLSessionDataTask, onResume: @escaping (Int) -> Void = { _ in }, result: DataTaskResult) {
        self.task = task
        self.onResume = onResume
        self.result = result
    }
    
    func get(from url: URL, completion: @escaping (EssentialFeed.HTTPClientResult) -> Void) {
        if let data = result.data, let response = result.response {
            completion(.success(data, response))
        } else {
            completion(.failure(.invalidData))
        }
        resumeCount += 1
        onResume(resumeCount)
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    func test_getFromURL_resumesDataTaskWithURLSuccess() {
        var resumeCounter = 0
        let expectation = expectation(description: "Wait for data task to finish")
        expectation.expectedFulfillmentCount = 2
        let url = URL(string: "http://espn.com")!
        let session = URLSession(configuration: .default)
        let sessionSpy = URLSessionWrapper(session: session)
        let task = session.dataTask(with: url) { data, response, _ in
            guard let response = response as? HTTPURLResponse else {
                sessionSpy.taskResult = DataTaskResult(data: data, response: nil, error: nil)
                expectation.fulfill()
                return
            }
            sessionSpy.taskResult = DataTaskResult(data: data, response: response, error: nil)
            expectation.fulfill()
        }
        task.resume()
        sessionSpy.stub(url: url, task: task)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let sut = URLSessionHTTPClient(task: task, onResume: { count in
                resumeCounter = count
            }, result: sessionSpy.taskResult)
            sut.get(from: url) { result in
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 2)
        XCTAssertEqual(resumeCounter, 1)
    }
    
    private class URLSessionWrapper: DataTaskMaking {
        var session: URLSession!
        var taskResult: DataTaskResult!
        private var stubs = [URL: URLSessionDataTask]()
        
        init(session: URLSession!) {
            self.session = session
        }
        
        func stub(url: URL, task: URLSessionDataTask) {
            stubs[url] = task
        }
        
        func dataTask(with url: URL, completionHandler: @escaping @Sendable (DataTaskResult) -> Void) -> URLSessionDataTask {
            guard let task = stubs[url] else {
                return session.dataTask(with: url) { _, _, _ in}
            }
            
            completionHandler(taskResult)
            return task
        }
    }
}

public protocol DataTaskMaking {
    var session: URLSession! { get set }
    func dataTask(with url: URL, completionHandler: @escaping @Sendable (DataTaskResult) -> Void) -> URLSessionDataTask
}
