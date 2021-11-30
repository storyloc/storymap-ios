//
//  MapStoryThumbnailCell.swift
//  StoryMap
//
//  Created by Dory on 10/11/2021.
//

import Foundation
import UIKit
import SwiftUI

class MapStoryThumbnailCell: UICollectionViewCell {
    private let imageView = UIImageView()
	private let playButton = UIButton()
	
	private var playAction: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
	
    public func update(with content: Content) {
		imageView.image = content.image
		
		playAction = content.playAction
		
		playButton.isHidden = playAction == nil
		let image = content.isPlaying ? StyleKit.image.icons.pause : StyleKit.image.icons.play
		playButton.setImage(StyleKit.image.make(from: image, with: .alwaysTemplate), for: .normal)
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
		contentView.addSubview(imageView)
		imageView.addSubview(playButton)
		
		setupImageView()
		setupButton()
    }
	
	private func setupImageView() {
		imageView.clipsToBounds = true
		imageView.layer.cornerRadius = StyleKit.metrics.cornerRadius
		imageView.isUserInteractionEnabled = true
		imageView.contentMode = .scaleToFill
		
		imageView.snp.makeConstraints { make in
			make.edges.equalToSuperview()
			make.width.equalTo(imageView.snp.height)
		}
	}
	
	private func setupButton() {
		playButton.isHidden = true
		// playButton.isSelected = false
		
//		playButton.setImage(
//			StyleKit.image.make(
//				from: StyleKit.image.icons.play,
//				with: .alwaysTemplate
//			),
//			for: .normal
//		)
//		playButton.setImage(
//			StyleKit.image.make(
//				from: StyleKit.image.icons.pause,
//				with: .alwaysTemplate
//			),
//			for: .selected
//		)
		playButton.addTarget(self, action: #selector(play), for: .touchUpInside)
		
		playButton.backgroundColor = .white.withAlphaComponent(0.9)
		
		playButton.imageEdgeInsets = UIEdgeInsets(
			top: StyleKit.metrics.padding.verySmall,
			left: StyleKit.metrics.padding.verySmall,
			bottom: StyleKit.metrics.padding.verySmall,
			right: StyleKit.metrics.padding.verySmall
		)
		
		playButton.snp.makeConstraints { make in
			make.top.trailing.equalToSuperview().inset(StyleKit.metrics.padding.small)
			make.size.equalTo(StyleKit.metrics.padding.medium)
		}
		
		playButton.clipsToBounds = true
		playButton.layer.borderColor = UIColor.systemBlue.cgColor
		playButton.layer.borderWidth = StyleKit.metrics.separator
		playButton.layer.cornerRadius = StyleKit.metrics.padding.medium / 2
	}
	
	@objc private func play() {
		// playButton.isSelected.toggle()
		playAction?()
	}
}

// MARK: - Content

extension MapStoryThumbnailCell {
	struct Content {
		let image: UIImage?
		var isPlaying: Bool
		let playAction: (() -> Void)?
	}
}
