//
//  SplashController.swift
//  GrabilityTest
//
//  Created by Yeisson Oviedo on 11/29/15.
//  Copyright © 2015 Sanduche. All rights reserved.
//

import UIKit
import EasyAnimation
import ChameleonFramework

class SplashController: UIViewController {

    @IBOutlet var message: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        message.alpha = 0        
        message.textColor = UIColor.whiteColor()
        self.view.backgroundColor = UIColor.flatMagentaColorDark()
    }

    override func viewDidAppear(animated: Bool) {
        animate()

    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.performSegueWithIdentifier("splashToNavigationSegue", sender: self)
    }

    func animate(){
        message.alpha = 0
        
        UIView.animateAndChainWithDuration(5, delay: 2.0, options: [UIViewAnimationOptions.CurveEaseIn], animations: { () -> Void in
                self.message.alpha = 1
            }, completion: nil).animateWithDuration(1.0, delay: 0.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0, options: [UIViewAnimationOptions.CurveEaseIn], animations: { () -> Void in
                self.message.layer.setAffineTransform(CGAffineTransformScale(self.message.layer.affineTransform(), 3.5, 3.5))
            }){_ in
                UtilRunAfterDelay(1) {
                    self.performSegueWithIdentifier("splashToNavigationSegue", sender: self)
            }
        }

    }
}
