//
//  AddStoryViewController.swift
//  StoryMap
//
//  Created by Dory on 18/10/2021.
//

import Foundation
import UIKit

class AddStoryViewController: UIViewController {
    
    // MARK: - Constants
    
    let titleTextField = UITextField()
    let locationTextField = UITextField()
    let recordButton = UIButton(type: .system)
    let addPhotoButton = UIButton(type: .system)
    let confirmButton = UIButton(type: .system)
    
    var confirmButtonBottomConstraint: NSLayoutConstraint?
    var shouldAnimate = true
    
    let padding: CGFloat = 20
    let topOffset: CGFloat = 50
    let confirmButtonHeight: CGFloat = 44
    
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
        navigationController?.setNavigationBarHidden(false, animated: false)
        
        setupTitleTextField()
        setupLocationTextField()
        setupRecordButton()
        setupAddPhotoButton()
        setupConfirmButton()
    }
    
    private func setupTitleTextField() {
        titleTextField.placeholder = "Add Title"
        titleTextField.backgroundColor = .white
        titleTextField.borderStyle = .roundedRect
        titleTextField.translatesAutoresizingMaskIntoConstraints = false
        titleTextField.returnKeyType = .next
        titleTextField.delegate = self
        titleTextField.becomeFirstResponder()
        view.addSubview(titleTextField)
        
        NSLayoutConstraint.activate([
            titleTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: topOffset),
            titleTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            titleTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding)
        ])
    }
    
    private func setupLocationTextField() {
        locationTextField.placeholder = "Add Location"
        locationTextField.backgroundColor = .white
        locationTextField.borderStyle = .roundedRect
        locationTextField.delegate = self
        locationTextField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(locationTextField)
        
        NSLayoutConstraint.activate([
            locationTextField.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: padding),
            locationTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            locationTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding)
        ])
    }
    
    private func setupRecordButton() {
        recordButton.setImage(UIImage(named: "record"), for: .normal)
        view.addSubview(recordButton)
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            recordButton.topAnchor.constraint(equalTo: locationTextField.bottomAnchor, constant: topOffset),
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func setupAddPhotoButton() {
        addPhotoButton.setTitle("Add Photo", for: .normal)
        view.addSubview(addPhotoButton)
        addPhotoButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            addPhotoButton.topAnchor.constraint(equalTo: recordButton.bottomAnchor, constant: padding),
            addPhotoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func setupConfirmButton() {
        confirmButton.setTitle("Create Story", for: .normal)
        view.addSubview(confirmButton)
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.layer.borderWidth = 1
        confirmButton.layer.borderColor = UIColor.lightGray.cgColor
        confirmButton.layer.cornerRadius = 8
        
        confirmButtonBottomConstraint = confirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -padding)
        confirmButtonBottomConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            confirmButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            confirmButton.widthAnchor.constraint(equalTo: locationTextField.widthAnchor),
            confirmButton.heightAnchor.constraint(equalToConstant: confirmButtonHeight)
        ])
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
            confirmButtonBottomConstraint?.constant = -padding
            
            UIView.animate(withDuration: animationDuration) { [weak self] in
                self?.view.layoutIfNeeded()
            }
        }
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
}
