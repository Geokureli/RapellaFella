package com.geokureli.rapella.art.ui;

import com.geokureli.rapella.art.Anim;
import com.geokureli.rapella.art.ScriptedWrapper;
import com.geokureli.rapella.utils.FuncUtils;
import openfl.display.DisplayObjectContainer;
import openfl.display.InteractiveObject;
import openfl.display.MovieClip;
import openfl.events.MouseEvent;

/**
 * ...
 * @author George
 */
class Btn extends Wrapper {
    
    public var state(default, set):BtnState;
    function set_state(value:BtnState):BtnState {
        
        if (value == null)
            value = BtnState.Up;
        
        state = value;
        updateFrame();
            
        return value;
    }
    public var mode(default, set):String;
    function set_mode(value:String):String {
        
        if (value == null)
            value = "";
        
        mode = value;
        updateFrame();
            
        return value;
    }
    
    var _events:Map<BtnEvent, Void->Void>;
    var _hitbox:InteractiveObject;
    var _wasPressed:Bool;

    public function new(target:MovieClip = null) { super(target); }
    
    override function setDefaults():Void {
        super.setDefaults();
        
        mode = "";
        state = BtnState.Up;
        
        _events = [
            BtnEvent.Click   => FuncUtils.doNothing,
            BtnEvent.Release => FuncUtils.doNothing,
            BtnEvent.Press   => FuncUtils.doNothing,
            BtnEvent.Over    => FuncUtils.doNothing,
            BtnEvent.Out     => FuncUtils.doNothing
        ];
    }
    
    override function init():Void {
        super.init();
        
        _clip.useHandCursor = true;
        _clip.buttonMode = true;
        _clip.gotoAndStop(1);
        updateFrame();
        
        if (_hitbox == null)
            _hitbox = target;
    }
    
    override function updateEnable():Void {
        super.updateEnable();
        
        if (enabled) addMouseListeners();
        else         removeMouseListeners();
    }
    
    override public function unwrap():Void {
        
        if (_clip != null) {
            
            _clip.useHandCursor = false;
            _clip.buttonMode = false;
            
        }
        
        super.unwrap();
        
        _hitbox = null;
    }
    
    inline function addMouseListeners() {
        
        _hitbox.addEventListener(MouseEvent.CLICK     , handleMouse);
        _hitbox.addEventListener(MouseEvent.MOUSE_DOWN, handleMouse);
        _hitbox.addEventListener(MouseEvent.MOUSE_OVER, handleMouse);
        _hitbox.addEventListener(MouseEvent.MOUSE_OUT , handleMouse);
    }
    
    inline function removeMouseListeners() {
        
        _hitbox.removeEventListener(MouseEvent.CLICK     , handleMouse);
        _hitbox.removeEventListener(MouseEvent.MOUSE_DOWN, handleMouse);
        _hitbox.removeEventListener(MouseEvent.MOUSE_OVER, handleMouse);
        _hitbox.removeEventListener(MouseEvent.MOUSE_OUT , handleMouse);
    }
    
    function handleMouse(e:MouseEvent):Void {
        
        switch(e.type) {
            case MouseEvent.MOUSE_OVER:
                state = _wasPressed ? BtnState.Down : BtnState.Over;
                dispatch(BtnEvent.Over);
            case MouseEvent.MOUSE_OUT:
                state = BtnState.Up;
                dispatch(BtnEvent.Out);
            case MouseEvent.CLICK:
                state = BtnState.Up;
                dispatch(BtnEvent.Click);
            case MouseEvent.MOUSE_UP:
                _wasPressed = false;
                dispatch(BtnEvent.Release);
            case MouseEvent.MOUSE_DOWN:
                _wasPressed = true;
                FuncUtils.addListenerOnce(Game.mainStage, MouseEvent.MOUSE_UP, handleMouse);
                state = BtnState.Down;
                dispatch(BtnEvent.Press);
        }
    }
    
    function updateFrame():Void {
        
        if (_clip != null) {
            
            if (Anim.hasFrame(_clip, mode + "_" + state))
                _clip.gotoAndStop(mode + "_" + state);
            else if (Anim.hasFrame(_clip, state))
                _clip.gotoAndStop(state);
        }
    }
    
    // =============================================================================
    //{ region                          CHAIN SETTERS
    // =============================================================================
    
    inline function addHandler(event:BtnEvent, handler:Void->Void):Btn {
        
        if (handler == null)
            handler = FuncUtils.doNothing;
        
        _events[event] = handler;
        return this;
    }
    
    function dispatch(event:BtnEvent):Void {
        
        _events[event]();
    }
    
    public function onClick(handler:Void->Void):Btn { return addHandler(BtnEvent.Click, handler); }
    public function onPress(handler:Void->Void):Btn { return addHandler(BtnEvent.Press, handler); }
    public function onOver (handler:Void->Void):Btn { return addHandler(BtnEvent.Over , handler); }
    public function onOut  (handler:Void->Void):Btn { return addHandler(BtnEvent.Out  , handler); }
   
    
    //} endregion                       CHAIN SETTERS
    // =============================================================================
    
    static public function caster(target:MovieClip):Btn { return new Btn(target); }
}

@:enum
abstract BtnState(String) {
    var Up       = "up";
    var Over     = "over";
    var Down     = "down";
}

@:enum
private abstract BtnEvent(String) {
    var Click   = "click";
    var Release = "release";
    var Press   = "press";
    var Over    = "over";
    var Out     = "out";
}
