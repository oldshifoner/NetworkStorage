//
//  ImageListViewModel.swift
//  NetworkStorage
//
//  Created by Максим Игоревич on 01.12.2024.
//

import Foundation

class ImageListViewModel {
    
    public var imageModels: [ImageModel] = []
    
    public var updateData: (() -> ())?
    
    public var updateCellData: ((Int) -> ())?
    
    public func initArrayImageModels(assets: [[String : Any]], serverURL: String){
        for asset in assets {
            if
            let id = asset["id"] as? NSNumber,
            let url = asset["url"] as? NSString,
            let name = asset["name"] as? NSString {
            imageModels.append(ImageModel(
                id: id.intValue,
                url: serverURL + (url as String),
                name: name as String,
                isDownloaded: false,
                isDownloadedEvent: { [weak self] id in
                    guard let self else {return}
                    self.isDownloaded(id: id)
                }
            ))
            }
        }
        updateData?()
    }
    
    private func isDownloaded(id: Int){
        guard let index = imageModels.firstIndex(where: { model in
            if model.id == id { return true }
            return false
        })
        else {
            return
        }
        
        let model = imageModels[index]
        imageModels.remove(at: index)
        imageModels.insert(.init(
            id: model.id,
            url: model.url,
            name: model.name,
            isDownloaded: !model.isDownloaded,
            isDownloadedEvent: model.isDownloadedEvent),
            at: index)
        updateCellData?(index)
    }
    
}
