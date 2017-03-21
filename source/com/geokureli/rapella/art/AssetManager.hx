package com.geokureli.rapella.art;

import com.geokureli.rapella.functional.MultiListener;
import openfl.Assets.AssetType;
import openfl.Assets;
import com.geokureli.rapella.debug.Debug;
import openfl.display.MovieClip;
import lime.utils.AssetLibrary;
class AssetManager {
    
    static var _scenes:Map<String, String>;
    
#if debug
    static var _debugAssets:Map<String, Dynamic>;
    
    static public function initDebug(callback:Void->Void):Void {
        
        _debugAssets = [
            "assets/data/Debug.json"  => Assets.loadText,
            "assets/data/Scenes.json" => Assets.loadText
        ];
        
        var listener = new MultiListener(callback);
        for (path in _debugAssets.keys()) {
            
            _debugAssets[path](path, handleAssetLoad.bind(_, path, listener.createListener(path)));
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
        var library:AssetLibrary;
        do {
            
            library = lime.Assets.getLibrary('library$l');
            if (library != null) {
                
                #if debug
                    if (!_scenes.exists(Debug.startingScene)
                    &&  library.exists(Debug.startingScene, cast AssetType.MOVIE_CLIP)) {
                        
                        _scenes[Debug.startingScene] = 'library$l:${Debug.startingScene}';
                    }
                #end
                
                do {
                    if (library.exists('Scene$s', cast AssetType.MOVIE_CLIP))
                        _scenes['Scene$s'] = 'library$l:Scene$s';
                    else if (s > 0)
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
        
        #if debug
            if (_debugAssets.exists(id))
                return cast _debugAssets[id];
        #end
        return Assets.getText(id);
    }
    
    static public function getScene(name:String):MovieClip {
        
        return Assets.getMovieClip(_scenes[name]);
    }
}
