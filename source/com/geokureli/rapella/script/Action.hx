package com.geokureli.rapella.script;

import haxe.Constraints.Function;
import com.geokureli.rapella.script.Action.ActionHandler;
import hx.debug.Assert;
import com.geokureli.rapella.utils.StringUtils;

class ActionMap {
    
    var _target:Dynamic;
    var _map:Map<String, ActionHandler>;
    
    public function new(target:Dynamic) {
        
        _target = target;
        _map = new Map<String, ActionHandler>();
    }
    
    public function add(
        func    :String,
        handler :Function,
        argNames:Array<String> = null ,
        async   :Bool          = false):ActionHandler {
        
        return _map[func] = new ActionHandler(handler, argNames, async);
    }
    
    public function addAsync(
        func    :String,
        handler :Function,
        argNames:Array<String> = null):ActionHandler {
        
        return add(func, handler, argNames, true);
    }
    
    public function handle(action:Action):Void {
        
        if (Assert.isTrue(_map.exists(action.func), 'Invalid func=${action.func}'))
            _map[action.func].handle(_target, action);
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
    
    public var async:Bool;
    
    var _handler:Function;
    var _argNames:Array<String>;
    
    public function new(handler:Function, argNames:Array<String> = null, async:Bool = false) {
        
        _handler = handler;
        _argNames = argNames;
        
        if(_argNames != null) {
            
            var restIndex:Int;
            for (i in 0 ... _argNames.length) {
                
                restIndex = _argNames[i].indexOf(Action.REST);
                if (restIndex != -1
                &&  Assert.isTrue(i == 0, 'invalid [arg="${_argNames[i]}"]')
                &&  !Assert.isTrue(i == _argNames.length - 1, '[arg="${_argNames[i]}"] must be the last argument')) {
                    
                    _argNames.splice(i + 1, _argNames.length - i - 1);
                    break;
                }
            }
        }
        
        this.async = async;
    }
    
    public function handle(target:Dynamic, action:Action):Void {
        
        action.setArgNames(_argNames);
        
        if (action.args.length == 0 && !async) {
            
            _handler();
            
            if (!async)
                action.complete();
            
        } else {
            
            if (async)
                action.args.push(action.complete);
            
            Reflect.callMethod(target, _handler, action.args);
            
            if (!async)
                action.complete();
        }
    }
    
    public function destroy():Void {
        
        _handler = null;
        _argNames = null;
    }
}

class Action {
    
    static public inline var REST:String = "...";
    static public inline var OPTIONAL:String = "?";
    
    static var _funcToken:EReg = ~/^\s*([^ (]+?)\s*\.\s*([^(]+)\s*\(\s*([^)]*?)\s*\)\s*?$/;
    
    public var valid (default, null):Bool;
    public var target(default, null):String;
    public var func  (default, null):String;
    public var args:Array<Dynamic>;
    
    var _callback:Void->Void;
    
    public function new (data:String, callback:Void->Void) {
        
        _callback = callback;
        args = new Array<Dynamic>();
        
        if (_funcToken.match(data)) {
            
            valid = true;
            
            target   = _funcToken.matched(1);
            func     = _funcToken.matched(2);
            var tempArgs = _funcToken.matched(3).split(",");
            
            while(tempArgs.length > 0)
                args.unshift(parseArg(tempArgs.pop()));
        }
    }
    
    static function parseArg(arg:String):String {
        
        return StringUtils.trimSpace(arg);
    }
    
    public function setArgNames(argNames:Array<String>):Void {
        
        var optional:Bool;
        var argName:String;
        var i:Int = 0;
        while(i < argNames.length) {
            
            argName = argNames[i];
            
            optional = argName.charAt(0) == OPTIONAL;
            if (optional)
                argName = argName.substring(1);
            
            if (argName.indexOf(REST) == 0) {
                
                optional = true;
                args.push(args.splice(i, args.length - i));
            }
            
            if (args.length <= i) {
                
                Assert.isTrue(optional, 'Missing [arg="$argName"][func="$func"]');
                args.push(null);
            }
            
            i++;
        }
        
        Assert.isTrue(args.length <= i, 'Too many arguments [args="${args.slice(i).join(", ")}"][func="$func"]');
        
        while (args.length > i)
            args.pop();
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
}