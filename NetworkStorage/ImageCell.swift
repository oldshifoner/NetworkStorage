//
//  ImageCell.swift
//  NetworkStorage
//
//  Created by Максим Игоревич on 01.12.2024.
//

import UIKit
import Combine

class ImageCell: UICollectionViewCell {
    static let identifier = "ImageCell"
    private var cancellables: Set<AnyCancellable> = []
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.backgroundColor = .lightGray
        return iv
    }()
    
    private let downloadButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Скачать", for: .normal)
        button.tintColor = .white
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        return button
    }()
    
    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progress = 0.0
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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(imageView)
        contentView.addSubview(downloadButton)
        contentView.addSubview(progressView)
        contentView.addSubview(progressLabel)
        
        imageView.frame = contentView.bounds
        downloadButton.frame = CGRect(x: 10, y: contentView.frame.height / 2 - 15, width: contentView.frame.width - 20, height: 30)
        progressView.frame = CGRect(x: 10, y: contentView.frame.height - 30, width: contentView.frame.width - 20, height: 10)
        progressLabel.frame = CGRect(x: 10, y: contentView.frame.height - 20, width: contentView.frame.width - 20, height: 20)
    }
    
    func configure(with model: ImageModel, downloadAction: @escaping () -> Void) {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
        if model.isDownloaded {
            imageView.image = model.localImage
            downloadButton.isHidden = true
            progressView.isHidden = true
            progressLabel.isHidden = true
        } else {
            imageView.image = nil
            downloadButton.isHidden = false
            progressView.isHidden = false
            progressLabel.isHidden = false
            progressView.progress = model.progress
            progressLabel.text = "\(Int(model.progress * 100))%"
        }
        
        downloadButton.addAction(UIAction(handler: { _ in
            downloadAction()
        }), for: .touchUpInside)
        
        model.$progress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.progressView.progress = progress
                self?.progressLabel.text = "\(Int(progress * 100))%"
            }
            .store(in: &cancellables)
        
        model.$localImage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                self?.imageView.image = image
                self?.downloadButton.isHidden = true
                self?.progressView.isHidden = true
                self?.progressLabel.isHidden = true
            }
            .store(in: &cancellables)
    }
}
