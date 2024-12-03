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
            ImageModel(id: "1", url: "http://164.90.163.215:1337/uploads/thumbnail_FD_046_BA_8_298_F_4946_9_C13_D3_CE_54_F1_E7_B3_8483506438.jpg"),
            ImageModel(id: "2", url: "http://164.90.163.215:1337/uploads/thumbnail_1746_E983_9793_492_A_86_A4_E3_CDB_7_A4_D911_6a52ef8620.jpg"),
            ImageModel(id: "3", url: "http://164.90.163.215:1337/uploads/thumbnail_FD_046_BA_8_298_F_4946_9_C13_D3_CE_54_F1_E7_B3_8483506438.jpg"),
            ImageModel(id: "4", url: "http://164.90.163.215:1337/uploads/thumbnail_1746_E983_9793_492_A_86_A4_E3_CDB_7_A4_D911_6a52ef8620.jpg"),
            ImageModel(id: "5", url: "http://164.90.163.215:1337/uploads/thumbnail_1746_E983_9793_492_A_86_A4_E3_CDB_7_A4_D911_6a52ef8620.jpg")
            
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
