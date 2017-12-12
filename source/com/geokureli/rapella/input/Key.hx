package com.geokureli.rapella.input;

import lime.app.Event;
import openfl.display.Stage;
import openfl.events.KeyboardEvent;

/**
 * Helper consts for all KeyCodes
 * @author George
 */
class Key {
    
    static var _stage:Stage;
    static var _states:Map<Int, Bool>;
    static var _listeners:Map<Int, Event<Bool->Void>>;
    static var _actions:Map<String, Int>;
    static var _binds:Map<Int, Array<String>>;
    
    inline static public function init(stage:Stage):Void {
        
       _stage = stage;
       _states    = new Map<Int, Bool>();
       _listeners = new Map<Int, Event<Bool->Void>>();
       _actions   = new Map<String, Int>();
       _binds     = new Map<Int, Array<String>>();
        
       _stage.addEventListener(KeyboardEvent.KEY_DOWN, keyHandler);
       _stage.addEventListener(KeyboardEvent.KEY_UP  , keyHandler);
    }
    
    inline static public function destroy():Void {
        
       _states    = null;
       _listeners = null;
       _actions   = null;
       _binds     = null;
        
       _stage.addEventListener(KeyboardEvent.KEY_DOWN, keyHandler);
       _stage.addEventListener(KeyboardEvent.KEY_UP  , keyHandler);
    }
    
    static function keyHandler(e:KeyboardEvent):Void {
        
       var wasDown = _states[e.keyCode];
       _states[e.keyCode] = e.type == KeyboardEvent.KEY_DOWN;
        
       handleListeners(e);
       if (wasDown != _states[e.keyCode])
           unpdateBinds(e);
    }
    
    inline static public function isDown (key:Int):Bool { return _states[key]; }
    inline static public function isUp   (key:Int):Bool { return !_states[key]; }
    inline static public function anyDown(keys:Array<Int>):Bool {
        
       var found = false;
        
       for (e in keys)
           if (isDown(e)) {
                
               found = true;
               break;
           }
        
       return found;
    }
    
    // =============================================================================
    //{ region                          LISTENERS
    // =============================================================================
    
    inline static function handleListeners(e:KeyboardEvent):Void {
        
       // --- DISPATCH LISTNERS
       if(_listeners.exists(e.keyCode))
           _listeners[e.keyCode].dispatch(_states[e.keyCode]);
    }
    
    inline static public function listen(key:Int, func:Bool->Void, ?once:Bool):Void {
        
       if (!_listeners.exists(key))
           _listeners[key] = new Event<Bool->Void>();
        
       _listeners[key].add(func, once);
    }
    
    inline static public function listenOnce(key:Int, func:Bool->Void):Void {
        
       listen(key, func, true);
    }
    
    inline static public function unlisten(key:Int, func:Bool->Void):Void {
        
       if (_listeners.exists(key))
           _listeners[key].remove(func);
    }
    
    //} endregion                       LISTENERS
    // =============================================================================
    
    // =============================================================================
    //{ region                          BINDS
    // =============================================================================
    
    inline static function unpdateBinds(e:KeyboardEvent):Void {
        
       // --- UPDATE WATCHERS
       if (_binds.exists(e.keyCode)) {
            
           var change = _states[e.keyCode] ? 1 : -1;
           for (i in 0 ... _binds[e.keyCode].length)
               _actions[_binds[e.keyCode][i]] += change;
       }
    }
    
    inline static function addBind(key:Int, action:String):Void {
        
       if (!_binds.exists(key))
           _binds[key] = new Array<String>();
        
       if(_binds[key].indexOf(action) == -1)
           _binds[key].push(action);
        
       if (_states[key])
           _actions[action] += 1;
    }
    
    inline static function removeBind(key:Int, action:String):Void {
        
       if (_binds.exists(key)
       &&  _binds[key].remove(action)) {
            
           if (_binds[key].length == 0)
               _binds.remove(key);
                
           if (_states[key])
               _actions[action] -= 1;
       }
    }
    
    inline static public function bind(key:Int, action:String):Void {
        
       if (!_actions.exists(action))
           _actions[action] = 0;
        
       addBind(key, action);
    }
    
    inline static public function unbind(key:Int, action:String):Void {
        
       if (_actions.exists(action))
           removeBind(key, action);
    }
    
    inline static public function bindAll(keys:Array<Int>, action:String):Void {
        
       if (!_actions.exists(action))
           _actions[action] = 0;
        
       for (key in keys)
           addBind(key, action);
    }
    
    inline static public function unbindAll(keys:Array<Int>, action:String):Void {
        
       if (_actions.exists(action)) {
            
           for (key in keys)
               removeBind(key, action);
       }
    }
    
    inline static public function checkAction(action:String):Bool {
        
       return _actions.exists(action) && _actions[action] > 0;
    }
    
    //} endregion                       BINDS
    // =============================================================================
    
    // =============================================================================
    //{ region                          KEYCODES
    // =============================================================================
    
    inline static public var BACKSPACE     :Int =   8;
    inline static public var TAB           :Int =   9;
    inline static public var ENTER         :Int =  13;
    inline static public var SHIFT         :Int =  16;
    inline static public var CONTROL       :Int =  17;
    inline static public var PAUSE         :Int =  19;
    inline static public var BREAK         :Int =  19;
    inline static public var CAPS_LOCK     :Int =  20;
    inline static public var ESC           :Int =  27;
    inline static public var SPACE         :Int =  32;
    inline static public var PAGE_UP       :Int =  33;
    inline static public var PAGE_DOWN     :Int =  34;
    inline static public var END           :Int =  35;
    inline static public var HOME          :Int =  36;
    inline static public var LEFT          :Int =  37;
    inline static public var UP            :Int =  38;
    inline static public var RIGHT         :Int =  39;
    inline static public var DOWN          :Int =  40;
    inline static public var INSERT        :Int =  45;
    inline static public var DELETE        :Int =  46;
    inline static public var D0            :Int =  48;
    inline static public var D1            :Int =  49;
    inline static public var D2            :Int =  50;
    inline static public var D3            :Int =  51;
    inline static public var D4            :Int =  52;
    inline static public var D5            :Int =  53;
    inline static public var D6            :Int =  54;
    inline static public var D7            :Int =  55;
    inline static public var D8            :Int =  56;
    inline static public var D9            :Int =  57;
    inline static public var A             :Int =  65;
    inline static public var B             :Int =  66;
    inline static public var C             :Int =  67;
    inline static public var D             :Int =  68;
    inline static public var E             :Int =  69;
    inline static public var F             :Int =  70;
    inline static public var G             :Int =  71;
    inline static public var H             :Int =  72;
    inline static public var I             :Int =  73;
    inline static public var J             :Int =  74;
    inline static public var K             :Int =  75;
    inline static public var L             :Int =  76;
    inline static public var M             :Int =  77;
    inline static public var N             :Int =  78;
    inline static public var O             :Int =  79;
    inline static public var P             :Int =  80;
    inline static public var Q             :Int =  81;
    inline static public var R             :Int =  82;
    inline static public var S             :Int =  83;
    inline static public var T             :Int =  84;
    inline static public var U             :Int =  85;
    inline static public var V             :Int =  86;
    inline static public var W             :Int =  87;
    inline static public var X             :Int =  88;
    inline static public var Y             :Int =  89;
    inline static public var Z             :Int =  90;
    inline static public var NUM_0         :Int =  96;
    inline static public var NUM_1         :Int =  97;
    inline static public var NUM_2         :Int =  98;
    inline static public var NUM_3         :Int =  99;
    inline static public var NUM_4         :Int = 100;
    inline static public var NUM_5         :Int = 101;
    inline static public var NUM_6         :Int = 102;
    inline static public var NUM_7         :Int = 103;
    inline static public var NUM_8         :Int = 104;
    inline static public var NUM_9         :Int = 105;
    inline static public var NUM_MULTIPLY  :Int = 106;
    inline static public var NUM_ADD       :Int = 107;
    inline static public var NUM_SUBTRACT  :Int = 109;
    inline static public var NUM_DECIMAL   :Int = 110;
    inline static public var NUM_DIVIDE    :Int = 111;
    inline static public var F1            :Int = 112;
    inline static public var F2            :Int = 113;
    inline static public var F3            :Int = 114;
    inline static public var F4            :Int = 115;
    inline static public var F5            :Int = 116;
    inline static public var F6            :Int = 117;
    inline static public var F7            :Int = 118;
    inline static public var F8            :Int = 119;
    inline static public var F9            :Int = 120;
    inline static public var F10           :Int = 121;
    inline static public var F11           :Int = 122;
    inline static public var F12           :Int = 123;
    inline static public var F13           :Int = 124;
    inline static public var F14           :Int = 125;
    inline static public var F15           :Int = 126;
    inline static public var NUM_LOCK      :Int = 144;
    inline static public var SCROLL_LOCK   :Int = 145;
    inline static public var COLON         :Int = 186;
    inline static public var EQUAL         :Int = 187;
    inline static public var COMMA         :Int = 188;
    inline static public var SUBTRACT      :Int = 189;
    inline static public var PERIOD        :Int = 190;
    inline static public var SLASH         :Int = 191;
    inline static public var TILDE         :Int = 192;
    inline static public var BRACKET_OPEN  :Int = 219;
    inline static public var BACK_SLASH    :Int = 220;
    inline static public var BRACKET_CLOSE :Int = 221;
    inline static public var QUOTE         :Int = 222;
    
    //} endregion                       KEYCODES
    // =============================================================================
}