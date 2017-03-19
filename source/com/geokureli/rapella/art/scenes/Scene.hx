package com.geokureli.rapella.art.scenes;

import com.geokureli.rapella.art.ui.DeathMenu;
import com.geokureli.rapella.utils.SwfUtils;
import com.geokureli.rapella.utils.FuncUtils;
import com.geokureli.rapella.ScriptInterpreter.IScriptInterpretable;
import com.geokureli.rapella.utils.TimeUtils;
import hx.debug.Expect;
import com.geokureli.rapella.art.scenes.ActionScene;
import openfl.events.Event;
import flash.display.FrameLabel;
import com.geokureli.rapella.art.ui.ChoiceMenu;
import hx.debug.Assert;
import com.geokureli.rapella.art.ui.InteractMenu;
import com.geokureli.rapella.utils.SwfUtils;
import openfl.display.MovieClip;
import openfl.display.Sprite;
import openfl.events.MouseEvent;
import openfl.geom.Rectangle;

/**
 * ...
 * @author George
 */

class Scene extends Wrapper {
    
    var _cameraBounds:Rectangle;
    var _interactables:Array<Sprite>;
    var _labels:Map<String, FrameData>;
    var _data:Dynamic;
    
    public function new(name:String) {
        
        _data = ScriptInterpreter.getSceneData(name);
        
        super(AssetManager.getScene(name));
        
        if (_clip.totalFrames > 1)
            _clip.gotoAndPlay(1);
    }
    
    override function setDefaults() {
        super.setDefaults();
        
        _scriptId = "scene";
        _isParent = true;
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
    
    override function initChildren() {
        super.initChildren();
        
        var cameraBoundsMC:MovieClip = SwfUtils.get(_target, 'cameraBounds');
        if (cameraBoundsMC != null){ 
            
            _cameraBounds = cameraBoundsMC.getBounds(_target);
            _target.removeChild(cameraBoundsMC);
            
        } else {
            
            //_cameraBounds.width  = Game.stage.stageWidth;
            //_cameraBounds.height = Game.stage.stageHeight;
            //_cameraBounds.x = -_cameraBounds.width  / 2;
            //_cameraBounds.y = -_cameraBounds.height / 2;
        }
        
        initCamera();
        
        _interactables = SwfUtils.getAll(_target, 'interactable');
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
    }
    
    override function onAddedToStage(e:Event = null) {
        super.onAddedToStage(e);
        
        if (Reflect.hasField(_data, "actions"))
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
    
    static var _tokens:Array<String> = [
        "choice",
        "death",
        "stop"
    ];
    
    public var number(get, never):Int;
    function get_number():Int { return _frame.frame; }
    
    var _target:MovieClip;
    var _frame:FrameLabel;
    var _data:Dynamic;
    var _isPlaying:Bool;
    
    public function new(target:MovieClip, frame:FrameLabel, data:Dynamic) {
        
        _target = target;
        _frame = frame;
        _data = data;
        
        _frame.addEventListener(Event.FRAME_LABEL, execute);
    }
    
    function execute(e:Event):Void {
        _frame.removeEventListener(Event.FRAME_LABEL, execute);
        
        for (token in _tokens) {
            
            if (_frame.name.indexOf(token) == 0) {
                
                Reflect.getProperty(this, "label_" + token)();
                break;
            }
        }
    }
    
    function handleExecuteComplete():Void
    {
        if (_frame != null)
            _frame.addEventListener(Event.FRAME_LABEL, execute);
    }
    
    function label_choice():Void {
        
        if (!Expect.nonNull(_data, 'Null data [label=${_frame.name}, not stopping'))
            return;
        
        _target.stop();
        
        var ui = new ChoiceMenu(_target, _data);
        ui.onSelect.add(handleSelectionComplete);
    }
    
    public function handleSelectionComplete(choice:String):Void {
        
        ScriptInterpreter.run(Reflect.field(_data, choice));
        handleExecuteComplete();
    }
    
    function label_stop():Void {
        
        _target.stop();
        handleExecuteComplete();
    }
    
    function label_death():Void {
        
        _target.stop();
        
        var ui = new DeathMenu(_target, _data);
        ui.onClick.add(handleRestartClick);
    }
    
    function handleRestartClick():Void {
        
        _target.gotoAndPlay(1);
        handleExecuteComplete();
    }
    
    public function destroy():Void {
        
        _frame.removeEventListener(Event.FRAME_LABEL, execute);
        
        _data = null;
        _frame = null;
        _target = null;
    }
}