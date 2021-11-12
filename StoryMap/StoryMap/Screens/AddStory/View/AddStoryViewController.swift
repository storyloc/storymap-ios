//
//  AddStoryViewController.swift
//  StoryMap
//
//  Created by Dory on 18/10/2021.
//

import Foundation
import UIKit
import SnapKit
import PhotosUI

class AddStoryViewController: UIViewController {
    
    // MARK: - Constants
    
    private var viewModel: AddStoryViewModelType
    
    private let titleStackView = UIStackView()
    private let titleTextFieldErrorLabel = UILabel()
    private let recordButton = UIButton(type: .system)
    private let photoStackView = UIStackView()
    private let pickedImageView = UIImageView()
    private let addPhotoButton = UIButton(type: .system)
    private let confirmButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)
    
    private var titleTextField = UITextField()
    private var locationTextField = UITextField()
    private var confirmButtonBottomConstraint: NSLayoutConstraint?
    
    init(viewModel: AddStoryViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        subscribeToKeyboardNotifications()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    // MARK: - Private methods
    
    private func setupUI() {
        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupCloseButton()
        setupTitleTextField()
        setupLocationTextField()
        setupRecordButton()
        setupAddPhotoButton()
        setupConfirmButton()
        
        updateUI()
    }
    
    private func updateUI() {
        titleTextField.placeholder = viewModel.titlePlaceholder
        titleTextField.attributedPlaceholder = NSAttributedString(string: viewModel.titlePlaceholder, attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        titleTextFieldErrorLabel.text = viewModel.titleError
        locationTextField.attributedPlaceholder = NSAttributedString(string: viewModel.locationPlaceholder, attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        recordButton.setImage(UIImage(named: viewModel.recordIcon), for: .normal)
        addPhotoButton.setTitle(viewModel.addPhotoTitle, for: .normal)
        confirmButton.setTitle(viewModel.confirmTitle, for: .normal)
        confirmButton.isEnabled = viewModel.confirmButtonEnabled
    }
    
    func updateTitleTextField() {
        titleTextFieldErrorLabel.alpha = viewModel.titleError.isEmpty ? 0 : 1
        titleTextFieldErrorLabel.text = viewModel.titleError
    }
    
    func setupCloseButton() {
        closeButton.setTitle(LocalizationKit.general.close, for: .normal)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        
        view.addSubview(closeButton)
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(StyleKit.metrics.padding.small)
            make.trailing.equalToSuperview().inset(StyleKit.metrics.padding.small)
        }
    }
    
    private func setupTitleTextField() {
        titleStackView.axis = .vertical
        titleStackView.distribution = .equalSpacing
        titleStackView.spacing = StyleKit.metrics.padding.verySmall
        
        titleStackView.addArrangedSubview(titleTextField)
        titleStackView.addArrangedSubview(titleTextFieldErrorLabel)
        
        titleTextFieldErrorLabel.textColor = .red
        titleTextFieldErrorLabel.textAlignment = .left
        titleTextFieldErrorLabel.font = StyleKit.font.caption2
        
        titleTextField.snp.makeConstraints { make in
            make.height.equalTo(StyleKit.metrics.textFieldHeight)
        }
        
        styleTextField(&titleTextField)
        titleTextField.delegate = self
        
        titleTextField.becomeFirstResponder()
        
        view.addSubview(titleStackView)
        
        titleStackView.snp.makeConstraints { make in
            make.top.equalTo(closeButton.snp.bottom).offset(StyleKit.metrics.padding.large)
            make.leading.trailing.equalToSuperview().inset(StyleKit.metrics.padding.common)
        }
    }
    
    private func setupLocationTextField() {
        locationTextField.backgroundColor = .white
        locationTextField.borderStyle = .roundedRect
        locationTextField.delegate = self
        
        styleTextField(&locationTextField)
        
        view.addSubview(locationTextField)
        
        locationTextField.snp.makeConstraints { make in
            make.top.equalTo(titleStackView.snp.bottom).offset(StyleKit.metrics.padding.small)
            make.leading.trailing.equalToSuperview().inset(StyleKit.metrics.padding.common)
            make.height.equalTo(StyleKit.metrics.textFieldHeight)
        }
    }
    
    private func styleTextField(_ textField: inout UITextField) {
        textField.borderStyle = .roundedRect
        textField.layer.masksToBounds = true
        textField.layer.borderWidth = StyleKit.metrics.separator
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.layer.cornerRadius = StyleKit.metrics.cornerRadius
        textField.backgroundColor = .white
        textField.tintColor = .lightGray
        textField.textColor = .systemBlue
        textField.returnKeyType = .next
        textField.delegate = self
    }
    
    private func setupRecordButton() {
        view.addSubview(recordButton)
        
        recordButton.snp.makeConstraints { make in
            make.top.equalTo(locationTextField.snp.bottom).offset(StyleKit.metrics.padding.large)
            make.centerX.equalToSuperview()
        }
    }
    
    private func setupAddPhotoButton() {
        photoStackView.axis = .vertical
        photoStackView.distribution = .equalSpacing
        photoStackView.spacing = StyleKit.metrics.padding.common
        
        photoStackView.addArrangedSubview(pickedImageView)
        photoStackView.addArrangedSubview(addPhotoButton)
        
        view.addSubview(photoStackView)
        
        addPhotoButton.addTarget(self, action: #selector(addPhotoTapped), for: .touchUpInside)
        
        photoStackView.snp.makeConstraints { make in
            make.top.equalTo(recordButton.snp.bottom).offset(StyleKit.metrics.padding.common)
            make.width.equalTo(locationTextField)
            make.centerX.equalToSuperview()
        }
    }
    
    private func updatePickedImageView(with image: UIImage) {
        pickedImageView.image = image
        pickedImageView.contentMode = .scaleAspectFit
        pickedImageView.snp.makeConstraints { make in
            make.width.height.lessThanOrEqualTo(StyleKit.metrics.imageWidth)
        }
        
        photoStackView.snp.removeConstraints()
        photoStackView.snp.makeConstraints { make in
            make.top.equalTo(recordButton.snp.bottom).offset(StyleKit.metrics.padding.common)
            make.width.equalTo(locationTextField)
            make.centerX.equalToSuperview()
        }
    }
    
    private func setupConfirmButton() {
        confirmButton.backgroundColor = .white
        
        view.addSubview(confirmButton)
        
        confirmButton.layer.borderWidth = 1
        confirmButton.layer.borderColor = UIColor.lightGray.cgColor
        confirmButton.layer.cornerRadius = 8
        
        confirmButton.addTarget(
            self,
            action: #selector(confirmTapped),
            for: .touchUpInside
        )
        
        confirmButtonBottomConstraint = confirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -StyleKit.metrics.padding.common)
        confirmButtonBottomConstraint?.isActive = true
        
        confirmButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(locationTextField)
            make.height.equalTo(StyleKit.metrics.buttonHeight)
        }
    }
    
    // MARK: - Actions
    
    @objc func addPhotoTapped() {
        hideKeyboard()
        viewModel.showPhotoAlert()
    }
    
    @objc func confirmTapped() {
        hideKeyboard()
        viewModel.confirm()
    }
    
    @objc func closeTapped() {
        hideKeyboard()
        viewModel.close()
    }
    
    // MARK: - Keyboard notifications
    
    private func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(notification:)),
            name: AddStoryViewController.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(notification:)),
            name: AddStoryViewController.keyboardWillHideNotification,
            object: nil
        )
    }
    
    private func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(
            self,
            name: AddStoryViewController.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: AddStoryViewController.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo,
           let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
           let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
            confirmButtonBottomConstraint?.constant = -keyboardSize.height
            
            UIView.animate(withDuration: animationDuration) { [weak self] in
                self?.view.layoutIfNeeded()
            }
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        if let userInfo = notification.userInfo,
           let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
            confirmButtonBottomConstraint?.constant = -StyleKit.metrics.padding.common
            
            UIView.animate(withDuration: animationDuration) { [weak self] in
                self?.view.layoutIfNeeded()
            }
        }
    }
    
    private func hideKeyboard() {
        locationTextField.resignFirstResponder()
        titleTextField.resignFirstResponder()
    }
}

// MARK: - UITextFieldDelegate

extension AddStoryViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == titleTextField {
            locationTextField.becomeFirstResponder()
            titleTextField.resignFirstResponder()
        } else if textField == locationTextField {
            locationTextField.resignFirstResponder()
        }
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == titleTextField {
            titleTextFieldErrorLabel.alpha = 0
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == titleTextField {
            viewModel.title = textField.text
            updateTitleTextField()
        }
    }
}

// MARK: - UIImagePickerControllerDelegate

extension AddStoryViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController (_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            return
        }
        
        
        dismiss(animated: true)
        viewModel.image = image.jpegData(compressionQuality: 1)
        updateUI()
        updatePickedImageView(with: image)
    }
}

// MARK: PHPickerViewControllerDelegate

extension AddStoryViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard let result = results.first else { return }
        let provider = result.itemProvider
        provider.loadObject(ofClass: UIImage.self) { image, error in
            if let image = image as? UIImage {
                DispatchQueue.main.async { [weak self] in
                    self?.dismiss(animated: true)
                    self?.viewModel.image = image.jpegData(compressionQuality: 1)
                    self?.updateUI()
                    self?.updatePickedImageView(with: image)
                }
            }
        }
    }
}
