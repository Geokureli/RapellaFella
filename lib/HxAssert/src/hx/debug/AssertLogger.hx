package hx.debug;

import haxe.PosInfos;

/**
 * ...
 * @author George
 */
class AssertLogger {
    
    public function new(fail:?String->?PosInfos->Void):Void { 
        
        if (fail != null)
            this.fail = fail;
    }
    
    /**
     * Called by failed asserts, throws an error by default. 
     * Can be redirected to any function.
     * 
     * @example myAssert.fail = haxe.Log.trace;    myAssert.isTrue(false, "test");// output: test
     * 
     * @param msg  An optional error message. If not passed a default one will be used
     */
    public dynamic function fail(?msg:String, ?pos:PosInfos):Void {
        
        if (msg == null) msg = "Failure";
        
        throw '${pos.fileName}[${pos.lineNumber}]: $msg';
    }
    
    inline public function isTrue(cond:Bool, ?msg:String, ?pos:PosInfos):Bool {
        
        if (!cond) fail(msg, pos);
        
        return cond;
    }
    
    inline public function isFalse(cond:Bool, ?msg:String, ?pos:PosInfos):Bool {
        
        return isTrue(!cond, msg, pos);
    }
    
    inline public function isNull(value:Dynamic, ?msg:String, ?pos:PosInfos):Bool {
        
        if (msg == null) msg = 'Expected null, got ${q(value)}';
        
        return isTrue(value == null, msg, pos);
    }
    
    inline public function nonNull(value:Dynamic, ?msg:String, ?pos:PosInfos):Bool {
        
        if (msg == null) msg = 'Unexpected null';
        
        return isTrue(value != null, msg, pos);
    }
    
    //@:generic
    inline public function exists<K, T>(map:Map<K, T>, key:K, ?msg:String, ?pos:PosInfos):Bool {
        
        if (msg == null)
            msg = 'Could not find key ${Std.string(key)}';
        
        return nonNull(map, null, pos) 
            && isTrue(map.exists(key), msg, pos);
    }
    
    //@:generic
    inline public function notExists<K, T>(map:Map<K, T>, key:K, ?msg:String, ?pos:PosInfos):Bool {
        
        if (msg == null)
            msg = 'Unexpected key ${Std.string(key)}';
        
        return nonNull(map, null, pos)
            && isTrue(!map.exists(key), msg, pos);
    }
    
    inline public function has(object:Dynamic, field:String, ?msg:String, ?pos:PosInfos):Bool {
        
        if (msg == null)
            msg = 'Could not find field $field';
        
        return nonNull(object, null, pos)
            && isTrue(Reflect.hasField(object, field), msg, pos);
    }
    
    inline public function missing(object:Dynamic, field:String, ?msg:String, ?pos:PosInfos):Bool {
        
        if (msg == null)
            msg = 'Unexpected field $field';
        
        return nonNull(object, null, pos)
            && isTrue(!Reflect.hasField(object, field), msg, pos);
    }
    
    inline public function is(value:Dynamic, type:Dynamic, ?msg:String, ?pos:PosInfos):Bool {
        
        if (msg == null)
            msg = 'Expected type ${typeToString(type)} but it is ${typeToString(value)}';
        
        return isTrue(Std.isOfType(value, type), msg, pos);
    }
    
    inline public function isNot(value:Dynamic, type:Dynamic, ?msg:String, ?pos:PosInfos):Bool {
        
        if (msg == null)
            msg = 'Unexpected type ${typeToString(type)}';
        
        return isTrue(!Std.isOfType(value, type), msg, pos);
    }
    
    inline public function isObject(value:Dynamic, ?msg:String, ?pos:PosInfos):Bool {
        
        if (msg == null)
            msg = "Expected Object type";
        
        return isTrue(Reflect.isObject(value), msg, pos);
    }
    
    inline public function equals(value:Dynamic, expected:Dynamic, ?msg:String, ?pos:PosInfos):Bool {
        
        if(msg == null) msg = 'Expected ${q(expected)} but it is ${q(value)}';
        
        return isTrue(expected == value, msg, pos);
    }
    
    inline public function notEquals(value:Dynamic, expected:Dynamic, ?msg:String, ?pos:PosInfos):Bool {
        
        if (msg == null)
            msg = 'Expected ${q(expected)} and test value ${q(value)} should be different';
        
        return isTrue(value != expected, msg, pos);
    }
    
    inline public function match(pattern:EReg, value:Dynamic, ?msg:String, ?pos:PosInfos):Bool {
        
        if(msg == null) msg = '${q(value)} does not match the provided pattern';
        
        return isTrue(pattern.match(value), msg, pos);
    }
    
    inline public function floatEquals(value:Float, expected:Float, approx:Float = 1e-5, ?msg:String, ?pos:PosInfos):Bool {
        
        if (msg == null) msg = 'Expected ${q(expected)} but it is ${q(value)}';
        
        return isTrue(compareFloats(expected, value, approx), msg, pos);
    }
    
    function compareFloats(value:Float, expected:Float, approx:Float):Bool {
        
        if (Math.isNaN(expected)) return Math.isNaN(value);
        if (Math.isNaN(value))    return false;
        
        if (!Math.isFinite(expected) && !Math.isFinite(value))
            return (expected > 0) == (value > 0);
        
        return Math.abs(value - expected) <= approx;
    }
    
    inline public function contains<T>(list:Iterable<T>, item:T, ?msg:String, ?pos:PosInfos):Bool {
        
        if (msg == null) msg = 'Couldn\'t find ${item} in ${q(list)}';
        return isTrue(Lambda.has(list, item), msg, pos);
    }
    
    inline public function notContains<T>(list:Array<T>, item:T, ?msg:String, ?pos:PosInfos):Bool {
        
        if (msg == null) msg = 'Found unexpected ${item} in ${q(list)}';
        
        return isTrue(!Lambda.has(list, item), msg, pos);
    }
    
    inline public function stringContains(str:String, token:String, ?msg:String, ?pos:PosInfos):Bool {
        
        if (msg == null) msg = 'String ${q(str)} do not contain ${token}';
        
        return isTrue(str != null && str.indexOf(token) >= 0, msg, pos);
    }
    
    // =============================================================================
    //{ region                            HELPERS
    // =============================================================================
    
    function typeToString(t:Dynamic):String {
        
        try {
            var _t = Type.getClass(t);
            
            if (_t != null) t = _t;
            
        } catch(e:Dynamic) { }
        
        try return Type.getClassName(t) catch (e:Dynamic) { }
        
        try {
            var _t = Type.getEnum(t);
            
            if (_t != null) t = _t;
            
        } catch(e:Dynamic) { }
        
        try return Type.getEnumName(t)        catch (e:Dynamic) { }
        try return Std.string(Type.typeof(t)) catch (e:Dynamic) { }
        try return Std.string(t)              catch (e:Dynamic) { }
        
        return "<Unknown Type>";
    }
    
    /** Wraps in quotes */
    inline function q(v:Dynamic):String {
        
        if (v is String)
            v = '"' + StringTools.replace(v, '"', '\\"') + '"';
        
        return Std.string(v);
    }
    
    //} endregion                         HELPERS
    // =============================================================================
    
}