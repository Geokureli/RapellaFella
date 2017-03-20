package com.geokureli.rapella;

import com.geokureli.rapella.script.Action;
import com.geokureli.rapella.debug.DebugConsole;
import hx.debug.Assert;
import com.geokureli.rapella.script.ScriptInterpreter;
import com.geokureli.rapella.art.scenes.ActionScene;
import flash.display.Stage;
import com.geokureli.rapella.art.AssetManager;
import com.geokureli.rapella.debug.Debug;
import com.geokureli.rapella.art.scenes.Scene;
import com.geokureli.rapella.art.ui.InteractMenu;
import com.geokureli.rapella.camera.Camera;
import com.geokureli.rapella.debug.DebugOverlay;
import com.geokureli.rapella.input.Key;
import motion.Actuate;
import motion.easing.Linear;
import openfl.display.Sprite;
import openfl.events.Event;

class Game extends Sprite {
    
    static public var mainStage(default, null):Stage;
    static public var fps(default, null):Float;
    static public var spf(default, null):Float;
    static public var currentScene(default, null):Scene;
    static public var instance(default, null):Game;
    
    static public var camera:Camera;

    static var _sceneLayer:Sprite;
    static var _debugLayer:Sprite;
    static var _sceneMap:Map<String, Class<Scene>>;
    static var _currentSceneIndex:Int;
    static var _actionMap:ActionMap;
    
    public function new () {
        
        super ();
        
        instance = this;
        
        if (stage != null)
            init();
        else
            addEventListener(Event.ADDED_TO_STAGE, init);
    }
    
    function init(e:Event = null):Void {
        removeEventListener(Event.ADDED_TO_STAGE, init);
        
        mainStage = stage;
        fps = stage.frameRate;
        spf = 1 / fps;
        _sceneMap = [
            "Scene3" => ActionScene
        ];
        
        _actionMap = new ActionMap(this);
        _actionMap.add("gotoScene", script_gotoScene, ["id", "?label"]);
        _actionMap.add("nextScene", script_nextScene, ["?label"      ]);
        _actionMap.add("error"    , script_error    , ["...msg"      ]);
        _actionMap.add("log"      , script_log      , ["...msg"      ]);
        
        #if debug
            AssetManager.initDebug(handleAssetsLoad);
        #else 
            handleAssetsLoad();
        #end
    }
    
    public function handleAssetsLoad():Void
    {
        initManagers();
        
        addChild(_sceneLayer = new Sprite());
        addChild(_debugLayer = new Sprite());
        
        #if debug
            _debugLayer.addChild(new DebugOverlay());
            createScene(Debug.startingScene);
        #else
            createScene("Scene1");
        #end
        //new InteractMenu(Assets.getMovieClip("library1:InteractMenu"));
        
        addEventListener(Event.ENTER_FRAME, onEnterFrame);
    }
    
    inline function initManagers():Void {
        
        // entry point
        Debug.init();
        AssetManager.init();
        Key.init(stage);
        Actuate.defaultEase = Linear.easeNone;
        camera = new Camera();
        ScriptInterpreter.init();
        ScriptInterpreter.addInterpreter("game", _actionMap);
    }
    
    function onEnterFrame(e:Event):Void {
        
        currentScene.update();
        
        Game.camera.update();
    }
    
    static public function createScene(name:String, label:String = null):Void {
        
        if(currentScene != null)
            currentScene.destroy();
        
        var sceneType:Class<Scene> = _sceneMap[name];
        if(sceneType == null)
            sceneType = Scene;
        
        var args = [name];
        if (label != null)
            args.push(label);
        
        _sceneLayer.addChild(currentScene = Type.createInstance(sceneType, args));
        
        _currentSceneIndex = Std.parseInt(name.substr(5,100));
    }
    
    inline static public function nextScene(label:String = null):Void {
        
        createScene('Scene${_currentSceneIndex + 1}', label);
    }
    
    // =================================================================================================================
    //{ region                                              SCRIPTS
    // =================================================================================================================
    
    function script_gotoScene(id:String, label:String):Void { createScene('Scene${id}', label); }
    
    function script_nextScene(label:String):Void { nextScene(label); }
    
    function script_log(msg:Array<String>):Void {
        
        DebugConsole.log(msg.join(", "));
    }
    
    function script_error(msg:Array<String>):Void {
        
        Assert.fail(msg.join(", "));
    }
    //} endregion                                           SCRIPTS
    // =================================================================================================================
}