package com.geokureli.rapella.utils;

import hx.debug.Assert;
import openfl.display.DisplayObjectContainer;
import openfl.display.DisplayObject;
import openfl.display.MovieClip;
import openfl.geom.Point;
import openfl.geom.Rectangle;

/**
 * ...
 * @author George
 */
class SwfUtils {
    
    static var _arrayToken:EReg = ~/\[(\d?)\]/;
    
    @:generic
    inline static public function getAll<T:DisplayObject>(parent:DisplayObjectContainer, path:String, ?list:Array<T>):Array<T> {
        
        var pathArr = path.split(".");
        path = pathArr.pop();
        
        if (pathArr.length > 0)
            parent = aGet(parent, pathArr);
        
        if (list == null)
            list = new Array<T>();
        
        var child:DisplayObject;
        if (_arrayToken.match(path)) {
            
            var length:Null<Int> = Std.parseInt(_arrayToken.matched(1));
            if (length == null)
                length = 0;
            path = _arrayToken.matchedLeft();
            // --- ACOUNT FOR UNEMPTY ARRAY PASSED IN
            if (length > 0)
                length += list.length;
            
            var i:Int = 0;
            do {
                child = parent.getChildByName(path + i);
                if (child != null)
                    list.push(cast child);
                else if (i > 0)
                    break;
                
                i++;
            } while (true);
            
            Assert.isTrue(length == 0 || list.length == length, 'Count mismatch path=$path expected=$length actual=${list.length}');
            
        } else {
            
            for (i in 0 ... parent.numChildren) {
                
                child = parent.getChildAt(i);
                if (child.name == path)
                    list.unshift(cast child);
            }
        }
        
        return list;
    }
    
    @:generic
    inline static public function get<T:DisplayObject>(parent:DisplayObjectContainer, path:String):T {
        
        return aGet(parent, path.split("."));
    }
    
    @:generic
    inline static public function aGet<T:DisplayObject>(parent:DisplayObjectContainer, path:Array<String>):T {
        
        var child:DisplayObject = null;
        while (path.length > 0) {
            
            child = parent.getChildByName(path.shift());
            if (Std.is(child, DisplayObjectContainer))
                parent = cast child;
        }
        
        return cast child;
    }
    
    inline static public function getMC(parent:DisplayObjectContainer, path:String):MovieClip {
        
        return get(parent, path);
    }
    
    static public function swapParent(
        child :DisplayObject,
        parent:DisplayObjectContainer,
        index :Int = -1):DisplayObject {
        
        var rect = new Rectangle(child.x, child.y, child.scaleX, child.scaleY);
        var p = rect.topLeft;
        
        if (child.parent != null)
            p = child.parent.localToGlobal(p);
        p = parent.globalToLocal(p);
        rect.x = p.x;
        rect.y = p.y;
        
        p = rect.size;
        var o = new Point();
        if (child.parent != null) {
            
            o = child.parent.localToGlobal(o);
            p = child.parent.localToGlobal(p);
        }
        o = parent.globalToLocal(o);
        p = parent.globalToLocal(p);
        
        p.offset( -o.x, -o.y);
        var len = p.length;
        p = rect.size;
        p.normalize(len);
        
        if (index > -1)
            parent.addChildAt(child, index);
        else
            parent.addChild(child);
        
        child.x      = rect.x;
        child.y      = rect.y;
        child.scaleX = rect.width;
        child.scaleY = rect.height;
        return child;
    }
}