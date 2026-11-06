package mobile;

#if mobile
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import sys.thread.Thread;

private enum Step {
	/**
	 * Waiting for the player to allow the game to use the storage.
	 */
	PERMISSION;

	/**
	 * Copying the bundled game files to the engine folder.
	 */
	COPYING;

	/**
	 * Something went wrong.
	 */
	FAILED;
}

/**
 * Plain OpenFL screen (no Flixel yet) that runs before the game starts and makes sure the engine folder is ready:
 *
 * 1. asks for storage access if the engine folder is in the `EXTERNAL` storage,
 * 2. copies the bundled game files to the engine folder (first launch and after updates only).
 *
 * If there is nothing to do the game starts right away without showing anything.
 */
class MobileSetupScreen extends Sprite {
	var onFinish:Void->Void;
	var step:Step = COPYING;

	var title:TextField;
	var status:TextField;
	var file:TextField;
	var bar:Sprite;
	var allowButton:Sprite;
	var retryButton:Sprite;
	var percent:TextField;
	var count:TextField;
	var hint:TextField;
	var subtitle:TextField;
	var shownProgress:Float = 0;

	var copyFinished:Bool = false;
	var copySuccess:Bool = false;
	var done:Bool = false;

	public function new(onFinish:Void->Void) {
		super();
		this.onFinish = onFinish;

		title = makeText(38, true);
		title.text = "LEATHER ENGINE";
		subtitle = makeText(16, false);
		subtitle.text = "1.1.9  ·  Mobile Port";
		subtitle.alpha = 0.55;
		percent = makeText(34, true);
		count = makeText(15, false);
		count.alpha = 0.7;
		hint = makeText(13, false);
		hint.alpha = 0.45;
		retryButton = makeButton("Try again");
		status = makeText(20, false);
		file = makeText(13, false);
		file.alpha = 0.6;
		bar = new Sprite();
		allowButton = makeButton("Allow access");

		allowButton.addEventListener(MouseEvent.CLICK, (_) -> MobileFiles.requestStorageAccess());
		retryButton.addEventListener(MouseEvent.CLICK, (_) -> begin());

		addChild(title);
		addChild(subtitle);
		addChild(status);
		addChild(percent);
		addChild(bar);
		addChild(count);
		addChild(file);
		addChild(hint);
		addChild(allowButton);
		addChild(retryButton);
	}

	function makeText(size:Int, bold:Bool):TextField {
		var text:TextField = new TextField();
		text.selectable = false;
		text.mouseEnabled = false;
		text.multiline = true;
		text.wordWrap = true;
		text.defaultTextFormat = new TextFormat("_sans", size, 0xFFFFFF, bold, null, null, null, null, TextFormatAlign.CENTER);
		return text;
	}

	function makeButton(label:String):Sprite {
		var button:Sprite = new Sprite();
		button.mouseChildren = false;
		button.buttonMode = true;

		var text:TextField = makeText(20, true);
		text.text = label;
		text.name = "label";
		button.addChild(text);
		return button;
	}

	/**
	 * Called once the screen is on the stage.
	 */
	public function start():Void {
		addEventListener(Event.ENTER_FRAME, update);
		begin();
	}

	/**
	 * Checks what is left to do, can be called again after the player changed something.
	 */
	function begin():Void {
		MobileFiles.refreshStorageDirectory();

		if (!MobileFiles.hasStorageAccess()) {
			step = PERMISSION;
			return;
		}

		MobileFiles.setWorkingDirectory();

		if (!MobileFiles.needsSetup()) {
			finish();
			return;
		}

		step = COPYING;
		copyFinished = false;

		Thread.create(() -> {
			copySuccess = MobileFiles.copyBundledFiles();
			copyFinished = true;
		});
	}

	function finish():Void {
		if (done)
			return;

		done = true;
		removeEventListener(Event.ENTER_FRAME, update);
		onFinish();
	}

	function update(_:Event):Void {
		if (done)
			return;

		// the player came back from the settings screen with the access granted
		if (step == PERMISSION && MobileFiles.hasStorageAccess()) {
			begin();
			if (done)
				return;
		}

		if (step == COPYING && copyFinished) {
			if (copySuccess) {
				finish();
				return;
			}
			step = FAILED;
		}

		draw();
	}

	function draw():Void {
		var stageWidth:Float = Lib.current.stage.stageWidth;
		var stageHeight:Float = Lib.current.stage.stageHeight;
		var accent:Int = step == FAILED ? 0xFF6B6B : 0x5FCBFF;

		// background
		graphics.clear();
		var matrix:openfl.geom.Matrix = new openfl.geom.Matrix();
		matrix.createGradientBox(stageWidth, stageHeight, Math.PI / 2);
		graphics.beginGradientFill(openfl.display.GradientType.LINEAR, [0x101830, 0x000000], [1, 1], [0, 255], matrix);
		graphics.drawRect(0, 0, stageWidth, stageHeight);
		graphics.endFill();

		// the card in the middle
		var cardWidth:Float = Math.min(stageWidth * 0.8, 900);
		var cardHeight:Float = Math.min(stageHeight * 0.62, 400);
		var cardX:Float = (stageWidth - cardWidth) / 2;
		var cardY:Float = stageHeight * 0.3;
		graphics.lineStyle(2, accent, 0.35);
		graphics.beginFill(0xFFFFFF, 0.06);
		graphics.drawRoundRect(cardX, cardY, cardWidth, cardHeight, 36, 36);
		graphics.endFill();
		graphics.lineStyle();

		// the title is a bit above the card
		title.width = subtitle.width = stageWidth;
		title.x = subtitle.x = 0;
		title.y = stageHeight * 0.07;
		subtitle.y = title.y + title.textHeight + 8;

		var innerWidth:Float = cardWidth - 80;
		var innerX:Float = cardX + 40;
		status.width = percent.width = count.width = file.width = innerWidth;
		status.x = percent.x = count.x = file.x = innerX;
		hint.width = stageWidth * 0.8;
		hint.x = stageWidth * 0.1;
		hint.y = stageHeight * 0.93;

		bar.graphics.clear();
		var copying:Bool = step == COPYING;
		bar.visible = percent.visible = count.visible = copying;
		file.visible = copying || step == FAILED;
		allowButton.visible = step == PERMISSION;
		retryButton.visible = step == FAILED;

		switch (step) {
			case PERMISSION:
				status.text = "Leather Engine keeps its mods and files in the folder\n\".Leather1.1.9\" of your storage.\nAllow it to access your files to continue.";
				status.y = cardY + 40;
				hint.text = "The folder can't be changed later: the mods and the assets live there.";
				layoutButton(allowButton, stageWidth, cardY + cardHeight - 110);
			case COPYING:
				// the bar moves smoothly between the values, the files come in jumps
				shownProgress += (MobileFiles.progress - shownProgress) * 0.2;

				var phaseName:String = MobileFiles.phase == "" ? "Preparing" : MobileFiles.phase;
				status.text = phaseName == "Mods" ? "Installing the mods" : (phaseName == "Game files" ? "Preparing the game files" : "Preparing");
				status.y = cardY + 36;

				percent.text = Std.int(shownProgress * 100) + "%";
				percent.y = cardY + 90;

				var barWidth:Float = innerWidth;
				var barHeight:Float = 18;
				var barY:Float = cardY + 170;

				bar.graphics.beginFill(0xFFFFFF, 0.14);
				bar.graphics.drawRoundRect(innerX, barY, barWidth, barHeight, barHeight, barHeight);
				bar.graphics.beginFill(accent);
				bar.graphics.drawRoundRect(innerX, barY, Math.max(barHeight, barWidth * shownProgress), barHeight, barHeight, barHeight);
				bar.graphics.endFill();

				count.text = MobileFiles.doneFiles + " / " + MobileFiles.totalFiles + " files";
				count.y = barY + 34;

				file.text = shorten(MobileFiles.currentFile, 56);
				file.alpha = 0.4;
				file.y = barY + 64;

				hint.text = "This only happens on the first launch and after updates.";
			case FAILED:
				status.text = "Could not prepare the game files";
				status.y = cardY + 36;
				file.text = Std.string(MobileFiles.error);
				file.alpha = 0.75;
				file.y = cardY + 100;
				hint.text = "Make sure there is enough free storage space, then try again.";
				layoutButton(retryButton, stageWidth, cardY + cardHeight - 110);
		}
	}

	/**
	 * Cuts the middle of a long path so the start and the end are still seen.
	 */
	function shorten(text:String, max:Int):String {
		if (text == null || text.length <= max)
			return text == null ? "" : text;

		var keep:Int = Std.int((max - 3) / 2);
		return text.substr(0, keep) + "..." + text.substr(text.length - keep);
	}

	function layoutButton(button:Sprite, stageWidth:Float, y:Float):Void {
		var width:Float = stageWidth * 0.6;
		var height:Float = 60;

		var label:TextField = cast button.getChildByName("label");
		label.width = width;
		label.y = (height - label.textHeight) / 2 - 3;

		button.graphics.clear();
		button.graphics.lineStyle(3, 0xFFFFFF, 0.8);
		button.graphics.beginFill(0x5FCBFF, 0.25);
		button.graphics.drawRoundRect(0, 0, width, height, 24, 24);
		button.graphics.endFill();

		button.x = (stageWidth - width) / 2;
		button.y = y;
	}
}
#end
