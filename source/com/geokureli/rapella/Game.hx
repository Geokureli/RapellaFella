package com.geokureli.rapella;

import hx.debug.Assert;
import haxe.Constraints.Function;
import com.geokureli.rapella.ScriptInterpreter.IScriptInterpretable;
import com.geokureli.rapella.ScriptInterpreter.Action;
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

class Game
    extends Sprite 
    implements IScriptInterpretable {
    
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
    static var _scriptHandlers:Map<String, Function>;
    
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
        
        _scriptHandlers = [
            "gotoScene" => script_gotoScene
        ];
        
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
    }
    
    function onEnterFrame(e:Event):Void {
        
        currentScene.update();
        
        Game.camera.update();
    }
    
     static public function createScene(name:String):Void {
        
        if(currentScene != null)
            currentScene.destroy();
        
        var sceneType:Class<Scene> = _sceneMap[name];
        if(sceneType == null)
            sceneType = Scene;
        _sceneLayer.addChild(currentScene = Type.createInstance(sceneType,[name]));
        
        _currentSceneIndex = Std.parseInt(name.substr(5,100));
    }
    
    inline static public function nextScene():Void {
        
        createScene('Scene${_currentSceneIndex + 1}');
    }
    
    // =================================================================================================================
    //{ region                                              SCRIPTS
    // =================================================================================================================
    
    public function runScript(action:Action):Void {
        
        if (Assert.isTrue(_scriptHandlers.exists(action.func), 'Invalid func=${action.func}'))
            _scriptHandlers[action.func](action);
        else
            action.complete();
    }
    
    function script_gotoScene(action:Action):Void {
        
        createScene('Scene${action.args[0]}');
        action.complete();
    }
    
    //} endregion                                           SCRIPTS
    // =================================================================================================================

}