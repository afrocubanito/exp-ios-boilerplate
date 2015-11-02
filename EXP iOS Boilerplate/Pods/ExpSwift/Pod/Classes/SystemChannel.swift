//
//  SystemChannel.swift
//  Pods
//
//  Created by Cesar on 9/10/15.
//
//

import Foundation
import Socket_IO_Client_Swift
import PromiseKit


public  class SystemChannel: Channel {
    
    var request = [String: Any]()
    public typealias CallBackType = [String: AnyObject] -> Void
    var listeners = [String: CallBackType]()
    var responders = [String: CallBackType]()
    let channel = "system"
    
    var socketSystem:SocketIOClient
    
    init(socket socketC:SocketIOClient) {
        self.socketSystem=socketC
    }
    
    
    /**
        Handle the Socket Type Response
        @param  Dictionarty.
    */
    public func onResponse(responseDic: NSDictionary){
        let error:String? = responseDic["error"] as? String
        let id:String = responseDic["id"] as! String
        if((request.indexForKey(id)) != nil){
            var dictionary:Dictionary<String,Any> = self.request[id] as! Dictionary
            if((error?.isEmpty) == nil){
                let fun = dictionary["fulfill"] as! Any -> Void
                fun(responseDic["payload"])
            }else{
                let errorLog:String = error!
                let rej = dictionary["reject"] as! NSError -> Void
                rej(NSError(domain: hostUrl, code: Config.EXP_ERROR_SOCKET, userInfo: ["error":errorLog]))
            }
            request.removeValueForKey(id)
        }
    }
    
    
    /**
        Handle the Socket Type Request
        @param  Dictionarty.
    */
    public func onRequest(responseDic: NSDictionary){
        let name:String? = responseDic["name"] as? String
        let callBack = self.responders[name!]!
        let payload:Dictionary<String,AnyObject> = responseDic["payload"] as! Dictionary
        callBack(payload)
        self.responders.removeValueForKey(name!)
        
    }
    
    
    /**
        Handle the Socket Type BroadCast
        @param  Dictionarty.
    */
    public func onBroadcast(responseDic: NSDictionary){
        let name:String? = responseDic["name"] as? String
        if(( self.listeners.indexForKey(name!)) != nil){
            let callBack = self.listeners[name!]!
            let payload:Dictionary<String,AnyObject> = responseDic["payload"] as! Dictionary
            callBack(payload)
        }
        
    }
    
    
    /**
        Send socket type request with Dictionary
        @param  Dictionarty.
        @return Promise<Any>
    */
    public func request(var messageDic: [String:String]) -> Promise<Any> {
        var uuid:String = NSUUID().UUIDString
        messageDic["id"] = uuid
        messageDic["channel"] = self.channel
        let requestPromise = Promise<Any> { fulfill, reject in
            self.socketSystem.emit(Config.SOCKET_MESSAGE,messageDic)
            var promiseDic = Dictionary<String,Any>()
            promiseDic  = [ "fulfill": fulfill,"reject":reject]
            request.updateValue(promiseDic, forKey: uuid)
        }
        return requestPromise
    }
    
    /**
        Send socket type broadcast with Dictionary
        @param  Dictionarty.
        @return Promise<Any>
    */
    public func broadcast(var messageDic:[String:AnyObject]) -> Void{
        messageDic["type"] = "broadcast"
        messageDic["channel"] = self.channel
        self.socketSystem.emit(Config.SOCKET_MESSAGE,messageDic)
    }
    
    /**
        Listen for particular socket name on type response broadcast
        @param  Dictionarty.
        @return Promise<Any>
    */
    public func listen(messageDic:[String: AnyObject], callback:CallBackType){
        var name:String = messageDic["name"] as! String
        listeners.updateValue(callback, forKey: name)
    }
    
    /**
        Respon for particular socket name on type request
        @param  Dictionarty.
        @return Promise<Any>
    */
    public func respond(messageDic:[String: AnyObject], callback:CallBackType){
        var name:String = messageDic["name"] as! String
        responders.updateValue(callback, forKey: name)
    }
}