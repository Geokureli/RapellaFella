package com.geokureli.rapella.debug;

import com.geokureli.rapella.art.AssetManager;
import hx.debug.Expect;
import haxe.PosInfos;
import hx.debug.Assert;
import haxe.Json;
import openfl.Assets;

class Debug {
    
    static public var scriptVars        :Dynamic = null;
    static public var startingScene     :String  = null;
    static public var startingLabel     :String  = null;
    static public var sceneDataName     :String  = null;
    static public var verboseAssertLog  :Bool    = false;
    static public var verboseExpectLog  :Bool    = false;
    static public var verboseScriptLog  :Bool    = false;
    static public var assertThrow       :Bool    = false;
    static public var showInvalidOptions:Bool    = false;
    static public var showBounds        :Bool    = false;
    
    static public function init():Void {
        
        #if debug
            startingScene = "Scene1";
            assertThrow = true;
            
            var data:Dynamic = Json.parse(AssetManager.getText("assets/data/Debug.json"));
            var value:Dynamic;
            for (fieldName in Reflect.fields(data)) {
                
                value = Reflect.field(data, fieldName);
                if (Std.is(Reflect.field(Debug, fieldName), Bool) && Std.is(value, String))
                    Reflect.setField(Debug, fieldName, value == "true");
                else
                    Reflect.setField(Debug, fieldName, value);
            }
        #end
        
        Assert.fail = handleAssertFail;
        Expect.fail = handleExpectFail;
    }
    
    static function handleAssertFail(?msg:String, ?pos:PosInfos):Void {
        
        if (msg == null) msg = "failure";
        #if debug
            
            DebugConsole.log(
                verboseAssertLog
                    ? 'Assert Fail - ${pos.fileName}[${pos.lineNumber}]: $msg'
                    : 'Assert Fail: $msg',
                true
            );
            
            if (assertThrow)
                throw '${pos.fileName}[${pos.lineNumber}]: $msg';
            else
                trace('$msg', pos);
        #else
            //TODO: something?
        #end
    }
    
    static function handleExpectFail(?msg:String, ?pos:PosInfos):Void {
        
        #if debug
            if (msg == null) msg = "failure";
            
            DebugConsole.log(
                verboseExpectLog
                ? 'Axpect Fail - ${pos.fileName}[${pos.lineNumber}]: $msg'
                : 'Expect Fail: $msg'
            );
            
            trace('${pos.fileName}[${pos.lineNumber}]: $msg');
        #end
    }
}
