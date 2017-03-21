package com.geokureli.rapella.debug;

import com.geokureli.rapella.input.Key;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;

/**
 * Houses all debug displays and tool, toggle via ~
 * @author George
 */
class DebugOverlay extends Sprite {
    
    static var _instance:DebugOverlay;
    
    var _console:DebugConsole;
    
    public function new() {
        super();
        
        _instance = this;
        
        addChild(new DebugStats());
        addChild(_console = new DebugConsole());
        _console.onForceShow.add(show);
        
        addEventListener(Event.ADDED_TO_STAGE, init);
    }
    
    function init(e:Event):Void {
        
        visible = false;
        
        Key.listen(Key.TILDE, handleKey);
    }
    
    function handleKey(isDown:Bool):Void {
        
        if (isDown)
            visible = !visible;
    }
    
    static public function show(value:Bool):Void {
        
        if (_instance != null)
            _instance.visible = value;
    }
}