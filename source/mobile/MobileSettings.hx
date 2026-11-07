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
	 * - ZOOMED: wide screen like FNF Mobile: same proportions, no black bars, the stage gets wider (see `FullWidthScaleMode`).
	 */
	public static function applyFullscreen():Void {
		var mode:String = Options.getData("mobileScreenMode");

		enableImmersive();

		try {
			if (mode == appliedMode)
				return;

			// leaving the wide screen: the stage goes back to 1280x720
			if (appliedMode == "ZOOMED" && mode != "ZOOMED")
				flixel.system.scaleModes.FullWidthScaleMode.restore();

			switch (mode) {
				case "STRETCHED":
					FlxG.scaleMode = new FillScaleMode();
				case "ZOOMED":
					FlxG.scaleMode = new flixel.system.scaleModes.FullWidthScaleMode();
				default:
					mode = "NORMAL";
					FlxG.scaleMode = new RatioScaleMode();
			}
			appliedMode = mode;
		} catch (e:Dynamic) {}
	}
}
#end
