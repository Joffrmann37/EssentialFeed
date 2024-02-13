//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Joffrey Mann on 1/30/24.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
    public typealias Error = ErrorTypes

    public enum ErrorTypes: Int, Swift.Error {
        case connectivity = 0
        case invalidData
    }
    
    public typealias Result = LoadFeedResult
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
            case let .failure(error as RemoteFeedLoader.Error):
                completion(.failure(error))
            case .failure(_):
                completion(.failure(.invalidData))
            }
        }
    }
}
