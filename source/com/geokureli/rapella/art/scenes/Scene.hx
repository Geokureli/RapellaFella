package com.geokureli.rapella.art.scenes;

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
    
    public function new(name:String, startingLabel:Dynamic = null) {
        
        _data = ScriptInterpreter.getSceneData(name);
        
        var asset = AssetManager.getScene(name);
        
        if (startingLabel == null)
            startingLabel = 1;
        
        if (asset.totalFrames > 1)
            asset.gotoAndPlay(startingLabel);
        
        super(asset);
    }
    
    override function setDefaults() {
        super.setDefaults();
        
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
    
    override function init() {
        super.init();
        
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
        
        initCamera();
        
        _interactables = SwfUtils.getAll(target, 'interactable');
        for (interactable in _interactables) {
            
            interactable.useHandCursor = true;
            interactable.mouseEnabled  = true;
            interactable.mouseChildren = true;
            interactable.addEventListener(MouseEvent.CLICK, onInteract);
        }
        
        initLabels();
    }
    
    function initCamera() {
        
        // --- CAMERA BOUNDS CAN'T BE SMALLER THAN THE LEVEL
        if (_cameraBounds.width  < Game.mainStage.stageWidth)
            _cameraBounds.width  = Game.mainStage.stageWidth;
        if (_cameraBounds.height < Game.mainStage.stageHeight)
            _cameraBounds.height = Game.mainStage.stageHeight;
        
        Game.camera.bounds.copyFrom(_cameraBounds);
        Game.camera.drawTarget = this;
    }
    
    function initLabels():Void
    {
        var labelData:Dynamic = {};
        if(_data != null && Reflect.hasField(_data, "labels"))
            labelData = Reflect.field(_data, "labels");
        
        for(frame in _clip.currentLabels)
            _labels[frame.name] = new FrameData(_clip, frame, Reflect.field(labelData, frame.name));
        
        for (frame in _labels) {
            
            if (frame.isEnd && Expect.isTrue(_labels.exists(frame.beginLabel), 'found [label="${frame.name}"] without a matching "${frame.beginLabel}"'))
                _labels[frame.beginLabel].endFrame = frame;
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
        
        _labels = null;
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
        
        addListeners();
    }
    
    function execute(e:Event):Void {
        _frame.removeEventListener(Event.FRAME_LABEL, execute);
        
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
    
    function addListeners():Void
    {
        if (!isEnd && _frame != null)
            _frame.addEventListener(Event.FRAME_LABEL, execute);
    }
    
    function label_choice():Void {
        
        if (!Expect.nonNull(_data, 'Null data [label=${_frame.name}, not stopping'))
            return;
        
        var ui = new ChoiceMenu(_target, _data);
        ui.onSelect.add(handleSelectionComplete);
        
        if (endFrame != null) {
            
            ui.enabled = false;
            FuncUtils.addListenerOnce(endFrame._frame, Event.FRAME_LABEL, label_menuEnd.bind(ui));
        }
        else
            _target.stop();
        
    }
    
    function label_menuEnd(ui:MenuWrapper, e:Event):Void {
        
        _target.stop();
        ui.enabled = true;
    }
    
    public function handleSelectionComplete(choice:String):Void {
        
        ScriptInterpreter.run(Reflect.field(_data, choice));
        addListeners();
    }
    
    function label_stop():Void {
        
        _target.stop();
        addListeners();
    }
    
    function label_death():Void {
        
        _target.stop();
        
        var ui = new DeathMenu(_target, _data);
        ui.onClick.add(handleRestartClick);
    }
    
    function handleRestartClick():Void {
        
        _target.gotoAndPlay(1);
        addListeners();
    }
    
    public function destroy():Void {
        
        _frame.removeEventListener(Event.FRAME_LABEL, execute);
        
        _data = null;
        _frame = null;
        _target = null;
    }
}