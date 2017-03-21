package com.geokureli.rapella.functional;
class MultiListener {
    
    var _listener:Void->Void;
    var _callbacks:Map<Int, String>;
    var _numCreated:Int;
    var _numHandled:Int;
    
    public function new(listener:Void->Void) {
        
        _listener = listener;
        _callbacks = new Map<Int, String>();
        _numCreated = 0;
        _numHandled = 0;
    }
    
    public function createListener(id:String = null):Void->Void {
        
        if (id == null)
            id = "[unnamed]";
        
        _callbacks[_numCreated] = id;
        
        return handle.bind(_numCreated++);
    }
    
    function handle(index:Int):Void {
        
        _callbacks.remove(index);
        
        if(++_numHandled == _numCreated){
            
            _listener();
            destroy();
        }
    }
    
    public function destroy():Void {
        
        _callbacks = null;
        _listener = null;
    }
    
    public function getLog():String { return _callbacks.toString(); }
}
