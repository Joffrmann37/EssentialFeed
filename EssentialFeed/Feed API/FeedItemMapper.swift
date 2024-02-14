//
//  FeedItemMapper.swift
//  EssentialFeed
//
//  Created by Joffrey Mann on 2/5/24.
//

import Foundation

internal final class FeedItemsMapper {
    struct Root: Decodable {
        let items: [Item]
        
        var feed: [FeedItem] {
            return items.map { $0.item }
        }
    }


    struct Item: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let image: URL
        
        var item: FeedItem {
            return FeedItemFactory.make(id: id, description: description, location: location, imageURL: image).model
        }
    }
    
    static var OK_200: Int { return 200 }
    
    internal static func map(_ data: Data, _ response: HTTPURLResponse) -> RemoteFeedLoader.Result {
        guard response.statusCode == OK_200, 
                                     let root = try?
                                     JSONDecoder().decode(Root.self,
                                     from: data) else {
            return .failure(RemoteFeedLoader.Error.invalidData)
        }
        
        return .success(root.feed)
    }
}
