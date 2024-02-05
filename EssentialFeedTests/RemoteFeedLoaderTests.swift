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
        let error = Error(errorType: .connectivity)
        expect(sut, toCompleteWithResult: .failure(error), when: {
            let clientError = Error(errorType: .connectivity)
            client.complete(with: clientError)
        })
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        let samples = [199, 201, 300, 400, 500]
        let error = Error(errorType: .invalidData)
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWithResult: .failure(error), when: {
                client.complete(withStatusCode: code, at: index)
            })
        }
    }
    
    func test_load_deliversErrorOn200HTTPResponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        let error = Error(errorType: .invalidData)
        expect(sut, toCompleteWithResult: .failure(error)) {
            let invalidJSON = Data("invalid json".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        }
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSUT()
        
        let item1 = FeedItem(id: UUID(), description: nil, location: nil, imageURL: URL(string: "http://a-url.com")!)
        
        let item1JSON = [
            "id": item1.id.uuidString,
            "image": item1.imageURL.absoluteString
        ]
        
        let item2 = FeedItem(id: UUID(), description: "a description", location: "a location", imageURL: URL(string: "http://another-url.com")!)
        
        let item2JSON = [
            "id": item2.id.uuidString,
            "description": item2.description,
            "location": item2.location,
            "image": item2.imageURL.absoluteString
        ]
        
        let itemsJSON = [
            "items": [item1JSON, item2JSON]
        ]
        
        expect(sut, toCompleteWithResult: .success([item1, item2])) {
            let json = try! JSONSerialization.data(withJSONObject: itemsJSON)
            client.complete(withStatusCode: 200, data: json)
        }
    }
    
    func test_load_deliversItemsOn200HTTPResponseWithJSONItems() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWithResult: .success([])) {
            let emptyListJSON = Data("{\"items\": []}".utf8)
            client.complete(withStatusCode: 200, data: emptyListJSON)
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedLoader, spy: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut: sut, spy: client)
    }
    
    private func expect(_ sut: RemoteFeedLoader, withJson json: Data? = nil, toCompleteWithResult result: Result, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        var capturedResults = [Result]()
        
        sut.load { capturedResults.append($0) }
        action()
        
        XCTAssertEqual(capturedResults, [result], file: file, line: line)
    }
    
    private func expect(_ sut: RemoteFeedLoader, withJson json: Data, when action: (Result) -> Void, file: StaticString = #file, line: UInt = #line) {
        var result: Result!
        
        do {
            let items = try JSONDecoder().decode([FeedItem].self, from: json)
            result = .success(items)
        } catch {
            result = .failure(.init(errorType: .invalidData))
        }
        
        var capturedResults = [Result]()
        
        sut.load { capturedResults.append($0) }
        action(result)
        
        XCTAssertEqual(capturedResults, [result], file: file, line: line)
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
        
        func complete(with error: Error, at index: Int = 0) {
            results[index].completion(.failure(error))
        }
        
        func complete(withStatusCode statusCode: Int, data: Data = Data(), at index: Int = 0) {
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

extension Error: CustomNSError {
   public static var errorDomain: String { "Test" }
   public var errorCode: Int { 0 }
   public var errorUserInfo: [String: Any] {
       return ["info": String(describing: self)]
   }
}
