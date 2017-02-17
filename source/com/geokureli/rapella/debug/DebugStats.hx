package com.geokureli.rapella.debug;

import openfl.Lib;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import openfl.system.System;
import openfl.text.TextField;
import openfl.text.TextFormat;

/**
 * ...
 * @author George
 */
class DebugStats extends Sprite{
	
	static inline var BG_COLOR:Int = 0x000033;
	
	static inline var GRAPH_WIDTH :Int = 70;
	static inline var GRAPH_HEIGHT:Int = 50;
	static inline var TEXT_HEIGHT :Int = 50;
	static inline var END_PX	  :Int = GRAPH_WIDTH - 1;
	
	var _prevTimer:Int;
	var _prevSecond:Int;
	var _desiredFps:Int;
	var _tickScaler:Float;
	var _msTally:Int;
	var _memMax:Int;
	var _framesTracked:Int;
	
	var _text:TextField;
	var _graph:BitmapData;
	var _rect:Rectangle;
	
	public function new() {
		super();
		
		_text = new TextField();
		_text.width = GRAPH_WIDTH;
		_text.height = TEXT_HEIGHT;
		//_text.condenseWhite = true;
		_text.selectable = false;
		_text.mouseEnabled = false;
		_text.defaultTextFormat = new TextFormat("_sans", 9, 0xFFFFFF, null, null, null, null, null, null, null, null, null, -2);
		this.addChild(_text);
		
		graphics.beginFill(Colors.bg);
		graphics.drawRect(0, 0, GRAPH_WIDTH, TEXT_HEIGHT);
		graphics.endFill();
		
		_graph = new BitmapData(GRAPH_WIDTH, GRAPH_HEIGHT, false, Colors.bg);
		graphics.beginBitmapFill(_graph, new Matrix(1, 0, 0, 1, 0, TEXT_HEIGHT));
		graphics.drawRect(0, TEXT_HEIGHT, GRAPH_WIDTH, GRAPH_HEIGHT);
		
		_rect = new Rectangle(GRAPH_WIDTH - 1, 0, 1, GRAPH_HEIGHT);			
		
		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
	}
	
	private function onAddedToStage(e:Event):Void {
		
		_desiredFps = Std.int(stage.frameRate);
		_tickScaler = (_desiredFps - 1) / _desiredFps;
		_msTally = 1000;
		_prevTimer = Lib.getTimer();
		_prevSecond = _prevTimer;
		addEventListener(Event.ENTER_FRAME, onUpdate);
	}
	
	private function onRemovedFromStage(e:Event):Void {
		
		removeEventListener(Event.ENTER_FRAME, onUpdate);
	}
	
	private function onUpdate(e:Event):Void {
		
		_framesTracked++;
		
		var t:Int = Lib.getTimer();
		var ms:Int = t - _prevTimer;
		_prevTimer += ms;
		_msTally = Std.int(_msTally * _tickScaler + ms);
		
		if (t - _prevSecond > 1000) {
			_prevSecond += 1000;
			
			var mem:Int = Std.int(System.totalMemory * 0.000000954);
			_memMax = _memMax > mem ? _memMax : mem;
			
			var fps:Int = Std.int(_desiredFps * 1000 / _msTally);
			var fpsGraph:Int = GRAPH_HEIGHT - Std.int(fps / _desiredFps * GRAPH_HEIGHT);
			if (fpsGraph > GRAPH_HEIGHT)
				fpsGraph = GRAPH_HEIGHT;
			
			var memGraph:Int = GRAPH_HEIGHT - normalizeMem(mem);
			var memMaxGraph:Int = GRAPH_HEIGHT - normalizeMem(_memMax);
			
			//milliseconds since last frame -- this fluctuates quite a bit
			var msGraph:Int = Std.int(GRAPH_HEIGHT - (GRAPH_HEIGHT * _msTally / _desiredFps));
			_graph.scroll(-1, 0);
			
			_graph.fillRect(_rect, Colors.bg);
			_graph.lock();
			_graph.setPixel(END_PX, fpsGraph   , Colors.fps);
			_graph.setPixel(END_PX, memGraph   , Colors.mem);
			_graph.setPixel(END_PX, memMaxGraph, Colors.memMax);
			_graph.setPixel(END_PX, msGraph    , Colors.ms);
			_graph.unlock();
			
			_text.htmlText
				= 'FPS: ${font(fps, Colors.fps)}\n'
				+ 'MEM: ${font(mem, Colors.mem)}/${font(_memMax, Colors.memMax)}';
		}
	}
	
	function font(text:Dynamic, color:Int):String {
		
		return '<font color="#${StringTools.hex(color)}">$text</font>';
	}
	
	function normalizeMem(mem:Float):Int {
		
		return Std.int(Math.min(GRAPH_HEIGHT, Math.sqrt(Math.sqrt(mem * 5000))) - 2);
	}
}

class Colors {

	inline static public var bg    :Int = 0x000033;
	inline static public var fps   :Int = 0xffff00;
	inline static public var ms    :Int = 0x00ff00;
	inline static public var mem   :Int = 0x00ffff;
	inline static public var memMax:Int = 0xff0070;
}
