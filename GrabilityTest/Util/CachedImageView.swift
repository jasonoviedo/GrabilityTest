//
//  CachedImageView.swift
//  GrabilityTest
//
//  Created by Yeisson Oviedo on 11/29/15.
//  Copyright © 2015 Sanduche. All rights reserved.
//

import Foundation
import UIKit

let debug = false

protocol AFImageCacheProtocol:class{
    func cachedImageForRequest(request:NSURLRequest) -> UIImage?
    func cacheImage(image:UIImage, forRequest request:NSURLRequest);
}

extension UIImageView {
    private struct AssociatedKeys {
        static var SharedImageCache = "SharedImageCache"
        static var RequestImageOperation = "RequestImageOperation"
        static var URLRequestImage = "UrlRequestImage"
    }
    
    class func setSharedImageCache(cache:AFImageCacheProtocol?) {
        objc_setAssociatedObject(self, &AssociatedKeys.SharedImageCache, cache, objc_AssociationPolicy.OBJC_ASSOCIATION_COPY)
    }
    
    class func sharedImageCache() -> AFImageCacheProtocol {
        struct Static {
            static var token : dispatch_once_t = 0
            static var defaultImageCache:AFImageCache?
        }
        
        dispatch_once(&Static.token, { () -> Void in
            Static.defaultImageCache = AFImageCache()
            NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidReceiveMemoryWarningNotification, object: nil, queue: NSOperationQueue.mainQueue()) { (NSNotification) -> Void in
                Static.defaultImageCache!.removeAllObjects()
            }
        })
        return objc_getAssociatedObject(self, &AssociatedKeys.SharedImageCache) as? AFImageCache ?? Static.defaultImageCache!
    }
    
    class func af_sharedImageRequestOperationQueue() -> NSOperationQueue {
        struct Static {
            static var token:dispatch_once_t = 0
            static var queue:NSOperationQueue?
        }
        
        dispatch_once(&Static.token, { () -> Void in
            Static.queue = NSOperationQueue()
            Static.queue!.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount
        })
        return Static.queue!
    }
    
    private var af_requestImageOperation:(operation:NSOperation?, request: NSURLRequest?) {
        get {
            let operation:NSOperation? = objc_getAssociatedObject(self, &AssociatedKeys.RequestImageOperation) as? NSOperation
            let request:NSURLRequest? = objc_getAssociatedObject(self, &AssociatedKeys.URLRequestImage) as? NSURLRequest
            return (operation, request)
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.RequestImageOperation, newValue.operation, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            objc_setAssociatedObject(self, &AssociatedKeys.URLRequestImage, newValue.request, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public func setImageWithUrlString(url:String?, placeHolderImage:UIImage? = nil){
        if (url == nil){
            self.image = placeHolderImage
            return
        }
        if let nsurl = NSURL(string:url!){
            setImageWithUrl(nsurl)
        }
        else{
            self.image = placeHolderImage
        }
    }
    
    public func setImageWithUrl(url:NSURL, placeHolderImage:UIImage? = nil) {
        let request:NSMutableURLRequest = NSMutableURLRequest(URL: url)
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        self.setImageWithUrlRequest(request, placeHolderImage: placeHolderImage, success: nil, failure: nil)
    }
    
    func setImageWithUrlRequest(request:NSURLRequest, placeHolderImage:UIImage? = nil,
        success:((request:NSURLRequest?, response:NSURLResponse?, image:UIImage) -> Void)?,
        failure:((request:NSURLRequest?, response:NSURLResponse?, error:NSError) -> Void)?)
    {
        self.cancelImageRequestOperation()
        
        if let cachedImage = UIImageView.sharedImageCache().cachedImageForRequest(request) {
            if success != nil {
                success!(request: nil, response:nil, image: cachedImage)
            }
            else {
                self.image = cachedImage
            }
            
            return
        }
        
        //        if placeHolderImage != nil {
        self.image = placeHolderImage
        //        }
        
        self.af_requestImageOperation = (NSBlockOperation(block: { () -> Void in
            var response:NSURLResponse?
            var error:NSError?
            let data: NSData?
            do {
                data = try NSURLConnection.sendSynchronousRequest(request, returningResponse: &response)
            } catch let error1 as NSError {
                error = error1
                data = nil
            } catch {
                fatalError()
            }
            let image:UIImage? = (data != nil ? UIImage(data: data!) : nil)
            if(image != nil){
                UIImageView.sharedImageCache().cacheImage(image!, forRequest: request)
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if request.URL!.isEqual(self.af_requestImageOperation.request?.URL) {
                    
                    if image != nil {
                        if success != nil {
                            success!(request: request, response: response, image: image!)
                        }
                        else {
                            self.image = image!
                        }
                    }
                    else {
                        if failure != nil {
                            failure!(request: request, response:response, error: error!)
                        }
                    }
                    
                    self.af_requestImageOperation = (nil, nil)
                }
            })
        }), request)
        
        UIImageView.af_sharedImageRequestOperationQueue().addOperation(self.af_requestImageOperation.operation!)
    }
    
    private func cancelImageRequestOperation() {
        self.af_requestImageOperation.operation?.cancel()
        self.af_requestImageOperation = (nil, nil)
    }
}

func AFImageCacheKeyFromURLRequest(request:NSURLRequest) -> String {
    return request.URL!.absoluteString
}

public class AFImageCache: NSCache, AFImageCacheProtocol {
    func cachedImageForRequest(request: NSURLRequest) -> UIImage? {
        switch request.cachePolicy {
        case NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData,
        NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData:
            return nil
        default:
            break
        }
        
        let url :String = AFImageCacheKeyFromURLRequest(request)
        return cachedImageForUrl(url)
    }
    
    public func cachedImageForUrl(url:String)->UIImage?{
//                Swift.print("Looking for URL in cache \(url) -> ")
        if let memCached = self.objectForKey(url) as? UIImage{
//                        Swift.print("found in memory")
            return memCached
        }
        
        if let image:UIImage = getImageFromDiskForKey(url){
//                        Swift.print("found in disk")
            saveToMemory(image, key: url)
            return image
        }
        
//                Swift.print("not found :(")
        
        return nil
        
    }
    
    public func cacheImage(image: UIImage, forRequest request: NSURLRequest) {
        let key :String = AFImageCacheKeyFromURLRequest(request)
        saveToDisk(image, url: key)
        saveToMemory(image, key: key)
    }
    
    func saveToMemory(image:UIImage, key:String){
        //        println("Saving URL image to memory cache: \(key)")
        self.setObject(image, forKey: key)
    }
    
    func saveToDisk (image:UIImage, url:String) {
        let path = (NSHomeDirectory() as NSString).stringByAppendingPathComponent("Library/Caches/\(url.hash).jpg")
        //        println("Saving URL image to disk cache: \(url) -> \(path)")
        
        UIImageJPEGRepresentation(image, 0.9)!.writeToFile(path, atomically: true)
    }
    
    func getImageFromDiskForKey (key:String) -> UIImage?{
        let path = (NSHomeDirectory() as NSString).stringByAppendingPathComponent("Library/Caches/\(key.hash).jpg")
        let fileMng = NSFileManager.defaultManager()
        if(fileMng.fileExistsAtPath(path)){
            return UIImage(contentsOfFile: path)
        }
        return nil
    }
    
    func print (value: AnyObject){
        if(debug){
            Swift.print(value)
        }
    }
}
