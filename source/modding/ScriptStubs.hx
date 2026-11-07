package modding;

#if !DISCORD_ALLOWED
/**
 * Mods call `DiscordClient.changePresence(...)` in their scripts (almost always in the first lines of `createPost`). The phone version of the
 * engine has no Discord, and without this a script that calls it fails right there: everything that comes after is never made (a custom
 * Freeplay with no background, no images...). The scripts get this one, that does nothing.
 */
class ScriptDiscordClient {
	public static var active(default, null):Bool = false;
	public static var defaultID(default, never):String = "864980501004812369";
	public static var ID:String = defaultID;

	public static function startup():Void {}

	public static function shutdown():Void {}

	public static function updatePresence():Void {}

	public static function loadModPresence():Bool {
		return false;
	}

	public static function changePresence(details:String = "", ?state:String, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float,
			largeImageKey:String = "icon", largeImageText:String = "Leather Engine"):Void {}
}
#end

#if mobile
/**
 * The `.ndll` files of the mods are made for the computer, they can't be loaded on Android. The scripts of the mods that use `CFFI` directly get
 * a function that does nothing instead of an error.
 */
class ScriptCFFI {
	public static function load(library:String, method:String, args:Int = 0, lazy:Bool = false):Dynamic {
		return Reflect.makeVarArgs(function(_:Array<Dynamic>):Dynamic return null);
	}
}
#end

#if mobile
/**
 * `FlxSprite` for the scripts of mods. A script that loads an image from its path (`new FlxSprite().loadGraphic(Paths.image("..."))`) keeps a copy of
 * it in the RAM too, and mods with dozens of big images (freeplay ports) filled the memory of phones until the images stopped showing.
 * Here the image goes to the GPU and the RAM copy is dropped (the same thing `VRAM Sprites` does for the engine's own sprites).
 */
class ScriptSprite extends flixel.FlxSprite {
	override public function loadGraphic(Graphic:flixel.system.FlxAssets.FlxGraphicAsset, Animated:Bool = false, Width:Int = 0, Height:Int = 0, Unique:Bool = false,
			?Key:String):flixel.FlxSprite {
		if (Std.isOfType(Graphic, String) && !Animated && !Unique && utilities.Options.getData("vramSprites") == true) {
			try {
				Graphic = Paths.gpuFile(cast Graphic);
			} catch (e:Dynamic) {}
		}
		return super.loadGraphic(Graphic, Animated, Width, Height, Unique, Key);
	}
}
#end
