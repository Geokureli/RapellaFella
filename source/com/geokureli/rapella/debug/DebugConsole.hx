package com.geokureli.rapella.debug;

import com.geokureli.rapella.utils.SwfUtils;
import openfl.filters.GlowFilter;
import hx.event.Signal;
import openfl.text.*;
import flash.display.Sprite;

class DebugConsole extends Sprite{
    
    static var _instance:DebugConsole;
    
    public var onForceShow(default, null):Signal<Bool>;
    
    var _output:TextField;
    
    public function new() {
        super();
        
        name = "DebugConsole";
        _instance = this;
        onForceShow = new Signal<Bool>();
        
        addChild(_output = new TextField());
        var format:TextFormat = _output.defaultTextFormat;
        format.font = "Arial";
        format.color = 0xFFFFFF;
        _output.defaultTextFormat = format;
        
        _output.x = DebugStats.GRAPH_WIDTH;
        _output.width = Game.mainStage.stageWidth - DebugStats.GRAPH_WIDTH;
        _output.height = 200;
        
        filters = [ new GlowFilter(0, 1, 2, 2, 8, 1) ];
        
        SwfUtils.mouseDisableAll(this);
    }
    
    public function addLog(msg:String, forceShow:Bool = false):Void {
        
        if (forceShow) {
            
            //onForceShow.dispatch(true);
            DebugOverlay.show(true);
        }
        
        _output.appendText('\n$msg');
    }
    
    static public function log(msg:String, forceShow:Bool = false):Void {
        
        if (_instance == null)
            return;
        
        _instance.addLog(msg, forceShow);
    }
}
