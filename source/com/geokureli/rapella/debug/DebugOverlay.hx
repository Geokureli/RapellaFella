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
    
    public function new() {
       super();
        
       addChild(new DebugStats());
        
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
}