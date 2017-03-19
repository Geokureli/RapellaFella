package com.geokureli.rapella;

/**
 * Interprets instructions from JSON
 * @author George
 */

import com.geokureli.rapella.utils.StringUtils;
import hx.debug.Assert;
import haxe.Json;
import Reflect;
import openfl.Assets;
import com.geokureli.rapella.debug.Debug;

typedef ActionHandler = String->(Void->Void)->Void;

class ScriptInterpreter {
    
    static var _varGetToken:EReg = ~/^\s*vars\s*\.\s*([^ =]+)\s*$/;
    static var _varSetToken:EReg = ~/^\s*vars\s*\.\s*([^ =]+)\s*=\s*([^ =]+)\s*$/;
    
    static var _sceneData:Map<String, Dynamic>;
    
    static var _vars:Map<String, String> = new Map<String, String>();
    static var _handlers:Map<String, ActionHandler>;
    static var _objects:Map<String, IScriptInterpretable>;
    
    static public function init():Void {
        
        for (varName in Reflect.fields(Debug.scriptVars))
            _vars[varName] = Reflect.field(Debug.scriptVars, varName);
        
        var sceneDataName:String = "Scenes";
        if (Debug.sceneDataName != null)
            sceneDataName = Debug.sceneDataName;
        
        var rawSceneData:Dynamic = Json.parse(Assets.getText('assets/data/$sceneDataName.json'));
        _sceneData = new Map<String, Dynamic>();
        for (varName in Reflect.fields(rawSceneData))
            _sceneData[varName] = Reflect.field(rawSceneData, varName);
        
        _objects = [
            
            "game"=>Game.instance
        ];
    }

    public static function addInterpreter(id:String, interpreter:IScriptInterpretable):Void {
        
        _objects[id] = interpreter;
    }

    public static function removeInterpreter(id:String, interpreter:IScriptInterpretable):Void {
        
        if(Assert.isTrue(_objects[id] == interpreter, "Invalid interpreter"))
            _objects.remove(id);
    }
    
    static public function run(action:Dynamic, callback:Void->Void = null):Void {
        
        if(callback == null)
            callback = emptyCallback;
        
        if (Std.is(action, Array)){
            
            var array:Array<Dynamic> = cast action;
            
            if (array.length > 1) {
                
                array = array.concat([]);
                action = array.shift();
                callback = run.bind(array, callback);
                
            } else
                action = array[0];
        }
        
        handle(action, callback);
    }
    
    static function handle(rawAction:Dynamic, callback:Void->Void):Void {
        
        if (Std.is(rawAction, Array))
        {
            run(rawAction, callback);
            return;
            
        } else if (Std.is(rawAction, String)) {
            
            if (_varSetToken.match(cast rawAction)){
                
                _vars[_varSetToken.matched(1)] = _varSetToken.matched(2);
                callback();
                return;
                
            } else {
                
                var action = new Action(cast rawAction, callback);
                
                if (action.valid) {
                    
                    var object:IScriptInterpretable = _objects[action.target];
                    if (Assert.nonNull(object))
                        object.runScript(action);
                    
                    return;
                }
            }
        } else if (rawAction != null) {
            
            if(Reflect.hasField(rawAction, "if") && Assert.isTrue(Reflect.hasField(rawAction, "then"), "missing 'then' case")) {
                
                var condition:String = Reflect.field(rawAction, "if");
                var result:Bool;
                if (condition.indexOf("==") != -1) {
                    
                    var operands = condition.split("==");
                    result = parseVar(operands[0]) == parseVar(operands[1]);
                    
                } else
                    result = parseVar(condition) == "true";
                
                if(result)
                    handle(Reflect.field(rawAction, "then"), callback);
                else if(Reflect.hasField(rawAction, "else"))
                    handle(Reflect.field(rawAction, "else"), callback);
                else
                    callback();
                
                return;
            }
        }
        
        callback();
        Assert.fail('unhandled action=$rawAction');
    }
    
    static function parseVar(v:String):String {
        
        if(_varGetToken.match(v))
            return getVar(_varGetToken.matched(1));
        
        return v;
    }
    
    static inline public function getVar(key:String):String { return _vars[key]; }
    static inline public function getSceneData(name:String):Dynamic { return _sceneData[name]; }
    
    static function emptyCallback():Void {}
}

interface IScriptInterpretable {
    
    public function runScript(action:Action):Void;
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
}