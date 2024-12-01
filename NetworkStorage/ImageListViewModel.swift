//
//  ImageListViewModel.swift
//  NetworkStorage
//
//  Created by Максим Игоревич on 01.12.2024.
//

import Foundation
import Combine
import UIKit

class ImageListViewModel: ObservableObject {
    @Published var images: [ImageModel] = []
    private var cancellables: Set<AnyCancellable> = []

    func fetchImages() {
        // Имитация получения данных с сервера
        let mockData = [
            ImageModel(id: "1", url: "https://example.com/image1.jpg"),
            ImageModel(id: "2", url: "https://example.com/image2.jpg")
        ]
        self.images = mockData
    }

    func downloadImage(for image: ImageModel) {
        guard let url = URL(string: image.url) else { return }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map { UIImage(data: $0.data) }
            .replaceError(with: nil)
            .handleEvents(receiveSubscription: { _ in
                DispatchQueue.main.async {
                    image.progress = 0.0
                }
            })
            .sink(receiveValue: { [weak image] downloadedImage in
                DispatchQueue.main.async {
                    image?.localImage = downloadedImage
                    image?.isDownloaded = (downloadedImage != nil)
                }
            })
            .store(in: &cancellables)
    }
}
