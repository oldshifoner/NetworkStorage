//
//  ImageCell.swift
//  NetworkStorage
//
//  Created by Максим Игоревич on 01.12.2024.
//

import UIKit
import Combine

class ImageCell: UICollectionViewCell {
   
    private var cancellables = Set<AnyCancellable>()
    
    public var viewModel: ImageModel? {
        didSet{
            updateUI()
        }
    }
    
    public var imageView = DownloadableImageView()
    
    public var downloadImageClouser: ((String) -> ())?
    
    private func updateUI(){
        guard let viewModel else {return}
        if viewModel.isDownloaded {
            print("\(viewModel.id)" + " \(viewModel.isDownloaded)")
            var image: UIImage?
            DispatchQueue.global().async {
                //image = self.imageView.getCachedImage(for: URL(string: viewModel.url)!, options: [.cache(.disk)])
            }
            DispatchQueue.main.async {
                //self.imageView.image = image
                //self.contentView.addSubview(self.imageTest)
                // НЕ НАХОДИТ ЭЛЕМЕНТ В КЭШЕ ВОЗМОЖНО по причине релоада DownloadableImageView
            }
            imageView.onDownloadProgress = { progress in
                print("Download progress: \(progress)%")
            }
        }
    }
    
    private lazy var imageTest: UIImageView = {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.backgroundColor = .clear
            imageView.translatesAutoresizingMaskIntoConstraints = false
            return imageView
        }()
    
    override func prepareForReuse() {
        imageView.image = nil
        imageView.cancelDownload()
    }
    
    private lazy var downloadButton: UIButton = {
        let button = UIButton()
        let imageView = UIImage(named: "cloud")
        button.setBackgroundImage(imageView, for: .normal)
        button.isEnabled = true
        button.addTarget(self, action: #selector(downloadImage(_:)), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.clipsToBounds = true
        
        return button
    }()
    
    @objc func downloadImage(_ sender: UIButton) {
        guard let viewModel = self.viewModel else {return}
        downloadImageClouser?(viewModel.url)
        print(viewModel.name)
    }
    
    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progress = 0.5
        return progress
    }()
    
    private let progressLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .darkGray
        label.text = "0%"
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        
        imageView.imageLoadedPublisher
            .receive(on: DispatchQueue.main) // Обрабатываем события на главном потоке
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("Image loading completed.")
                    case .failure(let error):
                        print("Failed to load image: \(error)")
    
                    }
                },
                receiveValue: { image in
                    print("Image downloaded successfully!")
                    self.imageView.image = image
                    guard let viewModel = self.viewModel else {return}
                    viewModel.isDownloadedEvent?(viewModel.id)
                }
                
            )
            .store(in: &cancellables)

        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        imageView.frame = contentView.bounds
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 20
        contentView.addSubview(imageView)
        contentView.addSubview(downloadButton)
        contentView.addSubview(progressView)
        contentView.addSubview(progressLabel)
        
        downloadButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
        downloadButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        downloadButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        downloadButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
        
        //imageView.heightAnchor.constraint(equalToConstant: contentView.frame.height).isActive = true
        //imageView.widthAnchor.constraint(equalToConstant: contentView.frame.width).isActive = true
        //downloadButton.frame = CGRect(x: contentView.frame.width / 2, y: contentView.frame.height / 2, width: 72, height: 49)
        progressView.frame = CGRect(x: 10, y: contentView.frame.height - 30, width: contentView.frame.width - 20, height: 10)
        progressLabel.frame = CGRect(x: 10, y: contentView.frame.height - 20, width: contentView.frame.width - 20, height: 20)
    }
    
}
