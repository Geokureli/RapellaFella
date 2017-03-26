package com.geokureli.rapella.art;

import com.geokureli.rapella.script.Action.ActionMap;
import com.geokureli.rapella.script.ScriptInterpreter;
import com.geokureli.rapella.utils.MCUtils;
import openfl.display.DisplayObjectContainer;

/**
 * ...
 * @author George
 */
class ScriptedWrapper extends Wrapper {
    
   var _scriptId:String;
   var _actionMap:ActionMap;
    
   public function new(target:DisplayObjectContainer) { super(target); }
    
   override function setDefaults() {
        super.setDefaults();
        
        _actionMap = new ActionMap(this);
        _actionMap.add("goto"      , script_goto      , ["label"        ]);
        _actionMap.add("playFromTo", script_playFromTo, ["start", "?end"], true);
        _actionMap.add("playTo"    , script_playTo    , ["start"        ], true);
        _actionMap.add("play"      , script_play);
        _actionMap.add("stop"      , script_stop);
    }
    
    override function init():Void { 
        super.init();
        
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