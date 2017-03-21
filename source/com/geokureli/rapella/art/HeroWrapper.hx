package com.geokureli.rapella.art;
import com.geokureli.rapella.art.Wrapper;
import com.geokureli.rapella.input.Key;
import hx.debug.Assert;
import openfl.display.MovieClip;
import openfl.geom.Point;
import openfl.geom.Rectangle;

/**
 * ...
 * @author George
 */

class HeroWrapper extends Wrapper {
    
    static var WALK_SPEED:Point = new Point(10, 0);
    static var RUN_SPEED :Point = new Point(20, 0);
    
    public var centerMassX(get, never):Float;
    public var centerMassY(get, never):Float;
    public var walls:Array<MovieClip>;
    
    // --- KEYS
    var _keyLeft :Bool;
    var _keyRight:Bool;
    var _keyUp   :Bool;
    var _keyDown :Bool;
    var _keyShift:Bool;
    
    // --- BOUNDS
    var _originalScale:Point;
    var _bounds:Rectangle;
    var _centerMass:Point;
    var _left  (get, never):Float;
    var _right (get, never):Float;
    var _top   (get, never):Float;
    var _bottom(get, never):Float;
    
    var _anims:Map<String, Animation>;
    var _currentAnim:Animation;
    
    public function new(mc:MovieClip) {
        super(mc);
        
        _originalScale = new Point(scaleX, scaleY);
        _bounds = _target.getChildByName('bounds').getBounds(parent);
        _bounds.x -= x;
        _bounds.y -= y;
        _centerMass = new Point(
            _bounds.x + _bounds.width  / 2,
            _bounds.y + _bounds.height / 2
        );
        
        Key.bindAll([Key.RIGHT, Key.D], ">");
        Key.bindAll([Key.LEFT , Key.A], "<");
        Key.bindAll([Key.DOWN , Key.S], "v");
        Key.bindAll([Key.UP   , Key.W], "^");
        Key.bind(Key.SHIFT, "run");
    }
    
    override function setDefaults() {
        super.setDefaults();
        
        _isParent = true;
        _anims = [
            "idle" => new Animation("idle"),
            "walk" => new Animation("walk"),
            "run"  => new Animation("run" ),
            "jump" => new Animation("jump")
        ];
        
        play("idle");
    }
    
    override public function update():Void {
        
        var vx:Float = (Key.checkAction(">") ? 1 : 0) - (Key.checkAction("<") ? 1 : 0);
        var vy:Float = (Key.checkAction("v") ? 1 : 0) - (Key.checkAction("^") ? 1 : 0);
        
        if(vx != 0)
            scaleX = vx * _originalScale.x;
        
        var run:Bool = Key.checkAction("run");
        vx *= run ? RUN_SPEED.x : WALK_SPEED.x;
        vy *= run ? RUN_SPEED.y : WALK_SPEED.y;
        
        if (vx != 0) {
            
            for (wall in walls) {
                
                if ((_left > wall.x + wall.width && _left + vx < wall.x + wall.width)
                ||  (_right < wall.x && _right + vx > wall.x))
                    vx = 0;
                
                if ((_top > wall.y + wall.height && _top + vy < wall.y + wall.height)
                ||  (_bottom < wall.y && _bottom + vy > wall.y))
                    vy = 0;
            }
            
            if (run) play("run");
            else     play("walk");
            
        } else
            play("idle");
        
        x += vx;
        y += vy;
    }
    
    public function play(animKey:String, reset:Bool = false):Void
    {
        if (Assert.isTrue(_anims.exists(animKey), 'Missing [animKey=$animKey]')) {
            
            if (!reset && _currentAnim == _anims[animKey])
                return;
            
            if(_currentAnim != null)
                _currentAnim.stop();
            
            _currentAnim = _anims[animKey];
            _currentAnim.loop(_clip);
        }
    }
    
    function get__left  ():Float { return _target.x + _bounds.left  ; }
    function get__right ():Float { return _target.x + _bounds.right ; }
    function get__top   ():Float { return _target.y + _bounds.top   ; }
    function get__bottom():Float { return _target.y + _bounds.bottom; }
    
    public function get_centerMassX():Float { return _centerMass.x + x; }
    public function get_centerMassY():Float { return _centerMass.y + y; }
}
