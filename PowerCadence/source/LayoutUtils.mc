import Toybox.Graphics;
import Toybox.WatchUi;

module LayoutUtils {
    var _cadenceIcon = null;

    function drawTwoLineCenter(dc as Graphics.Dc, top, bottom, color) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var topY = h * 0.38;
        dc.clear();
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);

        if (_cadenceIcon == null) {
            try {
                _cadenceIcon = WatchUi.loadResource(Rez.Drawables.iconCadence);
            } catch (e) {
                _cadenceIcon = null;
            }
        }

        if (_cadenceIcon != null) {
            var iconH = _cadenceIcon.getHeight();
            var iconX = (w / 2) - 46;
            var iconY = topY - (iconH / 2);
            dc.drawBitmap(iconX, iconY, _cadenceIcon);
        }

        dc.drawText(w/2, topY, Graphics.FONT_LARGE, top, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(w/2, h*0.70, Graphics.FONT_SMALL, bottom, Graphics.TEXT_JUSTIFY_CENTER);
    }
}
