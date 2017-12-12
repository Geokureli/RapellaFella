package com.geokureli.rapella.debug;

import com.geokureli.rapella.art.ui.UIColors;
import com.geokureli.rapella.utils.SwfUtils;
import flash.filters.BitmapFilter;
import flash.filters.GlowFilter;
import openfl.events.MouseEvent;
import openfl.display.*;
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
    static public var airAccel          :Bool    = true;
    static public var trackClicks       :Bool    = false;
    
    
    static private var _lastClick:DisplayObject;
    static private var _clickGlow:GlowFilter;
    
    static public function init(stage:Stage):Void {
        
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
            
            if (trackClicks){
                
                _clickGlow = UIColors.GLOW_DEBUG_CLICK;
                stage.addEventListener(MouseEvent.CLICK, onClickAnything);
            }
            
            trace("debug enabled");
        #end
        
        Assert.fail = handleAssertFail;
        Expect.fail = handleExpectFail;
        
        trace("assert/expect enabled");
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
    
#if debug
    static private function onClickAnything(e:MouseEvent):Void {
        
        var target:DisplayObject = e.target;
        var filters:Array<BitmapFilter>;
        if (_lastClick != null) {
            filters = _lastClick.filters;
            filters.pop();
            _lastClick.filters = filters;
        }
        
        _lastClick = target;
        filters = target.filters;
        filters.push(_clickGlow);
        target.filters = filters;
        
        
        DebugConsole.log('Clicked: ${SwfUtils.getHierarchyName(target)}');
    }
#end
}
