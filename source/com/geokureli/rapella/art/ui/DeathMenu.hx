package com.geokureli.rapella.art.ui;

import com.geokureli.rapella.utils.SwfUtils;
import com.geokureli.rapella.utils.FuncUtils;
import openfl.events.MouseEvent;
import hx.event.Signal;
import openfl.display.Sprite;

class DeathMenu extends MenuWrapper {
    
    public var onClick(default, null):Signal<Void>;
    
    public function new(target:Sprite, data:Dynamic) { super(target, data); }
    
    override function setDefaults() {
        super.setDefaults();
        
        onClick = new Signal<Void>();
    }
    
    override function initChildren():Void {
        super.initChildren();
        
        FuncUtils.addListenerOnce(SwfUtils.getMC(_target, "restartButton"), MouseEvent.CLICK, handleClick);
    }
    
    public function handleClick(e:MouseEvent):Void {
        
        onClick.dispatch();
    }
}
