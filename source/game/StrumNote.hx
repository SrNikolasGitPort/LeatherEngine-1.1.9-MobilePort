package game;

import game.Note.JsonData;
import openfl.Assets;
import haxe.Json;
import flixel.FlxG;
import utilities.NoteVariables;
import shaders.ColorSwap;
import shaders.NoteColors;
import states.PlayState;
import flixel.FlxSprite;
import flixel.addons.effects.FlxSkewedSprite;

using StringTools;

/*
	credit to psych engine devs (sorry idk who made this originally, all ik is that srperez modified it for shaggy and then i got it from there)
 */
class StrumNote extends #if MODCHARTING_TOOLS modcharting.FlxSprite3D #else FlxSkewedSprite #end {
	public var resetAnim:Float = 0;

	private var noteData:Int = 0;

	public var swagWidth:Float = 0;

	public var ui_Skin:String = "default";
	public var ui_settings:Array<String>;
	public var mania_size:Array<String>;
	public var keyCount:Int;

	public var colorSwap:ColorSwap = new ColorSwap();
	public var noteColor:Array<Int> = [255, 0, 0];
	public var affectedbycolor:Bool = false;

	public var isPlayer:Float;

	public var jsonData:JsonData;

	public static var cachedConfig(default, never):Map<String, JsonData> = [];

	public var modAngle:Float = 0;

	public function new(x:Float, y:Float, noteData:Int, ?ui_Skin:String, ?ui_settings:Array<String>, ?mania_size:Array<String>, ?keyCount:Int,
			?isPlayer:Float) {
		super(x, y);
		if (ui_Skin == null)
			ui_Skin = PlayState.SONG.ui_Skin;
		if(!Assets.exists('assets/data/ui skins/$ui_Skin')){
			ui_Skin = 'default';
		}


		if (ui_settings == null)
			ui_settings = PlayState.instance.ui_settings;

		if (mania_size == null)
			mania_size = PlayState.instance.mania_size;

		if (keyCount == null)
			keyCount = PlayState.SONG.keyCount;

		this.noteData = noteData;
		this.ui_Skin = ui_Skin;
		this.ui_settings = ui_settings;
		this.mania_size = mania_size;
		this.keyCount = keyCount;
		this.isPlayer = isPlayer;

		inline function setValues() {
			for (value in jsonData.values) {
				this.affectedbycolor = value.affectedbycolor;
			}
		}

		if (Assets.exists(Paths.json("ui skins/" + ui_Skin + "/config")) && !cachedConfig.exists(ui_Skin)) {
			jsonData = Json.parse(Assets.getText(Paths.json("ui skins/" + ui_Skin + "/config")));
			setValues();
			cachedConfig.set(ui_Skin, jsonData);
		} else if (cachedConfig.exists(ui_Skin)) {
			jsonData = cachedConfig.get(ui_Skin);
			setValues();
		}

		var spritesheetPath:String;
		if(Assets.exists(Paths.image('ui skins/$ui_Skin/arrows/strums', 'shared'))){
			spritesheetPath = 'ui skins/$ui_Skin/arrows/strums';
		}
		else if(Assets.exists(Paths.image('ui skins/$ui_Skin/arrows/default', 'shared'))){
			spritesheetPath = 'ui skins/$ui_Skin/arrows/default';
		}
		// Check for if source mod has custom spritesheet without strums.
		else if(Assets.exists(Paths.image('ui skins/default/arrows/strums', 'shared'))){
			spritesheetPath = 'ui skins/strums/arrows/strums';
		}
		else{
			spritesheetPath = 'ui skins/strums/arrows/default';
		}

		frames = Paths.getSparrowAtlas(spritesheetPath, 'shared');

		var animation_Base_Name:String = NoteVariables.maniaDirections[keyCount - 1][Std.int(Math.abs(noteData))].toLowerCase();

		animation.addByPrefix('static', animation_Base_Name + " static");
		animation.addByPrefix('pressed', NoteVariables.animationDirections[keyCount - 1][noteData] + ' press', 24, false);
		animation.addByPrefix('confirm', NoteVariables.animationDirections[keyCount - 1][noteData] + ' confirm', 24, false);

		antialiasing = ui_settings[3] == "true";

		setGraphicSize((width * Std.parseFloat(ui_settings[0])) * (Std.parseFloat(ui_settings[2]) - (Std.parseFloat(mania_size[keyCount - 1]))));
		updateHitbox();
		noteColor = NoteColors.getNoteColor(NoteVariables.animationDirections[keyCount - 1][noteData]);
		shader = affectedbycolor ? colorSwap.shader : null;

		if (affectedbycolor && PlayState.instance != null && colorSwap != null) {
			if (noteColor != null) {
				colorSwap.r = noteColor[0];
				colorSwap.g = noteColor[1];
				colorSwap.b = noteColor[2];
			}
		}
		playAnim('static');
	}

	/**
	 * Only draws the arrow while it glows (V-Slice mobile layout: the opponent's arrows are hidden).
	 */
	public var hideStatic:Bool = false;

	override function draw():Void {
		if (hideStatic && animation.name == "static")
			return;
		super.draw();
	}

	override function update(elapsed:Float) {
		#if MODCHARTING_TOOLS angle3D.z #else angle #end = modAngle;
		if (resetAnim > 0) {
			resetAnim -= elapsed;

			if (resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}

		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		// updateHitbox();
		centerOrigin();

		if (anim == "static") {
			colorSwap.r = 255;
			colorSwap.g = 0;
			colorSwap.b = 0;

			swagWidth = width;
		} else {
			colorSwap.r = noteColor[0];
			colorSwap.g = noteColor[1];
			colorSwap.b = noteColor[2];
		}

		var scale:Float = Std.parseFloat(ui_settings[0]) * (Std.parseFloat(ui_settings[2]) - (Std.parseFloat(mania_size[keyCount - 1])));

		centerOffsets();
	}
}
