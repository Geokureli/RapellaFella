package com.geokureli.rapella.art;

import flash.display.DisplayObject;
import com.geokureli.rapella.utils.ChildMap;
import com.geokureli.rapella.utils.ChildMap.IChildMappable;
import com.geokureli.rapella.script.Action.ActionHandler;
import com.geokureli.rapella.script.Action;
import com.geokureli.rapella.script.ScriptInterpreter;
import com.geokureli.rapella.utils.MCUtils;
import openfl.events.Event;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.display.MovieClip;

/**
 * ...
 * @author George
 */
class Wrapper extends Sprite 
    implements IChildMappable {
    
    var _target:DisplayObjectContainer;
    var _clip(get, never):MovieClip;
    var _childWrappers:Array<Wrapper>;
    
    var _isParent:Bool;
    var enabled:Bool;
    var _scriptId:String;
    var _actionMap:ActionMap;
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
        
        _actionMap = new ActionMap(this);
        _actionMap.add("goto"      , script_goto      , ["label"        ]);
        _actionMap.add("playFromTo", script_playFromTo, ["start", "?end"], true);
        _actionMap.add("playTo"    , script_playTo    , ["start"        ], true);
        _actionMap.add("play"      , script_play);
        _actionMap.add("stop"      , script_stop);
    }
    
    public function wrap(target:DisplayObjectContainer):Void {
        
        _target = target;
        _isParent = _isParent || _target.parent == null;
        
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
        
        if(_scriptId != null)
            ScriptInterpreter.addInterpreter(_scriptId, _actionMap);
        
        mapChildren();
        if (_childMapper.mapSuccessful) {
            
            initChildren();
            
            if (target.stage == null)
                _target.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            else
                onAddedToStage();
        } else 
            abort();
    }
    
    function mapChildren():Void {
        
        _children = _childMapper.map(this, _target);
    }
    
    function initChildren():Void { }
    
    function onAddedToStage(e:Event = null) {
        
        _target.removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
    }
    
    function abort():Void {
        
        destroy();
    }
    
    public function update():Void {
        
        for (child in _childWrappers) {
            
           if (child.enabled)
               child.update();
        }
    }
    
    public function add(child:Wrapper):Wrapper {
        
        if (_childWrappers.indexOf(child) == -1)
           _childWrappers.push(child);
        
        return child;
    }
    
    public function remove(child:Wrapper):Wrapper {
        
        _childWrappers.remove(child);
        
        return child;
    }
    
    function get__clip():MovieClip { return cast(_target, MovieClip); }
    
    public function destroy():Void {
        
        if(_target.parent == this)
            removeChild(_target);
        
        _target = null;
        _childWrappers = null;
        
        if(_scriptId != null)
            ScriptInterpreter.removeInterpreter(_scriptId, _actionMap);
        _scriptId = null;
        
        _actionMap.destroy();
        _actionMap = null;
        
        _childMapper.unMap(this);
        _childMapper.destroy();
        _childMapper = null;
    }
    
    // =================================================================================================================
    //{ region                                              SCRIPTS
    // =================================================================================================================
    
    function script_goto(label:String):Void { _clip.gotoAndPlay(label); }
    function script_play():Void { _clip.play(); }
    function script_stop():Void { _clip.stop(); }
    
    function script_playFromTo(start:String, end:String, callback:Void->Void):Void {
        
        _clip.stop();
        
        if (end == null)
            end = start + "_end";
        
        MCUtils.playFromTo(_clip, start, end).onComplete(callback);
    }
    
    function script_playTo(end:String, callback:Void->Void):Void {
        
        _clip.stop();
        
        MCUtils.playTo(_clip, end).onComplete(callback);
    }
    
    //} endregion                                           SCRIPTS
    // =================================================================================================================
}