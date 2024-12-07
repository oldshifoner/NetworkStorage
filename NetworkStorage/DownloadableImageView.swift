//
//  DownloadableImageView.swift
//  NetworkStorage
//
//  Created by Максим Игоревич on 05.12.2024.
//

import UIKit
import Combine

class DownloadableImageView: UIImageView, Downloadable {
    
    private var totalDataCount: Int64 = 0
    private var receivedDataCount: Int64 = 0
    
    private var currentDownloadTask: URLSessionDataTask?
    
    private static let memoryCache = NSCache<NSString, UIImage>()
    private static let diskCacheURL: URL = {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0]
    }()
    
    public var onDownloadProgress: ((Double) -> Void)?
    
    public var imageLoadedPublisher = PassthroughSubject<UIImage, Error>()
    
    public func loadImage(from url: URL, withOptions: [DownloadOptions]) {
        
        currentDownloadTask?.cancel()

        DispatchQueue.global().async {

            if let cachedImage = self.getCachedImage(for: url, options: withOptions) {
                DispatchQueue.main.async {
                    self.image = cachedImage
                }
                return
            }
            let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
            self.currentDownloadTask = session.dataTask(with: url) { [weak self] data, response, error in
                guard let self = self, let data = data, error == nil,
                      var image = UIImage(data: data) else {
                    return
                }
            for option in withOptions {
                image = self.performOption(image, option: option, for: url)
            }
            DispatchQueue.main.async {
                //self.image = image
                self.imageLoadedPublisher.send(image)
            }
        }
            self.currentDownloadTask?.resume()
        }
    }
    
    public func getCachedImage(for url: URL, options: [DownloadOptions]) -> UIImage?{
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

extension DownloadableImageView: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        print("responce")
        totalDataCount = response.expectedContentLength // Общий размер данных
        receivedDataCount = 0                           // Сбрасываем полученный объем
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print("data")
        receivedDataCount += Int64(data.count)          // Увеличиваем полученный объем
        
        if totalDataCount > 0 {
            let progress = Double(receivedDataCount) / Double(totalDataCount)
            DispatchQueue.main.async {
                self.onDownloadProgress?(progress * 100) // Прогресс в процентах
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Download failed with error: \(error)")
        } else {
            print("Download completed")
        }
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

