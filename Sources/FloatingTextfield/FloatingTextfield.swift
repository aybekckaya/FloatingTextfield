//
//  FloatingTextfield.swift
//  FloatingTextfield
//
//  Created by Aybek Can Kaya on 25.07.2021.
//

import Foundation
import UIKit
import DeclarativeLayout
import DeclarativeUI
import Debouncer

// MARK: - FloatingTextfield {Skeleton}
open class FloatingTextfield: UITextField {
    private var colorDefaultText = UIColor.black
    private var colorEditingText = UIColor.black
    private var colorDefaultTitle = UIColor.black
    private var colorEditingTitle = UIColor.black
    private var colorDefaultBottomLine = UIColor.black
    private var colorEditingBottomLine = UIColor.black
    private var titleLabelFont: UIFont?
    private var titleLabelHorizontalInset: CGFloat = 0
    private var title: String = ""
    private var dismissWithReturnKey: Bool = false
    private var textInset: CGPoint = .zero
    
    private var textFieldEditingChangedDebouncer:  Debouncer?
    private var textFieldDidBeginEditingCallback: ((FloatingTextfield) -> ())?
    private var textFieldDidEndEditingCallback: ((FloatingTextfield) -> ())?
    private var textFieldEditingChangedCallback:  ((FloatingTextfield, String) -> ())?
    private var textFieldShouldChangeCharactersCallback: ((FloatingTextfield, NSRange, String) -> (Bool))?
    
    private var centerYConstraintTitleLabel: NSLayoutConstraint!
    private var heightConstraintTitleLabel: NSLayoutConstraint!
    private var leadingConstraintTitleLabel: NSLayoutConstraint!
    private var trailingConstraintTitleLabel: NSLayoutConstraint!
    
    private let viewBottomLine = UIView.view()
    private let lblTitle = UILabel.label()
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setUpUI()
        updateUI(animated: false)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Set Up UI
extension FloatingTextfield {
    private func setUpUI() {
        self.delegate = self
        self.addSubview(viewBottomLine)
        viewBottomLine
            .bottomAnchor(margin: 0)
            .leadingAnchor(margin: 0)
            .trailingAnchor(margin: 0)
            .heightAnchor(1)
        
        self.addSubview(self.lblTitle)
        self.trailingConstraintTitleLabel = self.lblTitle.trailingAnchor.constraint(equalTo: viewBottomLine.trailingAnchor, constant: 0)
        self.leadingConstraintTitleLabel =  self.lblTitle.leadingAnchor.constraint(equalTo: viewBottomLine.leadingAnchor, constant: 0)
        self.heightConstraintTitleLabel = self.lblTitle.heightAnchor.constraint(equalToConstant: 35)
        self.centerYConstraintTitleLabel = self.lblTitle.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0)
       
        self.centerYConstraintTitleLabel.isActive = true
        self.heightConstraintTitleLabel.isActive = true
        self.leadingConstraintTitleLabel.isActive = true
        self.trailingConstraintTitleLabel.isActive = true
        
        self.addTarget(self, action: #selector(textFieldEditingChangedFn), for: .editingChanged)
    }
    
    private func updateUI(animated: Bool) {
        self.textColor = isEditing ? colorEditingText : colorDefaultText
        self.borderStyle(.none)
        self.placeholder = ""
        heightConstraintTitleLabel.constant = self.font?.lineHeight ?? 0
        leadingConstraintTitleLabel.constant = titleLabelHorizontalInset
        trailingConstraintTitleLabel.constant = -1 * titleLabelHorizontalInset
      
        lblTitle.text = title
        lblTitle.font = titleLabelFont ?? self.font
               
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
                self.viewBottomLine.backgroundColor = self.updatedBottomLineColor()
                self.lblTitle.textColor = self.updatedTitleLabelColor()
                self.lblTitle.alpha = self.updatedAlphaForTitleLabel()
                self.centerYConstraintTitleLabel.constant = self.updatedCenterYForTitleLabel()
                self.layoutIfNeeded()
            } completion: { _ in
                
            }
        } else {
            viewBottomLine.backgroundColor = self.updatedBottomLineColor()
            lblTitle.alpha = self.updatedAlphaForTitleLabel()
            lblTitle.textColor = self.updatedTitleLabelColor()
        }
        self.layoutIfNeeded()
    }
    
    private func updatedBottomLineColor() -> UIColor {
        if self.isEditing == true { return self.colorEditingBottomLine  }
        return self.colorDefaultBottomLine
    }
    
    private func updatedTitleLabelColor() -> UIColor {
         if self.isEditing == true { return self.colorEditingTitle }
        return self.colorDefaultTitle
    }
    
    private func updatedAlphaForTitleLabel() -> CGFloat {
        return 1.0
    }
    
    private func updatedCenterYForTitleLabel() -> CGFloat {
        let activeCenterXPoint = -1 * self.frame.size.height * (75/100)
        if let text = self.text, text.count > 0 { return activeCenterXPoint }
        else if self.isEditing == true { return activeCenterXPoint }
        return 0
    }
}

// MARK: - Delegate
extension FloatingTextfield: UITextFieldDelegate {
    @objc private func textFieldEditingChangedFn() {
        guard let closure = textFieldEditingChangedCallback else { return }
        guard let debouncer =  textFieldEditingChangedDebouncer else {
            closure(self, self.text ?? "")
            return
        }
        debouncer.ping()
        debouncer.tick {
            closure(self, self.text ?? "")
        }
    }
    
    public override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: textInset.x, dy: textInset.y)
    }
    
    public override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: textInset.x, dy: textInset.y)
    }
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        updateUI(animated: true)
        guard let closure = textFieldDidBeginEditingCallback else { return }
        closure(self)
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        updateUI(animated: true)
        guard let closure = textFieldDidEndEditingCallback else { return }
        closure(self)
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if self.dismissWithReturnKey { self.resignFirstResponder() }
        return true
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let closure = textFieldShouldChangeCharactersCallback else { return true }
        return closure(self, range, string)
    }
}

// MARK: - Public
extension FloatingTextfield {
    @discardableResult
    public func textFieldDidBeginEditing(_ callback: @escaping ((FloatingTextfield) -> ()) ) -> FloatingTextfield {
        self.textFieldDidBeginEditingCallback = callback
        return self
    }
    
    @discardableResult
    public func textFieldDidEndEditing(_ callback: @escaping ((FloatingTextfield) -> ()) ) -> FloatingTextfield {
        self.textFieldDidEndEditingCallback = callback
        return self
    }
    
    @discardableResult
    public func textFieldEditingChanged(debounceTimeInterval: TimeInterval = 0, callback: @escaping ((FloatingTextfield, String) -> ()) ) -> FloatingTextfield {
        self.textFieldEditingChangedCallback = callback
        self.textFieldEditingChangedDebouncer = nil
        if debounceTimeInterval > 0 {
            self.textFieldEditingChangedDebouncer = Debouncer(timeInterval: debounceTimeInterval)
        }
        return self
    }
    
    @discardableResult
    public func textFieldShouldChangeCharacters(_ callback: @escaping ((FloatingTextfield, NSRange, String) -> (Bool)) ) -> FloatingTextfield {
        self.textFieldShouldChangeCharactersCallback = callback
        return self
    }
}

// MARK: - Declarative UI
extension FloatingTextfield {
    public static func floatingTextField() -> FloatingTextfield {
        let tf = FloatingTextfield(frame: .zero)
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }
    
    @discardableResult
    public func dismissWhenReturnKeyPressed(_ isDismiss: Bool) -> FloatingTextfield {
        self.dismissWithReturnKey = isDismiss
        return self
    }
    
    @discardableResult
    public func textInsets(dx: CGFloat, dy: CGFloat) -> FloatingTextfield {
        self.textInset = CGPoint(x: dx, y: dy)
        return self
    }
    
    @discardableResult
    public func editingTextColor(_ color: UIColor) -> FloatingTextfield {
        self.colorEditingText = color
        updateUI(animated: false)
        return self
    }
    
    @discardableResult
    public func defaultTextColor(_ color: UIColor) -> FloatingTextfield {
        self.colorDefaultText = color
        updateUI(animated: false)
        return self
    }
    
    @discardableResult
    public func editingTitleColor(_ color: UIColor) -> FloatingTextfield {
        self.colorEditingTitle = color
        updateUI(animated: false)
        return self
    }
    
    @discardableResult
    public func defaultTitleColor(_ color: UIColor) -> FloatingTextfield {
        self.colorDefaultTitle = color
        updateUI(animated: false)
        return self
    }
    
    @discardableResult
    public func editingBottomLineColor(_ color: UIColor) -> FloatingTextfield {
        self.colorEditingBottomLine = color
        updateUI(animated: false)
        return self
    }
    
    @discardableResult
    public func defaultBottomLineColor(_ color: UIColor) -> FloatingTextfield {
        self.colorDefaultBottomLine = color
        updateUI(animated: false)
        return self
    }
    
    @discardableResult
    public func title(_ title: String) -> FloatingTextfield {
        self.title = title
        updateUI(animated: false)
        return self
    }
    
    @discardableResult
    public func configureTextfield() -> FloatingTextfield {
        updateUI(animated: false)
        return self
    }
    
    @discardableResult
    public func titleLabelFont(_ font: UIFont) -> FloatingTextfield {
        self.titleLabelFont = font
        updateUI(animated: false)
        return self
    }
    
    @discardableResult
    public func titleLabelHorizontalInset(_ inset: CGFloat) -> FloatingTextfield {
        self.titleLabelHorizontalInset = inset
        updateUI(animated: false)
        return self
    }
}

extension UIView {
    public func asFloatingTextfield() -> FloatingTextfield {
        return self as! FloatingTextfield
    }
}

