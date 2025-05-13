//
//  IdentifyViewController.swift
//  UserpilotSample
//
//  Created by Motasem Hamed on 11/08/2024.
//

import Foundation
import UIKit

class IdentifyViewController: BaseViewController {

    // MARK: - IBOutlet

    @IBOutlet weak var labelAuthorizedUser: PaddedLabel! {
        didSet {
            labelAuthorizedUser.textInsets = UIEdgeInsets(top: 10, left: 24, bottom: 10, right: 24)
        }
    }
    @IBOutlet weak var textFieldUserID: UITextField! {
        didSet {
            textFieldUserID.delegate = self
        }
    }
    @IBOutlet weak var userPropertiesStackView: UIStackView!
    @IBOutlet weak var companyPropertiesStackView: UIStackView!
    @IBOutlet weak var anonymousButton: UIButton! {
        didSet {
            anonymousButton.layer.borderColor = UIColor.accent.cgColor
            anonymousButton.layer.borderWidth = 1
        }
    }

    internal var userPropertiesViews: [String: PropertyView] = [:]
    internal var companyPropertiesViews: [String: PropertyView] = [:]

    // MARK: - Override

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UserpilotManager.shared.screen("identify")
    }

    // MARK: - IBActions

    @IBAction func onIdentifyButtonClicked(_ sender: UIButton) {
        labelAuthorizedUser.text = "identifing".localized
        labelAuthorizedUser.isHidden = false
        identifyUser()
    }

    @IBAction func onBackButtonClicked(_ sender: UIButton) {
        close()
    }

    @IBAction func onAddUserProperty(_ sender: UIButton) {
        showAddUserPropertyDiaog()
    }

    @IBAction func onAddCompanyProperty(_ sender: UIButton) {
        showAddCompanyPropertyDialog()
    }

    @IBAction func onLogout(_ sender: UIButton) {
        FlowRoutingManager.shared.showAlertMessage("User logged out successfully!")
        UserpilotManager.shared.logout()
    }

    @IBAction func onAnonymous(_ sender: UIButton) {
        labelAuthorizedUser.text = "identifing".localized
        labelAuthorizedUser.isHidden = false
        UserpilotManager.shared.anonymous()
    }

}

// MARK: - UITextFieldDelegate

extension IdentifyViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Helper methods

extension IdentifyViewController {

    private func identifyUser() {
        guard let userID = textFieldUserID.text, !userID.isEmpty else {
            FlowRoutingManager.shared.showAlertMessage("Please insert User ID!")
            return
        }

        var userProperties: [String: Any] = [:]
        for (_, propertyView) in userPropertiesViews {
            let (key, value) = propertyView.getParams()
            userProperties[key] = value
        }

        var companyProperties: [String: Any] = [:]
        for (_, propertyView) in companyPropertiesViews {
            let (key, value) = propertyView.getParams()
            companyProperties[key] = value
        }

        var properties: [String: Any] = userProperties
        if !companyProperties.isEmpty {
            properties["company"] = companyProperties
        }

        UserpilotManager.shared.identify(userID: userID, properties: properties)
    }

    func onUserIdentified(_ user: [String: Any]) {
        labelAuthorizedUser.attributedText = user.formattedJSONLabel()
    }

}

// MARK: - Instance

extension IdentifyViewController {

    static func newInstance() -> IdentifyViewController {
        return IdentifyViewController()
    }

}
