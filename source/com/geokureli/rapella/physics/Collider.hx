package com.geokureli.rapella.physics;

import hx.debug.Assert;
import lime.app.Event;
import com.geokureli.rapella.art.Wrapper;
import com.geokureli.rapella.debug.Debug;
import com.geokureli.rapella.physics.ColliderType;
import openfl.display.DisplayObjectContainer;
import openfl.display.Sprite;
import openfl.geom.Rectangle;
import openfl.geom.Point;

/**
 * ...
 * @author George
 */
class Collider {
    
    static inline var BUFFER:Float = 0.1;
    
    public var type (default, null):ColliderType;
    public var asset(default, null):Wrapper;
    
    var _bounds(default, null):Rectangle;
    public var left  (get, never):Float;
    public var right (get, never):Float;
    public var top   (get, never):Float;
    public var bottom(get, never):Float;
    public var width (get, never):Float;
    public var height(get, never):Float;
    
    public var moves:Bool;
    
    public var position    (default, null):Point;
    public var velocity    (default, null):Point;
    public var acceleration(default, null):Point;
    
    var _center:Point;
    public var centerX(get, never):Float;
    public var centerY(get, never):Float;
    
    var _touchingDir:Int;
    var _touching:Array<Collider>;
    public var onTouch   :Map<Wrapper, Event<Void->Void>>;
    public var onSeparate:Map<Wrapper, Event<Void->Void>>;
    public var trackTouches:Bool;
    public var solidSides(default, default):Int;
    public var isSolid(get, null):Bool;
    
    public var onDestroy(default, null):Event<Void->Void>;
    
    public function new(boundsMc:Sprite, wrapper:Wrapper = null) {
        
        Assert.isTrue(boundsMc != null || wrapper != null, "cannot handle null boundsMc and wrapper");
        asset = wrapper;
        
        position     = new Point();
        velocity     = new Point();
        acceleration = new Point();
        
        onDestroy   = new Event<Void->Void>();
        onTouch    = new Map<Wrapper, Event<Void->Void>>();
        onSeparate = new Map<Wrapper, Event<Void->Void>>();
        
        _touching = [];
        
        if (wrapper != null && (boundsMc == null || boundsMc == wrapper) && Std.is(wrapper.target, Sprite))
            boundsMc = cast wrapper.target;

        var parent:DisplayObjectContainer;
        if (wrapper != null && wrapper.parent != null)
            parent = wrapper.parent;
        else
            parent = boundsMc.parent;
        
        _bounds = boundsMc.getBounds(parent);
        if (wrapper != null) {
            
            _bounds.x -= wrapper.x;
            _bounds.y -= wrapper.y;
        }
        
        //_bounds.x *= boundsMc.scaleX;
        //_bounds.y *= boundsMc.scaleY;
        //_bounds.width  *= boundsMc.scaleX;
        //_bounds.height *= boundsMc.scaleY;
        _center = new Point(
            _bounds.x + _bounds.width  / 2,
            _bounds.y + _bounds.height / 2
        );
        
        if (boundsMc.name == cast ColliderType.Cloud)
            type = ColliderType.Cloud;
        else if (boundsMc.name == cast ColliderType.Ramp)
            type = ColliderType.Ramp;
        else
            type = ColliderType.Box;
        
        if (wrapper == null || boundsMc.name == "bounds")
            boundsMc.visible = Debug.showBounds;
        
        solidSides = Direction.Any;
        if (type == ColliderType.Cloud)
            solidSides = Direction.Up;
    }
    
    public function isTouching(asset:Wrapper):Bool
    {
        return _touching.indexOf(asset.collider) != -1;
    }
    
    public function isTouchingName(name:String):Bool
    {
        for(collider in _touching) {
            
            if (collider.asset.target != null && collider.asset.target.name == name)
                return true;
        }
        
        return false;
    }
    
    public function update(colliders:Array<Collider>):Void {
        
        var nowTouching:Array<Collider> = null;
        if (trackTouches)
            nowTouching = new Array<Collider>();
        
        if (moves) {
            // --- START ACCELORATION, SINCE d = (Vi + Vf) / 2 * t 
            halfAccel();
            // --- CHECK IF MOVEMENT IS POSSIBLE, TRIM VELOCITY IF NOT
            resolveCollision(colliders, nowTouching);
            // --- MOVE
            position.x += velocity.x;
            position.y += velocity.y;
            // --- FINISH ACCELORATION
            halfAccel();
            // --- REDUNDANT OVERLAP CHECK FOR SAFETY
            resolveOverlap(colliders);
        }
        
        if (trackTouches) {
            
            getAllOverlapping(colliders, nowTouching);
            
            var i = _touching.length;
            while (i-- > 0) {
                
                if (nowTouching.indexOf(_touching[i]) == -1) {
                    // --- STOP TOUCHING
                    if (_touching[i].asset != null) {
                        
                        if (onSeparate.exists(_touching[i].asset))
                            onSeparate[_touching[i].asset].dispatch();
                        
                        // trace('touching ${_touching[i].asset.name}');
                    }
                    _touching.splice(i, 1);
                }
                else
                    // --- STILL TOUCHING
                    nowTouching.remove(_touching[i]);
            }
            
            while (nowTouching.length > 0) {
                var touching = nowTouching.shift();
                
                // --- START TOUCHING
                if (touching.asset != null) {
                    
                    if (onTouch.exists(touching.asset))
                        onTouch[touching.asset].dispatch();
                    
                    // if (touching.asset.target != null)
                    //     trace('touching ${touching.asset.target.name}');
                    // else
                    //     trace('touching ${touching.asset.name}');
                }
                _touching.push(touching);
            }
        }
    }
    
    inline function halfAccel():Void
    {
        if (!isTouchingDir(acceleration.x > 0 ? Direction.Right : Direction.Left)) velocity.x += acceleration.x / 2;
        if (!isTouchingDir(acceleration.y > 0 ? Direction.Down  : Direction.Up  )) velocity.y += acceleration.y / 2;
    }
    
    inline function resolveCollision(colliders:Array<Collider>, touched:Array<Collider>):Void {
        
        var checkSides:Int = Direction.None;
        if      (velocity.x > 0)   checkSides |= Direction.Left ;
        else if (velocity.x < 0)   checkSides |= Direction.Right;
        if      (velocity.y > 0)   checkSides |= Direction.Up   ;
        else if (velocity.y < 0)   checkSides |= Direction.Down ;
        
        var sides:Int;
        var isTouching:Bool;
        
        for (collider in colliders) {
            
            sides = checkSides & collider.solidSides;
            if (collider == this || sides == 0)
                continue;
            
            isTouching = false;
            
            if (!collider.moves) {
                
                if (sides & Direction.X > 0
                &&  top    < collider.bottom
                &&  bottom > collider.top
                &&  (  (left  > collider.right && left  + velocity.x < collider.right)
                    || (right < collider.left  && right + velocity.x > collider.left ))) {
                    
                    isTouching = true;
                    if (velocity.x > 0) {
                        
                        _touchingDir |= Direction.Right;
                        velocity.x = collider.left  - right - BUFFER;
                        
                    } else {
                        
                        _touchingDir |= Direction.Left;
                        velocity.x = collider.right - left + BUFFER;
                    }
                }
                
                if (sides & Direction.Y > 0
                &&  left  + velocity.x < collider.right
                &&  right + velocity.x > collider.left
                &&  (  (top    > collider.bottom && top    + velocity.y < collider.bottom)
                    || (bottom < collider.top    && bottom + velocity.y > collider.top   ))) {
                    
                    isTouching = true;
                    if (velocity.y > 0) {
                        
                        _touchingDir |= Direction.Down;
                        velocity.y = collider.top - bottom - BUFFER;
                        
                    } else {
                        
                        _touchingDir |= Direction.Up;
                        velocity.y = collider.bottom - top + BUFFER;
                    }
                }
            } else {
                
                //TODO: 2 Moving bodies
            }
            
            if (touched != null && isTouching)
                touched.push(collider);
        }
    }
    
    inline function getAllOverlapping(colliders:Array<Collider>, touched:Array<Collider>):Void {
        
        for (collider in colliders) {
            
            if (isOverlapping(collider))
                touched.push(collider);
        }
    }
    
    public function isOverlapping(collider:Collider):Bool {
        
        // --- BOX ONLY FOR NOW
        return left < collider.right  && right  > collider.left
            && top  < collider.bottom && bottom > collider.top ;
    }
    
    inline function resolveOverlap(colliders:Array<Collider>):Void {
        
        var overlap:Point = new Point();
        
        var velSides:Int = Direction.None;
        if      (velocity.x > 0) velSides |= Direction.Left ;
        else if (velocity.x < 0) velSides |= Direction.Right;
        if      (velocity.y > 0) velSides |= Direction.Up   ;
        else if (velocity.y < 0) velSides |= Direction.Down ;
        
        _touchingDir = Direction.None;
        var checkSides:Int;
        var overlapSides:Int;
        var bufferSides:Int;
        
        for (collider in colliders) {
            
            checkSides = velSides & collider.solidSides;
            if (collider == this || checkSides == 0)
                continue;
            
            if (!collider.moves) {
                
                if (top    < collider.bottom
                &&  bottom > collider.top
                &&  left   < collider.right
                &&  right  > collider.left) {
                    
                    overlap.x = 0;
                    if (checkSides & Direction.X > 0) {
                        
                        overlap.x = collider.right - left;
                        if (overlap.x > (collider.width  + width ) / 2)
                            overlap.x -= collider.width  + width ;
                    }
                    
                    overlap.y = 0;
                    if (checkSides & Direction.Y > 0) {
                        
                        overlap.y = collider.bottom - top;
                        if (overlap.y > (collider.height + height) / 2)
                            overlap.y -= collider.height + height;
                    }
                    
                    // --- MOVE ALONG THE AXIS WITH THE LEAST OVERLAP
                    if (Math.abs(overlap.x) < Math.abs(overlap.y))
                        position.x += overlap.x;
                    else
                        position.y += overlap.y;
                }
                
                overlapSides
                    = (top    <= collider.bottom ? Direction.Up    : 0)
                    | (bottom >= collider.top    ? Direction.Down  : 0)
                    | (left   <= collider.right  ? Direction.Left  : 0)
                    | (right  >= collider.left   ? Direction.Right : 0);
                
                
                bufferSides
                    = (top    - BUFFER * 2 <= collider.bottom ? Direction.Up    : 0)
                    | (bottom + BUFFER * 2 >= collider.top    ? Direction.Down  : 0)
                    | (left   - BUFFER * 2 <= collider.right  ? Direction.Left  : 0)
                    | (right  + BUFFER * 2 >= collider.left   ? Direction.Right : 0);
                
                if (bufferSides == Direction.Any) {
                    
                    bufferSides ^= overlapSides;
                    
                    if ( overlapSides & ~Direction.Down > 0
                      && bufferSides  &  Direction.Down > 0)
                        _touchingDir |= Direction.Down;
                    
                    if ( overlapSides & ~Direction.Up > 0
                      && bufferSides  &  Direction.Up > 0)
                        _touchingDir |= Direction.Up;
                    
                    if ( overlapSides & ~Direction.Left > 0
                      && bufferSides  &  Direction.Left > 0)
                        _touchingDir |= Direction.Left;
                    
                    if ( overlapSides & ~Direction.Right > 0
                      && bufferSides  &  Direction.Right > 0)
                        _touchingDir |= Direction.Right;
                }
            }
        }
    }
    
    public function destroy():Void
    {
        position     = null;
        velocity     = null;
        acceleration = null;
        
        type = null;
        
        _bounds = null;
        _center = null;
        
        _touching   = null;
        onTouch    = null;
        onSeparate = null;
        
        onDestroy.dispatch();
    }
    
    inline public function isTouchingDir(direction:Int):Bool { return _touchingDir & direction > 0; }
    
    public function get_left  ():Float { return position.x + _bounds.left  ; }
    public function get_right ():Float { return position.x + _bounds.right ; }
    public function get_top   ():Float { return position.y + _bounds.top   ; }
    public function get_bottom():Float { return position.y + _bounds.bottom; }
    public function get_width ():Float { return _bounds.width ; }
    public function get_height():Float { return _bounds.height; }
    
    public function get_centerX():Float { return position.x + _center.x; }
    public function get_centerY():Float { return position.y + _center.y; }
    
    public function get_isSolid():Bool { return solidSides > 0; }
}

@:enum
class Direction {
    public static inline var None   :Int = 0x0000;
    public static inline var Left   :Int = 0x0001;
    public static inline var Right  :Int = 0x0010;
    public static inline var Up     :Int = 0x0100;
    public static inline var Down   :Int = 0x1000;
    public static inline var Any    :Int = Left | Right | Up | Down;
    public static inline var X      :Int = Left | Right;
    public static inline var Y      :Int = Up | Down;
    public static inline var Wall   :Int = X;
    public static inline var Ceiling:Int = Up;
    public static inline var Floor  :Int = Down;
}