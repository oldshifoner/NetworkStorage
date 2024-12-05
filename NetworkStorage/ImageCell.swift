//
//  ImageCell.swift
//  NetworkStorage
//
//  Created by Максим Игоревич on 01.12.2024.
//

import UIKit
import Combine

class ImageCell: UICollectionViewCell {
    
    public var viewModel: ImageModel? {
        didSet{
            updateUI()
        }
    }
    
    public var downloadableImageView = DownloadableImageView()
    
    private func updateUI(){
        guard let viewModel else {return}
        progressLabel.text = viewModel.name
        downloadButton.setTitle(viewModel.url, for: .normal)
    }
    
    override func prepareForReuse() {
        
    }
    
    static let identifier = "ImageCell"
    private var cancellables: Set<AnyCancellable> = []
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        //iv.image = UIImage(named: "photo")
        iv.backgroundColor = .clear
        iv.layer.cornerRadius = 20
        iv.translatesAutoresizingMaskIntoConstraints = false
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
        
        imageView.heightAnchor.constraint(equalToConstant: contentView.frame.height).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: contentView.frame.width).isActive = true
        downloadButton.frame = CGRect(x: 10, y: contentView.frame.height / 2 - 15, width: contentView.frame.width - 20, height: 30)
        progressView.frame = CGRect(x: 10, y: contentView.frame.height - 30, width: contentView.frame.width - 20, height: 10)
        progressLabel.frame = CGRect(x: 10, y: contentView.frame.height - 20, width: contentView.frame.width - 20, height: 20)
    }
    
}
