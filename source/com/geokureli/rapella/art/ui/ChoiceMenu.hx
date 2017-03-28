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
    
    var _options:Array<Btn>;
    var _texts:Array<TextField>;
    
    public function new(target:Sprite, data:Dynamic) { super(target, data); }
    
    override function setDefaults() {
        super.setDefaults();
        
        _options = new Array<Btn>();
        _texts   = new Array<TextField>();
        
        onSelect = new Signal<String>();
        _childMap['option[]'] = { field:'_options', caster:Btn.caster };
        _childMap['text[]'  ] =         '_texts'  ;
    }
    
    override function init():Void {
        super.init();
        
        var btnY:Float = 0;
        var spacing:Float = 0;
        var textOffset:Float = 0;
        if (Assert.isTrue(_options.length > 0 && _texts.length > 0, "missing choice art")) {
            
            if (_options.length > 1)
                spacing = _options[1].target.y - _options[0].target.y;
            btnY = _options[0].target.y;
            textOffset = _texts[0].y - btnY;
        }
        
        var i:Int = _options.length;
        var text:TextField;
        while (i-- > 0) {
            
            text = getText(i);
            if (text != null && isValidOption(i, text.text)) {
                
                _texts[i].mouseEnabled = false;
                
                _options[i].target.y = btnY + spacing * i;
                _texts[i].y = _options[i].target.y + textOffset;
                
            } else {
                
                if (_texts.length > i) {
                    
                    _texts[i].visible = false;
                    _texts.splice(i, 1);
                }
                _options[i].enabled = false;
                _options.splice(i, 1);
            }
        }
    }
    
    function getText(i:Int):TextField {
        
        if (_texts.length > i)
            return _texts[i];
        
        return Reflect.field(_options[i], "label");
    }
    
    function isValidOption(index:Int, text:String):Bool {
        
        if (Reflect.field(_data, _options[index].target.name) == null)
            return false;
        
        // --- CHECK CORRECT STAT
        return !_statToken.match(text.toLowerCase())
            || _statToken.matched(1) == ScriptInterpreter.getVar("stat");
    }
    
    override function handleShowComplete():Void {
        super.handleShowComplete();
        
        for (option in _options) {
            
            option.onClick(handleClick.bind(option.target.name));
        }
    }
    
    function handleClick(choice:String):Void {
        
        if (!enabled)
            return;
        
        onSelect.dispatch(choice);
        destroy();
    }
    
    override public function destroy():Void {
        super.destroy();
        
        onSelect.dispose();
    }
}