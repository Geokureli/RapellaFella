package com.geokureli.rapella.utils;

import motion.Actuate;
class TimeUtils {
    
    static public function delay(handler:Void->Void):Void {
        
        Actuate.timer(Game.spf).onComplete(handler);
    }
}
