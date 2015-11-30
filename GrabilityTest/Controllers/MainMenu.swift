//
//  MainMenu.swift
//  GrabilityTest
//
//  Created by Yeisson Oviedo on 11/29/15.
//  Copyright © 2015 Sanduche. All rights reserved.
//

import UIKit

class MainMenu: UIViewController {
    @IBOutlet var iPadContainer: UIView!
    @IBOutlet var iPhoneContainer: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let hideView = UIDevice.currentDevice().userInterfaceIdiom != UIUserInterfaceIdiom.Pad ? iPadContainer : iPhoneContainer
        
        hideView?.removeFromSuperview()
        
        self.navigationItem.title = "GrabilityTest"
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
