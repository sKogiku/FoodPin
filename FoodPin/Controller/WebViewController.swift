//
//  WebViewController.swift
//  FoodPin
//
//  Created by Simon Ng on 14/11/2019.
//  Copyright © 2019 AppCoda. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController {

    @IBOutlet var webView: WKWebView!

    var targetURL = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never
        
        if let url = URL(string: targetURL) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}
