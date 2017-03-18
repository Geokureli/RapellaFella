package com.geokureli.rapella.art;
import hx.debug.Assert;
import haxe.Constraints.Function;
import com.geokureli.rapella.ScriptInterpreter.IScriptInterpretable;
import com.geokureli.rapella.ScriptInterpreter.Action;
import openfl.events.Event;
import openfl.display.Sprite;
import openfl.display.MovieClip;

/**
 * ...
 * @author George
 */
class Wrapper extends Sprite
    implements IScriptInterpretable{
    
    var _target:Sprite;
    var _clip(get, never):MovieClip;
    var _childWrappers:Array<Wrapper>;
    
    var _isParent:Bool;
    var enabled:Bool;
    var _scriptId:String;
    var _scriptHandlers:Map<String, Function>;
    
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
        
        if(_scriptId != null)
            ScriptInterpreter.addInterpreter(_scriptId, this);
        
        initChildren();
        
        if (target.stage == null)
           _target.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        else
           onAddedToStage();
    }
    
    function setDefaults() {
        
        enabled = true;
        
        _childWrappers = new Array<Wrapper>();
        _isParent = _target.parent == null;
        _scriptHandlers = [
            "goto" => script_goto,
            "play" => script_play
        ];
    }
    
    function initChildren():Void { }
    
    function onAddedToStage(e:Event = null) {
        
        _target.removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
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
            ScriptInterpreter.removeInterpreter(_scriptId, this);
        _scriptId = null;
    }
    
    // =================================================================================================================
    //{ region                                              SCRIPTS
    // =================================================================================================================
    
    public function runScript(action:Action):Void {
        
        if (Assert.isTrue(_scriptHandlers.exists(action.func), 'Invalid func=${action.func}'))
            _scriptHandlers[action.func](action);
        else
            action.complete();
    }
    
    function script_goto(action:Action):Void {
        
        _clip.gotoAndPlay(action.args[0]);
        action.complete();
    }
    
    function script_play(action:Action):Void {
        
        _clip.play();
        action.complete();
    }
    
    //} endregion                                           SCRIPTS
    // =================================================================================================================
}