package com.geokureli.rapella.art;
import com.geokureli.rapella.art.Anim.AnimDef;
import com.geokureli.rapella.art.ScriptedWrapper;
import com.geokureli.rapella.debug.Debug;
import com.geokureli.rapella.input.Key;
import com.geokureli.rapella.utils.SwfUtils;
import hx.debug.Assert;
import openfl.display.MovieClip;
import openfl.geom.Point;
import openfl.geom.Rectangle;

/**
 * ...
 * @author George
 */

class HeroWrapper extends ScriptedWrapper {
    
    // --- ZTHE CLOSEST YOU CAN GET TO A WALL5
    static inline var BUFFER:Float = 0.1;
    static inline var JUMP_HEIGHT:Float = -50;
    static inline var JUMP_APEX_TIME:Float = 7;// --- FRAMES
    static inline var JUMP_VELOCITY:Float = 2 * JUMP_HEIGHT / JUMP_APEX_TIME;
    static inline var GRAVITY:Float = -2 * JUMP_HEIGHT / (JUMP_APEX_TIME * JUMP_APEX_TIME);
    
    static var WALK_SPEED:Point = new Point(10, 10);
    static var RUN_SPEED :Point = new Point(20, 20);
    
    public var centerMassX(get, never):Float;
    public var centerMassY(get, never):Float;
    public var walls:Array<MovieClip>;
    
    // --- JUMP
    var _jumpHeight  :Float;
    var _jumpVelocity:Float;
    var _gravity     :Float;
    
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
    
    var _anims:Map<String, AnimDef>;
    var _currentAnim:String;
    var _v:Point;
    var _onGround:Bool;
    var _running:Bool;
    var _canMove:Bool;
    
    public function new(mc:MovieClip) { super(mc); }
    
    override function setDefaults() {
        super.setDefaults();
        
        _v = new Point();
        
        isParent = true;
        _anims = [
            "idle" => AnimDef.createLoop("idle"),
            "walk" => AnimDef.createLoop("walk"),
            "run"  => AnimDef.createLoop("run" ),
            "jump" => AnimDef.create    ("jump", "fall"),
            "fall" => AnimDef.create    ("fall"),
            "land" => AnimDef.create    ("land"),
        ];
        
        Key.bindAll([Key.RIGHT, Key.D], ">");
        Key.bindAll([Key.LEFT , Key.A], "<");
        Key.bindAll([Key.UP   , Key.W, Key.SPACE], "jump");
        Key.bind(Key.SHIFT, "run");
    }
    
    override function init():Void {
        super.init();
        
        play("idle");
        
        _originalScale = new Point(scaleX, scaleY);
        var boundsMc:MovieClip = getChild('bounds');
        boundsMc.visible = Debug.showBounds;
        _bounds = boundsMc.getBounds(parent);
        
        _bounds.x -= x;
        _bounds.y -= y;
        _centerMass = new Point(
            _bounds.x + _bounds.width  / 2,
            _bounds.y + _bounds.height / 2
        );
    }
    
    override public function update():Void {
        
        fixOverlaps();
        
        if (_onGround) {
            
            _v.x = ((Key.checkAction(">") ? 1 : 0) - (Key.checkAction("<") ? 1 : 0)) * _originalScale.x;
            if(_v.x != 0)
                scaleX = _v.x;
            
            _running = Key.checkAction("run");
            _v.x *= _running ? RUN_SPEED.x : WALK_SPEED.x;
            
            if (Key.checkAction("jump")) {
                _v.y += JUMP_VELOCITY * _originalScale.y;
                _onGround = false;
                play("jump");
            }
        } else
            _v.y += GRAVITY / 2 * _originalScale.y;
        
        checkCollision();
        
        updateAnimation();
        
        x += _v.x;
        y += _v.y;
        
        if (_onGround)
            _v.y = 0;
        else
            _v.y += GRAVITY / 2 * _originalScale.y;
    }
    
    function fixOverlaps():Void {
        
        var overlapX:Float;
        var overlapY:Float;
        
        _onGround = false;
        
        for (wall in walls) {
            
            if (_top    < wall.y + wall.height
            &&  _bottom > wall.y
            &&  _left   < wall.x + wall.width
            &&  _right  > wall.x) {
                
                overlapX = wall.x + wall.width - _left;
                if (overlapX > (wall.width + _bounds.width) / 2)
                    overlapX -= wall.width + _bounds.width;
                
                overlapY = wall.y + wall.height - _top;
                if (overlapY > (wall.height + _bounds.height) / 2)
                    overlapY -= wall.height + _bounds.height;
                
                // --- MOVE ALONG THE AXIS WITH THE LEAST OVERLAP
                if (Math.abs(overlapX) < Math.abs(overlapY))
                    x += overlapX;
                else
                    y += overlapY;
            }
            
            _onGround = _onGround
                ||( _top    < wall.y + wall.height
                &&  _bottom + BUFFER * 2 >= wall.y
                &&  _left   < wall.x + wall.width
                &&  _right  > wall.x);
        }
    }
    
    inline function checkCollision():Void {
        
        for (wall in walls) {
            
            if (_top    < wall.y + wall.height
            &&  _bottom > wall.y
            &&  (  (_left  > wall.x + wall.width && _left  + _v.x < wall.x + wall.width)
                || (_right < wall.x              && _right + _v.x > wall.x)))
                _v.x = _v.x > 0 ? wall.x - _right - BUFFER : wall.x + wall.width - _left + BUFFER;
            
            if (!_onGround
            && _left  + _v.x < wall.x + wall.width
            &&  _right + _v.x > wall.x
            &&  (  (_top    > wall.y + wall.height && _top    + _v.y < wall.y + wall.height)
                || (_bottom < wall.y               && _bottom + _v.y > wall.y))) {
                
                _onGround = _v.y > 0;
                _v.y = _v.y > 0 ? wall.y - _bottom - BUFFER : wall.y + wall.height - _top + BUFFER;
            }
        }
    }
    
    inline function updateAnimation():Void {
        
        if (_onGround) {
            
            //if (_curentAnim == "jump") {
                //
                //vx = 0;
                //play("land");
                //
            //} else 
            if (_v.x == 0)     play("idle");
            else if (_running) play("run");
            else               play("walk");
        } else {
            
            if (_currentAnim != "jump" && _currentAnim != "fall")
                play("fall");
        }
    }
    
    public function play(animKey:String, reset:Bool = false):Anim
    {
        if (Assert.isTrue(_anims.exists(animKey), 'Missing [animKey=$animKey]')) {
            
            if (!reset && _currentAnim == animKey)
                return _anims[_currentAnim].activeAnim;
            
            if(_currentAnim != null)
                _anims[_currentAnim].stop();
            
            _currentAnim = animKey;
            return _anims[_currentAnim].play(_clip);
        }
        
        return null;
    }
    
    function get__left  ():Float { return x + _bounds.left  ; }
    function get__right ():Float { return x + _bounds.right ; }
    function get__top   ():Float { return y + _bounds.top   ; }
    function get__bottom():Float { return y + _bounds.bottom; }
    
    public function get_centerMassX():Float { return _centerMass.x + x; }
    public function get_centerMassY():Float { return _centerMass.y + y; }
}
