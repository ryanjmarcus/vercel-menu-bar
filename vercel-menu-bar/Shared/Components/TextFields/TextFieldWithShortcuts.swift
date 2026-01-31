//
//  TextFieldWithShortcuts.swift
//  Vercel Menu Bar
//
//  Copyright (c) 2026 Ryan Marcus
//  Licensed under the MIT License
//
import SwiftUI
import AppKit

// MARK: - Text Field with Keyboard Shortcuts

/// A text field that properly handles keyboard shortcuts in menu bar apps.
/// Standard SwiftUI TextField/SecureField don't receive Command+V/C/X/A in popover windows.
struct TextFieldWithShortcuts: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let isSecure: Bool
    let shouldFocus: Bool
    
    init(_ placeholder: String, text: Binding<String>, isSecure: Bool = false, shouldFocus: Bool = false) {
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.shouldFocus = shouldFocus
    }
    
    func makeNSView(context: Context) -> NSTextField {
        let textField: NSTextField
        if isSecure {
            let secureField = SecureTextFieldWithShortcuts(coordinator: context.coordinator)
            secureField.actualValue = text // Initialize tracked value
            textField = secureField
        } else {
            textField = TextFieldWithShortcutsNS(coordinator: context.coordinator)
        }
        
        textField.placeholderString = placeholder
        textField.stringValue = text
        textField.isBordered = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.focusRingType = .none
        textField.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        textField.textColor = NSColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)
        textField.delegate = context.coordinator
        
        // Focus the field if requested (with delay to ensure window is ready)
        if shouldFocus {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                textField.window?.makeFirstResponder(textField)
            }
        }
        
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        if let secureField = nsView as? SecureTextFieldWithShortcuts {
            // For secure fields, update the tracked actual value
            if secureField.actualValue != text {
                secureField.actualValue = text
                secureField.stringValue = text
            }
        } else {
            // For regular fields, update normally
            if nsView.stringValue != text {
                nsView.stringValue = text
            }
        }
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextFieldDelegate {
        let parent: TextFieldWithShortcuts
        
        init(_ parent: TextFieldWithShortcuts) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ obj: Notification) {
            guard let textField = obj.object as? NSTextField else { return }
            // For secure fields, use the tracked actual value
            if let secureField = textField as? SecureTextFieldWithShortcuts {
                parent.text = secureField.actualValue
            } else {
                parent.text = textField.stringValue
            }
        }
    }
}

// MARK: - Private NSTextField Subclasses

private class TextFieldWithShortcutsNS: NSTextField {
    weak var coordinator: TextFieldWithShortcuts.Coordinator?
    
    init(coordinator: TextFieldWithShortcuts.Coordinator) {
        self.coordinator = coordinator
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.modifierFlags.contains(.command),
              let key = event.charactersIgnoringModifiers?.lowercased(),
              let editor = currentEditor() else {
            return super.performKeyEquivalent(with: event)
        }
        
        switch key {
        case "v": return paste(editor: editor)
        case "c": return copy(editor: editor)
        case "x": return cut(editor: editor)
        case "a": editor.selectAll(nil); return true
        default: return super.performKeyEquivalent(with: event)
        }
    }
    
    private func paste(editor: NSText) -> Bool {
        guard let string = NSPasteboard.general.string(forType: .string) else { return false }
        let range = editor.selectedRange
        editor.replaceCharacters(in: range, with: string)
        
        // Manually trigger the delegate to update the binding
        // For NSTextField, we can read stringValue directly
        if let coordinator = coordinator {
            coordinator.controlTextDidChange(
                Notification(name: NSControl.textDidChangeNotification, object: self)
            )
        }
        return true
    }
    
    private func copy(editor: NSText) -> Bool {
        let range = editor.selectedRange
        guard range.length > 0 else { return false }
        let text = (stringValue as NSString).substring(with: range)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        return true
    }
    
    private func cut(editor: NSText) -> Bool {
        guard copy(editor: editor) else { return false }
        editor.replaceCharacters(in: editor.selectedRange, with: "")
        
        // Manually trigger the delegate to update the binding
        if let coordinator = coordinator {
            coordinator.controlTextDidChange(
                Notification(name: NSControl.textDidChangeNotification, object: self)
            )
        }
        return true
    }
}

private class SecureTextFieldWithShortcuts: NSSecureTextField {
    weak var coordinator: TextFieldWithShortcuts.Coordinator?
    var actualValue: String = "" // Track actual content for secure field
    
    init(coordinator: TextFieldWithShortcuts.Coordinator) {
        self.coordinator = coordinator
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Override to track actual value separately from masked display
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.modifierFlags.contains(.command),
              let key = event.charactersIgnoringModifiers?.lowercased(),
              let editor = currentEditor() else {
            return super.performKeyEquivalent(with: event)
        }
        
        switch key {
        case "v":
            if let string = NSPasteboard.general.string(forType: .string) {
                let range = editor.selectedRange
                editor.replaceCharacters(in: range, with: string)
                
                // Update our tracked actual value
                let currentText = (actualValue as NSString).mutableCopy() as! NSMutableString
                currentText.replaceCharacters(in: range, with: string)
                actualValue = currentText as String
                
                // Update the binding with the actual value
                if let coordinator = coordinator {
                    coordinator.parent.text = actualValue
                }
                return true
            }
        case "a":
            editor.selectAll(nil)
            return true
        default:
            break
        }
        return super.performKeyEquivalent(with: event)
    }
    
    override func textDidChange(_ notification: Notification) {
        super.textDidChange(notification)
        // Try to get actual value from editor if available
        if let editor = currentEditor() as? NSTextView {
            actualValue = editor.string
            // Update binding
            if let coordinator = coordinator {
                coordinator.parent.text = actualValue
            }
        }
    }
}
