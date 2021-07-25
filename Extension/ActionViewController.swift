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
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
		
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

    @objc func done() {
        let item = NSExtensionItem()
		let argument: NSDictionary = ["customJavaScript": script.text!]
		let webDictionary: NSDictionary = [NSExtensionJavaScriptFinalizeArgumentKey: argument]
		let customJavaScript = NSItemProvider(item: webDictionary, typeIdentifier: kUTTypePropertyList as String)
		item.attachments = [customJavaScript]
		extensionContext?.completeRequest(returningItems: [item])
    }
}
