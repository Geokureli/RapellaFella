package com.geokureli.rapella.art.ui;

import openfl.display.DisplayObjectContainer;

class DeathMenu extends MenuWrapper {
    
    var _restartButton:Btn;
    
    public function new(target:DisplayObjectContainer, data:Dynamic) { super(target, data); }
    
    override function setDefaults() {
        super.setDefaults();
        
        _childMap["restartButton"] = "_restartButton";
        _restartButton = new Btn()
            .onClick(handleClick);
        
    }
    
    function handleClick():Void {
        
        click.dispatch();
        destroy();
    }
}
