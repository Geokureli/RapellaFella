package com.geokureli.rapella;

import com.geokureli.rapella.script.Action;
import com.geokureli.rapella.debug.DebugConsole;
import hx.debug.Assert;
import com.geokureli.rapella.script.ScriptInterpreter;
import com.geokureli.rapella.art.scenes.ActionScene;
import com.geokureli.rapella.art.AssetManager;
import com.geokureli.rapella.debug.Debug;
import com.geokureli.rapella.art.scenes.Scene;
import com.geokureli.rapella.art.ui.InteractMenu;
import com.geokureli.rapella.camera.Camera;
import com.geokureli.rapella.debug.DebugOverlay;
import com.geokureli.rapella.input.Key;
import motion.Actuate;
import motion.easing.Linear;
import openfl.display.*;
import openfl.events.Event;

class Game extends Sprite {
    
    static inline public var FPS:Float = 30.0;
    static inline public var SPF:Float = 1 / FPS;
    
    static public var mainStage(default, null):Stage;
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
        
        name = "Game";
        instance = this;
        
        if (stage != null)
            init();
        else
            addEventListener(Event.ADDED_TO_STAGE, init);
    }
    
    function init(e:Event = null):Void {
        
        removeEventListener(Event.ADDED_TO_STAGE, init);
        
        mainStage = stage;
        _sceneMap = 
            [ "action" => ActionScene
            ];
        
        _actionMap = new ActionMap(this);
        _actionMap.add("gotoScene" , script_gotoScene , ["id", "?label"]);
        _actionMap.add("nextScene" , script_nextScene , ["?label"      ]);
        _actionMap.add("error"     , script_error     , ["...msg"      ]);
        _actionMap.add("log"       , script_log       , ["...msg"      ]);
        _actionMap.add("breakpoint", script_breakpoint, ["...msg"      ]);
        _actionMap.add("checkpoint", script_checkpoint);
        
        #if !embedAssets
            AssetManager.initDebugAssets(handleAssetsLoad);
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
            
            if(Debug.startingScene != null)
                createScene(Debug.startingScene, Debug.startingLabel);
            else
                createScene("Scene1");
        #else
            createScene("Scene1");
        #end
        //new InteractMenu(Assets.getMovieClip("library1:InteractMenu"));
        
        addEventListener(Event.ENTER_FRAME, onEnterFrame);
    }
    
    inline function initManagers():Void {
        
        // entry point
        Debug.init(stage);
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
        
        var data:Dynamic = ScriptInterpreter.getSceneData(name);
        var type:String = Reflect.field(data, "type");
        var sceneClass:Class<Scene> = Scene;
        if (type != null && Assert.isTrue(_sceneMap.exists(type), 'Invalid [type="$type"]'))
            sceneClass = _sceneMap[type];
        
        var args = [name, data];
        if (label != null)
            args.push(label);
        
        
        _sceneLayer.addChild(currentScene = Type.createInstance(sceneClass, args));
        
        _currentSceneIndex = Std.parseInt(name.substr(5));
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
    
    function script_breakpoint(msg:Array<String>):Void {
        
        if (msg.length == 0)
            msg.push("Breakpoint");
        else if (msg[0] == null)
            msg[0] = "Breakpoint";
        else
            msg[0] = "Breakpoint: " + msg[0];
        
        script_log(msg);
        var putBreakpointHere = true;
    }
    
    function script_checkpoint(msg:Array<String>):Void {
        
        Assert.fail("game.checkpoint() not implemented... yet");
    }
    //} endregion                                           SCRIPTS
    // =================================================================================================================
}