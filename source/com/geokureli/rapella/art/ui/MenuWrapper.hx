package com.geokureli.rapella.art.ui;

import openfl.display.MovieClip;
import com.geokureli.rapella.utils.FuncUtils;
import com.geokureli.rapella.utils.SwfUtils;
import openfl.events.MouseEvent;
import openfl.events.Event;
import openfl.display.Sprite;
import motion.Actuate;

class MenuWrapper extends Wrapper {
    
    var _data:Dynamic;
    var _isSelfContained:Bool;
    
    public function new(target:Sprite, data:Dynamic) {
        _data = data;
        
        var ui:Sprite = SwfUtils.get(target, "ui");
        if (ui == null)
            ui = target;
        
        super(target);
    }
    
    override function setDefaults() {
        super.setDefaults();
        
        _scriptId = "menu";
    }
    
    override function onAddedToStage(e:Event = null) {
        super.onAddedToStage(e);
        
        FuncUtils.addListenerOnce(_target, Event.REMOVED, function (e:Event):Void { destroy(); } );
        
        if (_isSelfContained) {
            
            _target.alpha = 0;
            Actuate.tween(_target, .5, { alpha:1 } ).onComplete(handleShowComplete);
        }
        else
            handleShowComplete();
    }
    
    function handleShowComplete():Void { }
    
    override public function destroy():Void {
        super.destroy();
        
        _data = null;
    }
}
