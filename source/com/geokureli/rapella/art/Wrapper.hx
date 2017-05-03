package com.geokureli.rapella.art;

import com.geokureli.rapella.utils.ChildMap;
import com.geokureli.rapella.utils.SwfUtils;
import flash.display.DisplayObject;
import hx.debug.Assert;
import openfl.display.DisplayObjectContainer;
import openfl.display.MovieClip;
import openfl.display.Sprite;
import openfl.events.Event;

/**
 * @author George
 */

class Wrapper extends Sprite 
    implements IChildMappable {
    
    public var target(default, null):DisplayObjectContainer;
    public var isParent(default, null):Bool;
    
    public var enabled(get, set):Bool;
    var _selfEnabled:Bool;
    function get_enabled():Bool { return _selfEnabled && _parentEnabled; }
    function set_enabled(value:Bool):Bool {
        
        if (value != _selfEnabled) {
            
            value = !value && _parentEnabled;
            _selfEnabled = !_selfEnabled;
            
            if (enabled != value)
                updateEnable();
        }
        
        return _selfEnabled;
    }
    
    var _parentEnabled(default, set):Bool;
    function set__parentEnabled(value:Bool):Bool {
        
        if (value != _parentEnabled) {
            
            value = !value && _selfEnabled;
            _parentEnabled = !_parentEnabled;
            
            if (enabled != value)
                updateEnable();
        }
        
        return _parentEnabled;
    }
    
    var _clip(get, never):MovieClip;
    var _childWrappers:Array<Wrapper>;
    
    var _childMap:Map<String, Dynamic>;
    var _childMapper:ChildMap;
    var _children:Array<DisplayObject>;
    
    public function new(target:DisplayObjectContainer) {
        super();
        
        setDefaults();
        
        if (target != null)
            wrap(target);
    }
    
    function setDefaults() {
        
        _parentEnabled = true;
        
        _childMap = new Map<String, Dynamic>();
        _childMapper = new ChildMap(_childMap);
        _childWrappers = new Array<Wrapper>();
    }
    
    public function wrap(target:DisplayObjectContainer):Void {
        
        if(!Assert.nonNull(target))
            return;
        
        this.target = target;
        isParent = isParent || target.parent == null;
        
        if (isParent) {
            
            if (target.parent != null) {
                
                target.parent.addChildAt(this, target.parent.getChildIndex(target));
                x        = target.x;        target.x        = 0;
                y        = target.y;        target.y        = 0;
                scaleX   = target.scaleX;   target.scaleX   = 1;
                scaleY   = target.scaleY;   target.scaleY   = 1;
                rotation = target.rotation; target.rotation = 0;
            }
            
            addChild(target);
        }
        
        mapChildren();
        if (_childMapper.mapSuccessful) {
            
            init();
            enabled = true;
            
            if (target.stage == null)
                target.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            else
                onAddedToStage();
                
        } else 
            abort();
    }
    
    function mapChildren():Void {
        
        _children = _childMapper.map(this, target);
    }
    
    function init():Void { }
    
    function updateEnable():Void 
    {
        for (child in _childWrappers)
            child._parentEnabled = enabled;
    }
    
    function onAddedToStage(e:Event = null) {
        
        target.removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
    }
    
    function abort():Void {
        
        destroy();
    }
    
    public function unwrap():Void {
        
        enabled = false;
        target.removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        _childMapper.unMap(this);
        target = null;
    }
    
    public function update():Void {
        
        for (child in _childWrappers) {
            
           if (child.enabled)
               child.update();
        }
    }
    
    public function addWrapper(child:Wrapper):Wrapper {
        
        if (!Assert.nonNull(child) || !Assert.notContains(_childWrappers, child))
            return child;
        
        _childWrappers.push(child);
        child._parentEnabled = enabled;
        
        return child;
    }
    
    public function removeWrapper(child:Wrapper):Wrapper {
        
        if (!Assert.nonNull(child) || !Assert.contains(_childWrappers, child))
            return child;
        
        child._parentEnabled = true;
        _childWrappers.remove(child);
        
        return child;
    }
    
    @:generic 
    inline function getChild<T:DisplayObject>(path:String):T {
        
        return SwfUtils.get(target, path);
    }
    
    @:generic 
    inline function getChildList<T:DisplayObject>(path:String, ?list:Array<T>):Array<T> {
        
        return SwfUtils.getAll(target, path, list);
    }
    
    function get__clip():MovieClip {
        
        if (target == null)
            return null;
        return cast(target, MovieClip);
    }
    
    public function destroy():Void {
        
        if(target.parent == this)
            removeChild(target);
        
        unwrap();
        _childMapper.destroy();
        _childMapper = null;
        
        _childWrappers = null;
    }
}