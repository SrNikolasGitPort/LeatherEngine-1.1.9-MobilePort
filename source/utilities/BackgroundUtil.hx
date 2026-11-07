package utilities;

import openfl.utils.Assets;
import flixel.util.FlxColor;
import flixel.FlxSprite;


/**
 * Helper class for loading menu backgrounds.
 * Should be used via:
 * ```hx
 * using utilities.BackgroundUtil;
 * ```
 */
class BackgroundUtil{

    /**
     * Creates a new menu background.
     * @param sprite the `FlxSprite` to manipulate.
     * @param color the color the background should be.
     * @return FlxSprite
     */
    public static function makeBackground(sprite:FlxSprite, color:FlxColor):FlxSprite{
        if(!Options.getData("menuBGs")){
            sprite.makeGraphic(1286, 730, color, true);
            return fillWideScreen(sprite);
        }
        sprite.color = color;
        var skin:String = Assets.exists(Paths.image('ui skins/${Options.getData('uiSkin')}/backgrounds/menuDesat')) ? Options.getData('uiSkin') : 'default';
        sprite.loadGraphic(Paths.gpuBitmap('ui skins/${skin}/backgrounds/menuDesat'));
        return fillWideScreen(sprite);
	}

    /**
     * Mobile wide screen: the stage is wider than 1280, the background is enlarged to cover all of it (no black strip at the side).
     */
    static function fillWideScreen(sprite:FlxSprite):FlxSprite{
        #if mobile
        var needed:Float = flixel.FlxG.width + 100;
        if(sprite.frameWidth > 0 && sprite.frameWidth < needed){
            var ratio:Float = needed / sprite.frameWidth;
            sprite.scale.set(ratio, ratio);
            sprite.updateHitbox();
        }
        #end
        return sprite;
    }
}