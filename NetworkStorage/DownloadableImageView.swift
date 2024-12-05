//
//  DownloadableImageView.swift
//  NetworkStorage
//
//  Created by Максим Игоревич on 05.12.2024.
//

import UIKit

class DownloadableImageView: UIImageView, Downloadable {
    
    private var currentDownloadTask: URLSessionDataTask?
    
    private static let memoryCache = NSCache<NSString, UIImage>()
    private static let diskCacheURL: URL = {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0]
    }()
    
    public func loadImage(from url: URL, withOptions: [DownloadOptions]) {
        
        currentDownloadTask?.cancel()
        
        DispatchQueue.global().async {

            if let cachedImage = self.getCachedImage(for: url, options: withOptions) {
                DispatchQueue.main.async {
                    self.image = cachedImage
                }
                return
            }
            let session = URLSession(configuration: .default)
            self.currentDownloadTask = session.dataTask(with: url) { [weak self] data, response, error in
                guard let self = self, let data = data, error == nil,
                      var image = UIImage(data: data) else {
                    return
                }
            for option in withOptions {
                image = self.performOption(image, option: option, for: url)
            }
            DispatchQueue.main.async {
                    self.image = image
                }
        }
            self.currentDownloadTask?.resume()
        }
    }
    
    private func getCachedImage(for url: URL, options: [DownloadOptions]) -> UIImage?{
        for option in options {
            switch option {
            case .cache(let from):
                let key = cacheKey(for: url)
                switch from {
                    case .disk:
                        let diskURL = DownloadableImageView.diskCacheURL.appendingPathComponent(key)
                        if let diskImage = UIImage(contentsOfFile: diskURL.path) {
                            return diskImage
                        }
                    case .memory:
                        if let cachedImage = DownloadableImageView.memoryCache.object(forKey: key as NSString) {
                            return cachedImage
                        }
                }
            default: break
            }
        }
        return nil
    }
    
    
    private func performOption(_ image: UIImage, option: DownloadOptions, for url: URL) -> UIImage {
        switch option {
        case .circle:
            return image.makeCircular()
        case .resize(let size):
            return image.resized(to: size)
        case .cache(let from):
            let key = cacheKey(for: url)
            switch from{
                case .disk:
                    let diskURL = DownloadableImageView.diskCacheURL.appendingPathComponent(key)
                    if let data = image.pngData() {
                        try? data.write(to: diskURL)
                    }
                case .memory:
                    DownloadableImageView.memoryCache.setObject(image, forKey: key as NSString)
            }
            return image
        }
    }

    private func cacheKey(for url: URL) -> String {
        return "\(url.absoluteString)"
    }
    
    public func cancelDownload() {
        currentDownloadTask?.cancel()
        currentDownloadTask = nil
    }
}

enum DownloadOptions {
    enum From {
        case memory
        case disk
    }
    case circle
    case cache(From)
    case resize(CGSize)
}
protocol Downloadable {
    func loadImage(from url: URL, withOptions: [DownloadOptions])
}

