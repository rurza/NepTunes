//
//  PageViewController.swift
//  NepTunes
//
//  Created by Adam Różyński on 17/07/2021.
//

import SwiftUI
import Cocoa

struct PageViewController<Page: View>: NSViewControllerRepresentable {
    
    var pages: [Page]
    @Binding var currentPage: Int
    
    func makeNSViewController(context: Context) -> NSPageController {
        let pageController = NSPageController(nibName: nil, bundle: nil)
        pageController.view = NSView()
        pageController.transitionStyle = .stackHistory
        pageController.delegate = context.coordinator
        return pageController
    }
    
    func updateNSViewController(_ nsViewController: NSPageController, context: Context) {
        nsViewController.arrangedObjects = context.coordinator.controllers
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSPageControllerDelegate {
        var parent: PageViewController
        var controllers = [NSViewController]()
        
        init(_ parent: PageViewController) {
            self.parent = parent
            controllers = parent.pages.map { NSHostingController(rootView: $0) }
        }
        
        func pageController(_ pageController: NSPageController, didTransitionTo object: Any) {
            guard let viewController = object as? NSViewController else { return }
            guard let index = controllers.firstIndex(of: viewController) else { return }
            parent.currentPage = index
        }
        
        func pageController(_ pageController: NSPageController, identifierFor object: Any) -> NSPageController.ObjectIdentifier {
            guard let viewController = object as? NSViewController else { return "" }
            guard let index = controllers.firstIndex(of: viewController) else { return "" }
            return "\(index)"
        }
        
        func pageController(_ pageController: NSPageController, viewControllerForIdentifier identifier: NSPageController.ObjectIdentifier) -> NSViewController {
            guard let index = Int(identifier) else { fatalError() }
            return controllers[index]
        }

    }
    
}

