package modding;

#if (MODDING_ALLOWED && mobile)
import haxe.io.Bytes;
import polymod.fs.SysFileSystem;
import polymod.fs.PolymodFileSystem.PolymodFileSystemParams;

/**
 * The file system of the mods for Android.
 *
 * Windows doesn't care about uppercase and lowercase in file names, but Android does: a mod that asks for `images/Freeplay/bg` while the file
 * is called `images/freeplay/BG.png` works on a PC and shows nothing on a phone. This works like the normal file system, and only when a file is
 * not found with the exact name it looks for it again ignoring the case (and the `#U2606` of zip tools, see `normalize`).
 */
class CaseInsensitiveFileSystem extends SysFileSystem {
	/** Folders already read: lowercase name of each entry -> the real name. */
	static var listings:Map<String, Map<String, String>> = [];

	/** Paths that were asked with the wrong case: the real path, or an empty text when there's no such file. */
	static var resolved:Map<String, String> = [];

	/**
	 * Forgets what was found. Called when the mods are loaded again and when a state starts, files can change in between.
	 */
	public static function clearCache():Void {
		listings.clear();
		resolved.clear();
	}

	public function new(params:PolymodFileSystemParams) {
		super(params);
	}

	override public function exists(path:String):Bool {
		return find(path) != null;
	}

	override public function isDirectory(path:String):Bool {
		var real:Null<String> = find(path);
		return real != null && sys.FileSystem.isDirectory(real);
	}

	override public function readDirectory(path:String):Array<String> {
		return super.readDirectory(find(path) ?? path);
	}

	override public function getFileBytes(path:String):Null<Bytes> {
		var real:Null<String> = find(path);
		if (real == null || sys.FileSystem.isDirectory(real))
			return null;
		return sys.io.File.getBytes(real);
	}

	override public function getFileContent(path:String):Null<String> {
		var bytes:Null<Bytes> = getFileBytes(path);
		return bytes == null ? null : bytes.toString();
	}

	/**
	 * The real path of a file or folder, or `null` if it doesn't exist (even ignoring the case).
	 */
	public static function find(path:String):Null<String> {
		if (path == null || path == "")
			return null;

		// almost every file is found like this
		if (sys.FileSystem.exists(path))
			return path;

		var known:Null<String> = resolved.get(path);
		if (known != null)
			return known == "" ? null : known;

		var real:Null<String> = search(path);
		resolved.set(path, real ?? "");
		return real;
	}

	static function search(path:String):Null<String> {
		var current:String = path.charAt(0) == "/" ? "/" : "";

		for (part in path.split("/")) {
			if (part == "" || part == ".") {
				continue;
			}

			var next:String = current == "" ? part : (current == "/" ? "/" + part : current + "/" + part);
			if (sys.FileSystem.exists(next)) {
				current = next;
				continue;
			}

			var entries:Null<Map<String, String>> = list(current == "" ? "." : current);
			var match:Null<String> = entries?.get(normalize(part));
			if (match == null)
				return null;

			current = current == "" ? match : (current == "/" ? "/" + match : current + "/" + match);
		}

		return current == "" ? null : current;
	}

	static final MANGLED:EReg = ~/#U([0-9A-Fa-f]{4,6})/g;

	/**
	 * The name used to compare file names: lowercase, and with the characters that some zip tools turn into `#U2606` written as the real
	 * character (a file called `CURE ☆.png` on the PC is `CURE #U2606.png` on a phone after it was extracted from a zip).
	 */
	static function normalize(name:String):String {
		if (name.indexOf("#U") >= 0)
			name = MANGLED.map(name, e -> String.fromCharCode(Std.parseInt("0x" + e.matched(1))));
		return name.toLowerCase();
	}

	static function list(directory:String):Null<Map<String, String>> {
		var cached:Null<Map<String, String>> = listings.get(directory);
		if (cached != null)
			return cached;

		var entries:Map<String, String> = [];
		try {
			for (name in sys.FileSystem.readDirectory(directory)) {
				var key:String = normalize(name);
				if (!entries.exists(key))
					entries.set(key, name);
			}
		} catch (e:Dynamic) {
			return null;
		}

		listings.set(directory, entries);
		return entries;
	}
}
#end
