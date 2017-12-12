package com.geokureli.rapella.art;

import openfl.display.Sprite;
import openfl.events.MouseEvent;
import hx.event.Signal;
import com.geokureli.rapella.script.Action.ActionMap;
import com.geokureli.rapella.script.ScriptInterpreter;
import openfl.display.DisplayObjectContainer;

/**
 * ...
 * @author George
 */
class ScriptedWrapper extends Wrapper {

    public var click(default, null):Signal<Void>;
    public var parse(default, null):Signal<Void>;
    public var use  (default, null):Signal<Void>;
    public var touch(default, null):Signal<Void>;
    public var leave(default, null):Signal<Void>;
    
    var _scriptId:String;
    var _fieldMap:Map<String, Dynamic->Void>;
    var _actionMap:ActionMap;
    
    public function new(target:DisplayObjectContainer) { super(target); }
    
    override function setDefaults() {
        super.setDefaults();
        
        click = new Signal<Void>();
        parse = new Signal<Void>();
        use   = new Signal<Void>();
        touch = new Signal<Void>();
        leave = new Signal<Void>();
        
        _actionMap = new ActionMap(this);
        _actionMap.add("goto"       , script_goto       , ["label"        ]);
        _actionMap.add("gotoAndStop", script_gotoAndStop, ["label"        ]);
        _actionMap.add("gotoAndPlay", script_gotoAndPlay, ["label"        ]);
        _actionMap.add("playFromTo" , script_playFromTo , ["start", "?end"], true);
        _actionMap.add("playTo"     , script_playTo     , ["start"        ], true);
        _actionMap.add("play"       , script_play);
        _actionMap.add("stop"       , script_stop);
        
        _fieldMap =
            [ "init"  => addListenerAction.bind(parse)
            , "click" => addClickAction
            , "use"   => addListenerAction.bind(use  )
            , "touch" => addListenerAction.bind(touch)
            , "leave" => addListenerAction.bind(leave)
            ];
    }

    override public function parseData(data:Dynamic):Void {
        
        for (field in Reflect.fields(data)) {
            
            if (_fieldMap.exists(field))
                _fieldMap[field](Reflect.field(data, field));
        }
        
        parse.dispatch();
    }
    
    override function init():Void { 
        super.init();
        
        if (_scriptId == null && target != null && target.name.indexOf("instance") != 0)
            _scriptId = target.name;
        
        if(_scriptId != null)
            ScriptInterpreter.addInterpreter(_scriptId, _actionMap);
    }
    
    override public function unwrap():Void {
        super.unwrap();
        
        if(_scriptId != null)
            ScriptInterpreter.removeInterpreter(_scriptId, _actionMap);
    }
    
    override public function destroy():Void {
        super.destroy();
        
        _scriptId = null;
        
        _actionMap.destroy();
        _actionMap = null;
    }
    
    // =================================================================================================================
    //{ region                                              EVENTS
    // =================================================================================================================
    
    function addListenerAction(signal:Signal<Void>, action:Dynamic):Void
    {
        signal.add(ScriptInterpreter.run.bind(action));
    }
    
    function addClickListener(listener:Void->Void):Void
    {
        cast (target, Sprite).useHandCursor = true;
        target.mouseEnabled  = true;
        target.mouseChildren = true;
        target.addEventListener(MouseEvent.CLICK     , onClick);
        target.addEventListener(MouseEvent.MOUSE_OVER, onOverOut);
        target.addEventListener(MouseEvent.MOUSE_OUT , onOverOut);
        click.add(listener);
    }
    
    function addClickAction(action:Dynamic):Void
    {
        addClickListener(ScriptInterpreter.run.bind(action));
    }
    
    function addUseAction(action:Dynamic, targetName:String):Void
    {
        addClickListener(checkCanUse.bind(action, targetName));
    }
    
    function checkCanUse(action:Dynamic, targetName:String):Void->Void
    {
        return null;
    }
    
    function onClick(e:MouseEvent):Void
    {
        click.dispatch();
    }
    
    function onOverOut(e:MouseEvent):Void
    {
        
    }
    
    //} endregion                                           EVENTS
    // =================================================================================================================
    
    // =================================================================================================================
    //{ region                                              SCRIPTS
    // =================================================================================================================
    
    function script_gotoAndStop(label:String):Void { _clip.gotoAndStop(label); }
    function script_gotoAndPlay(label:String):Void { _clip.gotoAndPlay(label); }
    function script_goto(label:String):Void { _clip.gotoAndPlay(label); }
    function script_play():Void { _clip.play(); }
    function script_stop():Void { _clip.stop(); }
    
    function script_playFromTo(start:String, end:String, callback:Void->Void):Void {
        
        _clip.stop();
        
        Anim.playFromTo(_clip, start, end).setOnComplete(callback);
    }
    
    function script_playTo(end:String, callback:Void->Void):Void {
        
        _clip.stop();
        
        Anim.playTo(_clip, end).setOnComplete(callback);
    }
    
    //} endregion                                           SCRIPTS
    // =================================================================================================================
}