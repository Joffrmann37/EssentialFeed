//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Joffrey Mann on 1/30/24.
//

import Foundation

public enum Result: Equatable {
    case success([FeedItem])
    case failure(Error)
}

public struct Error: Equatable {
    let errorType: ErrorTypes
}

public enum ErrorTypes: Swift.Error {
    case connectivity
    case invalidData
}

public final class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            
            switch result {
            case let .success(data, response):
                completion(FeedItemsMapper.map(data, response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
