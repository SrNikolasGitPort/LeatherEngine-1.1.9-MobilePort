package mobile;

#if mobile
import flixel.FlxG;
import flixel.system.scaleModes.FillScaleMode;
import flixel.system.scaleModes.RatioScaleMode;
import lime.app.Application;
import openfl.Lib;
import openfl.events.Event;
#if android
import lime.system.JNI;
#end

/**
 * Applies the settings from `Options > Mobile Options` that need to be pushed to the system.
 *
 * The system bars (status / navigation bar) are always hidden. The `Fullscreen` option only decides how the game fits the screen:
 * ON stretches it over the whole screen (no black bars on the sides), OFF keeps the original proportions.
 */
class MobileSettings {
	static var started:Bool = false;

	/**
	 * Hides the system bars and keeps them hidden, also when the app comes back to the front.
	 */
	public static function initialize():Void {
		if (started)
			return;
		started = true;

		enableImmersive();
		Lib.current.stage.addEventListener(Event.ACTIVATE, (_) -> enableImmersive());
		Application.current.window.onFocusIn.add(enableImmersive);
	}

	public static function enableImmersive():Void {
		#if android
		try {
			var enable:Dynamic = JNI.createStaticMethod("com/leather128/funkin/MobileStorage", "enableImmersive", "()V");
			enable();
		} catch (e:Dynamic) {}
		#end
	}

	static var appliedMode:String = "";

	/**
	 * Sets how the game fits the screen from the `mobileScreenMode` option:
	 * - NORMAL: the original proportions, with black bars if the screen has other proportions,
	 * - STRETCHED: the picture is stretched over the whole screen,
	 * - ZOOMED: like NORMAL but with no black bars, the picture is widened to use the whole width of the screen (see `FullWidthScaleMode`).
	 */
	public static function applyFullscreen():Void {
		var mode:String = Options.getData("mobileScreenMode");

		enableImmersive();

		try {
			if (mode == appliedMode)
				return;

			switch (mode) {
				case "STRETCHED":
					FlxG.scaleMode = new FillScaleMode();
				case "ZOOMED":
					FlxG.scaleMode = new FullWidthScaleMode();
				default:
					mode = "NORMAL";
					FlxG.scaleMode = new RatioScaleMode();
			}
			appliedMode = mode;
		} catch (e:Dynamic) {}
	}
}

/**
 * Normal look, no black bars: the game fills the whole width of the screen (like a wider stage) and the height is only
 * enlarged half of what a full zoom would need, so almost nothing is cut off and the picture is barely stretched.
 */
class FullWidthScaleMode extends flixel.system.scaleModes.BaseScaleMode {
	override function updateGameSize(Width:Int, Height:Int):Void {
		var fitY:Float = Height / FlxG.height;
		var cover:Float = Math.max(fitY, Width / FlxG.width);
		gameSize.x = Width;
		gameSize.y = Math.ceil(FlxG.height * (fitY + (cover - fitY) * 0.5));
	}
}
#end
