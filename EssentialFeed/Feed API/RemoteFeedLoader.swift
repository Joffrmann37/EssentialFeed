//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Joffrey Mann on 1/30/24.
//

import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (RemoteFeedLoader.Result) -> Void)
}

public enum ErrorTypes: Swift.Error {
    case connectivity
    case invalidData
}

public final class RemoteFeedLoader {
    public enum Result: Equatable {
        case success([FeedItem])
        case failure(Error)
    }

    public struct Error: Equatable {
        let errorType: ErrorTypes
    }
    
    private let url: URL
    private let client: HTTPClient
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (RemoteFeedLoader.Result) -> Void) {
        client.get(from: url) { result in
            completion(result)
        }
    }
}
