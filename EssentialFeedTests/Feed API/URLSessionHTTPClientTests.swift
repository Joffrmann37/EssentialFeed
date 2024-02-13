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
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        if let data = result.data, let response = result.response {
            completion(.success(data, response))
        } else if let error = result.error {
            completion(.failure(error))
        }
        resumeCount += 1
        onResume(resumeCount)
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    func test_getFromURL_resumesDataTaskWithURL() {
        var resumeCounter = 0
        let url = URL(string: "http://any-url.com")!
        let (task, expectation, sessionSpy) = testTaskWithExpectation(url: url, error: nil, fulfillmentCount: 2)
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
    
    func test_getFromURL_failsOnRequestError() {
        let url = URL(string: "http://any-url.com")!
        let error = NSError(domain: RemoteFeedLoader.Error.errorDomain, code: 0)
        let (task, expectation, sessionSpy) = testTaskWithExpectation(url: url, error: error)
        task.resume()
        wait(for: [expectation])
        sessionSpy.stub(url: url, task: task)
        let sut = URLSessionHTTPClient(task: sessionSpy.getStubs()[url]!.task, result: sessionSpy.taskResult)
        sut.get(from: url) { result in
            switch result {
            case .failure(let receivedError):
                XCTAssertEqual(receivedError, .connectivity)
            default:
                XCTFail("Expected failure with error \(error), got \(result) instead")
            }
        }
    }
    
    // MARK: Helper Functions
    private func testTaskWithExpectation(url: URL, error: NSError? = nil, fulfillmentCount: Int = 1) -> (URLSessionDataTask, XCTestExpectation, URLSessionWrapper) {
        let expectation = expectation(description: "Wait for data task to finish")
        expectation.expectedFulfillmentCount = fulfillmentCount
        let session = URLSession(configuration: .default)
        let sessionSpy = URLSessionWrapper(session: session)
        let task = session.dataTask(with: url) { data, response, error in
            guard let response = response as? HTTPURLResponse else {
                sessionSpy.taskResult = DataTaskResult(data: data, response: nil, error: RemoteFeedLoader.Error.connectivity)
                expectation.fulfill()
                return
            }
            sessionSpy.taskResult = DataTaskResult(data: data, response: response, error: RemoteFeedLoader.Error.connectivity)
            expectation.fulfill()
        }
        sessionSpy.stub(url: url, task: task, error: error)
        return (task, expectation, sessionSpy)
    }
    
    private class URLSessionWrapper: DataTaskMaking {
        var session: URLSession!
        var taskResult: DataTaskResult!
        private var stubs = [URL: Stub]()
        
        struct Stub {
            let task: URLSessionDataTask
            let error: Error?
        }
        
        init(session: URLSession!) {
            self.session = session
        }
        
        func stub(url: URL, task: URLSessionDataTask, error: Error? = nil) {
            stubs[url] = Stub(task: task, error: error)
        }
        
        func dataTask(with url: URL, completionHandler: @escaping @Sendable (DataTaskResult) -> Void) -> URLSessionDataTask {
            guard let stub = stubs[url] else {
                fatalError("Couldn't find stub for \(url)")
            }
            
            completionHandler(taskResult)
            return stub.task
        }
        
        func getStubs() -> [URL: Stub] {
            return stubs
        }
    }
}

public protocol DataTaskMaking {
    var session: URLSession! { get set }
    func dataTask(with url: URL, completionHandler: @escaping @Sendable (DataTaskResult) -> Void) -> URLSessionDataTask
}
