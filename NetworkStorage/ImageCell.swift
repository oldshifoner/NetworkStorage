//
//  ImageCell.swift
//  NetworkStorage
//
//  Created by Максим Игоревич on 01.12.2024.
//

import UIKit

class ImageCell: UICollectionViewCell {
    private let serverURL = "http://164.90.163.215:1337"
    public var viewModel: ImageModel? {
        didSet{
            updateUI()
        }
    }
    
    public var imageView = DownloadableImageView()
    
    public var downloadImage: ((String) -> ())?
    
    private func updateUI(){
        guard let viewModel else {return}
//        imageView.loadImage(from: URL(string: serverURL + viewModel.url)!, withOptions: [.resize(contentView.bounds.size), .cache(.memory)])
    }
    
    override func prepareForReuse() {
        imageView.image = nil
    }
    
    static let identifier = "ImageCell"
    //private var cancellables: Set<AnyCancellable> = []
    
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
        downloadImage?(viewModel.url)
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
