package com.geokureli.rapella.utils;

import hx.debug.Expect;
import hx.debug.Assert;
import hx.debug.Require;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import haxe.PosInfos;
import hx.debug.AssertLogger;
import hx.event.Signal;
typedef ChildDef = { field:String, ?priority:ChildPriority, ?caster:Dynamic->Dynamic }

class ChildMap {
    
    static var ARRAY_EX:EReg = ~/\[(\d*)\]/;

    @unreflective public var mapSuccessful(default, null):Bool;
    @unreflective public var sortChildren:Bool;
    
    @:unreflective var _map:Map<String, Dynamic>;
    @:unreflective var _onFail:Signal<String>;
    @:unreflective var _failListeners:Int;
    @:unreflective var _priorityMap:Map<ChildPriority, AssertLogger>;
    @:unreflective var _mapLog:String;
    @:unreflective var _logPriority:ChildPriority;
    
    public function new(map:Map<String, Dynamic>) {
        
        _map = map;
        setDefaults();
    }
    
    function setDefaults():Void {
        
        _onFail = new Signal<String>();
        _failListeners = 0;
        
        _priorityMap = [
            ChildPriority.Strict   => new AssertLogger(handleStrictFail),
            ChildPriority.Normal   => new AssertLogger(handleFail      ),
            ChildPriority.Optional => new AssertLogger(doNothing       )
        ];
    }
    
    public function addStrictFailListener(listener:String->Void):Void {
        
        _onFail.add(listener);
        _failListeners++;
    }
    
    public function removeStrictFailListener(listener:String->Void):Void {
        
        if (_onFail.get(listener) != null)
            _failListeners++;
        
        _onFail.remove(listener);
    }
    
    public function map(target:Dynamic, parent:DisplayObjectContainer):Array<DisplayObject> {
        
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
                
                if (Std.is(asset, IChildMappable) && !cast(asset, IChildMappable).isParent)
                    children.push(cast(asset, IChildMappable).target);
                else if (Std.is(asset, DisplayObject))
                    children.push(asset);
                else if (Std.is(asset, Array)) {
                    
                    for (i in 0...asset.length)
                        children.push(asset[i]);
                }
            }
        }
        
        if (_logPriority == ChildPriority.Strict) {
            
            if (_failListeners > 0)
                _onFail.dispatch(_mapLog);
            else
                Require.fail(_mapLog);
            
        } else if (_logPriority == ChildPriority.Normal)
            Assert.fail(_mapLog);
        
        if(sortChildren)
            children.sort(sortByIndex.bind(target));
        
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
    
    function sortByIndex(target:DisplayObjectContainer, child1:DisplayObject, child2:DisplayObject):Int {
        
        if (child1 == child2
        ||  (!target.contains(child1) && !target.contains(child2)))
            return 0;
        if (!target.contains(child1))
            return 1;
        if (!target.contains(child2))
            return -1;
        
        while (!child1.parent.contains(child2)) {
        
            child1 = child1.parent;
            target = child1.parent;
        }
        
        while (child2.parent != target)
            child2 = child2.parent;
        
        return target.getChildIndex(child2) - target.getChildIndex(child1);
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
            value.unwrap();
        
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
    
    function handleStrictFail(?msg:String, ?pos:PosInfos):Void {
        
        mapSuccessful = false;
        _logPriority = ChildPriority.Strict;
        
        _mapLog += 'REQUIRE FAIL: $msg\n';
    }
    
    function handleFail(?msg:String, ?pos:PosInfos):Void {
        
        mapSuccessful = false;
        if(_logPriority != ChildPriority.Strict)
            _logPriority = ChildPriority.Normal;
        
        _mapLog += 'ASSERT FAIL: $msg\n';
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
    
    public var target(default, null):DisplayObjectContainer;
    public var isParent(default, null):Bool;
    
    public function wrap(target:DisplayObjectContainer):Void;
    public function unwrap():Void;
    public function destroy():Void;
}