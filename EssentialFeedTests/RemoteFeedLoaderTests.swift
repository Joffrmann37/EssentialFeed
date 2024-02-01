//
//  RemoteFeedLoaderTests.swift
//
//  Created by Joffrey Mann on 1/30/24.
//

import XCTest
@testable import EssentialFeed

class RemoteFeedLoaderTests: XCTestCase {
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
                
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _  in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _  in }
        sut.load { _  in }
        
        XCTAssertEqual(client.requestedURLs,
        [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        let error = RemoteFeedLoader.Error(errorType: .connectivity)
        expect(sut, toCompleteWithResult: .failure(error), when: { result in
            let clientError = RemoteFeedLoader.Error(errorType: .connectivity)
            client.complete(with: clientError)
        })
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        let samples = [199, 201, 300, 400, 500]
        let error = RemoteFeedLoader.Error(errorType: .invalidData)
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWithResult: .failure(error), when: { result in
                client.complete(withStatusCode: code, at: index, withResult: result)
            })
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        let error = RemoteFeedLoader.Error(errorType: .invalidData)
        expect(sut, toCompleteWithResult: .failure(error)) { result in 
            client.complete(withStatusCode: 200, withResult: result)
        }
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWithResult: .success([])) { result in
            client.complete(withStatusCode: 200, withResult: result)
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedLoader, spy: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut: sut, spy: client)
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWithResult result: RemoteFeedLoader.Result, when action: (RemoteFeedLoader.Result) -> Void, file: StaticString = #file, line: UInt = #line) {
        var capturedResults = [RemoteFeedLoader.Result]()
        
        sut.load { capturedResults.append($0) }
        action(result)
        
        XCTAssertEqual(capturedResults, [result], file: file, line: line)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var results = [FeedLoaderResult]()
        var requestedURLs: [URL] {
            return results.map { $0.url }
        }
        
        func get(from url: URL, completion: @escaping (RemoteFeedLoader.Result) -> Void) {
            let feedLoaderResult = FeedLoaderResult(url: url, completion: completion)
            results.append(feedLoaderResult)
        }
        
        func complete(with error: RemoteFeedLoader.Error, at index: Int = 0) {
            results[index].completion(.failure(error))
        }
        
        func complete(withStatusCode statusCode: Int, at index: Int = 0, withResult result: RemoteFeedLoader.Result) {
            let err = RemoteFeedLoader.Error(errorType: .invalidData)
            switch result {
            case .success(let items):
                results[index].completion(.success([]))
            case .failure(let error):
                results[index].completion(.failure(err))
            }
        }
    }
}

public struct FeedLoaderResult {
    var url: URL
    var completion: (RemoteFeedLoader.Result) -> Void
}

extension RemoteFeedLoader.Error: CustomNSError {
   public static var errorDomain: String { "Test" }
   public var errorCode: Int { 0 }
   public var errorUserInfo: [String: Any] {
       return ["info": String(describing: self)]
   }
}
