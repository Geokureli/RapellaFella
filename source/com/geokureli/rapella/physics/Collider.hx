package com.geokureli.rapella.physics;

import hx.debug.Assert;
import hx.event.Signal;
import com.geokureli.rapella.art.Wrapper;
import com.geokureli.rapella.debug.Debug;
import com.geokureli.rapella.physics.Collider.ColliderType;
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
    var _onTouch   :Map<Wrapper, Signal>;
    var _onSeparate:Map<Wrapper, Signal>;
    public var trackTouches:Bool;
    public var solidSides(default, null):Int;
    public var isSolid(get, null):Bool;
    
    public var onDestroy(default, null):Signal;
    
    public function new(boundsMc:Sprite, wrapper:Wrapper = null) {
        
        Assert.isTrue(boundsMc != null || wrapper != null, "cannot handle null boundsMc and wrapper");
        asset = wrapper;
        
        position     = new Point();
        velocity     = new Point();
        acceleration = new Point();
        
        onDestroy   = new Signal();
        _onTouch    = new Map<Wrapper, Signal>();
        _onSeparate = new Map<Wrapper, Signal>();
        
        _touching = [];
        
        if (wrapper != null && (boundsMc == null || boundsMc == wrapper) && Std.is(wrapper.target, Sprite))
            boundsMc = cast wrapper.target;

        var parent:DisplayObjectContainer;
        if (wrapper != null)
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
        
        type = cast boundsMc.name;
        if (type == null)
            type = ColliderType.Box;
        
        solidSides = Direction.Any;
        if (type == ColliderType.Cloud)
            solidSides = Direction.Up;
        
        boundsMc.visible = Debug.showBounds;
    }
    
    public function isTouching(asset:Wrapper):Bool
    {
        return _touching.indexOf(asset.collider) != -1;
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
                        
                        if (_onSeparate.exists(_touching[i].asset))
                            _onSeparate[_touching[i].asset].dispatch();
                        
                        trace('touching ${_touching[i].asset.name}');
                    }
                    _touching.splice(i, 1);
                }
                else
                    // --- STILL TOUCHING
                    nowTouching.remove(_touching[i]);
            }
            
            while (nowTouching.length > 0) {
                // --- START TOUCHING
                if (nowTouching[0].asset != null) {
                    
                    if (_onTouch.exists(nowTouching[0].asset))
                        _onTouch[nowTouching[0].asset].dispatch();
                    
                    trace('touching ${nowTouching[0].asset.name}');
                }
                _touching.push(nowTouching.shift());
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
        return  (  (left <= collider.left   && right  >= collider.left  )
                || (left <= collider.right  && right  >= collider.right )
                )
            &&  (  (top >= collider.top    && bottom <= collider.top   )
                || (top >= collider.bottom && bottom <= collider.bottom)
                )
            ;
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
        _onTouch    = null;
        _onSeparate = null;
        
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
abstract ColliderType(String) {
    var Box   = "box";
    var Ramp  = "ramp";
    var Cloud = "cloud";
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