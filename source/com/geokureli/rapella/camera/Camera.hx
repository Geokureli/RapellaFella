package com.geokureli.rapella.camera;

import flash.display.DisplayObject;
import com.geokureli.rapella.utils.Game;
import openfl.display.Sprite;
import openfl.geom.Rectangle;
import openfl.geom.Point;

/**
 * ...
 * @author George
 */
class Camera {
    
    public var drawTarget:Sprite;
    public var bounds(default, null):Rectangle;
    public var followSpeed:Float;
    public var followTarget:DisplayObject;
    
    public var x      (get, set):Float;
    public var y      (get, set):Float;
    public var width  (get, null):Float;
    public var height (get, null):Float;
    public var centerX(get, set):Float;
    public var centerY(get, set):Float;
    public var left   (get, set):Float;
    public var right  (get, set):Float;
    public var top    (get, set):Float;
    public var bottom (get, set):Float;
    
    var _halfWidth:Float;
    var _halfHeight:Float;
    var _view:Rectangle;
    
    public function new() {
        
        bounds = new CameraBounds();
        _view = new Rectangle(0, 0, Game.stage.stageWidth, Game.stage.stageHeight);
        
        _halfWidth  = _view.width  / 2;
        _halfHeight = _view.height / 2;
        followSpeed = Math.NaN;
    }
    
    public function update():Void {
        if (drawTarget == null)
            return;
        
        if(followTarget != null) {
    
            var diff:Point = new Point(followTarget.x - centerX, followTarget.y - centerY);
            
            if(!Math.isNaN(followSpeed) && Math.isFinite(followSpeed)) {
                
                if      (diff.x >  followSpeed) diff.x =  followSpeed;
                else if (diff.x < -followSpeed) diff.x = -followSpeed;
                if      (diff.y >  followSpeed) diff.y =  followSpeed;
                else if (diff.y < -followSpeed) diff.y = -followSpeed;
            }
            
            _view.x += diff.x;
            _view.y += diff.y;
        }
        
        // --- KEEP CAMERA IN BOUNDS
        if      (left   < bounds.left  ) left   = bounds.left  ;
        else if (right  > bounds.right ) right  = bounds.right ;
        if      (top    < bounds.top   ) top    = bounds.top   ;
        else if (bottom > bounds.bottom) bottom = bounds.bottom;
        
        drawTarget.x = -_view.x;
        drawTarget.y = -_view.y;
    }
    
    function get_x()       :Float { return _view.x; }
    function set_x(v:Float):Float { return _view.x = v; }
    function get_y()       :Float { return _view.y; }
    function set_y(v:Float):Float { return _view.y = v; }
    function get_width ()  :Float { return _view.width ; }
    function get_height()  :Float { return _view.height; }
    
    function get_left  ()       :Float { return _view.x; }
    function set_left  (v:Float):Float { return _view.x = v; }
    function get_right ()       :Float { return _view.x + width; }
    function set_right (v:Float):Float { x = v - width;  return v; }
    function get_top   ()       :Float { return _view.y; }
    function set_top   (v:Float):Float { return _view.y = v; }
    function get_bottom()       :Float { return _view.y + height; }
    function set_bottom(v:Float):Float { y = v - height; return v; }
    
    function get_centerX():Float { return _view.x + _halfWidth; }
    function set_centerX(v:Float):Float { _view.x = v - _halfWidth; return v; }
    function get_centerY():Float { return _view.y + _halfHeight; }
    function set_centerY(v:Float):Float { _view.y = v - _halfHeight; return v; }
}

private class CameraBounds extends Rectangle {
    
    public function new() { super(); }
    
    
}