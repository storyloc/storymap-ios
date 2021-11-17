//
//  MapStoryThumbnailCell.swift
//  StoryMap
//
//  Created by Dory on 10/11/2021.
//

import Foundation
import UIKit

class MapStoryThumbnailCell: UICollectionViewCell {
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
    
    public func select(_ selected: Bool) {
        if selected {
            imageView.layer.borderWidth = 3
            imageView.layer.borderColor = UIColor.systemBlue.cgColor
            isSelected = true
        } else {
            imageView.layer.borderColor = UIColor.clear.cgColor
            isSelected = false
        }
    }
    
    private func setupUI() {
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = StyleKit.metrics.cornerRadius
        imageView.contentMode = .scaleToFill
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(imageView.snp.height)
        }
    }
}
