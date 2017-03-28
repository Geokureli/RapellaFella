package com.geokureli.rapella.art.ui;

import com.geokureli.rapella.utils.TimeUtils;
import flash.display.DisplayObjectContainer;
import openfl.text.TextField;
import com.geokureli.rapella.utils.ChildMap.ChildPriority;
import openfl.display.MovieClip;
import com.geokureli.rapella.utils.FuncUtils;
import com.geokureli.rapella.utils.SwfUtils;
import openfl.events.Event;
import openfl.display.Sprite;
import motion.Actuate;

class MenuWrapper extends ScriptedWrapper {
    
    var _data:Dynamic;
    var _isSelfContained:Bool;
    var _bg:MovieClip;
    var _message:TextField;
    
    public function new(target:DisplayObjectContainer, data:Dynamic) {
        _data = data;
        
        var ui:Sprite = SwfUtils.get(target, "ui");
        if (ui != null) {
            
            target = ui;
            _isSelfContained = true;
        }
        
        super(target);
    }
    
    override function setDefaults() {
        super.setDefaults();
        
        isParent = false;
        _scriptId = "menu";
        
        _childMapper.sortChildren = true;
        _childMap["uiBg"   ] = { field:"_bg"     , priority:ChildPriority.Optional };
        _childMap["message"] = { field:"_message", priority:ChildPriority.Optional };
    }
    
    override function init():Void {
        super.init();
        
        if (_bg != null && !_isSelfContained) {
            
            target = _bg;
            _children.remove(_bg);
            _isSelfContained = true;
            
            for (child in _children)
                SwfUtils.swapParent(child, _bg);
        }
        
        if (_isSelfContained) {
            
            target.alpha = 0;
            Actuate.tween(target, .5, { alpha:1 } ).onComplete(handleShowComplete);
            
        } else
            handleShowComplete();
    }
    
    function handleShowComplete():Void { }
    
    override public function destroy():Void {
        
        super.destroy();
        
        _data = null;
    }
}
