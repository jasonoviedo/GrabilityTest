//
//  MainMenuIPad.swift
//  GrabilityTest
//
//  Created by Yeisson Oviedo on 11/29/15.
//  Copyright © 2015 Sanduche. All rights reserved.
//

import UIKit
import ChameleonFramework

class MainMenuIPad: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    let reuseIdentifier = "Cell"
    let standardColor = UIColor.flatPowderBlueColor()
    let screenSize = UIScreen.mainScreen().bounds
    weak var collectionView: UICollectionView?
    var currentApp: GrabilityApp?
    var currentCell: UIView?
    let transition = PopAnimator()
    let testServices = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupCollectionView()
        
        Model.get{ [weak self] in
            self?.collectionView?.reloadData()
        }
    }
        
    override func viewDidAppear(animated: Bool) {
        self.collectionView?.frame = self.view.bounds
        self.collectionView?.contentSize = CGSizeMake(screenSize.width, screenSize.height)

    }
    
    func setupCollectionView(){
        // Initialize Flow Layout.
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSizeMake(140, 135)
        layout.scrollDirection = .Vertical
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 5
        layout.sectionInset = UIEdgeInsetsMake(15, 5, 15, 5)
        
        // Initilaize collection view.
        let collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        self.collectionView = collectionView
        // Set it as delegate and data source.
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = standardColor//.darkenByPercentage(0.07)
        collectionView.bounces = true
        collectionView.alwaysBounceVertical = true
        
        collectionView.registerNib(UINib(nibName: "IPadCell", bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)
        
        
        // Add collection view as subview to our root view.
        
        self.view.addSubview(collectionView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        //#warning Incomplete method implementation -- Return the number of sections
        return 1
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //#warning Incomplete method implementation -- Return the number of items in the section
        return Model.apps.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! IPadCell
        
        cell.layer.borderWidth = 1
        cell.layer.borderColor = UIColor.flatPowderBlueColorDark().CGColor
        cell.layer.cornerRadius = 5
        cell.backgroundColor = UIColor.whiteColor()
        
        // Configure the cell
        cell.appImage.clipsToBounds = true
        cell.appImage.layer.cornerRadius = 10
        
        cell.appImage.setImageWithUrlString(Model.apps[indexPath.row].imageMedium)
        cell.appName.text = Model.apps[indexPath.row].name
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        currentApp = Model.apps[indexPath.row]
        currentCell = collectionView.cellForItemAtIndexPath(indexPath)
        performSegueWithIdentifier("mainMenuToDetailSegue", sender: self)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let nextController = segue.destinationViewController as! AppDetail
        nextController.app = currentApp!
        nextController.transitioningDelegate = self
    }

}

extension MainMenuIPad: UIViewControllerTransitioningDelegate {
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

class IPadCell: UICollectionViewCell{
    @IBOutlet var appImage: UIImageView!
    
    @IBOutlet var appName: UILabel!
}
