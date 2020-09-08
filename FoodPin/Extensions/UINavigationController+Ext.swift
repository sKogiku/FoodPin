//
//  UINavigationController+Ext.swift
//  FoodPin
//
//  Created by Simon Ng on 29/10/2019.
//  Copyright © 2019 AppCoda. All rights reserved.
//

import UIKit

extension UINavigationController {
    
    open override var childForStatusBarStyle: UIViewController? {
        return topViewController
    }
    
}
