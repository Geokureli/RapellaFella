package com.geokureli.rapella.utils;

import hx.debug.Assert;
import motion.Actuate;
import motion.actuators.GenericActuator;
import motion.easing.Linear;
import openfl.display.MovieClip;

using com.geokureli.rapella.utils.StringUtils.Extender;

/**
 * ...
 * @author George
 */

typedef FrameActuator = GenericActuator<Dynamic->?Null<String>->Void>;

class MCUtils {
    
    static public function getFrame(target:MovieClip, frame:Dynamic):Int {
        
        if (!Assert.nonNull(target))
            return 0;
        
        if (Std.is(frame, Int)) {
            
            if (frame == -1)
                return target.totalFrames;
            
            if (Assert.isTrue(frame < target.totalFrames))
                return frame;
            
            return target.totalFrames;
            
        } else if(Assert.is(frame, String)) {
            
            for (label in target.currentLabels) {
                
                if (label.name == frame)
                    return label.frame;
            }
            Assert.fail('Missing label "$frame"');
        }
        
        return 0;
    }
    
    static public function hasFrame(target:MovieClip, frame:Dynamic):Bool
    {
        
        if (!Assert.nonNull(target))
            return false;
        
        if (Std.is(frame, Int))
            return frame == -1 || frame < target.totalFrames;
            
        if(Assert.is(frame, String)) {
            
            for (label in target.currentLabels) {
                
                if (label.name == frame)
                    return true;
            }
        }
        
        return false;
    }
    
    inline static public function playFromTo(target:MovieClip, start:Dynamic, end:Dynamic, duration:Float = -1, overwrite:Bool = false):FrameActuator {
        
        if (end == null) {
            
            end = -1;
            if(Std.is(start, String) && hasFrame(target, Std.string(start) + "_end"))
                end = Std.string(start) + "_end";
        }
        start = getFrame(target, start);
        end   = getFrame(target, end);
        if (duration < 0)
            duration = (end - start) / Game.fps;
        
        return Actuate.update(target.gotoAndStop, duration, [start], [end], overwrite)
            .snapping(true)
            .ease(Linear.easeNone);
    }
    
    inline static public function playTo(target:MovieClip, frame:Dynamic, duration:Float = -1, overwrite:Bool = false):FrameActuator {
        
        return playFromTo(target, target.currentFrame, frame, duration, overwrite);
    }
    
    inline static public function playFrom(target:MovieClip, frame:Dynamic, duration:Float = -1, overwrite:Bool = false):FrameActuator {
        
        return playFromTo(target, frame, target.currentFrame, duration, overwrite);
    }
}