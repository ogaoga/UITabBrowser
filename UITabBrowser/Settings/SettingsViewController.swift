//
//  SettingsViewController.swift
//  UITabBrowser
//
//  Created by ogaoga on 2021/02/15.
//

import Combine
import SafariServices
import UIKit

class SettingsViewController: UITableViewController {

    // MARK: - Private properties

    private let viewModel = SettingsViewModel.shared
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Outlet

    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var searchEngineLabel: UILabel!
    @IBOutlet weak var versionLabel: UILabel!

    // MARK: - Action

    @IBAction func close(_ sender: Any) {
        dismiss(animated: true)
    }

    // MARK: - Lifecycle methods

    override func viewDidLoad() {
        super.viewDidLoad()

        // Show title of selected search engine
        viewModel.$searchEngine
            .receive(on: DispatchQueue.main)
            .map { $0.title }
            .sink(receiveValue: { [weak self] in
                self?.searchEngineLabel.text = $0
            })
            .store(in: &cancellables)

        // Version label
        #if DEBUG
            versionLabel.text = "v\(viewModel.appVersion) (\(viewModel.buildVersion))"
        #else
            versionLabel.text = "v\(viewModel.appVersion)"
        #endif
    }

    deinit {
        cancellables.forEach { $0.cancel() }
    }
}

// MARK: - Tap handling

extension SettingsViewController {

    enum CellID: String {
        case rateAndReview = "RateAndReviewCell"
        case feedbackForm = "FeedbackFormCell"
        case privacyPolicy = "PrivacyPolicyCell"
        case sourceCode = "SourceCodeCell"
        case twitter = "TwitterCell"
        case openSystemSettingsCell = "OpenSystemSettingsCell"
        case showOnboardingCell = "ShowOnboardingCell"
    }

    private func showFeedbackForm() {
        showSafariView(
            parent: self,
            url: URL(
                string:
                    "https://docs.google.com/forms/d/e/1FAIpQLSd7fy_px-gLDRdm-qdWr_aZjdnG2S4Mwv_BV-xM9AOgXsyYtQ/viewform?usp=sf_link"
            )!
        )
    }

    private func showReview() {
        let url = URL(string: "https://apps.apple.com/app/id1553379094?action=write-review")!
        UIApplication.shared.open(url, options: [:]) { result in
            if result {
                self.dismiss(animated: true)
            }
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let id = tableView.cellForRow(at: indexPath)?.reuseIdentifier,
            let cellId: CellID = CellID(rawValue: id)
        else {
            return
        }

        switch cellId {
        case .rateAndReview:
            showReview()
        case .feedbackForm:
            showFeedbackForm()
        case .privacyPolicy:
            showPrivacyPolicy(parent: self)
        case .sourceCode:
            dismiss(animated: true) {
                self.viewModel.showGitHub()
            }
        case .twitter:
            dismiss(animated: true) {
                self.viewModel.showTwitter()
            }
        case .openSystemSettingsCell:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }
        case .showOnboardingCell:
            performSegue(withIdentifier: "OnboardingSegue", sender: nil)
        }

        // Deselect cell
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
