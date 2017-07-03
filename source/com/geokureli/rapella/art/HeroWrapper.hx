package com.geokureli.rapella.art;
import com.geokureli.rapella.art.Anim.AnimDef;
import com.geokureli.rapella.art.ScriptedWrapper;
import com.geokureli.rapella.debug.Debug;
import com.geokureli.rapella.input.Key;
import com.geokureli.rapella.physics.Collider;
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
    static inline var JUMP_HEIGHT:Float = -50;
    static inline var JUMP_APEX_TIME:Float = 7;// --- FRAMES
    static inline var JUMP_VELOCITY:Float = 2 * JUMP_HEIGHT / JUMP_APEX_TIME;
    static inline var GRAVITY:Float = -2 * JUMP_HEIGHT / (JUMP_APEX_TIME * JUMP_APEX_TIME);
    
    static var WALK_SPEED:Float = 10;
    static var RUN_SPEED :Float = 20;
    static var AIR_ACCEL :Float = 2;
    
    // --- JUMP
    var _jumpHeight  :Float;
    var _jumpVelocity:Float;
    
    // --- KEYS
    var _keyLeft :Bool;
    var _keyRight:Bool;
    var _keyUp   :Bool;
    var _keyDown :Bool;
    var _keyShift:Bool;
    
    var _originalScale:Point;
    var _originalPos:Point;
    public var centerMassX(get, never):Float;
    public var centerMassY(get, never):Float;
    
    var _anims:Map<String, AnimDef>;
    var _currentAnim:String;
    var _running:Bool;
    var _canMove:Bool;
    
    public function new(mc:MovieClip) { super(mc); }
    
    override function setDefaults() {
        super.setDefaults();
        
        moves = true;
        
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
        _originalPos = new Point(x, y);
        _collider.acceleration.y = GRAVITY * _originalScale.y;
    }
    
    override public function updatePhysics(colliders:Array<Collider>):Void {
        
        #if debug
        if (Key.isDown(Key.R)) {
            
            x = _originalPos.x;
            y = _originalPos.y;
            scaleX = _originalScale.x;
            _collider.velocity.x = 0;
            _collider.velocity.y = 0;
        }
        #end
        
        if (_collider.isTouching(Direction.Down)) {
            
            _collider.velocity.x = ((Key.checkAction(">") ? 1 : 0) - (Key.checkAction("<") ? 1 : 0)) * _originalScale.x;
            if(_collider.velocity.x != 0)
                scaleX = _collider.velocity.x;
            
            _running = Key.checkAction("run");
            _collider.velocity.x *= _running ? RUN_SPEED : WALK_SPEED;
            
            if (Key.checkAction("jump")) {
                _collider.velocity.y += JUMP_VELOCITY * _originalScale.y;
                play("jump");
            }
        } else {
            
            _collider.velocity.x += ((Key.checkAction(">") ? 1 : 0) - (Key.checkAction("<") ? 1 : 0)) 
                * _originalScale.x * AIR_ACCEL;
            
            var speed:Float = _running ? RUN_SPEED : WALK_SPEED;
            
            if (_collider.velocity.x > speed)
                _collider.velocity.x = speed;
            else if (_collider.velocity.x < -speed)
                _collider.velocity.x = -speed;
        }
        
        super.updatePhysics(colliders);
    }
    
    override public function update():Void {
        super.update();
        
        updateAnimation();
    }
    
    inline function updateAnimation():Void {
        
        if (_collider.isTouching(Direction.Down)) {
            
            //if (_curentAnim == "jump") {
                //
                //vx = 0;
                //play("land");
                //
            //} else 
            if (_collider.velocity.x == 0)
                play("idle");
            else if (_running)
                play("run");
            else
                play("walk");
            
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
    
    function get_centerMassX():Float { return _collider.centerX; }
    function get_centerMassY():Float { return _collider.centerY; }
}
