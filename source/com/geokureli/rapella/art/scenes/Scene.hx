package com.geokureli.rapella.art.scenes;

import Reflect;
import openfl.display.DisplayObject;
import hx.debug.Assert;
import com.geokureli.rapella.art.ui.DeathMenu;
import com.geokureli.rapella.art.ui.MenuWrapper;
import com.geokureli.rapella.utils.FuncUtils;
import com.geokureli.rapella.utils.SwfUtils;
import com.geokureli.rapella.script.ScriptInterpreter;
import hx.debug.Expect;
import openfl.events.Event;
import flash.display.FrameLabel;
import com.geokureli.rapella.art.ui.ChoiceMenu;
import openfl.display.MovieClip;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.geom.Rectangle;

/**
 * ...
 * @author George
 */

class Scene extends ScriptedWrapper {
    
    var _cameraBounds:Rectangle;
    var _interactables:Array<Sprite>;
    var _labels:Map<String, FrameData>;
    var _data:Dynamic;
    
    var _assetMap:Map<String, Class<ScriptedWrapper>>;
    var _assets:Map<String, ScriptedWrapper>;
    
    public function new(name:String, data:Dynamic, startingLabel:Dynamic = null) {
        
        _data = data;
        
        var asset = AssetManager.getScene(name);
        
        if (startingLabel == null)
            startingLabel = 1;
        
        if (asset.totalFrames > 1)
            asset.gotoAndPlay(startingLabel);
        
        asset.name = "scene";
        super(asset);
    }
    
    override function setDefaults() {
        super.setDefaults();
        
        _assets = new Map<String, ScriptedWrapper>();
        _assetMap = 
            [ "hero" => HeroWrapper
            ];
        
        _scriptId = "scene";
        isParent = true;
        _cameraBounds = new Rectangle();
        _labels = new Map<String, FrameData>();
    }
    
    override public function update():Void {
        super.update();
        
        if (_clip.currentFrame == _clip.totalFrames && _clip.totalFrames > 1) {
            
            _clip.stop();
            Game.nextScene();
        }
    }
    
    override function init():Void {
        super.init();
        
        initCamera();
        initAssets();
        initLabels();
    }
    
    function initCamera() {
        
        var cameraBoundsMC:MovieClip = SwfUtils.get(target, 'cameraBounds');
        if (cameraBoundsMC != null){
            
            _cameraBounds = cameraBoundsMC.getBounds(target);
            target.removeChild(cameraBoundsMC);
            
        } else {
            
            //_cameraBounds.width  = Game.stage.stageWidth;
            //_cameraBounds.height = Game.stage.stageHeight;
            //_cameraBounds.x = -_cameraBounds.width  / 2;
            //_cameraBounds.y = -_cameraBounds.height / 2;
        }
        
        // --- CAMERA BOUNDS CAN'T BE SMALLER THAN THE LEVEL
        if (_cameraBounds.width  < Game.mainStage.stageWidth)
            _cameraBounds.width  = Game.mainStage.stageWidth;
        if (_cameraBounds.height < Game.mainStage.stageHeight)
            _cameraBounds.height = Game.mainStage.stageHeight;
        
        Game.camera.bounds.copyFrom(_cameraBounds);
        Game.camera.drawTarget = this;
    }
    
    function initAssets():Void {
        
        _interactables = SwfUtils.getAll(target, 'interactable');
        for (interactable in _interactables) {
            
            interactable.useHandCursor = true;
            interactable.mouseEnabled  = true;
            interactable.mouseChildren = true;
            interactable.addEventListener(MouseEvent.CLICK, onInteract);
        }
        
        var assetData:Dynamic = {};
        if(_data != null && Reflect.hasField(_data, "assets")) {
            
            assetData = Reflect.field(_data, "assets");
            
            var assetClass:Class<ScriptedWrapper>;
            var type:String;
            var child:DisplayObject;
            var data:Dynamic;
            for (assetName in Reflect.fields(assetData)) {
                
                data = Reflect.field(assetData, assetName);
                type = Reflect.field(data, "type");
                assetClass = ScriptedWrapper;
                if (type != null && Assert.isTrue(_assetMap.exists(type), 'Invalid [type="$type"]'))
                    assetClass = _assetMap[type];
                
                child = target.getChildByName(assetName);
                if (child != null)
                    _assets[assetName] = cast addWrapper(Type.createInstance(assetClass, [child]));
            }
            
            // --- ONCE ALL ASSETS ARE CREATED, INIT THEM
            for (assetName in _assets.keys())
                _assets[assetName].parseData(Reflect.field(assetData, assetName));
        }
    }
    
    function initLabels():Void {
        
        var labelData:Dynamic = {};
        if(_data != null && Reflect.hasField(_data, "labels")) {
            
            labelData = Reflect.field(_data, "labels");
            
            for(frame in _clip.currentLabels)
                _labels[frame.name] = new FrameData(_clip, frame, Reflect.field(labelData, frame.name));
            
            for (frame in _labels) {
                
                if (frame.isEnd && Expect.isTrue(_labels.exists(frame.beginLabel), 'found [label="${frame.name}"] without a matching "${frame.beginLabel}"'))
                    _labels[frame.beginLabel].endFrame = frame;
            }
        }
    }
    
    override function onAddedToStage(e:Event = null) {
        super.onAddedToStage(e);
        
        if (_data != null && Reflect.hasField(_data, "actions"))
            ScriptInterpreter.run(Reflect.field(_data, "actions"));
    }
    
    function onInteract(e:MouseEvent):Void {
        
        //InteractMenu.setTarget(cast e.currentTarget);
    }
    
    override public function destroy():Void {
        super.destroy();
        
        _cameraBounds = null;
        _interactables = null;
        _data = null;
        
        for (label in _labels)
            label.destroy();
        
        for (asset in _assets)
            asset.destroy();
        
        _labels = null;
        _assets = null;
    }
}

class FrameData {
    
    static inline var END:String = "_end";
    
    static var _tokens:Array<String> = [
        "choice",
        "death",
        "stop"
    ];
    
    public var endFrame:FrameData;
    public var isEnd(default, null):Bool;
    public var beginLabel(default, null):String;
    public var number(get, never):Int;
    function get_number():Int { return _frame.frame; }
    public var name(get, never):String;
    function get_name():String { return _frame.name; }
    
    var _target:MovieClip;
    var _frame:FrameLabel;
    var _data:Dynamic;
    var _isPlaying:Bool;
    
    public function new(target:MovieClip, frame:FrameLabel, data:Dynamic) {
        
        _target = target;
        _frame = frame;
        _data = data;
        
        var i = _frame.name.indexOf(END);
        if (i > -1 && i == _frame.name.length - END.length) {
            
            isEnd = true;
            beginLabel = _frame.name.substr(0, i);
        }
        
        if (!isEnd && _frame != null)
            _target.addFrameScript(number-1, execute);
    }
    
    function execute():Void {
        
        var tokenFound:Bool = false;
        for (token in _tokens) {
            
            if (_frame.name.indexOf(token) == 0) {
                
                tokenFound = true;
                Reflect.getProperty(this, "label_" + token)();
                break;
            }
        }
        
        if (!tokenFound && _data != null)
            ScriptInterpreter.run(_data);
    }
    
    function label_death():Void {
        
        var ui = initMenu(DeathMenu);
        if (ui != null)
            ui.click.add(onRestartClick);
    }
    
    function onRestartClick():Void {
        
        _target.gotoAndPlay(1);
    }
    
    function label_choice():Void {
        
        if (Expect.nonNull(_data, 'Null data [label=${_frame.name}] not stopping')) {
            
            var ui = initMenu(ChoiceMenu);
            if (ui != null)
                ui.onSelect.add(handleSelectionComplete);
        }
    }
    
    function handleSelectionComplete(choice:String):Void {
        
        ScriptInterpreter.run(Reflect.field(_data, choice));
    }
    
    function initMenu<T:MenuWrapper>(menuType:Class<T>):T {
        
        var ui = Type.createInstance(menuType, [_target, _data]);
        
        if (endFrame != null) {
            
            ui.enabled = false;
            FuncUtils.addFrameScriptOnce(_target, endFrame.number - 1, label_menuEnd.bind(ui));
        }
        else
            _target.stop();
        
        return ui;
    }
    
    function label_menuEnd(ui:MenuWrapper):Void {
        
        _target.stop();
        ui.enabled = true;
    }
    
    function label_stop():Void {
        
        _target.stop();
    }
    
    public function destroy():Void {
        
        _target.addFrameScript(number, null);
        
        _data = null;
        _frame = null;
        _target = null;
    }
}