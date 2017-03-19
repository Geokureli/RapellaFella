package com.geokureli.rapella.debug;

import openfl.filters.GlowFilter;
import hx.event.Signal;
import openfl.text.TextField;
import flash.display.Sprite;

class DebugConsole extends Sprite{
    
    static var _instance:DebugConsole;
    
    public var onForceShow(default, null):Signal<Bool>;
    
    var _output:TextField;
    
    public function new() {
        super();
        
        _instance = this;
        onForceShow = new Signal<Bool>();
        
        addChild(_output = new TextField());
        _output.x = DebugStats.GRAPH_WIDTH;
        _output.width = Game.mainStage.stageWidth - DebugStats.GRAPH_WIDTH;
        _output.height = 200;
        
        filters = [ new GlowFilter(0xFFFFFF, 1, 2, 2, 8, 2) ];
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
