package com.geokureli.rapella.art.ui;

import flash.display.DisplayObjectContainer;
import openfl.text.TextField;
import com.geokureli.rapella.utils.ChildMap.ChildPriority;
import openfl.display.MovieClip;
import com.geokureli.rapella.utils.FuncUtils;
import com.geokureli.rapella.utils.SwfUtils;
import openfl.events.Event;
import openfl.display.Sprite;
import motion.Actuate;

class MenuWrapper extends Wrapper {
    
    var _data:Dynamic;
    var _isSelfContained:Bool;
    var _autoDestroyListener:Dynamic->Void;
    var _bg:MovieClip;
    var _message:TextField;
    
    public function new(target:DisplayObjectContainer, data:Dynamic) {
        _data = data;
        
        var ui:Sprite = SwfUtils.get(target, "ui");
        if (ui != null)
            target = ui;
        
        super(target);
    }
    
    override function setDefaults() {
        super.setDefaults();
        
        _scriptId = "menu";
        
        _childMapper.sortChildren = true;
        _childMap["bg"     ] = { field:"_bg"     , priority:ChildPriority.Optional };
        _childMap["message"] = { field:"_message", priority:ChildPriority.Optional };
    }
    
    override function onAddedToStage(e:Event = null) {
        super.onAddedToStage(e);
        
        _autoDestroyListener = FuncUtils.addListenerOnce(_target, Event.REMOVED, function(_):Void { destroy(); });
        
        if (_isSelfContained) {
            
            _target.alpha = 0;
            Actuate.tween(_target, .5, { alpha:1 } ).onComplete(handleShowComplete);
        }
        else
            handleShowComplete();
    }
    
    function handleShowComplete():Void { }
    
    override public function destroy():Void {
        
        if (_autoDestroyListener != null)
            _target.removeEventListener(Event.REMOVED, _autoDestroyListener);
        
        super.destroy();
        
        _data = null;
    }
}
