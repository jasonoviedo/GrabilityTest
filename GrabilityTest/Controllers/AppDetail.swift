//
//  AppDetail.swift
//  GrabilityTest
//
//  Created by Yeisson Oviedo on 11/30/15.
//  Copyright © 2015 Sanduche. All rights reserved.
//

import UIKit

class AppDetail: UIViewController {
    @IBOutlet var image: UIImageView!
    @IBOutlet var name: UILabel!
    @IBOutlet var price: UILabel!
    @IBOutlet var summary: UILabel!
    
    @IBOutlet var navigationBar: UINavigationBar!
    @IBOutlet var category: UILabel!
    var app: GrabilityApp?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        summary.layer.borderColor = UIColor.flatCoffeeColor().CGColor
        summary.layer.borderWidth = 1
        summary.layer.cornerRadius = 10
        
        // Do any additional setup after loading the view.
        image.setImageWithUrlString(app?.imageMedium ?? "")
        name.text = app?.name
        price.text = "$\(app?.price ?? "0,0") \(app?.currency ?? "USD")"
        summary.text = app?.summary
        category.text = app?.category
        

    }

    override func viewDidLayoutSubviews() {
        let frame = CGRectMake(0, navigationBar.frame.minY, UIScreen.mainScreen().bounds.width, navigationBar.frame.height)
        navigationBar.frame = frame
    }
    
    override func viewDidAppear(animated: Bool) {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func close(sender: AnyObject) {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
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
