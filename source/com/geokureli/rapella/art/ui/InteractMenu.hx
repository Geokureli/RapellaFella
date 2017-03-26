package com.geokureli.rapella.art.ui;

import com.geokureli.rapella.art.Wrapper;
import com.geokureli.rapella.utils.SwfUtils;
import haxe.Json;
import openfl.Assets;
import openfl.display.MovieClip;
import openfl.display.Sprite;
import openfl.utils.Object;

/**
 * ...
 * @author George
 */
class InteractMenu extends Wrapper {
	
	static public var instance(default, null):InteractMenu;
	
	private var _useBtn :MovieClip;
	private var _talkBtn:MovieClip;
	private var _lookBtn:MovieClip;
	
	private var _data:Object;
	
	public function new(target:MovieClip) {
		super(target);
		
		instance = this;
		
		_useBtn  = SwfUtils.get(target, 'useBtn' );
		_talkBtn = SwfUtils.get(target, 'talkBtn');
		_lookBtn = SwfUtils.get(target, 'lookBtn');
		
		_useBtn .gotoAndStop("up");
		_talkBtn.gotoAndStop("up");
		_lookBtn.gotoAndStop("up");
		
		//Json.parse(Assets.getText("data/Objects.json"));
	}
	
	static public function setTarget(target:Sprite):Void
	{
		target.addChild(instance);
		
		trace(Type.getClassName(Type.getClass(target)));
	}
}