package com.geokureli.rapella.art;

import com.geokureli.rapella.utils.TimeUtils;
import hx.debug.Assert;
import motion.Actuate;
import motion.actuators.IGenericActuator;
import openfl.display.MovieClip;
import openfl.events.Event;

/**
 * ...
 * @author George
 */
class AnimDef {
    
    public var start(default, null):Dynamic;
    public var end(default, null):Dynamic;
    public var activeAnim(default, null):Anim;
    public var loop(default, null):Bool;
    
    public function new(start:Dynamic, ?end:Dynamic, loop:Bool = true) {
        
        this.start = start;
        this.end = end;
        this.loop = loop;
    }
    
    public function play(target:MovieClip):Anim {
        
        stop();
        
        if (end == null && !Anim.hasFrame(target, start + Anim.END)) {
            
            target.gotoAndStop(start);
            return null;
        }
        
        return activeAnim = Anim.playFromTo(target, start, end)
            .setRepeat(loop ? -1 : 0);
    }
    
    inline public function stop():Void {
        
        if (activeAnim != null)
            activeAnim.destroy();
        
        activeAnim = null;
    }
    
    static inline public function create    (start:Dynamic, ?end:Dynamic):AnimDef { return new AnimDef(start, end, false); }
    static inline public function createLoop(start:Dynamic, ?end:Dynamic):AnimDef { return new AnimDef(start, end, true); }
}

class Anim {
    
    static inline public var END:String = "_end";
    
    public var repeat:Int;
    public var onComplete:Void->Void;
    public var onRepeat:Void->Void;
    
    var _target:MovieClip;
    var _start:Int;
    var _end:Int;
    var _repeatCount:Int;
    var _replayTimer:IGenericActuator;
    
    public function new (target:MovieClip, start:Dynamic, end:Dynamic) {
        
        _target = target;
        
        if (end == null) {
            
            end = -1;
            if(Std.is(start, String) && hasFrame(target, Std.string(start) + END))
                end = Std.string(start) + END;
        }
        
        _start = getFrame(target, start);
        _end = getFrame(target, end);
        repeat = 0;
        _repeatCount = 0;
        
        restart();
    }
    
    private function update(e:Event):Void {
        
        if (_target.currentFrame == _end) {
            
            _target.stop();
            _target.removeEventListener(Event.ENTER_FRAME, update);
            if (++_repeatCount > repeat && repeat > -1) {
                
                if (onComplete != null)
                    onComplete();
                //destroy();
            }
            else {
                
                if (onRepeat != null)
                    onRepeat();
                _replayTimer = TimeUtils.delay(restart);
            }
        } else if (!_target.isPlaying)
            _target.play();
    }
    
    function restart():Void {
        
        _target.addEventListener(Event.ENTER_FRAME, update);
        _target.gotoAndPlay(_start);
    }
    
    public function destroy():Void {
        
        Actuate.stop(_replayTimer);
        
        _target.removeEventListener(Event.ENTER_FRAME, update);
        _target = null;
        onComplete = null;
        onRepeat = null;
    }
    
    // =============================================================================
    //{ region                          CHAIN SETTERS
    // =============================================================================
    
    public function setRepeat(num:Int = -1):Anim {
        
        repeat = num;
        return this;
    }
    
    public function setOnComplete(listener:Void->Void):Anim {
        
        onComplete = listener;
        return this;
    }
    
    public function setOnRepeat(listener:Void->Void):Anim {
        
        onRepeat = listener;
        return this;
    }
    
    //} endregion                       CHAIN SETTERS
    // =============================================================================
    
    // =============================================================================
    //{ region                          STATIC
    // =============================================================================
    
    static public function getFrame(target:MovieClip, frame:Dynamic):Int {
        
        if (!Assert.nonNull(target))
            return 0;
        
        if (Std.is(frame, Int)) {
            
            if (frame == -1)
                return target.totalFrames;
            
            if (Assert.isTrue(frame <= target.totalFrames))
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
    
    static public function hasFrame(target:MovieClip, frame:Dynamic):Bool {
        
        if (!Assert.nonNull(target))
            return false;
        
        if (Std.is(frame, Int))
            return frame == -1 || frame <= target.totalFrames;
            
        if(Assert.is(frame, String)) {
            
            for (label in target.currentLabels) {
                
                if (label.name == frame)
                    return true;
            }
        }
        
        return false;
    }
    
    inline static public function playFromTo(target:MovieClip, start:Dynamic, end:Dynamic):Anim {
        
        return new Anim(target, start, end);
    }
    
    inline static public function playTo(target:MovieClip, frame:Dynamic):Anim {
        
        return playFromTo(target, target.currentFrame, frame);
    }
    
    inline static public function playFrom(target:MovieClip, frame:Dynamic):Anim {
        
        return playFromTo(target, frame, target.currentFrame);
    }
    
    //} endregion                       STATIC
    // =============================================================================
}