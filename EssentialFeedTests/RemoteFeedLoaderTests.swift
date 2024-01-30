//
//  RemoteFeedLoaderTests.swift
//
//  Created by Joffrey Mann on 1/30/24.
//

import XCTest

class RemoteFeedLoader {
    let url: URL
    let client: HTTPClient
    
    init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    func load() {
        client.get(from: url)
    }
}

protocol HTTPClient {
    func get(from url: URL)
}

class HTTPClientSpy: HTTPClient {
    func get(from url: URL) {
        requestedURL = url
    }
    
    var requestedURL: URL?
}

class RemoteFeedLoaderTests: XCTestCase {
    func test_init_doesNotRequestDataFromURL() {
        let url = URL(string: "https://a-url.com")!
        let client = HTTPClientSpy()
        _ = RemoteFeedLoader(url: url, client: client)
                
        XCTAssertNil(client.requestedURL)
    }
    
    func test_load_requestDataFromURL() {
        let url = URL(string: "https://a-urll.com")!
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        
        sut.load()
        
        XCTAssertEqual(client.requestedURL, url)
    }
}
