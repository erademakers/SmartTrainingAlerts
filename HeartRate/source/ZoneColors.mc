using Toybox.Graphics as Gfx;

module ZoneColors {
    function colorForZone(z)  {
        if (z <= 2) {return Gfx.COLOR_GREEN;}
        if (z == 3 or z == 4) {return Gfx.COLOR_ORANGE;}
        return Gfx.COLOR_RED;
    }
}
