package com.geokureli.rapella.debug;

import haxe.Json;
import openfl.Assets;

class Debug {
    
    static public var scriptVars:Dynamic;
    static public var startingScene:String;
    static public var sceneDataName:String;
    
    static public function init():Void {
        
        startingScene = "Scene1";
        
        var data:Dynamic = Json.parse(Assets.getText("assets/data/Debug.json"));
        for (fieldName in Reflect.fields(data)) {
            
            Reflect.setField(Debug, fieldName, Reflect.field(data, fieldName));
        }
    }
}
