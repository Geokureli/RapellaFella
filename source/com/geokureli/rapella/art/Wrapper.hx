package com.geokureli.rapella.art;
import openfl.events.Event;
import openfl.display.Stage;
import openfl.display.Sprite;
import openfl.display.MovieClip;

/**
 * ...
 * @author George
 */
class Wrapper extends Sprite {
    
    var _target:Sprite;
    var _clip(get, never):MovieClip;
    var _childWrappers:Array<Wrapper>;
    
    var _isParent:Bool;
    var enabled:Bool;
    
    public function new(target:Sprite) {
        super();
        
        _target = target;
        
        setDefaults();
        
        if (_isParent) {
            
            if (_target.parent != null) {
                
                _target.parent.addChildAt(this, _target.parent.getChildIndex(_target));
                x      = _target.x;      _target.x      = 0;
                y      = _target.y;      _target.y      = 0;
                scaleX = _target.scaleX; _target.scaleX = 1;
                scaleY = _target.scaleY; _target.scaleY = 1;
            }
            
            addChild(_target);
        }
        
        if (target.stage == null)
           _target.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        else
           onAddedToStage();
    }
    
    function setDefaults() {
        
        enabled = true;
        
        _childWrappers = new Array<Wrapper>();
        _isParent = _target.parent == null;
    }
    
    function onAddedToStage(e:Event = null) {
        
        _target.removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
    }
    
    public function update():Void {
        
        for (child in _childWrappers) {
            
           if (child.enabled)
               child.update();
        }
    }
    
    public function add(child:Wrapper):Wrapper
    {
        if (_childWrappers.indexOf(child) == -1)
           _childWrappers.push(child);
        
        return child;
    }
    
    public function remove(child:Wrapper):Wrapper
    {
        _childWrappers.remove(child);
        
        return child;
    }
    
    function get__clip():MovieClip { return cast(_target, MovieClip); }
    
    //@:getter(stage)
    //override function get_stage():Stage {
        //
        //if (super.get_stage() != null)
           //return super.get_stage();
        //
        //return _target.stage;
    //}
}