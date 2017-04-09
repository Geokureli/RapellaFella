package com.geokureli.rapella.utils;

import haxe.Constraints.Function;
import openfl.events.Event;
import openfl.events.EventDispatcher;

class FuncUtils {
    
    static public function traceBind(msg:String, func:Void->Void):Void->Void {
       
        return function():Void {
            
            trace(msg);
            func();
        }
    }
    
    static public function addListenerOnce(dispatcher:EventDispatcher, type:String, listener:Dynamic->Void):Dynamic->Void {
        
        function func(e:Event):Void {
            
            dispatcher.removeEventListener(type, func);
            listener(e);
        }
        
        dispatcher.addEventListener(type, func);
        
        return func;
    }
    
    
    
    static public function doNothing():Void { }
}
