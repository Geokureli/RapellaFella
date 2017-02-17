package com.geokureli.rapella.art;

import com.geokureli.rapella.utils.MCUtils;
import motion.actuators.GenericActuator;
import openfl.display.MovieClip;

/**
 * ...
 * @author George
 */
class Animation{
	
	public var start(default, null):Dynamic;
	public var end(default, null):Dynamic;
	
	public function new(start:Dynamic, ?end:Dynamic) {
		
		this.start = start;
		this.end = end;
	}
	
	public function play(target:MovieClip):FrameActuator {
		
		return MCUtils.playFromTo(target, start, end);
	}
	
	public function loop(target:MovieClip, numLoops:Int = -1):FrameActuator {
		
		return MCUtils.playFromTo(target, start, end)
			.repeat(numLoops);
	}
}