//
//  ImageModel.swift
//  NetworkStorage
//
//  Created by Максим Игоревич on 01.12.2024.
//

struct ImageModel {
    let id: Int
    let url: String
    let name: String
    
    init(id: Int, url: String, name: String) {
        self.id = id
        self.url = url
        self.name = name
    }
}
