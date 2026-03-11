import Toybox.WatchUi;
import Toybox.Graphics;

class CadenceIcon extends WatchUi.Drawable {
    var _y = 6;
    var _textGap = 6;
    var _bitmap = null;

    function initialize(params) {
        Drawable.initialize(params);

        try {
            _bitmap = WatchUi.loadResource(Rez.Drawables.iconCadence);
        } catch (e) {
            _bitmap = null;
        }
    }

    function draw(dc as Graphics.Dc) as Void {
        if (_bitmap != null) {
            var label = "CADENCE";
            var textW = dc.getTextWidthInPixels(label, Graphics.FONT_XTINY);
            var groupW = _bitmap.getWidth() + _textGap + textW;
            var groupX = (dc.getWidth() - groupW) / 2;
            var iconX = groupX;
            var textX = iconX + _bitmap.getWidth() + _textGap;
            var textY = _y + (_bitmap.getHeight() / 2);

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(textX, textY, Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_LEFT);
            dc.drawBitmap(iconX, _y, _bitmap);
        }
    }
}
