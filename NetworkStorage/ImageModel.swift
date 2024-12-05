//
//  ImageModel.swift
//  NetworkStorage
//
//  Created by Максим Игоревич on 01.12.2024.
//

import Foundation

struct ImageModel {
    let id: Int
    let url: String
    let name: String
    let isDownloaded: Bool
    
    init(id: Int, url: String, name: String, isDownloaded: Bool) {
        self.id = id
        self.url = url
        self.name = name
        self.isDownloaded = isDownloaded
    }
}
