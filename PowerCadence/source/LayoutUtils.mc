import Toybox.Graphics;

module LayoutUtils {
    function drawTwoLineCenter(dc as Graphics.Dc, top, bottom, color) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        dc.clear();
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w/2, h*0.38, Graphics.FONT_LARGE, top, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(w/2, h*0.70, Graphics.FONT_SMALL, bottom, Graphics.TEXT_JUSTIFY_CENTER);
    }
}
