package com.geokureli.rapella.art;

import com.geokureli.rapella.functional.MultiListener;
import com.geokureli.rapella.utils.TimeUtils;
import openfl.utils.AssetType;
import openfl.Assets;
import com.geokureli.rapella.debug.Debug;
import openfl.display.MovieClip;
import lime.utils.AssetLibrary;
import lime.app.Future;

class AssetManager {
    
    static var _scenes:Map<String, String>;
    
#if !embedAssets
    static var _debugAssets:Map<String, Dynamic>;
    
    static public function initDebugAssets(callback:Void->Void):Void {
        
        _debugAssets = new Map<String, Dynamic>();
        var loaderFuncs:Map<String, String->Dynamic> = [
            "assets/data/Debug.json"  => Assets.loadText,
            "assets/data/Scenes.json" => Assets.loadText
        ];
        
        var listener = new MultiListener(callback);
        TimeUtils.delay(listener.createListener("wait"));
        
        for (path in loaderFuncs.keys()) {
            
            _debugAssets[path] = loaderFuncs[path](path)
                .onComplete(handleAssetLoad.bind(_, path, listener.createListener(path)));
        }
    }
    
    static function handleAssetLoad(data:Dynamic, path:String, callback:Void->Void):Void {
        
        _debugAssets[path] = data;
        callback();
    }
#end
    
    static public function init() {
        
        checkScenes();
    }
    
    static function checkScenes():Void {
        
        _scenes = new Map<String, String>();
        
        var l:Int = 0;
        var s:Int = 0;
        var min:Int = 0;
        
        #if debug
            min = Std.parseInt(Debug.startingScene.split("Scene").join(""));
            if (min < 0)
                min = 0;
        #end
        
        var library:AssetLibrary;
        do {
            
            library = lime.utils.Assets.getLibrary('library$l');
            if (library != null) {
                
                do {
                    if (library.exists('Scene$s', cast AssetType.MOVIE_CLIP))
                        _scenes['Scene$s'] = 'library$l:Scene$s';
                    else if (s >= min)
                        break;
                    
                    s++;
                }
                while (true);
            }
            else if(l > 0)
                break;
            
            l++;
        }
        while (true);
    }
    
    static public function getText(id:String):String {
        
        #if !embedAssets
            if (_debugAssets.exists(id))
                return cast _debugAssets[id];
        #end
            return Assets.getText(id);
    }
    
    static public function getScene(name:String):MovieClip {
        
        return Assets.getMovieClip(_scenes[name]);
    }
}
