package mobile;

#if mobile
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxMath;
import lime.utils.Assets;
import states.FreeplayState;
import utilities.CoolUtil;

/**
 * The "ports" of the freeplay of some mods: a big picture for each group of songs, that fades in behind the list.
 *
 * Those mods read the picture of each song from `data/freeplaySonglist.txt` (6th field of the line of the song, `name:icon:week:difficulties:color:port`)
 * and the pictures from `images/freeplay/ports/<port>.png` (`data.txt` of the same folder lists them).
 * The scripts of the mods keep ALL of the pictures loaded at once (dozens of 1280x720 pictures), which is too much for a phone and depends
 * on fields that changed between versions of the engine, so the engine does it itself: only the picture of the selected song is loaded,
 * the others are freed when they faded out.
 */
class FreeplayPorts {
	static inline var FOLDER:String = "freeplay/ports/";

	var state:FreeplayState;

	/** song name (lowercase) -> port. */
	var portOfSong:Map<String, String> = [];

	/** port -> its sprite (only the ones that are showing or fading). */
	var sprites:Map<String, FlxSprite> = [];

	var target:String = null;

	/** Where the pictures go in the state: right over the background. */
	var insertIndex:Int = 0;

	/**
	 * Gives the ports of the current mod, or `null` when it doesn't have any.
	 */
	public static function create(state:FreeplayState):FreeplayPorts {
		try {
			if (!Assets.exists(Paths.file('images/freeplay/ports/data.txt')))
				return null;

			var ports:FreeplayPorts = new FreeplayPorts();
			ports.state = state;
			ports.read();
			return ports.portOfSong.keys().hasNext() ? ports : null;
		} catch (e:Dynamic) {
			trace('Freeplay ports: $e', ERROR);
			return null;
		}
	}

	function new() {}

	function read():Void {
		var lines:Array<String> = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));
		if (lines.length == 0) {
			// not found through the asset library: look for it straight in the folder of the mod
			var path:String = modding.ModFiles.fix('mods/${utilities.Options.getData("curMod")}/data/freeplaySonglist.txt');
			if (sys.FileSystem.exists(path))
				lines = [for (l in sys.io.File.getContent(path).split("\n")) l.trim()].filter(l -> l != "");
		}

		for (line in lines) {
			var fields:Array<String> = line.split(":");
			if (fields.length > 5 && fields[5].trim() != "")
				portOfSong.set(fields[0].trim().toLowerCase(), fields[5].trim());
		}

		// `extraData: { "port": "..." }` of freeplay.json works too
		for (song in state.songs) {
			var port:Dynamic = song.extraData != null ? Reflect.field(song.extraData, "port") : null;
			if (port != null && Std.string(port) != "")
				portOfSong.set(song.name.toLowerCase(), Std.string(port));
		}
	}

	/**
	 * Tells which song is selected now.
	 */
	public function select(songName:String):Void {
		var port:String = songName != null ? portOfSong.get(songName.toLowerCase()) : null;
		if (port == target)
			return;
		target = port;

		if (port == null || sprites.exists(port))
			return;

		var file:String = Paths.image(FOLDER + port);
		if (!Assets.exists(file)) {
			trace('Freeplay port not found: $file', WARNING);
			return;
		}

		try {
			var sprite:FlxSprite = new FlxSprite();
			sprite.loadGraphic(Paths.gpuFile(file));
			sprite.alpha = 0;
			sprite.antialiasing = utilities.Options.getData("antialiasing");

			// covers the whole stage (it is wider than 1280 in the FULL SCREEN mode)
			var scale:Float = Math.max(FlxG.width / sprite.frameWidth, FlxG.height / sprite.frameHeight);
			sprite.scale.set(scale, scale);
			sprite.updateHitbox();
			sprite.screenCenter();

			state.insert(Std.int(Math.max(0, state.members.indexOf(state.bg) + 1)), sprite);
			sprites.set(port, sprite);
		} catch (e:Dynamic) {
			trace('Freeplay port "$port": $e', ERROR);
		}
	}

	public function update(elapsed:Float):Void {
		for (port => sprite in sprites) {
			sprite.alpha = FlxMath.lerp(sprite.alpha, port == target ? 1 : 0, Math.min(1, elapsed * 8));

			// faded out: free it
			if (port != target && sprite.alpha < 0.02) {
				sprites.remove(port);
				state.remove(sprite, true);
				sprite.destroy();
			}
		}
	}
}
#end
