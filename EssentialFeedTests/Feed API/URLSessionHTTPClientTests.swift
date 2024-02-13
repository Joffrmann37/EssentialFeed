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
    private var session: HTTPSession
    private var onResume: (Int) -> Void
    private var resumeCount = 0
    
    
    fileprivate init(session: HTTPSession, onResume: @escaping (Int) -> Void = { _ in }) {
        self.session = session
        self.onResume = onResume
    }
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        if let data = session.taskResult.data, let response = session.taskResult.response {
            completion(.success(data, response))
        } else if let error = session.taskResult.error {
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
        let (expectation, sessionSpy) = testTaskWithExpectation(url: url, error: nil, fulfillmentCount: 2)
        sessionSpy.getStubs()[url]!.task.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let sut = URLSessionHTTPClient(session: sessionSpy, onResume: { count in
                resumeCounter = count
            })
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
        let (expectation, sessionSpy) = testTaskWithExpectation(url: url, error: error)
        sessionSpy.getStubs()[url]!.task.resume()
        wait(for: [expectation])
        let sut = URLSessionHTTPClient(session: sessionSpy)
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
    private func testTaskWithExpectation(url: URL, error: NSError? = nil, fulfillmentCount: Int = 1) -> (XCTestExpectation, URLSessionWrapper) {
        let expectation = expectation(description: "Wait for data task to finish")
        expectation.expectedFulfillmentCount = fulfillmentCount
        let session = URLSession(configuration: .default)
        let sessionSpy = URLSessionWrapper(session: session)
        let task = sessionSpy.dataTask(with: url) {
            expectation.fulfill()
        }
        sessionSpy.stub(url: url, task: task, error: error)
        return (expectation, sessionSpy)
    }
    
    private class URLSessionWrapper: HTTPSession {
        var task: URLSessionDataTask!
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
        
        func stub(url: URL, task: URLSessionDataTask, error: Error?) {
            stubs[url] = Stub(task: task, error: error)
        }
        
        func dataTask(with url: URL, completionHandler: @escaping @Sendable () -> Void) -> URLSessionDataTask {
            let task = session.dataTask(with: url) { data, response, error in
                guard let response = response as? HTTPURLResponse else {
                    self.taskResult = DataTaskResult(data: data, response: nil, error: RemoteFeedLoader.Error.connectivity)
                    completionHandler()
                    return
                }
                self.taskResult = DataTaskResult(data: data, response: response, error: RemoteFeedLoader.Error.connectivity)
                completionHandler()
            }
            return task
        }
        
        func getStubs() -> [URL: Stub] {
            return stubs
        }
    }
}

public protocol HTTPSession {
    var task: URLSessionDataTask! { get set }
    var taskResult: DataTaskResult! { get set }
}
