//
//  TagFilterView.swift
//  StoryMap
//
//  Created by Dory on 18/12/2021.
//

import UIKit

final class TagFilterView: UIScrollView {
	private var buttons: [TagButton] = []
	private let stackView = UIStackView()
	private let contentView = UIView()
	
	override init(frame: CGRect) {
		super.init(frame: .zero)
		
		setupUI()
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func update(with tags: [TagButton.Content]) {
		tags.forEach { content in
			if let existingButton = buttons.first(where: { $0.titleLabel?.text == content.title } ) {
				existingButton.update(with: content)
			} else {
				let button = TagButton()
				button.update(with: content)
				buttons.append(button)
				stackView.addArrangedSubview(button)
			}
		}
	}
	
	private func setupUI() {
		showsHorizontalScrollIndicator = false
		
		addSubview(contentView)
		contentView.snp.makeConstraints { make in
			make.edges.equalToSuperview()
		}
		
		contentView.addSubview(stackView)
		
		setupStackView()
		
		contentSize = stackView.intrinsicContentSize
	}
	
	private func setupStackView() {
		stackView.axis = .horizontal
		stackView.distribution = .equalSpacing
		stackView.alignment = .center
		stackView.spacing = StyleKit.metrics.padding.small
		
		stackView.snp.makeConstraints { make in
			make.edges.equalToSuperview()
			make.height.equalToSuperview()
		}
	}
}
