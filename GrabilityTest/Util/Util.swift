//
//  Util.swift
//  GrabilityTest
//
//  Created by Yeisson Oviedo on 11/29/15.
//  Copyright © 2015 Sanduche. All rights reserved.
//

import Foundation
import MobileCoreServices

class NetworkClient {
    
    static var API_KEY: String!
    
    static let BASE_URL = ""
    
    var defaultHandlers: [NetworkClientHandler] = [DefaultErrorHandler()]
    
    init(defaultHandlers: NetworkClientHandler...){
        if defaultHandlers.count > 0 {
            self.defaultHandlers = defaultHandlers
        }
    }
    
    /// Determine mime type on the basis of extension of a file.
    ///
    /// This requires MobileCoreServices framework.
    ///
    /// - parameter path:         The path of the file for which we are going to determine the mime type.
    ///
    /// - returns:                Returns the mime type if successful. Returns application/octet-stream if unable to determine mime type.
    
    func mimeTypeForPath(path: String) -> String {
        let url = NSURL(fileURLWithPath: path)
        let pathExtension = url.pathExtension
        
        
        var mimeTypeR = "application/octet-stream"
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension! as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                mimeTypeR = mimetype as String
            }
        }
        
        //        print("Mime type: \(mimeTypeR)")
        
        return mimeTypeR
    }
    
    func getDefaultHeaders() -> [String:String]{
        let headers: [HTTPRequestHeader:String] = [:]
        
        var rHeaders:[String:String] = [:]
        for (key, value) in headers{
            rHeaders[key.rawValue] = value
        }
        return rHeaders
    }
    
    func createRequest (method: String, endpoint:String, params: AnyObject?, headers: [HTTPRequestHeader:String] = [:] ) -> NSMutableURLRequest{
        let request = NSMutableURLRequest(URL: NSURL(string: NetworkClient.BASE_URL + endpoint)!)
        request.HTTPMethod = method
        request.timeoutInterval = 12
        
        do{
            request.HTTPBody = params != nil ? try NSJSONSerialization.dataWithJSONObject(params!, options: []) : nil
        } catch _ {
            
        }
        let rHeaders = getDefaultHeaders()
        
        for (header, value) in rHeaders{
            request.addValue(value, forHTTPHeaderField: header)
        }
        
        for (header, value) in headers{
            request.addValue(value, forHTTPHeaderField: header.rawValue)
        }
        
        return request;
    }
    
    /// Create request
    ///
    /// - parameter userid:   The userid to be passed to web service
    /// - parameter password: The password to be passed to web service
    /// - parameter email:    The email address to be passed to web service
    ///
    /// - returns:            The NSURLRequest that was created
    
    func createUploadRequest (filePath:String, params:[String:AnyObject]?, headers:[HTTPRequestHeader:String] = [:]) -> NSURLRequest {
        
        let boundary = "Boundary-\(NSUUID().UUIDString)"
        
        let url = NSURL(string: NetworkClient.BASE_URL + "/messages")!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        
        let rHeaders = getDefaultHeaders()
        
        for (header, value) in rHeaders{
            request.addValue(value, forHTTPHeaderField: header)
        }
        
        for (header, value) in headers{
            request.addValue(value, forHTTPHeaderField: header.rawValue)
        }
        
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = createBodyWithParameters(params, filePathKey: "content", paths: [filePath], boundary: boundary)
        
        return request
    }
    
    /// Create body of the multipart/form-data request
    ///
    /// - parameter parameters:   The optional dictionary containing keys and values to be passed to web service
    /// - parameter filePathKey:  The optional field name to be used when uploading files. If you supply paths, you must supply filePathKey, too.
    /// - parameter paths:        The optional array of file paths of the files to be uploaded
    /// - parameter boundary:     The multipart/form-data boundary
    ///
    /// - returns:                The NSData of the body of the request
    
    func createBodyWithParameters(params: [String: AnyObject]?, filePathKey: String?, paths: [String]?, boundary: String) -> NSData {
        let body = NSMutableData()
        
        if params != nil {
            for (key, value) in params! {
                body.appendString("--\(boundary)\r\n")
                body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.appendString("\(value)\r\n")
            }
        }
        
        if paths != nil {
            for path in paths! {
                let url = NSURL(fileURLWithPath: path)
                let filename = url.lastPathComponent
                let data = NSData(contentsOfURL: url)!
                let mimetype = mimeTypeForPath(path)
                
                body.appendString("--\(boundary)\r\n")
                body.appendString("Content-Disposition: form-data; name=\"\(filePathKey!)\"; filename=\"\(filename!)\"\r\n")
                body.appendString("Content-Type: \(mimetype)\r\n\r\n")
                body.appendData(data)
                body.appendString("\r\n")
            }
        }
        
        body.appendString("--\(boundary)--\r\n")
        return body
    }
    
    
    func sendAuthenticatedRequestUsingMethod(method: HTTPMethod,toEndpoint endpoint:String,withParams params: AnyObject?) -> RequestPromise{
        let defaults = NSUserDefaults.standardUserDefaults()
        let authToken = defaults.objectForKey("token") as? String ?? ""
        let promise = sendRequestUsingMethod(method, toEndpoint: endpoint, withParams: params, withExtraHeaders: [.AUTH_TOKEN:authToken])
        return promise
    }
    
    func sendRequestUsingMethod(method: HTTPMethod, toEndpoint endpoint:String, withParams params: AnyObject?, withExtraHeaders headers: [HTTPRequestHeader:String] = [:])-> RequestPromise{
        
        let request = createRequest(method.rawValue, endpoint:endpoint, params:params, headers:headers )
        let session = NSURLSession.sharedSession()
        let promise = RequestPromise(handlers:self.defaultHandlers)
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            self.handleNetworkResponseForPromise(promise, data: data, response: response, error: error)
        })
        
        task.resume()
        return promise;
    }
    
    func uploadAuthenticatedFile(filePath:String, toEndpoint endpoint:String, withParams params: [String:AnyObject]? = nil) -> RequestPromise{
        let defaults = NSUserDefaults.standardUserDefaults()
        let authToken = defaults.objectForKey("token") as? String ?? ""
        return uploadFile(filePath, toEndpoint: endpoint, withParams: params, withExtraHeaders:[.AUTH_TOKEN:authToken])
    }
    
    func uploadFile(filePath:String, toEndpoint endpoint:String, withParams params:[String:AnyObject]?, withExtraHeaders headers: [HTTPRequestHeader:String] = [:]) -> RequestPromise{
        let request = createUploadRequest(filePath, params:params, headers:headers)
        let promise = RequestPromise(handlers:self.defaultHandlers)
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            self.handleNetworkResponseForPromise(promise, data: data, response: response, error: error)
        })
        
        task.resume()
        return promise;
    }
    
    func handleNetworkResponseForPromise(promise:RequestPromise, data:NSData!, response:NSURLResponse!, error:NSError!){
        
        let strData: String? = data != nil ? NSString(data: data, encoding: NSUTF8StringEncoding) as? String : nil
        
        let statusCode: Int = error != nil ? 0 :(response as? NSHTTPURLResponse)?.statusCode ?? 0
        
        if statusCode == 0 {
            promise.dispatchError(ErrorData(errorMessage:"Verifica que estás conectado a internet e intenta nuevamente", statusCode:statusCode, error:error, response:response, errorJson:nil, data:strData ))
            return
        }
        
        var err: NSError?
        
        //This could be either a json object or a json array
        var json: AnyObject?
        do {
            json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableLeaves)
        } catch let error as NSError {
            err = error
            json = nil
        }
        
        if err != nil || json == nil{ // Json could not be deserialized,
            promise.dispatchError(ErrorData(errorMessage:err!.localizedDescription, statusCode:statusCode, error:error, response:response, errorJson:nil, data:strData ))
            
            //TODO log WTF
            return
        }
        
        let defaultErrorMessage = "Ocurrió un error, por favor intenta más tarde"
        
        switch statusCode {
        case 200..<300:
            //success
            promise.dispatchSuccess(json!)
        case 400..<500:
            //not found, bad request
            
            //It was an error, json MUST be a dictionary
            let errorJson = json as! NSDictionary
            promise.dispatchError(ErrorData(errorMessage:errorJson["error"] as? String ?? defaultErrorMessage, statusCode:statusCode, error:error, response:response, errorJson: errorJson, data:strData ))
            
        case 500..<600:
            //Oops
            promise.dispatchError(ErrorData(errorMessage:defaultErrorMessage, statusCode:statusCode, error:error, response:response, errorJson: nil, data:strData ))
            
        default:
            //WTF
            print("WTF")
        }
        
    }
    
    enum HTTPMethod: String {
        case GET = "GET"
        case POST = "POST"
        case PUT = "PUT"
        case PATCH = "PATCH"
        case DELETE = "DELETE"
    }
    
    enum HTTPRequestHeader : String{
        case CONTENT_TYPE = "Content-Type"
        case ACCEPT = "Accept"
        
        case APP_VERSION = "App-Version"
        case SOURCE_APP = "Source-App"
        case OS_NAME = "Os-Name"
        case OS_VERSION = "Os-Version"
        case DEVICE_LAT = "Device-Lat"
        case DEVICE_LNG = "Device-Lng"
        case DEVICE_ACC = "Device-Acc"
        case APP_LANGUAGE = "App-Language"
        case APP_KEY = "App-Key"
        case AUTH_TOKEN = "Auth-Token"
    }
}

class RequestPromise {
    var successHandler :(AnyObject -> Void)?
    var errorHandler:(ErrorData -> Void)?
    var finallyHandler : (() -> Void)?
    
    var errorData: ErrorData?
    var json: AnyObject?
    
    var defaultHandlers: [NetworkClientHandler]
    
    init (handlers:[NetworkClientHandler]){
        self.defaultHandlers = handlers
    }
    
    func success(handler:(AnyObject -> Void)) -> RequestPromise{
        self.successHandler = handler;
        //Response already arrived
        if(json != nil){
            dispatchSuccess(json!)
        }
        return self
    }
    
    func error(handler:(ErrorData -> Void))-> RequestPromise{
        self.errorHandler = handler
        //Error already acourred
        if(errorData != nil){
            dispatchError(errorData!)
        }
        return self
    }
    
    func finally(handler:()->Void) -> RequestPromise{
        self.finallyHandler = handler
        //Response/error already happened
        if(json != nil || errorData != nil){
            dispatch_async(dispatch_get_main_queue()){
                self.finallyHandler!()
            }
        }
        return self
    }
    
    func dispatchSuccess(json:AnyObject){
        self.json = json
        dispatch_async(dispatch_get_main_queue()){
            self.successHandler?(json)
            for h in self.defaultHandlers{
                h.onSuccess(json)
            }
            self.finallyHandler?()
        }
    }
    
    func dispatchError(errorData:ErrorData){
        self.errorData = errorData
        dispatch_async(dispatch_get_main_queue()){
            self.errorHandler?(errorData)
            for h in self.defaultHandlers{
                h.onError(errorData)
            }
            self.finallyHandler?()
        }
    }
}

struct ErrorData{
    let errorMessage:String
    let statusCode: Int?
    let error: NSError?
    let response: NSURLResponse?
    let errorJson: NSDictionary?
    let data: String?
    
    init (errorMessage:String, statusCode: Int?, error: NSError?, response: NSURLResponse?, errorJson: NSDictionary?, data:String?){
        self.errorMessage = errorMessage
        self.statusCode = statusCode
        self.error = error
        self.response = response
        self.errorJson = errorJson
        self.data = data
    }
    
    func humanReadableString () -> String{
        return "ErrorData{{code: \(statusCode ?? nil), data:\(data ?? nil), json:\(errorJson ?? nil), message:\(errorMessage), localizedError:\(error?.localizedDescription), response:\(response ?? nil)}}"
    }
}

protocol NetworkClientHandler{
    func onError(errorData:ErrorData)
    
    func onSuccess(data:AnyObject)
    
}


class DefaultErrorHandler: NetworkClientHandler{
    func onError(errorData:ErrorData) {
        print(errorData.humanReadableString())
        
        let code = errorData.statusCode ?? 0
        if code >= 400 {
            let statusString = errorData.statusCode?.description ?? ""
            let atts:[String:String] =  ["Error.StatusCode":statusString,
                "Error.Message":errorData.errorMessage,
                "Error.Response":errorData.response?.description ?? "",
                "Error.ResponseData":errorData.data ?? "",
                "Error.Json":errorData.errorJson?.description ?? "",
                "Error.Error.localizedDescription":errorData.error?.localizedDescription ?? ""]
            print (atts)
            //TODO log using some utility
        }
        
    }
    
    func onSuccess(data: AnyObject) {
        //This is an error handler, no need to do anything
    }
}

func UtilRunAfterDelay(delay: NSTimeInterval, block: dispatch_block_t) {
    let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
    dispatch_after(time, dispatch_get_main_queue(), block)
}

func UtilRunAsync(block: dispatch_block_t){
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
        block()
    }
}

func UtilRunInUIThread(block: dispatch_block_t){
    dispatch_async(dispatch_get_main_queue()) {
        block()
    }
}

import UIKit
class UtilMoveOnKeyboardShowHelper: NSObject{
    var offset: CGFloat = -10
    var contentViewOffset: CGFloat = 0
    var viewFrame: CGRect
    let superView: UIView
    
    convenience init(viewFrame:CGRect, superView:UIView){
        self.init(viewFrame:viewFrame, superView:superView, onKeyboardShow:nil,onKeyboardHide:nil)
    }
    
    init(viewFrame:CGRect, superView:UIView, onKeyboardShow: (() -> Void)?, onKeyboardHide: (() -> Void)?){
        self.viewFrame = viewFrame
        self.superView = superView
        super.init()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func deRegister(){
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func keyboardWillShow(notification:NSNotification){
        let ss = UIScreen.mainScreen().bounds
        
        let info: NSDictionary = notification.userInfo!
        let kbSize = info.objectForKey(UIKeyboardFrameBeginUserInfoKey)!.CGRectValue.size
        
        let tf = viewFrame
        let sf = superView.frame
        
        //Absolute topmost position of keyboard
        let kTop = ss.height - kbSize.height
        
        //Absolute bottommost position of the field we want to move
        let tBottom = tf.minY + tf.height - contentViewOffset
        
        let movement = tBottom < kTop ? 0 : kTop - tBottom + offset
        
        let bkRect =  CGRectMake(0, movement, sf.width, sf.height)
        superView.frame = bkRect
    }
    
    func keyboardWillHide(notification: NSNotification){
        let sf = superView.frame
        let bkRect =  CGRectMake(0, 0, sf.width, sf.height)
        superView.frame = bkRect
    }
}

extension NSMutableData {
    
    /// Append string to NSMutableData
    ///
    /// Rather than littering my code with calls to `dataUsingEncoding` to convert strings to NSData, and then add that data to the NSMutableData, this wraps it in a nice convenient little extension to NSMutableData. This converts using UTF-8.
    ///
    /// - parameter string:       The string to be added to the `NSMutableData`.
    
    func appendString(string: String) {
        let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        appendData(data!)
    }
}


