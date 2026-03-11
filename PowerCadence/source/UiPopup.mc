import Toybox.Graphics;

module UiPopup {
    function drawPopup(dc as Graphics.Dc, text, bg, fg) {
        var w = dc.getWidth();
        var h = dc.getHeight();
        // var pad = 4;
        dc.setColor(fg, bg);
        dc.fillRectangle(0, h/3, w, h/3); // middle band
        dc.setColor(fg, bg);
        dc.drawText(w/2, h/2, Graphics.FONT_MEDIUM, text, Graphics.TEXT_JUSTIFY_CENTER);
    }
}
