package com.geokureli.rapella.utils;

import haxe.Constraints.Function;
import openfl.events.Event;
import openfl.events.EventDispatcher;

class FuncUtils {
    
    inline static public function addListenerOnce(dispatcher:EventDispatcher, type:String, listener:Dynamic->Void):Dynamic->Void {
        
        var func:Event->Void;
        func = function (e:Event):Void {
            
            dispatcher.removeEventListener(type, func);
            listener(e);
        }
        
        dispatcher.addEventListener(type, func);
        
        return func;
    }
    
    static public function doNothing():Void { }
}
