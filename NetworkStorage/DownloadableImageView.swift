//
//  DownloadableImageView.swift
//  NetworkStorage
//
//  Created by Максим Игоревич on 05.12.2024.
//

import UIKit
import Combine



class DownloadableImageView: UIImageView, Downloadable {
    
    private var downloadedData = Data()
    
    private var currentURL: URL!
    private var currentOptions: [DownloadOptions] = []

    
    private var totalDataCount: Int64 = 0
    private var receivedDataCount: Int64 = 0
    
    private var currentDownloadTask: URLSessionDataTask?
    
    private static let memoryCache = NSCache<NSString, UIImage>()
    private static let diskCacheURL: URL = {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0]
    }()
    
    public var onDownloadProgress: ((Float) -> Void)?
    
    public var imageLoadedPublisher = PassthroughSubject<UIImage, Error>()
    
    public func loadImage(from url: URL, withOptions options: [DownloadOptions]) {
        currentDownloadTask?.cancel()
        currentURL = url
        currentOptions = options

        DispatchQueue.global().async {
            // Проверяем кэш
            if let cachedImage = self.getCachedImage(for: url, options: options) {
                DispatchQueue.main.async {
                    self.image = cachedImage
                }
                return
            }

            // Создаём URLSession с делегатом
            let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
            self.currentDownloadTask = session.dataTask(with: url) // Создаём задачу без замыкания
            self.currentDownloadTask?.resume()
        }
    }

    
    
    public func getCachedImage(for url: URL, options: [DownloadOptions]) -> UIImage? {
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
            switch from {
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
            print("Response received")
            totalDataCount = response.expectedContentLength // Общий размер данных
            receivedDataCount = 0
            downloadedData = Data()                         // Инициализируем хранилище данных
            completionHandler(.allow)
        }
        
        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            print("Receiving data")
            receivedDataCount += Int64(data.count)
            downloadedData.append(data)                    // Добавляем полученные данные
            
            if totalDataCount > 0 {
                let progress = Float(receivedDataCount) / Float(totalDataCount)
                DispatchQueue.main.async {
                    self.onDownloadProgress?(progress) // Прогресс в процентах
                }
            }
        }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Download failed with error: \(error)")
            DispatchQueue.main.async {
                self.imageLoadedPublisher.send(completion: .failure(error))
            }
        } else {
            print("Download completed")
            guard let image = UIImage(data: downloadedData) else {
                DispatchQueue.main.async {
                    self.imageLoadedPublisher.send(completion: .failure(NSError(domain: "Invalid image data", code: 0, userInfo: nil)))
                }
                return
            }

            DispatchQueue.global().async {
                var processedImage = image
                for option in self.currentOptions {
                    processedImage = self.performOption(processedImage, option: option, for: self.currentURL)
                }

                DispatchQueue.main.async {
                    //self.image = processedImage
                    self.imageLoadedPublisher.send(processedImage)
                }
            }
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

