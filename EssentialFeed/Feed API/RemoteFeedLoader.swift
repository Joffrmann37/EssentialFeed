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
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}

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
        client.get(from: url) { result in
            switch result {
            case let .success(data, response):
                do {
                    let items = try FeedItemsMaapper.map(data, response)
                    completion(.success(items))
                } catch {
                    guard let error = error as? ErrorTypes else {
                        return
                    }
                    completion(.failure(.init(errorType: error)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

private class FeedItemsMaapper {
    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [FeedItem] {
        guard response.statusCode == 200 else {
            throw ErrorTypes.invalidData
        }
        
        return try
            JSONDecoder().decode(Root.self,
            from: data).items.map { $0.item }
    }
}

private struct Root: Decodable {
    let items: [Item]
}


private struct Item: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
    
    var item: FeedItem {
        return FeedItemFactory.make(id: id, description: description, location: location, imageURL: image).model
    }
}
