//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Joffrey Mann on 1/29/24.
//

import Foundation

public struct FeedItem: Equatable {
    let id: UUID
    let description: String?
    let location: String?
    let imageURL: URL
}

public struct FeedItemFactory {
    static func make(id: UUID, description: String?, location: String?, imageURL: URL) -> (model: FeedItem, json: [String:Any]) {
        let item = FeedItem(id: id, description: description, location: location, imageURL: imageURL)
        let json: [String:Any] = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].reduce(into: [String: Any]()) { (acc, dict) in
            if let value = dict.value { acc[dict.key] = value }
        }
        
        return (item, json)
    }
}
