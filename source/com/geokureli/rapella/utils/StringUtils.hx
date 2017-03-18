package com.geokureli.rapella.utils;

/**
 * ...
 * @author George
 */
class StringUtils {
    
    static var _spaceTrimmer:EReg = ~/^\s*(.*?)\s*$/;
    
    static public function trimSpace(str:String):String {
        
        if(_spaceTrimmer.match(str))
            return _spaceTrimmer.matched(1);
        
        return str;
    }
}
