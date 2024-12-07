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
    let isDownloadedEvent: ((Int) -> ())?
    
    init(id: Int, url: String, name: String, isDownloaded: Bool, isDownloadedEvent: ((Int) -> ())?) {
        self.id = id
        self.url = url
        self.name = name
        self.isDownloaded = isDownloaded
        self.isDownloadedEvent = isDownloadedEvent
    }
}
