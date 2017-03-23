package com.geokureli.rapella.utils;

import hx.debug.Expect;
import hx.debug.Assert;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import haxe.PosInfos;
import hx.debug.AssertLogger;
import hx.event.Signal;
typedef ChildDef = { field:String, ?priority:ChildPriority, ?caster:Dynamic->Dynamic }

class ChildMap {
    
    static var ARRAY_EX:EReg = ~/\[(\d*)\]/;

    @unreflective public var mapSuccessful(default, null):Bool;
    
    @:unreflective var _map:Map<String, Dynamic>;
    @:unreflective var _onFail:Signal<String, String>;
    @:unreflective var _priorityMap:Map<ChildPriority, AssertLogger>;
    @:unreflective var _mapLog:String;
    @:unreflective var _logPriority:ChildPriority;
    
    public function new(map:Map<String, Dynamic>) {
        
        _map = map;
        setDefaults();
    }
    
    function setDefaults():Void {
        
        _onFail = new Signal<String, String>();
        
        _priorityMap = [
            ChildPriority.Strict   => new AssertLogger(onAssertFail),
            ChildPriority.Normal   => new AssertLogger(onExpectFail),
            ChildPriority.Optional => new AssertLogger(doNothing   )
        ];
    }
    
    public function map(target:Dynamic, parent:DisplayObjectContainer):Array<DisplayObject>
    {
        mapSuccessful = true;
        _mapLog = "";
        _logPriority = ChildPriority.Optional;
        
        var handler:ChildDef;
        var asset:Dynamic;
        var errorLog:AssertLogger;
        var children:Array<DisplayObject> = new Array<DisplayObject>();
        for (path in _map.keys()) {
            
            if (Std.is(_map[path], String))
                handler = { field:_map[path] };
            else 
                handler = cast _map[path];
            
            errorLog = _priorityMap[handler.priority];
            
            if (handler == null || !errorLog.has(target, handler.field, 'Missing [path=$${handler.field}]'))
                continue;
            
            asset = get(parent, path, handler, Reflect.field(target, handler.field), errorLog);
            if (asset != null) {
                
                Reflect.setField(target, handler.field, asset);
                
                if (Std.is(asset, DisplayObject))
                    children.push(asset);
                else if (Std.is(asset, Array)) {
                    
                    for (i in 0...asset.length)
                        children.push(asset[i]);
                }
            }
        }
        
        if (_logPriority == ChildPriority.Strict)
            Assert.fail(_mapLog);
        else if (_logPriority == ChildPriority.Normal)
            Expect.fail(_mapLog);
        
        return children;
    }
    
    inline function get(
        parent  :DisplayObjectContainer,
        path    :String,
        handler :ChildDef,
        target  :Dynamic,
        errorLog:AssertLogger):Dynamic {
        
        if (ARRAY_EX.match(path)) {
            
            var length:String = ARRAY_EX.matched(1);
            if(length != "")
                path = path.split(length).join("");
            
            target = SwfUtils.getAll(parent, path, target);
            errorLog.nonNull(target, 'Missing [path=$path]');
            
            if (target != null && length != "")
                errorLog.isTrue(target.length == Std.parseInt(length),
                    'Invalid length [expected=$length][actual=${target.length}][path=$path]');
            
            for (i in 0 ... target.length)
                target[i] = applyParams(target[i], handler);
            
        } else {
            
            var asset:DisplayObject = SwfUtils.get(parent, path);
            if (errorLog.nonNull(asset, 'Missing [path=$path]')) {
                
                asset = applyParams(asset, handler);
                
                if (Std.is(target, IChildMappable)
                &&  errorLog.is(asset, DisplayObjectContainer, "Wrapped assets should be DisplayObjectContainers"))
                    asset = target.wrap(asset);
                
                target = asset;
            }
        }
        
        return target;
    }
    
    function applyParams(asset:Dynamic, handler:ChildDef):Dynamic {
        
        if (handler.caster != null)
            asset = handler.caster(asset);
        
        return asset;
    }
    
    public function unMap(target:DisplayObjectContainer):Void {
        
        var field:String;
        var value:Dynamic;
        for (path in _map.keys()) {
            
            if (Std.is(_map[path], String))
                field = _map[path];
            else
                field = _map[path].field;
            
            if (Reflect.hasField(target, field)) {
                
                value = Reflect.field(target, field);
                destroyChild(value);
                Reflect.setField(target, field, null);
            }
        }
    }
    
    function destroyChild(value:Dynamic):Void {
        
        if (Std.is(value, IChildMappable))
            value.destroy();
        
        if (Std.is(value, Array)) {
            
            while (value.length > 0)
                destroyChild(value.pop());
        }
    }
    
    public function destroy():Void {
        
        _map = null;
        _onFail = null;
        _priorityMap = null;
        _mapLog = null;
    }
    
    function onAssertFail(?msg:String, ?pos:PosInfos):Void {
        
        mapSuccessful = false;
        _logPriority = ChildPriority.Strict;
        
        _mapLog += 'ASSERT FAIL: $msg\n';
    }
    
    function onExpectFail(?msg:String, ?pos:PosInfos):Void {
        
        if(_logPriority != ChildPriority.Strict)
            _logPriority = ChildPriority.Normal;
        
        _mapLog += 'EXPECT FAIL: $msg\n';
    }
    
    function doNothing(?msg:String, ?pos:PosInfos):Void {}
}

@:enum 
abstract ChildPriority(String) {
    
    var Normal   = null;
    var Strict   = "strict";
    var Optional = "optional";
}

interface IChildMappable {
    
    public function wrap(target:DisplayObjectContainer):Void;
    public function destroy():Void;
}