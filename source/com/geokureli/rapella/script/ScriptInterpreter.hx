package com.geokureli.rapella.script;

/**
 * Interprets instructions from JSON
 * @author George
 */

import com.geokureli.rapella.script.Action.ActionMap;
import hx.debug.Assert;
import haxe.Json;
import Reflect;
import openfl.Assets;
import com.geokureli.rapella.debug.Debug;

class ScriptInterpreter {
    
    static var _varGetToken:EReg = ~/^\s*vars\s*\.\s*([^ =]+)\s*$/;
    static var _varSetToken:EReg = ~/^\s*vars\s*\.\s*([^ =]+)\s*=\s*([^ =]+)\s*$/;
    
    static var _sceneData:Map<String, Dynamic>;
    
    static var _vars:Map<String, String> = new Map<String, String>();
    static var _objects:Map<String, ActionMap>;
    
    static public function init():Void {
        
        #if debug
            for (varName in Reflect.fields(Debug.scriptVars))
                _vars[varName] = Reflect.field(Debug.scriptVars, varName);
        #else
            if(!_vars.exists("stat"))
                _vars["stat"] = "charisma";
        #end
        
        var sceneDataName:String = "Scenes";
        if (Debug.sceneDataName != null)
            sceneDataName = Debug.sceneDataName;
        
        var rawSceneData:Dynamic = Json.parse(Assets.getText('assets/data/$sceneDataName.json'));
        _sceneData = new Map<String, Dynamic>();
        for (varName in Reflect.fields(rawSceneData))
            _sceneData[varName] = Reflect.field(rawSceneData, varName);
        
        _objects = new Map<String, ActionMap>();
    }

    public static function addInterpreter(id:String, interpreter:ActionMap):Void {
        
        _objects[id] = interpreter;
    }

    public static function removeInterpreter(id:String, interpreter:ActionMap):Void {
        
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
                    
                    var object:ActionMap = _objects[action.target];
                    if (Assert.nonNull(object))
                        object.handle(action);
                    
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