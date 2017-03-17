package com.geokureli.rapella;

/**
 * Interprets instructions from JSON
 * @author George
 */

import hx.debug.Assert;
import haxe.Json;
import Reflect;
import openfl.Assets;
import com.geokureli.rapella.debug.Debug;

typedef ActionHandler = String->(Void->Void)->Void;

class ScriptInterpreter {
    
    static var _funcToken:EReg = ~/^\s*([^ (]+)\s*\(\s*([^ )]+)\s*\)\s*?$/;
    static var _varGetToken :EReg = ~/^\s*vars\s*\.\s*([^ =]+)\s*$/;
    static var _varSetToken :EReg = ~/^\s*vars\s*\.\s*([^ =]+)\s*=\s*([^ =]+)\s*$/;
    
    static var _sceneData:Map<String, Dynamic>;
    
    static var _vars:Map<String, String> = new Map<String, String>();
    static var _handlers:Map<String, ActionHandler>;
    
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
        
        _handlers = [
        
            "goto"     =>gotoLabel,
            "gotoScene"=>gotoScene
        ];
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
    
    static function handle(action:Dynamic, callback:Void->Void):Void {
        
        if (Std.is(action, Array))
        {
            run(action, callback);
            return;
            
        } else if (Std.is(action, String)) {
            
            if (_funcToken.match(cast action)) {
                
                var handler:ActionHandler = _handlers[_funcToken.matched(1)];
                if (Assert.nonNull(handler)) {
                    
                    handler(_funcToken.matched(2), callback);
                    return;
                }
                
            } else if (_varSetToken.match(cast action)){
                
                _vars[_varSetToken.matched(1)] = _varSetToken.matched(2);
                callback();
                return;
            }
            
        } else if (action != null) {
            
            if(Reflect.hasField(action, "if") && Assert.isTrue(Reflect.hasField(action, "then"), "missing 'then' case")) {
                
                var condition:String = Reflect.field(action, "if");
                var result:Bool;
                if (condition.indexOf("==") != -1) {
                    
                    var operands = condition.split("==");
                    result = parseVar(operands[0]) == parseVar(operands[1]);
                    
                } else
                    result = parseVar(condition) == "true";
                
                if(result)
                    handle(Reflect.field(action, "then"), callback);
                else if(Reflect.hasField(action, "else"))
                    handle(Reflect.field(action, "else"), callback);
                
                return;
            }
        }
        
        callback();
        Assert.fail('unhandled action=$action');
    }
    
    static function parseVar(v:String):String {
        
        if(_varGetToken.match(v))
            return getVar(_varGetToken.matched(1));
        
        return v;
    }
    
    static inline public function getVar(key:String):String { return _vars[key]; }
    static inline public function getSceneData(name:String):Dynamic { return _sceneData[name]; }

    static function gotoLabel(label:String, callback:Void->Void):Void {
        
        Game.currentScene.goto(label);
        callback();
    }
    
    static function playTo():Void {
        
        
    }
    
    static function gotoScene(name:String, callback:Void->Void):Void
    {
        Game.createScene(name);
        callback();
    }
    
    static function emptyCallback():Void {}
}
