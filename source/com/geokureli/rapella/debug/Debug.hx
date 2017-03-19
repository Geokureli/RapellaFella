package com.geokureli.rapella.debug;

import hx.debug.Expect;
import haxe.PosInfos;
import hx.debug.Assert;
import haxe.Json;
import openfl.Assets;

class Debug {
    
    static public var scriptVars        :Dynamic = null;
    static public var startingScene     :String  = null;
    static public var sceneDataName     :String  = null;
    static public var verboseAssertLog  :Bool    = false;
    static public var verboseExpectLog  :Bool    = false;
    static public var assertThrow       :Bool    = false;
    static public var showInvalidOptions:Bool    = false;
    
    static public function init():Void {
        
        #if debug
            startingScene = "Scene1";
            assertThrow = true;
            
            var data:Dynamic = Json.parse(Assets.getText("assets/data/Debug.json"));
            for (fieldName in Reflect.fields(data)) {
                
                if (Std.is(Reflect.field(Debug, fieldName), Bool))
                    Reflect.setField(Debug, fieldName, Reflect.field(data, fieldName) == "true");
                else
                    Reflect.setField(Debug, fieldName, Reflect.field(data, fieldName));
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
                trace('${pos.fileName}[${pos.lineNumber}]: $msg');
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
