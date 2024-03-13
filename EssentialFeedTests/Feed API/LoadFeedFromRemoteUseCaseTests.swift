//
//  RemoteFeedLoaderTests.swift
//
//  Created by Joffrey Mann on 1/30/24.
//

import XCTest
@testable import EssentialFeed

class LoadFeedFromRemoteUseCaseTests: XCTestCase {
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
        expect(sut, toCompleteWithResult: failure(.connectivity), when: {
            client.complete(with: .connectivity)
        })
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWithResult: failure(.invalidData), when: {
                let json = makeItemsJSON([])
                client.complete(withStatusCode: code, data: json, at: index)
            })
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        expect(sut, toCompleteWithResult: failure(.invalidData)) {
            let invalidJSON = Data("invalid json".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        }
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWithResult: .success([])) {
            let emptyListJSON = makeItemsJSON([])
            client.complete(withStatusCode: 200, data: emptyListJSON)
        }
    }
    
    func test_load_deliversItemsOn200HTTPResponseWithJSONItems() {
        let (sut, client) = makeSUT()
        
        let (item1, item1JSON) = makeItem(id: UUID(), imageURL: URL(string: "http://a-url.com")!)
        
        let (item2, item2JSON) = makeItem(id: UUID(), description: "a description", location: "a location", imageURL: URL(string: "http://another-url.com")!)
        
        expect(sut, toCompleteWithResult: .success([item1, item2])) {
            let json = makeItemsJSON([item1JSON, item2JSON])
            client.complete(withStatusCode: 200, data: json)
        }
    }
    
    func test_load_doesNotDeliverResultAfterSUTInstance() {
        let url = URL(string: "http://any-url.com")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)
        
        var capturedResults = [RemoteFeedLoader.Result]()
        
        sut?.load { capturedResults.append($0) }
        
        sut = nil
        client.complete(withStatusCode: 200, data: makeItemsJSON([]))
        
        XCTAssertTrue(capturedResults.isEmpty)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!, file: StaticString = #file, line: UInt = #line) -> (sut: RemoteFeedLoader, spy: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        trackForMemoryLeaks(sut)
        return (sut: sut, spy: client)
    }
    
    private func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
        return .failure(error)
    }
    
    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedItem, json: [String:Any]) {
        return FeedItemFactory.make(id: id, description: description, location: location, imageURL: imageURL)
    }
    
    private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
        let itemsJSON = [
            "items": items
        ]
        
        return try! JSONSerialization.data(withJSONObject: itemsJSON)
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWithResult expectedResult: RemoteFeedLoader.Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        
        let expectation = expectation(description: "Wait for load completion")
        sut.load { [weak self] receivedResult in
            guard let self = self else { return }
            let (isSuccess, isResultsMatch) = compare(receivedResult: receivedResult, expectedResult: expectedResult)
            guard isResultsMatch else {
                XCTFail("Expected result \(expectedResult) got \(receivedResult) instead", file: file, line: line)
                return
            }
            XCTAssertTrue(isSuccess, file: file, line: line)
            expectation.fulfill()
        }
        action()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    private func compare(receivedResult: RemoteFeedLoader.Result, 
                         expectedResult: RemoteFeedLoader.Result,
                         file: StaticString = #file,
                         line: UInt = #line) -> (isSuccess: Bool,
                                                 isResultsMatch: Bool)  {
        switch (receivedResult, expectedResult) {
        case let (.success(receivedItems), .success(expectedItems)):
            return (receivedItems == expectedItems, true)
        case let (.failure(receivedError), .failure(expectedError)):
            return (receivedError == expectedError, true)
        default:
            return (false, false)
        }
    }
    
    private class HTTPClientSpy: HTTPClient {
        var results = [FeedLoaderResult]()
        var requestedURLs: [URL] {
            return results.map { $0.url }
        }
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            let feedLoaderResult = FeedLoaderResult(url: url, completion: completion)
            results.append(feedLoaderResult)
        }
        
        func complete(with error: RemoteFeedLoader.Error, at index: Int = 0) {
            results[index].completion(.failure(error))
        }
        
        func complete(withStatusCode statusCode: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(
                            url: requestedURLs[index],
                            statusCode: statusCode,
                            httpVersion: nil,
                            headerFields: nil
                        )!
            results[index].completion(.success(data, response))
        }
    }
}

public struct FeedLoaderResult {
    var url: URL
    var completion: (HTTPClientResult) -> Void
}

extension RemoteFeedLoader.Error: CustomNSError {
   public static var errorDomain: String { "Test" }
   public var errorCode: Int { 0 }
   public var errorUserInfo: [String: Any] {
       return ["info": String(describing: self)]
   }
}
