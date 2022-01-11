//
//  StoryDetailViewController.swift
//  StoryMap
//
//  Created by Dory on 11/01/2022.
//

import UIKit
import Combine
import SnapKit

final class StoryDetailViewController: UIViewController {
	
	// MARK: Private properties
	
	private let viewModel: StoryDetailViewModel
	
	private let pageController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
	private let pageControl = UIPageControl()
	private var placeholder: UIStackView?
	
	private var pages = [UIViewController]() {
		didSet {
			pageControl.numberOfPages = pages.count
		}
	}
	
	private var subscriptions = Set<AnyCancellable>()
	
	private var pendingIndex: Int?
	private var selectedPageIndex: Int = 0 {
		didSet {
			pageControl.currentPage = selectedPageIndex
		}
	}
	
	// MARK: - Initializers
	
	init(viewModel: StoryDetailViewModel) {
		self.viewModel = viewModel
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: - Overrides
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		createPages(from: viewModel.storyPointViewModels)
		
		setupSubscriptions()
		setupUI()
		setupNavBar()
	}
	
	// MARK: - Private methods
	
	private func setupUI() {
		view.backgroundColor = .white
		
		view.addSubview(pageControl)
		
		setupPageControl()
		setupPageController()
	}
	
	private func setupPageController() {
		pageController.delegate = self
		pageController.dataSource = self
		
		addChild(pageController)
		view.addSubview(pageController.view)
		
		pageController.view.snp.makeConstraints { make in
			make.top.equalTo(pageControl.snp.bottom).offset(StyleKit.metrics.padding.small)
			make.leading.trailing.bottom.equalToSuperview()
		}
		
		if let initialPage = pages.first {
			pageController.setViewControllers([initialPage], direction: .forward, animated: true, completion: nil)
		}
		
		pageController.didMove(toParent: self)
	}
	
	private func setupPageControl() {
		pageControl.numberOfPages = pages.count
		pageControl.currentPage = 0
		
		pageControl.pageIndicatorTintColor = .lightGray
		pageControl.currentPageIndicatorTintColor = .systemBlue
		
		pageControl.snp.makeConstraints { make in
			make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(StyleKit.metrics.padding.small)
			make.centerX.equalToSuperview()
		}
	}
	
	private func setupNavBar() {
		title = viewModel.title
		
		let deleteButton = UIBarButtonItem(
			image: StyleKit.image.make(from: StyleKit.image.icons.delete, with: .alwaysTemplate),
			style: .plain,
			target: self,
			action: #selector(deleteTapped)
		)
		
		let addButton = UIBarButtonItem(
			image: StyleKit.image.make(from: StyleKit.image.icons.plus, with: .alwaysTemplate),
			style: .plain,
			target: self,
			action: #selector(addItemTapped)
		)
		
		navigationItem.rightBarButtonItems = [addButton, deleteButton]
	}
	
	private func setupSubscriptions() {
		viewModel.$storyPointViewModels
			.receive(on: DispatchQueue.main)
			.sink { [weak self] viewModels in
				self?.createPages(from: viewModels)
			}
			.store(in: &subscriptions)

		viewModel.storyPointAddedSubject
			.receive(on: DispatchQueue.main)
			.sink { [weak self] _ in
				guard let self = self else { return }
				self.pageController.setViewControllers([self.pages.last!], direction: .forward, animated: true, completion: nil)
				self.selectedPageIndex = self.pages.count - 1
			}
			.store(in: &subscriptions)
	}
	
	private func setupEmptyPlaceholder() {
		if placeholder != nil {
			placeholder?.removeFromSuperview()
			placeholder = nil
		}
		
		placeholder = UIStackView()
		
		view.insertSubview(placeholder!, at: 0)
		
		placeholder?.axis = .vertical
		placeholder?.alignment = .center
		placeholder?.distribution = .equalSpacing
		placeholder?.spacing = StyleKit.metrics.padding.common
		
		let button = UIButton()
		button.setImage(StyleKit.image.make(from: StyleKit.image.icons.plusCircle, with: .alwaysTemplate), for: .normal)
		button.tintColor = .systemBlue
		button.addTarget(self, action: #selector(addItemTapped), for: .touchUpInside)
		
		let label = UILabel()
		label.text = LocalizationKit.storyDetail.emptyPlaceholder
		label.textAlignment = .center
		label.font = .boldSystemFont(ofSize: 20)
		label.textColor = .gray
		label.numberOfLines = 0
		
		placeholder?.addArrangedSubview(label)
		placeholder?.addArrangedSubview(button)
		
		placeholder?.snp.makeConstraints { make in
			make.centerX.centerY.equalToSuperview()
			make.width.equalToSuperview().multipliedBy(0.8)
		}
	}
	
	private func createPages(from viewModels: [StoryPointDetailViewModel]) {
		pages.removeAll()
		
		for (i, vm) in viewModels.enumerated() {
			let vc = StoryPointDetailViewController(viewModel: vm)
			vc.index = i
			pages.append(vc)
		}
		
		if viewModels.isEmpty {
			setupEmptyPlaceholder()
		} else {
			placeholder?.removeFromSuperview()
			placeholder = nil
		}
	}
	
	// MARK: - Actions
	
	@objc func deleteTapped() {
		viewModel.deleteStory()
	}
	
	@objc func addItemTapped() {
		viewModel.addStoryPoint()
	}
}

// MARK: - UIPageViewControllerDelegate

extension StoryDetailViewController: UIPageViewControllerDelegate {
	func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
		if let page = pendingViewControllers.first as? StoryPointDetailViewController {
			pendingIndex = page.index
		}
	}
	
	func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
		if completed, let pendingIndex = pendingIndex {
			selectedPageIndex = pendingIndex
		}
	}
}

// MARK: - UIPageViewControllerDataSource

extension StoryDetailViewController: UIPageViewControllerDataSource {
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
		if let page = viewController as? StoryPointDetailViewController {
			return page.index > 0 ? pages[page.index - 1] : nil
		}
		
		return nil
	}
	
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
		if let page = viewController as? StoryPointDetailViewController {
			return page.index < pages.count - 1 ? pages[page.index + 1] : nil
		}
		
		return nil
	}
}
