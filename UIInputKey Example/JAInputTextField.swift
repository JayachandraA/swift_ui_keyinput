//
//  JAInputTextField.swift
//  UIInputKey Example
//
//  Created by Jayachandra Agraharam on 10/05/22.
//

import UIKit

//Referance - https://developer.apple.com/library/archive/samplecode/SimpleTextInput/History/History.html#//apple_ref/doc/uid/DTS40010633-RevisionHistory-DontLinkElementID_1
class JAInputTextField: UIView, UITextInput {
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        text.draw(in: rect)
    }
    
    open override var inputAccessoryView: UIView? {
        get {
            return self.getToolbarWithDone()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame : frame)
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    var text: NSMutableString = ""
    var textContainer = JATextContainer()
    
    // MARK: - UITextInput - Replacing and Returning Text
    /**
     UITextInput protocol required method.
     Called by text system to get the string for a given range in the text storage.
     */
    public func text(in range: UITextRange) -> String? {
        
        if let r = range as? JAIndexedRange {
            return self.text.substring(with: r.range)
        }
        return nil
    }
    
    /**
     UITextInput protocol required method.
     Called by text system to replace the given text storage range with new text.
     */
    public func replace(_ range: UITextRange, withText text: String) {
        
        var selectedNSRange = textContainer.selectedTextRange
        // Determine if replaced range intersects current selection range
        // and update selection range if so.
        if let indexedRange = range as? JAIndexedRange {
            if (indexedRange.range.location + indexedRange.range.length) <= (selectedNSRange.location ) {
                // This is the easy case.
                selectedNSRange.location -= indexedRange.range.length - text.count
            }else {
                // Need to also deal with overlapping ranges.  Not addressed
                // in this simplified sample.
            }
            
            // Now replace characters in text storage
            self.text.replaceCharacters(in: indexedRange.range, with: text)
            
            // Update underlying APLSimpleCoreTextView
            self.textContainer.contentText = self.text
            self.textContainer.selectedTextRange = selectedNSRange
            setNeedsDisplay()
        }
    }
    
    // MARK: - UITextInput - Working with Marked and Selected Text
    /**
     UITextInput selectedTextRange property accessor overrides (access/update underlaying APLSimpleCoreTextView)
     */
    public var selectedTextRange: UITextRange? {
        get {
            
            return JAIndexedRange(range: textContainer.selectedTextRange)
        }
        
        set {
            
            if let r = newValue as? JAIndexedRange {
                textContainer.selectedTextRange = r.range
            }
        }
    }
    
    /**
     UITextInput markedTextRange property accessor overrides (access/update underlaying APLSimpleCoreTextView).
     */
    public var markedTextRange: UITextRange? {
        get {
            
            /*
             Return nil if there is no marked text.
             */
            let markedTextRange = textContainer.markedTextRange
            if markedTextRange.length == 0 {
                return nil
            }
            return JAIndexedRange(range: markedTextRange)
        }
    }
    
    public var markedTextStyle: [NSAttributedString.Key : Any]?

    public func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        
        var selectedNSRange = textContainer.selectedTextRange
        var markedTextRange = textContainer.markedTextRange
        if markedTextRange.location != NSNotFound {
            var lMarkedText = ""
            if markedText != nil {
                lMarkedText = markedText!
            }
            // Replace characters in text storage and update markedText range length.
            self.text.replaceCharacters(in: markedTextRange, with: lMarkedText)
            markedTextRange.length = lMarkedText.count
        }else if selectedNSRange.length > 0 {
            // There currently isn't a marked text range, but there is a selected range,
            // so replace text storage at selected range and update markedTextRange.
            if let lMarkedText = markedText {
                self.text.replaceCharacters(in: selectedNSRange, with: lMarkedText)
                markedTextRange.location = selectedNSRange.location;
                markedTextRange.length = lMarkedText.count;
            }
        }else {
            // There currently isn't marked or selected text ranges, so just insert
            // given text into storage and update markedTextRange.
            if let lMarkedText = markedText {
                self.text.insert(lMarkedText, at: selectedNSRange.location)
                markedTextRange.location = selectedNSRange.location;
                markedTextRange.length = lMarkedText.count;
            }
        }
        
        // Updated selected text range and underlying RMtextContainer.
        if let lMarkedText = markedText {
            selectedNSRange = NSRange(location: selectedRange.location + lMarkedText.count, length: selectedRange.length)

            textContainer.contentText = self.text
            textContainer.markedTextRange = markedTextRange
            textContainer.selectedTextRange = selectedNSRange
        }
        setNeedsDisplay()
    }
    
    /**
     UITextInput protocol required method.
     Unmark the currently marked text.
     */
    public func unmarkText() {
        
        var markedTextRange = textContainer.markedTextRange
        if markedTextRange.location == NSNotFound {
            return
        }
        // Unmark the underlying RMtextContainer.markedTextRange.
        markedTextRange.location = NSNotFound
        textContainer.markedTextRange = markedTextRange
    }
    
    
    //MARK: - UITextInput - Computing Text Ranges and Text Positions
    // UITextInput beginningOfDocument property accessor override.
    public var beginningOfDocument: UITextPosition {
        get {
            
            // For this sample, the document always starts at index 0 and is the full length of the text storage.
            return JAIndexedPosition(index: 0)
        }
    }
    
    // UITextInput endOfDocument property accessor override.
    public var endOfDocument: UITextPosition {
        get {
            
            // For this sample, the document always starts at index 0 and is the full length of the text storage.
            return JAIndexedPosition(index: self.text.length)
        }
    }
    
    /*
     UITextInput protocol required method.
     Return the range between two text positions using our implementation of UITextRange.
     */
    public func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
        
        // Generate IndexedPosition instances that wrap the to and from ranges.
        if let fromIndexedPosition = fromPosition as? JAIndexedPosition , let toIndexedPosition = toPosition as? JAIndexedPosition {
            let range = NSRange(location: Int(min(fromIndexedPosition.index, toIndexedPosition.index)), length: Int(abs(toIndexedPosition.index - fromIndexedPosition.index)))
            return JAIndexedRange(range: range)
        }
        return nil
    }
    
    
    /**
     UITextInput protocol required method.
     Returns the text position at a given offset from another text position using our implementation of UITextPosition.
     */
    public func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
        
        // Generate IndexedPosition instance, and increment index by offset.
        if let indexedPosition = position as? JAIndexedPosition {
            let end = indexedPosition.index + offset
            // Verify position is valid in document.
            if end > text.length || end < 0 {
                return nil
            }
            return JAIndexedPosition(index: end)
        }
        return nil
    }
    
    /**
     UITextInput protocol required method.
     Returns the text position at a given offset in a specified direction from another text position using our implementation of UITextPosition.
     */
    public func position(from position: UITextPosition, in direction: UITextLayoutDirection, offset: Int) -> UITextPosition? {
        
        // Note that this sample assumes left-to-right text direction.
        if let indexedPosition = position as? JAIndexedPosition {
            var newPosition = indexedPosition.index
            switch direction {
            case .right:
                newPosition += offset
            case .left:
                newPosition -= offset
            default:
                // This does not support vertical text directions.
                break
            }
            
            // Verify new position valid in document.
            if newPosition < 0 {
                newPosition = 0
            }
            if newPosition > self.text.length {
                newPosition = self.text.length
            }
            
            return JAIndexedPosition(index: newPosition)
        }
        return nil
    }
    
    //MARK: - UITextInput - Evaluating Text Positions
    /**
     UITextInput protocol required method.
     Return how one text position compares to another text position.
     */
    public func compare(_ position: UITextPosition, to other: UITextPosition) -> ComparisonResult {
        
        if let indexedPosition = position as? JAIndexedPosition, let otherIndexedPosition = other as? JAIndexedPosition {
            // For this sample, simply compare position index values.
            if indexedPosition.index < otherIndexedPosition.index {
                return .orderedAscending
            }
            if indexedPosition.index > otherIndexedPosition.index {
                return .orderedDescending
            }
        }
        return .orderedSame
    }
    
    /**
     UITextInput protocol required method.
     Return the number of visible characters between one text position and another text position.
     */
    public func offset(from: UITextPosition, to toPosition: UITextPosition) -> Int {
        
        if let fromIndexedPosition = from as? JAIndexedPosition, let toIndexedPosition = toPosition as? JAIndexedPosition{
            return toIndexedPosition.index - fromIndexedPosition.index
        }
        return .max
    }
    
    public var inputDelegate: UITextInputDelegate?
    
    public lazy var tokenizer: UITextInputTokenizer = UITextInputStringTokenizer(textInput: self)
    
    // MARK: - UITextInput - Text Layout, writing direction and position related methods
    /**
     UITextInput protocol method.
     Return the text position that is at the farthest extent in a given layout direction within a range of text.
     */
    public func position(within range: UITextRange, farthestIn direction: UITextLayoutDirection) -> UITextPosition? {
        
        // Note that this sample assumes left-to-right text direction.
        if let indexedRange = range as? JAIndexedRange {
            let position: Int
            /*
             For this sample, we just return the extent of the given range if the given direction is "forward" in a left-to-right context (UITextLayoutDirectionRight or UITextLayoutDirectionDown), otherwise we return just the range position.
             */
            switch direction {
            case .up, .left:
                position = indexedRange.range.location
                // Return text position using our UITextPosition implementation.
                // Note that position is not currently checked against document range.
                return JAIndexedPosition(index: position)
            case .right, .down:
                position = indexedRange.range.location + indexedRange.range.length
                // Return text position using our UITextPosition implementation.
                // Note that position is not currently checked against document range.
                return JAIndexedPosition(index: position)
            default:
                break
            }
        }
        return nil
    }
    
    /**
     UITextInput protocol required method.
     Return a text range from a given text position to its farthest extent in a certain direction of layout.
     */
    public func characterRange(byExtending position: UITextPosition, in direction: UITextLayoutDirection) -> UITextRange? {
        
        // Note that this sample assumes left-to-right text direction.
        if let pos = position as? JAIndexedPosition {
            var result: NSRange

            switch direction {
            case .up, .left:
                result = NSRange(location: pos.index - 1, length: 1)
                // Return range using our UITextRange implementation.
                // Note that range is not currently checked against document range.
                return JAIndexedRange(range: result)
            case .right, .down:
                result = NSRange(location: pos.index, length: 1)
                // Return range using our UITextRange implementation.
                // Note that range is not currently checked against document range.
                return JAIndexedRange(range: result)
            default:
                break
            }
        }
        return nil
    }
    
    public func baseWritingDirection(for position: UITextPosition, in direction: UITextStorageDirection) -> NSWritingDirection {
        
        return .leftToRight
    }
    
    public func setBaseWritingDirection(_ writingDirection: NSWritingDirection, for range: UITextRange) {
        
    }
    
    public func firstRect(for range: UITextRange) -> CGRect {
        
        return self.bounds
    }
    
    public func caretRect(for position: UITextPosition) -> CGRect {
        
        return CGRect(x: 0, y: 0, width: 10, height: 30)
    }
    
    public func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        
        return []
    }
    
    public func selectionRects(for range: UITextRange) -> [Any] {
        
        return []
    }
    
    public func closestPosition(to point: CGPoint) -> UITextPosition? {
        
        return nil
    }
    
    public func closestPosition(to point: CGPoint, within range: UITextRange) -> UITextPosition? {
        
        return nil
    }
    
    public func characterRange(at point: CGPoint) -> UITextRange? {
        
        return nil
    }
    /**
     UIKeyInput protocol required method.
     A Boolean value that indicates whether the text-entry objects have any text.
     */
    public var hasText: Bool {
        
        return self.text.length != 0
    }
    
    /**
     UIKeyInput protocol required method.
     Insert a character into the displayed text. Called by the text system when the user has entered simple text.
     */
    public func insertText(_ text: String) {
        
        var selectedNSRange = textContainer.selectedTextRange
        var markedTextRange = textContainer.markedTextRange
        /*
         While this sample does notzz provide a way for the user to create marked or selected text, the following code still checks for these ranges and acts accordingly.
         */
        if markedTextRange.location != NSNotFound {
            // There is marked text -- replace marked text with user-entered text.
            self.text.replaceCharacters(in: markedTextRange, with: text)
            selectedNSRange.location = markedTextRange.location + text.count
            selectedNSRange.length = 0
            markedTextRange = NSRange(location: NSNotFound, length: 0)
        } else if selectedNSRange.length > 0 {
            // Replace selected text with user-entered text.
            self.text.replaceCharacters(in: selectedNSRange, with: text)
            selectedNSRange.length = 0
            selectedNSRange.location += text.count
        } else {
            // Insert user-entered text at current insertion point.
            self.text.insert(text, at: selectedNSRange.location)
            selectedNSRange.location += text.count
        }
        // Update underlying RMtextContainer.
        self.textContainer.contentText = self.text;
        self.textContainer.markedTextRange = markedTextRange;
        self.textContainer.selectedTextRange = selectedNSRange;
        setNeedsDisplay()
    }
    
    /**
     UIKeyInput protocol required method.
     Delete a character from the displayed text. Called by the text system when the user is invoking a delete (e.g. pressing the delete software keyboard key).
     */
    public func deleteBackward() {
        
        var selectedNSRange = textContainer.selectedTextRange
        var markedTextRange = textContainer.markedTextRange
        
        /*
         Note: While this sample does not provide a way for the user to create marked or selected text, the following code still checks for these ranges and acts accordingly.
         */
        if markedTextRange.location != NSNotFound {
            // There is marked text, so delete it.
            self.text.deleteCharacters(in: markedTextRange)
            selectedNSRange.location = markedTextRange.location
            selectedNSRange.length = 0
            markedTextRange = NSRange(location: NSNotFound, length: 0)
        } else if selectedNSRange.length > 0 {
            // Delete the selected text.
            self.text.deleteCharacters(in: selectedNSRange)
            selectedNSRange.length = 0
        } else if selectedNSRange.location > 0 {
            // Delete one char of text at the current insertion point.
            selectedNSRange.location -= 1
            selectedNSRange.length = 1
            self.text.deleteCharacters(in: selectedNSRange)
            selectedNSRange.length = 0
        }
        
        // Update underlying APLSimpleCoreTextView.
        self.textContainer.contentText = self.text;
        self.textContainer.markedTextRange = markedTextRange;
        self.textContainer.selectedTextRange = selectedNSRange;
        setNeedsDisplay()
    }
    
    open override var canBecomeFirstResponder: Bool {
        return true
    }
}

extension JAInputTextField {
        
    func getToolbarWithDone() ->UIToolbar {
        // ToolBar
        let toolBar = UIToolbar()
        
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor.blue
        toolBar.sizeToFit()
        toolBar.isUserInteractionEnabled = true
        
        if #available(iOS 13.0, *) {
            let appearance = UIToolbarAppearance()
            appearance.configureWithOpaqueBackground()
            toolBar.standardAppearance = appearance
            if #available(iOS 15.0, *) {
                toolBar.scrollEdgeAppearance = appearance
            }
        }
        
        //add a done button on this toolbar
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneClicked))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolBar.setItems([spaceButton,doneButton], animated: true)
        
        return toolBar
    }
    
    @objc func doneClicked() {
        self.resignFirstResponder()
    }
}

class JAIndexedPosition: UITextPosition {
    var index = 0
    
    convenience init(index: Int) {
        self.init()
        self.index = index
    }
}


class JAIndexedRange: UITextRange {
    
    var range: NSRange
    
    override init() {
        self.range = NSRange(location: 0, length: 0)
        super.init()
    }
    
    convenience init(range: NSRange) {
        self.init()
        self.range = range
    }

    // UITextRange read-only property - returns start index of range.
    override var start: UITextPosition {
        get {
            return JAIndexedPosition(index: self.range.location)
        }
    }

    // UITextRange read-only property - returns end index of range.
    override var end: UITextPosition {
        get {
            return JAIndexedPosition(index: range.location + range.length)
        }
    }
    
    // UITextRange read-only property - returns YES if range is zero length.
    override var isEmpty: Bool {
        return range.length == 0
    }
}

class JATextContainer {
    var contentText: NSMutableString = "" // The text content (without attributes).
    var markedTextRange = NSRange(location: NSNotFound, length: 0) // Marked text range (for input method marked text).
    var selectedTextRange = NSRange(location: 0, length: 0) // Selected text range.
}
