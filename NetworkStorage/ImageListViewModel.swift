//
//  ImageListViewModel.swift
//  NetworkStorage
//
//  Created by Максим Игоревич on 01.12.2024.
//

import Foundation

class ImageListViewModel {
    
    public lazy var imageModels: [ImageModel] = []
    
    public var updateData: (() -> ())?
    
//    private func convertNSCStringToString(value: NSString?) -> String {
//        guard let value else {return ""}
//        let nsString = NSString(cString: value, encoding: String.Encoding.utf8.rawValue)
//        if let swiftString = nsString as String? {
//            return swiftString
//        }
//        return ""
//    }
    
    public func initArrayImageModels(assets: [[String : Any]]){
        for asset in assets {
            if
            let id = asset["id"] as? NSNumber,
            let url = asset["url"] as? NSString,
            let name = asset["name"] as? NSString {
            imageModels.append(ImageModel(
                id: id.intValue,
                url: url as String,
                name: name as String))
            }
        }
        updateData?()
    }
}
