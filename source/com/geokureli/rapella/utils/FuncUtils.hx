package com.geokureli.rapella.utils;

import openfl.events.Event;
import openfl.events.EventDispatcher;

class FuncUtils {
    
    static public function addListenerOnce(dispatcher:EventDispatcher, type:String, listener:Event->Void):Event->Void {
        
        var func:Event->Void;
        func = function (e:Event):Void {
            
            dispatcher.removeEventListener(type, func);
            listener(e);
        }
        
        dispatcher.addEventListener(type, func);
        
        return func;
    }
}
