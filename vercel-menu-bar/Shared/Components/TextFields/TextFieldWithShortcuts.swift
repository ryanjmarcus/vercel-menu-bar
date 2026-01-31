//
//  TextFieldWithShortcuts.swift
//  vercel-menu
//
//  Created by Ryan Marcus on 1/29/26.
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
    
    init(_ placeholder: String, text: Binding<String>, isSecure: Bool = false) {
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
    }
    
    func makeNSView(context: Context) -> NSTextField {
        let textField: NSTextField = isSecure
            ? SecureTextFieldWithShortcuts()
            : TextFieldWithShortcutsNS()
        
        textField.placeholderString = placeholder
        textField.stringValue = text
        textField.isBordered = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.focusRingType = .none
        textField.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        textField.textColor = NSColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)
        textField.delegate = context.coordinator
        
        return textField
    }
    
    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
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
            parent.text = textField.stringValue
        }
    }
}

// MARK: - Private NSTextField Subclasses

private class TextFieldWithShortcutsNS: NSTextField {
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
        editor.replaceCharacters(in: editor.selectedRange, with: string)
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
        return true
    }
}

private class SecureTextFieldWithShortcuts: NSSecureTextField {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.modifierFlags.contains(.command),
              let key = event.charactersIgnoringModifiers?.lowercased(),
              let editor = currentEditor() else {
            return super.performKeyEquivalent(with: event)
        }
        
        switch key {
        case "v":
            if let string = NSPasteboard.general.string(forType: .string) {
                editor.replaceCharacters(in: editor.selectedRange, with: string)
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
}
