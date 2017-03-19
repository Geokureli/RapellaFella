package com.geokureli.rapella.script;

import com.geokureli.rapella.script.Action.ActionHandler;
import hx.debug.Assert;
import com.geokureli.rapella.utils.StringUtils;

class ActionMap {
    var _map:Map<String, ActionHandler>;
    
    public function new() {
        
        _map = new Map<String, ActionHandler>();
    }
    
    public function add(
        func    :String,
        handler :Action->Void,
        argNames:Array<String> = null ,
        async   :Bool          = false):ActionHandler {
        
        return _map[func] = new ActionHandler(handler, argNames, async);
    }
    
    public function handle(action:Action):Void {
        
        if (Assert.isTrue(_map.exists(action.func), 'Invalid func=${action.func}'))
            _map[action.func].handle (action);
        else
            action.complete();
    }
    
    public function destroy():Void
    {
        for (key in _map.keys())
            _map[key].destroy();
        
        _map = null;
    }
}

class ActionHandler {
    
    var _handler:Action->Void;
    var _argNames:Array<String>;
    var _async:Bool;
    
    public function new(handler:Action->Void, argNames:Array<String> = null, async:Bool = false) {
        
        _handler = handler;
        _argNames = argNames;
        _async = async;
    }
    
    public function handle(action:Action):Void {
        
        _handler(action);
        if (!_async)
            action.complete();
    }
    
    public function destroy():Void {
        
        _handler = null;
        _argNames = null;
    }
}

class Action {
    
    static var _funcToken:EReg = ~/^\s*([^ (]+?)\s*\.\s*([^(]+)\s*\(\s*([^)]*?)\s*\)\s*?$/;
    
    public var valid (default, null):Bool;
    public var target(default, null):String;
    public var func  (default, null):String;
    public var args  (default, null):Array<String>;
    
    var _callback:Void->Void;
    
    public function new (data:String, callback:Void->Void) {
        
        _callback = callback;
        
        if (_funcToken.match(data)) {
            
            valid = true;
            
            target = _funcToken.matched(1);
            func   = _funcToken.matched(2);
            args   = _funcToken.matched(3).split(",");
            
            for(i in 0 ... args.length)
                args[i] = parseArg(args[i]);
        }
    }
    
    static function parseArg(arg:String):String {
        
        return StringUtils.trimSpace(arg);
    }
    
    public function complete():Void {
        
        _callback();
        
        destroy();
    }
    
    public function destroy():Void {
        
        _callback = null;
        target = null;
        func = null;
        args = null;
    }
    
    public function getFullArgs(sep:String = ", "):String {
        
        return args.join(sep);
    }
}