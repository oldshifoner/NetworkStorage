//
//  ViewController.swift
//  lesson_19
//
//  Created by Pavel Guzenko on 25.11.2024.
//

import UIKit

class TestViewController: UIViewController {
    let serverURL = "http://164.90.163.215:1337"
    let token = "11c211d104fe7642083a90da69799cf055f1fe1836a211aca77c72e3e069e7fde735be9547f0917e1a1000efcb504e21f039d7ff55bf1afcb9e2dd56e4d6b5ddec3b199d12a2fac122e43b4dcba3fea66fe428e7c2ee9fc4f1deaa615fa5b6a68e2975cd2f99c65a9eda376e5b6a2a3aee1826ca4ce36d645b4f59f60cf5b74a"

    override func viewDidLoad() {
        super.viewDidLoad()

        getImages()
    }
    
    func baseRequest() {
        let string = "https://fake-json-api.mock.beeceptor.com/users"
        guard let url = URL(string: string) else {
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data else {
                return
            }
            
            guard error == nil else {
                return
            }
            
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                return
            }

            struct BaseError: Codable {
                struct Error: Codable {
                    let code: String
                    let message: String
                }
                let error: Error
            }

            if (try? JSONDecoder().decode(BaseError.self, from: data)) != nil {
                return
            }
            
            switch response.statusCode {
            case 200...299:
                print("sucess response")
            case 400...499:
                print("client error")
            case 500...599:
                print("server error")
            default:
                print("unknown error")
            }

            do {
                let posts = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
                print(posts)
            } catch {
                print(error)
            }
        }
        task.resume()
        
        // URLSession
        // URLSessionTask
        //        URLSessionUploadTask
        //        URLSessionDownloadTask
        
        //        URLSessionConfiguration
        //        URLSessionDelegate
        
        
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataDontLoad
        config.timeoutIntervalForRequest = 8
        config.timeoutIntervalForResource = 10
        
        task.resume()
        task.cancel()
        task.suspend()
    }
    
    func getImages() {
        getAllAssets(from: serverURL, token: token) { result in
            switch result {
            case .success(let assets):
                print("Assets: \(assets)")
            case .failure(let error):
                print("Error fetching assets: \(error.localizedDescription)")
            }
        }
    }
    
    func uploadImage() {
        if let image = UIImage(named: "testImage") {
            uploadImage(to: serverURL, image: image, token: token) { result in
                switch result {
                case .success(let data):
                    print("Uploaded image data: \(data)")
                case .failure(let error):
                    print("Error uploading image: \(error.localizedDescription)")
                }
            }
        }

    }
    
    func downloadRequest() {
        let string = "https://fake-json-api.mock.beeceptor.com/file.zip"
        guard let url = URL(string: string) else {
            return
        }
        
        let task = URLSession.shared.downloadTask(with: url) { location, response, error in
            guard let location else {
                return
            }
            
            let fileManager = FileManager.default
            do {
                
                let newUrl = FileManager.default.temporaryDirectory.appendingPathComponent(location.lastPathComponent)
                try fileManager.moveItem(at: location, to: newUrl)
            } catch {
                print(error)
            }
        }
        task.delegate = self
        task.resume()
    }
    
    func upload() {
        let string = "https://fake-json-api.mock.beeceptor.com/users"
        guard let url = URL(string: string) else {
            return
        }
        
        var request = URLRequest(url: url)
        var headers: [String: String] = ["Content-Type": "application/json"]
        let token: String? = "adqweqweqweqwe"
        if let token {
            headers["Authorization"] = "Bearer \(token)"
        }
        request.allHTTPHeaderFields = headers
        
        let file = URL(fileURLWithPath: "path/file/example.png")
        let task  = URLSession.shared.uploadTask(with: request, fromFile: file) { data, response, error in
            
        }
        // task.delegate = self
        task.resume()
    }
    
    func websocket() {
        let string = "wss://fake-json-api.mock.beeceptor.com/socket"
        guard let url = URL(string: string) else {
            return
        }
        
        let task = URLSession.shared.webSocketTask(with: url)
        task.resume()
        
        let message = URLSessionWebSocketTask.Message.string("Hello, World!")
        task.send(message) { error in
            if let error {
                print("Error: \(error)")
            }
        }
        
        task.receive { result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print(text)
                case .data(let data):
                    print("receive data")
                }
            case .failure(let error):
                print("error \(error)")
            }
        }
    }
}

extension TestViewController: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let credentional = URLCredential(user: "qweqwe", password: "gwrgsdfg", persistence: .forSession)
        completionHandler(.useCredential, credentional)
    }
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        print("Download Progress: \(progress * 100)%")
    }
    
}

extension TestViewController {
    func uploadImage(to url: String, image: UIImage, token: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "ImageConversionError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to convert image to data"])))
            return
        }

        guard let uploadURL = URL(string: "\(url)/api/upload") else {
            completion(.failure(NSError(domain: "InvalidURLError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let imageName = UUID().uuidString
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(imageName).jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(.failure(NSError(domain: "ServerError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]], let firstFile = json.first {
                    completion(.success(firstFile))
                } else {
                    completion(.failure(NSError(domain: "ParsingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to parse server response"])))
                }
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
    }
    
    func getAllAssets(from url: String, token: String, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        guard let assetsURL = URL(string: "\(url)/api/upload/files") else {
            completion(.failure(NSError(domain: "InvalidURLError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: assetsURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(.failure(NSError(domain: "ServerError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    completion(.success(json))
                } else {
                    completion(.failure(NSError(domain: "ParsingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to parse server response"])))
                }
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
    }


}
