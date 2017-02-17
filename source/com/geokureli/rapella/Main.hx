package com.geokureli.rapella;

import com.geokureli.rapella.art.HeroWrapper;
import com.geokureli.rapella.art.Scene;
import com.geokureli.rapella.art.ui.InteractMenu;
import com.geokureli.rapella.camera.Camera;
import com.geokureli.rapella.debug.DebugOverlay;
import com.geokureli.rapella.input.Key;
import com.geokureli.rapella.utils.Game;
import com.geokureli.rapella.utils.SwfUtils;
import motion.Actuate;
import motion.easing.Linear;
import openfl.Assets;
import openfl.display.MovieClip;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.geom.Point;
import openfl.geom.Rectangle;

class Main extends Sprite {
	
	var _sceneLayer:Sprite;
	var _debugLayer:Sprite;
	var _currentScene:SceneWrapper;
	
	public function new () {
		
		super ();
		
		if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
	}
	
	function init(e:Event = null):Void {
		removeEventListener(Event.ADDED_TO_STAGE, init);
		
		// entry point
		Game.init(stage);
		Key.init(stage);
		Actuate.defaultEase = Linear.easeNone;
		Game.camera = new Camera();
		
		addChild(_sceneLayer = new Sprite());
		addChild(_debugLayer = new Sprite());
		_debugLayer.addChild(new DebugOverlay());
		
		_sceneLayer.addChild(_currentScene = new SceneWrapper(Assets.getMovieClip("library:SceneTest")));
		new InteractMenu(Assets.getMovieClip("library:InteractMenu"));
		
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}
	
	function onEnterFrame(e:Event):Void {
		
		_currentScene.update();
		
		Game.camera.update();
	}
}

class SceneWrapper extends Scene {
	
	static inline var RETICLE_MAX_DIS:Int = 100;
	static inline var CAMERA_DELAY:Int = 2;
	
	static var FOLLOW_ZONE_SIZE:Point = new Point(100, -1);
	
	var _reticle:Reticle;
	var _hero:HeroWrapper;
	var _cameraFollowZone:Rectangle;
	var _showReticle:Bool;
	
	/** Reusable point for shit */
	var _pt:Point;
	
	public function new(target:Sprite) { super(target); }
	
	override function initChildren() {
		super.initChildren();
		
		add(_hero = new HeroWrapper(cast _target.getChildByName('hero')));
		_pt = new Point();
		
		addChild(_reticle = new Reticle())
			.visible = _showReticle;
		
		var lights:Array<MovieClip> = SwfUtils.getAll(_target, 'light', new Array<MovieClip>());
		for (light in lights)
			light.gotoAndStop("on");
		
		_hero.walls = SwfUtils.getAll(_target, 'wall', new Array<MovieClip>());
		
		SwfUtils.getMC(_target, 'well').gotoAndStop("echoOpen");
		//SwfUtils.get(_target, 'bg').cacheAsBitmap = true;
	}
	
	override function initCamera():Void {
		super.initCamera();
		
			// --- FOLLOW ZONE CAN'T BE BIGGER THAN THE BOUNDS
		if (FOLLOW_ZONE_SIZE.x == -1 || FOLLOW_ZONE_SIZE.x > _cameraBounds.width)
			FOLLOW_ZONE_SIZE.x = _cameraBounds.width;
		if (FOLLOW_ZONE_SIZE.y == -1 || FOLLOW_ZONE_SIZE.y > _cameraBounds.height)
			FOLLOW_ZONE_SIZE.y = _cameraBounds.height;
		
		_cameraFollowZone = new Rectangle(
			(Game.stage.stageWidth  - FOLLOW_ZONE_SIZE.x) / 2,
			(Game.stage.stageHeight - FOLLOW_ZONE_SIZE.y) / 2,
			FOLLOW_ZONE_SIZE.x,
			FOLLOW_ZONE_SIZE.y
		);
	}
	
	override public function update():Void {
		super.update();
		
		if (_cameraFollowZone != null) 
			updateCamera();
	}
	
	function updateCamera():Void {
		
		if (_showReticle) {
			
			_pt.setTo(_target.mouseX - _hero.centerMassX, _target.mouseY - _hero.centerMassY);
			if (_pt.x * _pt.x + _pt.y * _pt.y > RETICLE_MAX_DIS * RETICLE_MAX_DIS)
				_pt.normalize(RETICLE_MAX_DIS);
			_reticle.x = _pt.x + _hero.centerMassX;
			_reticle.y = _pt.y + _hero.centerMassY;
			_pt.setTo(_pt.x / 2 + _hero.centerMassX, _pt.y / 2 + _hero.centerMassY);
			
		} else
			_pt.setTo(_hero.centerMassX, _hero.centerMassY);
		
		var cam:Point = new Point(Game.camera.x, Game.camera.y);
		
		// --- KEEP PLAYER IN FOLLOW ZONE
		if      (cam.x > _cameraFollowZone.right  - _pt.x) cam.x = _cameraFollowZone.right  - _pt.x;
		else if (cam.x < _cameraFollowZone.left   - _pt.x) cam.x = _cameraFollowZone.left   - _pt.x;
		if      (cam.y > _cameraFollowZone.bottom - _pt.y) cam.y = _cameraFollowZone.bottom - _pt.y;
		else if (cam.y < _cameraFollowZone.top    - _pt.y) cam.y = _cameraFollowZone.top    - _pt.y;
		
		Game.camera.centerX = _hero.x;
		Game.camera.centerY = _hero.y;
	}
}


class Reticle extends Shape {
	
	static inline var RADIUS:Int = 18;
	static var CROSSHAIR_SIZE:Int = Std.int(RADIUS / 5 * 6);
	
	public function new() {
		super();
		
		graphics.lineStyle(2, 0xFF0000);
		graphics.drawCircle(0, 0, RADIUS);
		graphics.moveTo(-CROSSHAIR_SIZE, 0);
		graphics.lineTo( CROSSHAIR_SIZE, 0);
		graphics.moveTo(0, -CROSSHAIR_SIZE);
		graphics.lineTo(0,  CROSSHAIR_SIZE);
	}
}