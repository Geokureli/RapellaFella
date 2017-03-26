package com.geokureli.rapella.art.ui;

import openfl.display.MovieClip;
import openfl.display.DisplayObjectContainer;
import com.geokureli.rapella.utils.SwfUtils;
import com.geokureli.rapella.utils.FuncUtils;
import openfl.events.MouseEvent;
import hx.event.Signal;

class DeathMenu extends MenuWrapper {
    
    public var onClick(default, null):Signal<Void>;
    
    var _restartButton:MovieClip;
    
    public function new(target:DisplayObjectContainer, data:Dynamic) { super(target, data); }
    
    override function setDefaults() {
        super.setDefaults();
        
        onClick = new Signal<Void>();
        _childMap["restartButton"] = "_restartButton";
    }
    
    override function init():Void {
        super.init();
        
        FuncUtils.addListenerOnce(_restartButton, MouseEvent.CLICK, handleClick);
    }
    
    public function handleClick(e:MouseEvent):Void {
        
        onClick.dispatch();
    }
}
