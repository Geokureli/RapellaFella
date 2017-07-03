package com.geokureli.rapella.physics;

import com.geokureli.rapella.art.Wrapper;
import com.geokureli.rapella.art.scenes.Scene;
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
    
    public var type  (default, null):ColliderType;
    
    var _bounds(default, null):Rectangle;
    public var left  (get, never):Float;
    public var right (get, never):Float;
    public var top   (get, never):Float;
    public var bottom(get, never):Float;
    public var width (get, never):Float;
    public var height(get, never):Float;
    public var moves (default, null):Bool;
    
    public var position    (default, null):Point;
    public var velocity    (default, null):Point;
    public var acceleration(default, null):Point;
    
    var _center:Point;
    public var centerX(get, never):Float;
    public var centerY(get, never):Float;
    
    var touching:Int;
    public var solidSides(default, null):Int;
    
    public function new(mc:Sprite, wrapper:Wrapper = null) {
        
        position     = new Point();
        velocity     = new Point();
        acceleration = new Point();
        
        var parent:DisplayObjectContainer = mc.parent;
        if (wrapper != null) {
            
            moves = wrapper.moves;
            parent = wrapper.parent;
        }
        
        _bounds = mc.getBounds(parent);
        if (wrapper != null) {
            
            _bounds.x -= wrapper.x;
            _bounds.y -= wrapper.y;
        }
            
        //_bounds.x *= mc.scaleX;
        //_bounds.y *= mc.scaleY;
        //_bounds.width  *= mc.scaleX;
        //_bounds.height *= mc.scaleY;
        _center = new Point(
            _bounds.x + _bounds.width  / 2,
            _bounds.y + _bounds.height / 2
        );
        
        type = cast mc.name;
        if (type == null)
            type = ColliderType.Box;
        
        solidSides = Direction.Any;
        if (type == ColliderType.Cloud)
            solidSides = Direction.Up;
        
        mc.visible = Debug.showBounds;
    }
    
    public function update(colliders:Array<Collider>):Void {
        
        if (!isTouching(acceleration.x > 0 ? Direction.Right : Direction.Left))
            velocity.x += acceleration.x / 2;
        
        if (!isTouching(acceleration.y > 0 ? Direction.Down : Direction.Up))
            velocity.y += acceleration.y / 2;
        
        resolveCollision(colliders);
        
        position.x += velocity.x;
        position.y += velocity.y;
        
        if (!isTouching(acceleration.x > 0 ? Direction.Right : Direction.Left))
            velocity.x += acceleration.x / 2;
        
        if (!isTouching(acceleration.y > 0 ? Direction.Down : Direction.Up))
            velocity.y += acceleration.y / 2;
        
        resolveOverlap(colliders);
    }
    
    inline function resolveCollision(colliders:Array<Collider>):Void {
        
        var checkSides:Int = Direction.None;
        if      (velocity.x > 0)   checkSides |= Direction.Left ;
        else if (velocity.x < 0)   checkSides |= Direction.Right;
        if      (velocity.y > 0)   checkSides |= Direction.Up   ;
        else if (velocity.y < 0)   checkSides |= Direction.Down ;
        
        var sides:Int;
        
        for (collider in colliders) {
            
            sides = checkSides & collider.solidSides;
            if (collider == this || sides == 0)
                continue;
            
            if (!collider.moves) {
                
                if (sides & Direction.X > 0
                &&  top    < collider.bottom
                &&  bottom > collider.top
                &&  (  (left  > collider.right && left  + velocity.x < collider.right)
                    || (right < collider.left  && right + velocity.x > collider.left ))) {
                    
                    if (velocity.x > 0) {
                        
                        touching |= Direction.Right;
                        velocity.x = collider.left  - right - BUFFER;
                        
                    } else {
                        
                        touching |= Direction.Left;
                        velocity.x = collider.right - left + BUFFER;
                    }
                }
                
                if (sides & Direction.Y > 0
                &&  left  + velocity.x < collider.right
                &&  right + velocity.x > collider.left
                &&  (  (top    > collider.bottom && top    + velocity.y < collider.bottom)
                    || (bottom < collider.top    && bottom + velocity.y > collider.top   ))) {
                    
                    if (velocity.y > 0) {
                        
                        touching |= Direction.Down;
                        velocity.y = collider.top - bottom - BUFFER;
                        
                    } else {
                        
                        touching |= Direction.Up;
                        velocity.y = collider.bottom - top + BUFFER;
                    }
                }
            } else {
                
                //TODO: 2 Moving bodies
            }
        }
    }
    
    inline function resolveOverlap(colliders:Array<Collider>):Void {
        
        var overlap:Point = new Point();
        
        var velSides:Int = Direction.None;
        if      (velocity.x > 0) velSides |= Direction.Left ;
        else if (velocity.x < 0) velSides |= Direction.Right;
        if      (velocity.y > 0) velSides |= Direction.Up   ;
        else if (velocity.y < 0) velSides |= Direction.Down ;
        
        touching = Direction.None;
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
                        touching |= Direction.Down;
                    
                    if ( overlapSides & ~Direction.Up > 0
                      && bufferSides  &  Direction.Up > 0)
                        touching |= Direction.Up;
                    
                    if ( overlapSides & ~Direction.Left > 0
                      && bufferSides  &  Direction.Left > 0)
                        touching |= Direction.Left;
                    
                    if ( overlapSides & ~Direction.Right > 0
                      && bufferSides  &  Direction.Right > 0)
                        touching |= Direction.Right;
                }
            }
        }
    }
    
    inline public function isTouching(direction:Int):Bool { return touching & direction > 0; }
    
    public function get_left  ():Float { return position.x + _bounds.left  ; }
    public function get_right ():Float { return position.x + _bounds.right ; }
    public function get_top   ():Float { return position.y + _bounds.top   ; }
    public function get_bottom():Float { return position.y + _bounds.bottom; }
    public function get_width ():Float { return _bounds.width ; }
    public function get_height():Float { return _bounds.height; }
    
    public function get_centerX():Float { return position.x + _center.x; }
    public function get_centerY():Float { return position.y + _center.y; }
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