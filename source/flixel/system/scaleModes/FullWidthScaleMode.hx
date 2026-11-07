package flixel.system.scaleModes;

import flixel.FlxG;

/**
 * Wide screen (like FNF Mobile): the picture keeps its normal proportions and the height of the screen, and the stage gets wider
 * until the width of the screen is full, so there are no black bars, no stretching and no zoom. The original 1280x720 area stays in the middle.
 */
class FullWidthScaleMode extends BaseScaleMode {
	override function onMeasure(Width:Int, Height:Int):Void {
		var scale:Float = Height / FlxG.initialHeight;
		FlxG.height = FlxG.initialHeight;
		FlxG.width = Std.int(Math.max(FlxG.initialWidth, Math.ceil(Width / scale)));
		updateGameSize(Width, Height);
		updateDeviceSize(Width, Height);
		updateScaleOffset();
		updateGamePosition();
	}

	override function updateGameSize(Width:Int, Height:Int):Void {
		gameSize.x = Width;
		gameSize.y = Height;
		resizeCameras();
	}

	/**
	 * Makes every camera as wide as the stage, the picture stays centered.
	 */
	public static function resizeCameras():Void {
		for (camera in FlxG.cameras.list) {
			if (camera == null)
				continue;
			var oldWidth:Float = camera.width;
			camera.setSize(FlxG.width, FlxG.height);
			camera.scroll.x += 0.5 * (oldWidth - FlxG.width);
		}
	}

	/**
	 * Back to the original 1280x720 stage.
	 */
	public static function restore():Void {
		for (camera in FlxG.cameras.list) {
			if (camera == null)
				continue;
			var oldWidth:Float = camera.width;
			camera.setSize(FlxG.initialWidth, FlxG.initialHeight);
			camera.scroll.x += 0.5 * (oldWidth - FlxG.initialWidth);
		}
		FlxG.width = FlxG.initialWidth;
		FlxG.height = FlxG.initialHeight;
	}
}
