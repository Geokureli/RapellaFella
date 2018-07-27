package com.geokureli.rapella.art;

import lime.app.Event;

import openfl.display.Sprite;
import openfl.display.DisplayObjectContainer;
import openfl.events.MouseEvent;
import openfl.filters.BitmapFilter;

import com.geokureli.rapella.art.scenes.Scene;
import com.geokureli.rapella.art.ui.UIColors;
import com.geokureli.rapella.script.Action.ActionMap;
import com.geokureli.rapella.script.ScriptInterpreter;

import hx.debug.Assert;

/**
 * ...
 * @author George
 */
class ScriptedWrapper extends Wrapper {

    public var click(default, null):Event<Void->Void>;
    public var parse(default, null):Event<Void->Void>;
    public var use  (default, null):Event<Void->Void>;
    
    var _scriptId:String;
    var _fieldMap:Map<String, Dynamic->String->Scene->Void>;
    var _actionMap:ActionMap;
    var _filters:Array<BitmapFilter>;
    var _overGlow:BitmapFilter;
    
    public function new(target:DisplayObjectContainer) { super(target); }
    
    override function setDefaults() {
        super.setDefaults();
        
        _overGlow = UIColors.GLOW_CANT_USE;
        
        click = new Event<Void->Void>();
        parse = new Event<Void->Void>();
        use   = new Event<Void->Void>();
        
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
            , "use"   => addUseAction
            , "touch" => addTouchAction
            , "leave" => addLeaveAction
            ];
    }

    override public function parseData(data:Dynamic, scene:Scene):Void {
        
        var target:String;
        var action;
        var splitIndex;
        for (field in Reflect.fields(data)) {
            
            target = null;
            action = field;
            splitIndex = field.indexOf(":");
            
            if (splitIndex != -1) {
                
                action = field.substr(0, splitIndex);
                target = field.substr(splitIndex + 1);
            }
            
            if (_fieldMap.exists(action))
                _fieldMap[action](Reflect.field(data, field), target, scene);
        }
        
        parse.dispatch();
    }
    
    override function init():Void { 
        super.init();
        
        if (target != null) {
            
            _filters = target.filters;
            
            if (_scriptId == null && target.name.indexOf("instance") != 0)
                _scriptId = target.name;
        }
        
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
    
    function addListenerAction(event:Event<Void->Void>, action:Dynamic, params:String, scene:Scene):Void {
        
        event.add(ScriptInterpreter.run.bind(action));
    }
    
    public function addClickListener(listener:Void->Void):Void {
        
        cast (target, Sprite).useHandCursor = true;
        target.mouseEnabled  = true;
        target.mouseChildren = true;
        target.addEventListener(MouseEvent.CLICK     , onClick);
        target.addEventListener(MouseEvent.MOUSE_OVER, onOverOut);
        target.addEventListener(MouseEvent.MOUSE_OUT , onOverOut);
        click.add(listener);
    }
    
    static inline function getSceneTarget(params:String, scene:Scene):ScriptedWrapper {
        
        var ret = null;
        if (params != null && params != "")
            ret = scene.findAsset(params);
        
        return ret;
    }
    
    function addTouchAction(action:Dynamic, params:String, scene:Scene):Void {
        
        if (params == null)
            params = "hero";
        var target = getSceneTarget(params, scene);
        
        //TODO: Set or check collider.trackTouches
        //Notes: be smart about the number the assets sensing touches (either in json or automated here)
        
        if (target.collider.onTouch[this] == null)
            target.collider.onTouch[this] = new Event<Void->Void>();
        target.collider.onTouch[this].add(ScriptInterpreter.run.bind(action));
    }
    
    function addLeaveAction(action:Dynamic, params:String, scene:Scene):Void {
        
        if (params == null)
            params = "hero";
        var target = getSceneTarget(params, scene);
        
        if (target.collider.onSeparate[this] == null)
            target.collider.onSeparate[this] = new Event<Void->Void>();
        target.collider.onSeparate[this].add(ScriptInterpreter.run.bind(action));
    }
    
    function addClickAction(action:Dynamic, params:String, scene:Scene):Void {
        
        addClickListener(ScriptInterpreter.run.bind(action));
    }
    
    function addUseAction(action:Dynamic, params:String, scene:Scene):Void {
        
        if (params == null)
            params = "hero";
        var target = getSceneTarget(params, scene);
        
        addClickListener(target.checkCanUse.bind(action, this));
        
        if (target.collider.onTouch[this] == null)
            target.collider.onTouch[this] = new Event<Void->Void>();
        target.collider.onTouch[this].add(onTouchUser);
        
        if (target.collider.onSeparate[this] == null)
            target.collider.onSeparate[this] = new Event<Void->Void>();
        target.collider.onSeparate[this].add(onLeaveUser);
    }
    
    function onTouchUser():Void {
        
        var filterVisible = _filters.indexOf(_overGlow) != -1;
        if (filterVisible)
            _filters.remove(_overGlow);
        
        _overGlow = UIColors.GLOW_CAN_USE;
        
        if (filterVisible) {
            
            _filters.push(_overGlow);
            target.filters = _filters;
        }
    }
    
    function onLeaveUser():Void {
        
        var filterVisible = _filters.indexOf(_overGlow) != -1;
        if (filterVisible)
            _filters.remove(_overGlow);
        
        _overGlow = UIColors.GLOW_CANT_USE;
        
        if (filterVisible) {
            
            _filters.push(_overGlow);
            target.filters = _filters;
        }
    }
    
    function checkCanUse(action:Dynamic, target:ScriptedWrapper):Void {
        
        if(collider.isTouching(target)) {
            
            ScriptInterpreter.run(action);
            use.dispatch();
        }
    }
    
    function onClick(e:MouseEvent):Void {
        
        click.dispatch();
    }
    
    function onOverOut(e:MouseEvent):Void {
        
        if (e.type == MouseEvent.MOUSE_OVER) {
            
            if (_filters.indexOf(_overGlow) == -1) {
                
                _filters.push(_overGlow);
                target.filters = _filters;
            }
        } else if (_filters.indexOf(_overGlow) != -1) {
            
            _filters.remove(_overGlow);
            target.filters = _filters;
        }
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