//
//  ShareViewController.swift
//  RecipeShareExtension
//
//  Created by Codex on 2025-10-25.
//

import SwiftUI
import UIKit

final class ShareViewController: UIViewController {
//  private lazy var viewModel: ShareImportViewModel = {
//    ShareExtensionBootstrap.configure()
//    return ShareImportViewModel()
//  }()
//  private var hostingController: UIHostingController<ShareReviewView>?

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .systemBackground

    guard let context = extensionContext else { return }
//    let rootView = ShareReviewView(viewModel: viewModel, context: context)
//
//    let hostingController = UIHostingController(rootView: rootView)
//    hostingController.view.translatesAutoresizingMaskIntoConstraints = false
//
//    addChild(hostingController)
//    view.addSubview(hostingController.view)
//    NSLayoutConstraint.activate([
//      hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//      hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//      hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
//      hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//    ])
//    hostingController.didMove(toParent: self)
//    self.hostingController = hostingController
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if let context = extensionContext {
//      viewModel.loadInitialShare(from: context)
    }
  }

  override func viewWillTransition(
    to size: CGSize,
    with coordinator: UIViewControllerTransitionCoordinator
  ) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: { _ in
      self.preferredContentSize = size
    })
  }
}
