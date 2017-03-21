package com.geokureli.rapella.utils;

class Safe {
    
    @:generic
    inline static public function get<T>(object:Dynamic, path:String, defaultValue:T = null):T {
        
        return aGet(object, path.split("."), defaultValue);
    }
    
    @:generic
    inline static public function aGet<T>(object:Dynamic, path:Array<String>, defaultValue:T = null):T {
        
        while (path.length > 0 && object.hasField(path[0]))
            object = Reflect.field(object, path.shift());
        
        if (path.length == 0)
            return object;
        
        return defaultValue;
    }
}
