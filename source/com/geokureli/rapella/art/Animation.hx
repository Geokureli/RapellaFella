package com.geokureli.rapella.art;

import motion.Actuate;
import com.geokureli.rapella.utils.MCUtils;
import openfl.display.MovieClip;

/**
 * ...
 * @author George
 */
class Animation{
    
    public var start(default, null):Dynamic;
    public var end(default, null):Dynamic;
    public var activeActuator(default, null):FrameActuator;
    
    public function new(start:Dynamic, ?end:Dynamic) {
        
        this.start = start;
        this.end = end;
    }
    
    public function play(target:MovieClip):FrameActuator {
        
        return MCUtils.playFromTo(target, start, end);
    }
    
    inline public function loop(target:MovieClip, numLoops:Int = -1):FrameActuator {
        
        stop();
        
        return activeActuator = MCUtils.playFromTo(target, start, end)
           .repeat(numLoops);
    }
    
    inline public function stop():Void {
        
        if (activeActuator != null)
            Actuate.stop(activeActuator);
        
        activeActuator = null;
    }
}