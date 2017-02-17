package com.geokureli.rapella.utils;

import de.polygonal.Printf;
import haxe.macro.Expr;
using com.geokureli.rapella.utils.StringUtils.Extender;

/**
 * ...
 * @author George
 */
class StringUtils{
	
}

class Extender {
	
	static public function vformat(s:String, args:Array<Dynamic>) {
		
		return Printf.format(s, args);
	}
	
	macro public static function format(s:ExprOf<String>, _passedArgs:Array<Expr>):ExprOf<String> {
		
		return Printf.eformat(s, args);
	}
}