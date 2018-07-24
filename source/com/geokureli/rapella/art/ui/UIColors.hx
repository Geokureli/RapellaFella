package com.geokureli.rapella.art.ui;

import flash.filters.GlowFilter;

class UIColors {
    
    static public var GLOW_DEBUG_CLICK:GlowFilter = new GlowFilter(0x0000FF, 1, 2, 2, 8, 1);
    static public var GLOW_CAN_USE    :GlowFilter = new GlowFilter(0x00FF00, 1, 2, 2, 8, 1);
    static public var GLOW_CANT_USE   :GlowFilter = new GlowFilter(0xFF0000, 1, 2, 2, 8, 1);
}
