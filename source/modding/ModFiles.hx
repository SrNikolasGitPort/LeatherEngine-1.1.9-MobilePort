package modding;

/**
 * Some parts of the engine look for files of the mods directly in the folders (the scripts of `classes`, `freeplay.json`, the scripts of the
 * songs...). On Android uppercase and lowercase letters count in file names, on Windows they don't, so a mod with `Classes/States/FreeplayState.hx`
 * works on a PC and is ignored on a phone. `fix` gives the real path of the file, however its name is written (and the same path if it's
 * not found, or when it's not a phone).
 */
class ModFiles {
	public static inline function fix(path:String):String {
		#if (MODDING_ALLOWED && mobile)
		return CaseInsensitiveFileSystem.find(path) ?? path;
		#else
		return path;
		#end
	}
}
