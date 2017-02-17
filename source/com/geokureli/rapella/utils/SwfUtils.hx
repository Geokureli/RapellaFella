package com.geokureli.rapella.utils;

import openfl.display.DisplayObjectContainer;
import openfl.display.DisplayObject;
import openfl.display.MovieClip;

/**
 * ...
 * @author George
 */
class SwfUtils {
	
	@:generic
	inline static public function getAll<T:DisplayObject>(parent:DisplayObjectContainer, path:String, ?list:Array<T>):Array<T> {
		
		var pathArr = path.split(".");
		path = pathArr.pop();
		
		if (pathArr.length > 0)
			parent = aGet(parent, pathArr);
		
		if (list == null)
			list = new Array<T>();
		
		var child:DisplayObject;
		for (i in 0 ... parent.numChildren) {
			
			child = parent.getChildAt(i);
			if (child.name == path)
				list.unshift(cast child);
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
}