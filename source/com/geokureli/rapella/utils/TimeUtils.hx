package com.geokureli.rapella.utils;

import motion.Actuate;
import motion.actuators.IGenericActuator;
class TimeUtils {
    
    static public function delay(handler:Void->Void):IGenericActuator {
        
        return Actuate.timer(Game.SPF).onComplete(handler);
    }
}
