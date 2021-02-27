//
//  OnboardingViewController.swift
//  UITabBrowser
//
//  Created by ogaoga on 2021/02/25.
//

import UIKit
import Combine

class OnboardingViewController: UIViewController {

    private var pages: [UIViewController] = []
    private var pageViewController: UIPageViewController! = nil
    private var cancellables: Set<AnyCancellable> = []

    @Published private var index = 0
    
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var skipButton: UIBarButtonItem!
    @IBOutlet weak var nextButton: UIButton!
    
    @IBAction func dismissOnboarding(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func next(_ sender: Any) {
        if index < pages.count - 1 {
            index += 1
            pageViewController.setViewControllers(
                [pages[index]], direction: .forward, animated: true, completion: nil
            )
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Disable to dismiss by swiping down
        isModalInPresentation = true
        
        // Make navigation bar transparent
        navigationController!.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController!.navigationBar.shadowImage = UIImage()
        
        // Page Control
        $index
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentPage, on: pageControl)
            .store(in: &cancellables)
        
        // Change title of skip button based on current page
        $index
            .receive(on: DispatchQueue.main)
            .map {
                $0 == self.pages.count - 1
                    ? NSLocalizedString("Done", comment: "bar button in onboarding")
                    : NSLocalizedString("Skip", comment: "bar button in onboarding")
            }
            .assign(to: \.title, on: skipButton)
            .store(in: &cancellables)
        
        // Next button
        $index
            .receive(on: DispatchQueue.main)
            .sink { index in
                let label = index < self.pages.count - 1
                    ? NSLocalizedString("Next", comment: "button in onboarding")
                    : NSLocalizedString("Let's Go", comment: "button in onboarding")
                self.nextButton.setTitle(label, for: .normal)
            }
            .store(in: &cancellables)
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        Settings.shared.onboarding = true
        Browsers.shared.initialize()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PageViewSegue" {
            // Set page view controller
            pageViewController = segue.destination as? UIPageViewController
            configurePageView()
        }
    }
    
    private func configurePageView() {
        // Delegate and data source
        pageViewController.delegate = self
        pageViewController.dataSource = self

        // Add view controllers
        let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
        pages = (1...5).map {
            storyboard.instantiateViewController(withIdentifier: "View\($0)")
        }
        pageViewController.setViewControllers(
            [pages[0]], direction: .forward, animated: true, completion: nil
        )
        // Set number of pages to page control
        pageControl.numberOfPages = pages.count
    }
}

extension OnboardingViewController : UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let index = pages.firstIndex(of: viewController) {
            return index > 0 ? pages[index - 1] : nil
        } else {
            return nil
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let index = pages.firstIndex(of: viewController) {
            return index < pages.count - 1 ? pages[index + 1] : nil
        } else {
            return nil
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let current = pageViewController.viewControllers?[0],
           let index = pages.firstIndex(of: current) {
            self.index = index
        }
    }
}
