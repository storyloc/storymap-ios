//
//  TagButton.swift
//  StoryMap
//
//  Created by Dory on 18/12/2021.
//

import UIKit

final class TagButton: UIButton {
	
	private var action: (() -> Void)?
	
	// MARK: - Initializers
	
	override init(frame: CGRect) {
		super.init(frame: .zero)
		setupUI()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: - Overrides
	
	override func layoutSubviews() {
		super.layoutSubviews()
		layer.cornerRadius = frame.height / 2
	}
	
	// MARK: - Public methods
	
	func update(with content: TagButton.Content) {
		setTitle(content.title, for: .normal)
		
		if let contentAction = content.action {
			action = contentAction
			isUserInteractionEnabled = true
		} else {
			isUserInteractionEnabled = false
		}
		
		isSelected = content.isSelected
		backgroundColor = content.isSelected ? .systemBlue : .white
		layer.borderColor = content.isSelected ? UIColor.white.cgColor : UIColor.systemBlue.cgColor
	}
	
	// MARK: - Private methods
	
	private func setupUI() {
		backgroundColor = .white
		
		setTitleColor(.white, for: .selected)
		setTitleColor(.systemBlue, for: .normal)
		
		layer.borderWidth = StyleKit.metrics.separator
		
		titleLabel?.font = UIFont.systemFont(ofSize: 13)
		
		contentEdgeInsets = UIEdgeInsets(
			top: StyleKit.metrics.padding.verySmall,
			left: StyleKit.metrics.padding.small,
			bottom: StyleKit.metrics.padding.verySmall,
			right: StyleKit.metrics.padding.small
		)
		
		addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
	}
	
	@objc private func buttonAction() {
		action?()
	}
}

// MARK: - Content
extension TagButton {
	struct Content {
		let title: String
		var isSelected: Bool
		let action: (() -> Void)?
	}
}
