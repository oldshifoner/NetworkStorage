//
//  ImageModel.swift
//  NetworkStorage
//
//  Created by Максим Игоревич on 01.12.2024.
//

import UIKit
import Combine

class ImageModel: ObservableObject {
    let id: String
    let url: String
    @Published var isDownloaded: Bool = false
    @Published var localImage: UIImage? = nil
    @Published var progress: Float = 0.0
    
    init(id: String, url: String) {
        self.id = id
        self.url = url
    }
}
