//
//  ThumbnailCell.swift
//  StoryMap
//
//  Created by Dory on 10/11/2021.
//

import Foundation
import UIKit

class ThumbnailCell: UICollectionViewCell {
    private let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func update(with image: UIImage?) {
        imageView.image = image
    }
    
    private func setupUI() {
        imageView.contentMode = .scaleToFill
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(imageView.snp.height)
        }
    }
}
