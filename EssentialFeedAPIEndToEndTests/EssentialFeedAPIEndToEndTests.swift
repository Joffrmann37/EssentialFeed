//
//  EssentialFeedAPIEndToEndTests.swift
//  EssentialFeedAPIEndToEndTests
//
//  Created by Joffrey Mann on 2/14/24.
//

import XCTest
@testable import EssentialFeed

class EssentialFeedAPIEndToEndTests: XCTestCase {
    func test_endToEndTestServerGETFeedResult_matchesFixedTestAccountData() {
        let receivedResult = result()
        
        switch receivedResult {
        case let .success(items):
            XCTAssertEqual(items.count, 8)
            items.enumerated().forEach { index, item in
                XCTAssertEqual(item, expectedItem(index: index), "Unexpected item values at index \(index)")
            }
        default:
            XCTFail("Expected successful feed result, got no result instead")
        }
    }
    
    // MARK: - Helpers
    private func result(file: StaticString = #file, line: UInt = #line) -> LoadFeedResult? {
        let expectation = expectation(description: "Wait for completion")
        let testServerURL = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!
        let client = URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
        let loader = RemoteFeedLoader(url: testServerURL, client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(loader, file: file, line: line)
        
        var receivedResult: LoadFeedResult?
        loader.load { result in
            receivedResult = result
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)
        return receivedResult
    }
    
    private func expectedItem(index: Int) -> FeedItem {
        return FeedItem(id: id(at: index), description: description(at: index), location: location(at: index), imageURL: imageURL(at: index))
    }
    
    private func id(at index: Int) -> UUID {
        return UUID(uuidString: [
            "73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6",
            "BA298A85-6275-48D3-8315-9C8F7C1CD109",
            "5A0D45B3-8E26-4385-8C5D-213E160A5E3C",
            "FF0ECFE2-2879-403F-8DBE-A83B4010B340",
            "DC97EF5E-2CC9-4905-A8AD-3C351C311001",
            "557D87F1-25D3-4D77-82E9-364B2ED9CB30",
            "A83284EF-C2DF-415D-AB73-2A9B8B04950B",
            "F79BD7F8-063F-46E2-8147-A67635C3BB01"
        ][index])!
    }
    
    private func description(at index: Int) -> String? {
        return [
            "Description 1",
            nil,
            "Description 3",
            nil,
            "Description 5",
            "Description 6",
            "Description 7",
            "Description 8"
        ][index]
    }
    
    private func location(at index: Int) -> String? {
        return [
            "Location 1",
            "Location 2",
            nil,
            nil,
            "Location 5",
            "Location 6",
            "Location 7",
            "Location 8"
        ][index]
    }
    
    private func imageURL(at index: Int) -> URL {
        return URL(string: [
            "https://url-1.com",
            "https://url-2.com",
            "https://url-3.com",
            "https://url-4.com",
            "https://url-5.com",
            "https://url-6.com",
            "https://url-7.com",
            "https://url-8.com"
        ][index])!
    }
}
