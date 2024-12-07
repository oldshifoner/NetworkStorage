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
        progressLabel.isHidden = true
        progressView.isHidden = true
        if viewModel.isDownloaded {
            print("\(viewModel.id)" + " \(viewModel.isDownloaded)")
            downloadButton.isHidden = true
            progressLabel.isHidden = true
            progressView.isHidden = true
            var image: UIImage?
            DispatchQueue.global().async {
                //image = self.imageView.getCachedImage(for: URL(string: viewModel.url)!, options: [.cache(.disk)])
            }
            DispatchQueue.main.async {
                //self.imageView.image = image
                //self.contentView.addSubview(self.imageTest)
                // НЕ НАХОДИТ ЭЛЕМЕНТ В КЭШЕ ВОЗМОЖНО по причине релоада DownloadableImageView
            }
            
        }
    }
    
    override func prepareForReuse() {
        imageView.image = nil
        imageView.cancelDownload()
        progressView.progress = 0.0
        progressLabel.text = "0%"
        progressLabel.isHidden = true
        progressView.isHidden = true
        downloadButton.isHidden = false
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
        downloadButton.isHidden = true
        progressLabel.isHidden = false
        progressView.isHidden = false
        print(viewModel.name)
    }
    
    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = .red
        progress.progress = 0.0
        return progress
    }()
    
    private let progressLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .white
        label.text = "0%"
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        
        imageView.onDownloadProgress = { progress in
            self.progressView.progress = progress
            let formattedProgress = String(format: "%.0f", progress * 100)
            self.progressLabel.text = formattedProgress + "%"
        }
        
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
                    //self.imageView.image = image
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
        progressView.frame = CGRect(x: 10, y: contentView.frame.height - 90, width: contentView.frame.width - 20, height: 10)
        progressLabel.frame = CGRect(x: 10, y: contentView.frame.height - 80, width: contentView.frame.width - 20, height: 20)
    }
    
}
