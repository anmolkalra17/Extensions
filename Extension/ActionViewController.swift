//
//  ActionViewController.swift
//  Extension
//
//  Created by Anmol Kalra on 24/07/21.
//

import UIKit
import MobileCoreServices

class ActionViewController: UIViewController {

	@IBOutlet weak var script: UITextView!
	var pageTitle = ""
	var pageURL = ""
	let defaults = UserDefaults.standard
	
    override func viewDidLoad() {
        super.viewDidLoad()
		getScriptText()
		
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
		navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(getExamples))
		
		let notificationCenter = NotificationCenter.default
		notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
		notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
		
		if let inputItem = extensionContext?.inputItems.first as? NSExtensionItem {
			if let itemProvider = inputItem.attachments?.first {
				itemProvider.loadItem(forTypeIdentifier: kUTTypePropertyList as String) { [weak self] (dict, error) in
					guard let itemDictionary = dict as? NSDictionary else { return }
					guard let javaScriptValues = itemDictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary else { return }
					self?.pageTitle = javaScriptValues["title"] as? String ?? ""
					self?.pageURL = javaScriptValues["URL"] as? String ?? ""
					
					DispatchQueue.main.async {
						self?.title = self?.pageTitle
					}
				}
			}
		}
    }
	
	override func viewDidAppear(_ animated: Bool) {
		getScriptText()
	}

    @objc func done() {
        let item = NSExtensionItem()
		let argument: NSDictionary = ["customJavaScript": script.text!]
		let webDictionary: NSDictionary = [NSExtensionJavaScriptFinalizeArgumentKey: argument]
		let customJavaScript = NSItemProvider(item: webDictionary, typeIdentifier: kUTTypePropertyList as String)
		item.attachments = [customJavaScript]
		extensionContext?.completeRequest(returningItems: [item])
		saveUserJS()
    }
	
	@objc func adjustForKeyboard(notification: Notification) {
		guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
		let keyboardScreenEndFrame = keyboardValue.cgRectValue
		let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
		
		if notification.name == UIResponder.keyboardWillHideNotification {
			script.contentInset = .zero
		} else {
			script.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
		}
		
		script.scrollIndicatorInsets = script.contentInset
		
		let selectedRange = script.selectedRange
		script.scrollRangeToVisible(selectedRange)
	}
	
	@objc func getExamples() {
		let alert = UIAlertController(title: "Examples", message: "Some examples to run: \n 1. alert(\"Hello World\");\n 2. alert(2 + 2);", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
		present(alert, animated: true, completion: nil)
	}
	
	func saveUserJS() {
		guard let url = URL(string: pageURL) else { return }
		defaults.setValue(script.text, forKey: url.host!)
	}
	
	func getScriptText() {
		guard let url = URL(string: pageURL) else { return }
		
		if defaults.string(forKey: url.host!) != nil {
			script.text = defaults.string(forKey: url.host!)
		}
	}
}
