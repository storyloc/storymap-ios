//
//  StoryListCell.swift
//  StoryMap
//
//  Created by Dory on 18/12/2021.
//

import UIKit
import SwiftUI

final class StoryListCell: UITableViewCell {
	
	// MARK: - Public properties
	
	static let reuseIdentifier = "StoryListCell"
	static let estimatedHeight: CGFloat = 50 + 2 * StyleKit.metrics.padding.common
	
	// MARK: - Private properties
	
	private let thumbnailImageView = UIImageView()
	private let titleLabel = UILabel()
	private let tagView = TagFilterView()
	
	// MARK: - Initializers
	
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: .default, reuseIdentifier: StoryListCell.reuseIdentifier)
		setupUI()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: - Public methods
	
	func update(with content: Content) {
		thumbnailImageView.image = content.image
		titleLabel.text = content.title
		tagView.update(with: content.tagContent)
	}
	
	// MARK: - Private methods
	
	private func setupUI() {
		contentView.addSubview(thumbnailImageView)
		contentView.addSubview(titleLabel)
		contentView.addSubview(tagView)
		
		setupImageView()
		setupTitleLabel()
		setupTagView()
	}
	
	private func setupImageView() {
		thumbnailImageView.contentMode = .scaleAspectFill
		thumbnailImageView.clipsToBounds = true
		thumbnailImageView.layer.cornerRadius = StyleKit.metrics.cornerRadius
		
		thumbnailImageView.snp.makeConstraints { make in
			make.top.leading.equalToSuperview().offset(StyleKit.metrics.padding.common)
			make.bottom.equalToSuperview().inset(StyleKit.metrics.padding.common)
			make.size.equalTo(50)
		}
	}
	
	private func setupTitleLabel() {
		titleLabel.numberOfLines = 1
		titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
		titleLabel.snp.makeConstraints { make in
			make.leading.equalTo(thumbnailImageView.snp.trailing).offset(StyleKit.metrics.padding.common)
			make.top.equalTo(thumbnailImageView)
		}
	}
	
	private func setupTagView() {
		tagView.snp.makeConstraints { make in
			make.top.equalTo(titleLabel.snp.bottom).offset(StyleKit.metrics.padding.small)
			make.leading.equalTo(titleLabel)
			make.trailing.equalToSuperview().inset(StyleKit.metrics.padding.common)
			make.height.equalTo(StyleKit.metrics.padding.medium)
		}
	}
}

extension StoryListCell {
	struct Content {
		let title: String
		let image: UIImage?
		let tagContent: [TagButton.Content]
	}
}
