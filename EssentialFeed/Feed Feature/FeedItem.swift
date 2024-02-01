//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Joffrey Mann on 1/29/24.
//

import Foundation

public struct FeedItem: Codable, Equatable {
    let id: UUID
    let description: String?
    let location: String?
    let imageURL: URL
}
