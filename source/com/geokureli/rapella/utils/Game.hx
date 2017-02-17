package com.geokureli.rapella.utils;

import com.geokureli.rapella.camera.Camera;
import com.geokureli.rapella.debug.DebugOverlay;
import openfl.display.Stage;

/**
 * Global game vars for errybuddy
 * @author George
 */
class Game {
	
	static public var stage(default, null):Stage;
	static public var fps(default, null):Float;
	static public var spf(default, null):Float;
	
	static public var camera:Camera;
	
	static public function init(stage:Stage):Void {
		
		Game.stage = stage;
		fps = stage.frameRate;
		spf = 1 / fps;
	}
}