//
//  ImageListViewController.swift
//  NetworkStorage
//
//  Created by Максим Игоревич on 01.12.2024.
//

import UIKit
import Combine

class ImageListViewController: UIViewController {
    let serverURL = "http://164.90.163.215:1337"
    let token = "11c211d104fe7642083a90da69799cf055f1fe1836a211aca77c72e3e069e7fde735be9547f0917e1a1000efcb504e21f039d7ff55bf1afcb9e2dd56e4d6b5ddec3b199d12a2fac122e43b4dcba3fea66fe428e7c2ee9fc4f1deaa615fa5b6a68e2975cd2f99c65a9eda376e5b6a2a3aee1826ca4ce36d645b4f59f60cf5b74a"

    private var viewModel = ImageListViewModel()
    private var cancellables: Set<AnyCancellable> = []
    private var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        setupCollectionView()
//        bindViewModel()
//        viewModel.fetchImages()
        getImages()
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
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: view.frame.width / 2 - 16, height: view.frame.width / 2 - 16)
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: ImageCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        
        view.addSubview(collectionView)
    }

    private func bindViewModel() {
        viewModel.$images
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.collectionView.reloadData()
            }
            .store(in: &cancellables)
    }
}

extension ImageListViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.images.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCell.identifier, for: indexPath) as? ImageCell else {
            return UICollectionViewCell()
        }

        let imageModel = viewModel.images[indexPath.item]
        cell.configure(with: imageModel) { [weak self] in
            self?.viewModel.downloadImage(for: imageModel)
        }

        return cell
    }
}

extension ImageListViewController {
    
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
