package mobile;

#if mobile
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.group.FlxGroup;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

/**
 * The editors have no save dialog on a phone, so what they make goes to its own folder in the engine folder,
 * next to `assets` and `mods`: `Charts-Saves`, `Characters-Saves`, `Modcharts-Saves` and `Stages-Saves`.
 */
class EditorSaves {
	public static inline var CHARTS:String = "Charts-Saves";
	public static inline var CHARACTERS:String = "Characters-Saves";
	public static inline var MODCHARTS:String = "Modcharts-Saves";
	public static inline var STAGES:String = "Stages-Saves";

	/** Creates the four folders (the working directory is the engine folder). */
	public static function createFolders():Void {
		for (folder in [CHARTS, CHARACTERS, MODCHARTS, STAGES]) {
			try {
				if (!FileSystem.exists(folder))
					FileSystem.createDirectory(folder);
			} catch (e:Dynamic) {}
		}
	}

	/**
	 * Saves `data` in `<folder>/<subFolder>/<fileName>` and shows where it went on the screen of `state`.
	 *
	 * @return the full path, or `null` if it could not be saved.
	 */
	public static function save(state:FlxGroup, folder:String, subFolder:String, fileName:String, data:String):Null<String> {
		var saved:Null<String> = null;

		try {
			var directory:String = Path.join([folder, subFolder]);
			createDirectories(directory);
			var path:String = Path.join([directory, fileName]);
			File.saveContent(path, data);
			saved = Path.normalize(Path.join([Sys.getCwd(), path]));
		} catch (e:Dynamic) {
			trace('Could not save $fileName in $folder: $e', ERROR);
		}

		var toast:FlxText = new FlxText(0, FlxG.height * 0.85, FlxG.width,
			saved != null ? "Saved:\n" + saved : "Could not save (check the storage permission).", 14);
		toast.alignment = CENTER;
		toast.color = saved != null ? 0xFF9BFF9B : 0xFFFF6060;
		toast.borderStyle = OUTLINE;
		toast.borderColor = 0xFF000000;
		toast.scrollFactor.set();
		state.add(toast);
		FlxTween.tween(toast, {alpha: 0}, 1, {startDelay: 4, onComplete: (_) -> toast.destroy()});

		return saved;
	}

	static function createDirectories(path:String):Void {
		var parts:Array<String> = Path.normalize(path).split("/");
		var current:String = "";
		for (part in parts) {
			current = current == "" ? part : current + "/" + part;
			if (part != "" && !FileSystem.exists(current))
				FileSystem.createDirectory(current);
		}
	}
}
#end
