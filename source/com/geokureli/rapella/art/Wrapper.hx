package com.geokureli.rapella.art;

import com.geokureli.rapella.utils.ChildMap;
import flash.display.DisplayObject;
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
    public var enabled:Bool;
    
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
        
        enabled = true;
        
        _childMap = new Map<String, Dynamic>();
        _childMapper = new ChildMap(_childMap);
        _childWrappers = new Array<Wrapper>();
    }
    
    public function wrap(target:DisplayObjectContainer):Void {
        
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
    
    function onAddedToStage(e:Event = null) {
        
        target.removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
    }
    
    function abort():Void {
        
        destroy();
    }
    
    public function unwrap():Void {
        
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
        
        if (_childWrappers.indexOf(child) == -1)
           _childWrappers.push(child);
        
        return child;
    }
    
    public function removeWrapper(child:Wrapper):Wrapper {
        
        _childWrappers.remove(child);
        
        return child;
    }
    
    function get__clip():MovieClip { return cast(target, MovieClip); }
    
    public function destroy():Void {
        
        if(target.parent == this)
            removeChild(target);
        
        unwrap();
        _childMapper.destroy();
        _childMapper = null;
        
        _childWrappers = null;
    }
}