//
//  MainMenuIPhone.swift
//  GrabilityTest
//
//  Created by Yeisson Oviedo on 11/29/15.
//  Copyright © 2015 Sanduche. All rights reserved.
//

import UIKit

class MainMenuIPhone: UIViewController, UITableViewDataSource, UITableViewDelegate {
    let reuseIdentifier = "Cell"
    let standardColor = UIColor.whiteColor()
    let screenSize = UIScreen.mainScreen().bounds

    var currentApp: GrabilityApp?
    var currentCell: UIView?
    
    let transition = PopAnimator()

    @IBOutlet var tableView: UITableView!
//    weak var tableView: UITableView
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.dataSource = self
        tableView.delegate = self    
        
        Model.get{ [weak self] in
            self?.tableView?.reloadData()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        tableView.frame = UIScreen.mainScreen().bounds
        tableView.contentSize = CGSizeMake(667, 1050)
//        print(tableView.frame)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Model.apps.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! IPhoneCell
        
        cell.appImage.layer.cornerRadius = 5
        
        cell.appImage.setImageWithUrlString(Model.apps[indexPath.row].imageMedium)
        cell.appName.text = Model.apps[indexPath.row].name
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        currentApp = Model.apps[indexPath.row]
        currentCell = tableView.cellForRowAtIndexPath(indexPath)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        performSegueWithIdentifier("mainMenuToDetailSegue", sender: self)
    }
    
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        currentApp = Model.apps[indexPath.row]
        currentCell = tableView.cellForRowAtIndexPath(indexPath)
        performSegueWithIdentifier("mainMenuToDetailSegue", sender: self)
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let nextController = segue.destinationViewController as! AppDetail
        nextController.app = currentApp!
        nextController.transitioningDelegate = self
        // Pass the selected object to the new view controller.
    }
    

}

extension MainMenuIPhone: UIViewControllerTransitioningDelegate {
    func animationControllerForPresentedController(
        presented: UIViewController,
        presentingController presenting: UIViewController,
        sourceController source: UIViewController) ->
        UIViewControllerAnimatedTransitioning? {
            
            transition.originFrame = currentCell!.superview!.convertRect(currentCell!.frame, toView: nil)
            transition.presenting = true
            
            return transition
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transition.presenting = false
        return transition
    }
}

class IPhoneCell: UITableViewCell{
    
    @IBOutlet var appImage: UIImageView!
    @IBOutlet var appName: UILabel!
}
        