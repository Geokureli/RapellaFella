package com.geokureli.rapella.art.ui;

import com.geokureli.rapella.script.ScriptInterpreter;
import hx.debug.Assert;
import openfl.events.MouseEvent;
import com.geokureli.rapella.utils.SwfUtils;
import openfl.text.TextField;
import openfl.display.MovieClip;
import openfl.events.Event;
import hx.event.Signal;
import openfl.display.Sprite;

class ChoiceMenu extends MenuWrapper {
    
    static var _statToken:EReg = ~/\[(\w+)\]/i;
    
    public var onSelect:Signal<String>;
    
    var _options:Array<MovieClip>;
    var _texts:Array<TextField>;
    
    public function new(target:Sprite, data:Dynamic) { super(target, data); }
    
    override function setDefaults() {
        super.setDefaults();
        
        _options = new Array<MovieClip>();
        _texts   = new Array<TextField>();
        
        onSelect = new Signal<String>();
        _childMap['option[]'] = '_options';
        _childMap['text[]'  ] = '_texts';
    }
    
    override function initChildren():Void {
        super.initChildren();
        
        var btnY:Float = 0;
        var spacing:Float = 0;
        var textOffset:Float = 0;
        if (Assert.isTrue(_options.length > 0 && _texts.length > 0, "missing choice art")) {
            
            if (_options.length > 1)
                spacing = _options[1].y - _options[0].y;
            btnY = _options[0].y;
            textOffset = _texts[0].y - btnY;
        }
        
        var i:Int = _options.length;
        while (i-- > 0) {
            
            if (_texts.length > i && isValidOption(i, _texts[i].text)) {
                
                _texts[i].mouseEnabled = false;
                _options[i].alpha = 0;
                _options[i].useHandCursor = true;
                
                _options[i].y = btnY + spacing * i;
                _texts[i].y = _options[i].y + textOffset;
                
            } else {
                
                _texts[i].visible = false;
                _texts.splice(i, 1);
                _options[i].visible = false;
                _options.splice(i, 1);
            }
        }
    }
    
    function isValidOption(index:Int, text:String):Bool {
        
        if (Reflect.field(_data, _options[index].name) == null)
            return false;
        
        // --- CHECK CORRECT STAT
        return !_statToken.match(text.toLowerCase())
            || _statToken.matched(1) == ScriptInterpreter.getVar("stat");
    }
    
    override function handleShowComplete():Void {
        super.handleShowComplete();
        
        for (option in _options) {
            
            option.addEventListener(MouseEvent.CLICK     , handleClick);
            option.addEventListener(MouseEvent.MOUSE_OVER, handleMouseRoll);
            option.addEventListener(MouseEvent.MOUSE_OUT , handleMouseRoll);
        }
    }
    
    function handleMouseRoll(e:Event):Void {
        
        e.currentTarget.alpha = e.type == MouseEvent.MOUSE_OVER ? 1 : 0;
    }
    
    function handleClick(e:Event):Void {
        
        if (!enabled)
            return;
        
        for (option in _options) {
            
            option.removeEventListener(MouseEvent.CLICK     , handleClick);
            option.removeEventListener(MouseEvent.MOUSE_OVER, handleMouseRoll);
            option.removeEventListener(MouseEvent.MOUSE_OUT , handleMouseRoll);
        }
        
        onSelect.dispatch(e.currentTarget.name);
    }
    
    override public function destroy():Void {
        super.destroy();
        
        onSelect.dispose();
    }
}