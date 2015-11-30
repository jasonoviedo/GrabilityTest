//
//  PopAnimator.swift
//  GrabilityTest
//
//  Created by Yeisson Oviedo on 11/30/15.
//  Copyright © 2015 Sanduche. All rights reserved.
//

import UIKit

class PopAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    let duration    = 1.0
    var presenting  = true
    var originFrame = CGRect.zero
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?)-> NSTimeInterval {
        return duration
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        
        let containerView = transitionContext.containerView()!
        let toView = transitionContext.viewForKey(UITransitionContextToViewKey)!
        let target = presenting ? toView : transitionContext.viewForKey(UITransitionContextFromViewKey)!
        
        let initialFrame = presenting ? originFrame : target.frame
        let finalFrame = presenting ? target.frame : originFrame
        
        let xScaleFactor = presenting ?
            initialFrame.width / finalFrame.width : 0.01
        
        let yScaleFactor = presenting ?
            initialFrame.height / finalFrame.height : 0.01
        
        let scaleTransform = CGAffineTransformMakeScale(xScaleFactor, yScaleFactor)
        
        if presenting {
            target.transform = scaleTransform
            target.center = CGPoint(
                x: CGRectGetMidX(initialFrame),
                y: CGRectGetMidY(initialFrame))
            target.clipsToBounds = true
        }
        
        containerView.addSubview(toView)
        containerView.bringSubviewToFront(target)
        
        target.alpha = 1
        
        UIView.animateWithDuration(presenting ? duration : 1, delay:0.0,
            usingSpringWithDamping: presenting ? 0.4 : 1,
            initialSpringVelocity: 0.0,
            options: [],
            animations: {
                target.transform = self.presenting ?
                    CGAffineTransformIdentity : scaleTransform
                
                target.center = CGPoint(x: CGRectGetMidX(finalFrame),
                    y: CGRectGetMidY(finalFrame))
                if (!self.presenting){
                    target.alpha = 0
                }
            }, completion:{_ in
                transitionContext.completeTransition(true)
        })
        
        let round = CABasicAnimation(keyPath: "cornerRadius")
        round.fromValue = presenting ? 20.0/xScaleFactor : 0.0
        round.toValue = presenting ? 0.0 : 20.0/xScaleFactor
        round.duration = duration / 2
        target.layer.addAnimation(round, forKey: nil)
        target.layer.cornerRadius = presenting ? 0.0 : 20.0/xScaleFactor
    }
    
}

