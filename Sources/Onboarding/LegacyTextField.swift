//
//  LegacyTextField.swift
//  
//
//  Created by Adam Różyński on 21/07/2021.
//

import Foundation
import SwiftUI

struct LegacyTextField: NSViewRepresentable {
    
    @Binding public var isFirstResponder: Bool
    @Binding public var text: String

    public var configuration = { (view: NSTextField) in }

    public init(text: Binding<String>, isFirstResponder: Binding<Bool>, configuration: @escaping (NSTextField) -> () = { _ in }) {
        self.configuration = configuration
        self._text = text
        self._isFirstResponder = isFirstResponder
    }

    public func makeNSView(context: Context) -> NSTextField {
        let view = NSTextField()
        view.target = context.coordinator
        view.action = #selector(Coordinator.textViewDidChange)
        view.delegate = context.coordinator
        return view
    }

    public func updateNSView(_ nsView: NSTextField, context: Context) {
        nsView.stringValue = text
        switch isFirstResponder {
        case true: nsView.becomeFirstResponder()
        case false: nsView.resignFirstResponder()
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator($text, isFirstResponder: $isFirstResponder)
    }

    public class Coordinator: NSObject, NSTextFieldDelegate {
        var text: Binding<String>
        var isFirstResponder: Binding<Bool>

        init(_ text: Binding<String>, isFirstResponder: Binding<Bool>) {
            self.text = text
            self.isFirstResponder = isFirstResponder
        }

        @objc public func textViewDidChange(_ textField: NSTextField) {
            self.text.wrappedValue = textField.stringValue
        }

        public func textFieldDidBeginEditing(_ textField: NSTextField) {
            self.isFirstResponder.wrappedValue = true
        }

        public func textFieldDidEndEditing(_ textField: NSTextField) {
            self.isFirstResponder.wrappedValue = false
        }
    }
}
