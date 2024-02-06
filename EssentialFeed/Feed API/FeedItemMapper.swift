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
    
    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [FeedItem] {
        guard response.statusCode == OK_200 else {
            throw ErrorTypes.invalidData
        }
        
        return try
            JSONDecoder().decode(Root.self,
            from: data).items.map { $0.item }
    }
}
