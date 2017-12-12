package com.geokureli.rapella.art.scenes;

import com.geokureli.rapella.art.HeroWrapper;
import com.geokureli.rapella.art.Wrapper;
import com.geokureli.rapella.debug.Debug;
import com.geokureli.rapella.physics.Collider;
import com.geokureli.rapella.utils.SwfUtils;
import openfl.display.MovieClip;
import openfl.display.Shape;
import openfl.geom.Point;
import openfl.geom.Rectangle;

class ActionScene extends Scene {
    
    static inline var RETICLE_MAX_DIS:Int = 100;
    static inline var CAMERA_DELAY:Int = 2;
    
    static var FOLLOW_ZONE_SIZE:Point = new Point(100, -1);
    
    var _reticle:Reticle;
    var _hero:HeroWrapper;
    var _cameraFollowZone:Rectangle;
    var _showReticle:Bool;
    var _wallData:Array<Collider>;
    
    /** Reusable point for shit */
    var _pt:Point;
    
    public function new(symbolId:String, data:Dynamic) { super(symbolId, data); }
    
    override function init():Void {
        
        SwfUtils.mouseDisableAll(target);
        
        var walls:Array<MovieClip> = new Array<MovieClip>();
        
        super.init();
        
        SwfUtils.getAll(target, 'wall' , walls);
        SwfUtils.getAll(target, 'cloud', walls);
        SwfUtils.getAll(target, 'ramp' , walls);
        
        _wallData = new Array<Collider>();
        for (wall in walls)
            _wallData.push(new Collider(wall));
        
        addWrapper(_hero = new HeroWrapper(cast target.getChildByName('hero')));
        _pt = new Point();
        
        addChild(_reticle = new Reticle())
            .visible = _showReticle;
        
        var lights:Array<MovieClip> = SwfUtils.getAll(target, 'light', new Array<MovieClip>());
        for (light in lights)
            light.gotoAndStop("on");
        
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
            (Game.mainStage.stageWidth  - FOLLOW_ZONE_SIZE.x) / 2,
            (Game.mainStage.stageHeight - FOLLOW_ZONE_SIZE.y) / 2,
            FOLLOW_ZONE_SIZE.x,
            FOLLOW_ZONE_SIZE.y
        );
    }
    
    override function initAssets():Void {
        
        super.initAssets();
        
        for (asset in _assets) {
            
            asset.click.add(onAssetClick.bind(asset));
        }
    }
    
    function onAssetClick(asset:ScriptedWrapper):Void
    {
        if(_hero.canUse(asset))
            asset.use.dispatch();
    }
    
    override public function update():Void {
        
        for (child in _childWrappers) {
            
           if (child.enabled
           &&  child.collider != null
           &&  (child.collider.moves || child.collider.trackTouches))
               child.updatePhysics(_wallData);
        }
        
        super.update();
        
        if (_cameraFollowZone != null)
            updateCamera();
    }
    
    function updateCamera():Void {
        
        if (_showReticle) {
            
            _pt.setTo(target.mouseX - _hero.centerMassX, target.mouseY - _hero.centerMassY);
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
    
    override public function addWrapper(child:Wrapper):Wrapper {
        
        if (child != null && child.collider != null && _wallData.indexOf(child.collider) == -1)
            _wallData.push(child.collider);
        
        return super.addWrapper(child);
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