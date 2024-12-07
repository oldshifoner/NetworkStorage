//
//  ImageListViewController.swift
//  NetworkStorage
//
//  Created by Максим Игоревич on 01.12.2024.
//

import UIKit
import Combine

class ImageListViewController: UIViewController {
    
    private let serverURL = "http://164.90.163.215:1337"
    private let token = "11c211d104fe7642083a90da69799cf055f1fe1836a211aca77c72e3e069e7fde735be9547f0917e1a1000efcb504e21f039d7ff55bf1afcb9e2dd56e4d6b5ddec3b199d12a2fac122e43b4dcba3fea66fe428e7c2ee9fc4f1deaa615fa5b6a68e2975cd2f99c65a9eda376e5b6a2a3aee1826ca4ce36d645b4f59f60cf5b74a"
    public static let memoryCache = NSCache<NSString, UIImage>()
    public static let diskCacheURL: URL = {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return paths[0]
    }()

    private var imageListViewModel = ImageListViewModel()
    private var cancellables: Set<AnyCancellable> = []
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSize(width: view.frame.width / 2 - 16, height: view.frame.width / 2 - 16)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.sectionInset = .init(top: 10, left: 10, bottom: 0, right: 10)
        
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = .black
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: String(describing: ImageCell.self))
        collectionView.dataSource = self
        collectionView.delegate = self
        
        return collectionView
    }()
    private lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.textColor = .white
            label.numberOfLines = 0
            label.backgroundColor = .clear
            label.numberOfLines = 0
            label.textAlignment = NSTextAlignment.center
            label.font = UIFont.boldSystemFont(ofSize: 16)
            label.text = "Список изображений"
            return label
    }()
    private lazy var nextUploadScreenButton: UIButton = {
            let button = UIButton()
            let imageView = UIImageView(image: UIImage(named: "nextScreen"))
            button.setImage(imageView.image, for: .normal)
            button.backgroundColor = .clear
            button.isEnabled = true
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(nextUploadScreenButtonTapped(_:)), for: .touchUpInside)
            return button
    }()
    @objc func nextUploadScreenButtonTapped(_ sender: UIButton) {
        self.navigationController?.pushViewController(ViewController(), animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getImages()
        setupUI()
        imageListViewModel.updateData = { [weak self] in
            guard let self else {return}
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
        imageListViewModel.updateCellData = { [weak self] index in
            guard let self else {return}
            DispatchQueue.main.async {
                //self.collectionView.reloadData()
                let indexPath = IndexPath(item: index, section: 0)
                self.collectionView.reloadItems(at: [indexPath])
            }
            
        }
    }
    private func getImages() {
        getAllAssets(from: serverURL, token: token) { result in
            switch result {
            case .success(let assets):
                self.imageListViewModel.initArrayImageModels(assets: assets, serverURL: self.serverURL)
            case .failure(let error):
                print("Error fetching assets: \(error.localizedDescription)")
            }
        }
    }
    
    private func setupUI() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.shadowColor = .clear
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        self.navigationItem.titleView = titleLabel
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: nextUploadScreenButton)
        NSLayoutConstraint.activate([
            nextUploadScreenButton.heightAnchor.constraint(equalToConstant: 24),
            nextUploadScreenButton.widthAnchor.constraint(equalToConstant: 24),
        ])
        view.backgroundColor = .black
        view.addSubview(collectionView)
    }

}

extension ImageListViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageListViewModel.imageModels.count
        
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ImageCell.self), for: indexPath) as? ImageCell else {
            return UICollectionViewCell()
        }
        print("reloadCurrentCell")
        let imageModel = imageListViewModel.imageModels[indexPath.row]
        cell.viewModel = imageModel
        cell.layer.cornerRadius = 20
        cell.layer.borderWidth = 1
        cell.layer.borderColor = CGColor.init(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0)
        cell.downloadImageClouser = { url in
            cell.imageView.loadImage(from: URL(string: url)!, withOptions: [.resize(cell.bounds.size), .cache(.memory)])
        }
        if imageModel.isDownloaded {
            cell.imageView.loadImage(from: URL(string: imageModel.url)!, withOptions: [.resize(cell.bounds.size), .cache(.memory)])
        }
        return cell
    }
}

extension ImageListViewController {
    
    private func uploadImage(to url: String, image: UIImage, token: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
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
    
    private func getAllAssets(from url: String, token: String, completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
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
