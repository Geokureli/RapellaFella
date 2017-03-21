package com.geokureli.rapella.art.ui;

import com.geokureli.rapella.script.ScriptInterpreter;
import com.geokureli.rapella.utils.FuncUtils;
import hx.debug.Assert;
import openfl.events.MouseEvent;
import com.geokureli.rapella.utils.SwfUtils;
import openfl.text.TextField;
import openfl.display.MovieClip;
import openfl.events.Event;
import hx.event.Signal;
import motion.Actuate;
import openfl.display.Sprite;

class ChoiceMenu extends MenuWrapper {
    
    static var _statToken:EReg = ~/\[(\w+)\]/i;
    
    public var onSelect:Signal<String>;
    
    var _options:Array<MovieClip>;
    
    public function new(target:Sprite, data:Dynamic) { super(target, data); }
    
    override function setDefaults() {
        super.setDefaults();
        
        onSelect = new Signal<String>();
    }
    
    override function initChildren():Void {
        super.initChildren();
        
        _options = SwfUtils.getAll(_target, "option[]");
        var texts:Array<TextField> = SwfUtils.getAll(_target, "text[]");
        
        var btnY:Float = 0;
        var spacing:Float = 0;
        var textOffset:Float = 0;
        if (Assert.isTrue(_options.length > 0 && texts.length > 0, "missing choice art")) {
            
            if (_options.length > 1)
                spacing = _options[1].y - _options[0].y;
            btnY = _options[0].y;
            textOffset = texts[0].y - btnY;
        }
        
        var i:Int = _options.length;
        while (i-- > 0) {
            
            if (texts.length > i && isValidOption(i, texts[i].text)) {
                
                texts[i].mouseEnabled = false;
                _options[i].alpha = 0;
                _options[i].useHandCursor = true;
                
                _options[i].y = btnY + spacing * i;
                texts[i].y = _options[i].y + textOffset;
                
            } else {
                
                texts[i].visible = false;
                texts.splice(i, 1);
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
        
        _options = null;
    }
}