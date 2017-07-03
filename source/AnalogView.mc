//
// Copyright 2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.Graphics as Gfx;
using Toybox.Lang as Lang;
using Toybox.Math as Math;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.WatchUi as Ui;

// This implements an analog watch face
// Original design by Austen Harbour
class AnalogView extends Ui.WatchFace
{
    var font;
    var isAwake;
    var counter;
    var screenShape;
    var dndIcon;
    var vasaImage;

    function initialize() {
        WatchFace.initialize();
        screenShape = Sys.getDeviceSettings().screenShape;
        
      
    }

    function onLayout(dc) {
        font = Ui.loadResource(Rez.Fonts.id_font_black_diamond);
        if (Sys.getDeviceSettings() has :doNotDisturb) {
            dndIcon = Ui.loadResource(Rez.Drawables.DoNotDisturbIcon);
        } else {
            dndIcon = null;
        }
        
        vasaImage = Ui.loadResource(Rez.Drawables.VasaImage);
    }

    // Draw the watch hand
    // @param dc Device Context to Draw
    // @param angle Angle to draw the watch hand
    // @param length Length of the watch hand
    // @param width Width of the watch hand
    function drawHand(dc, angle, length, width) {
        // Map out the coordinates of the watch hand
        var coords = [[-(width / 2),0], [-(width / 2), -length], [width / 2, -length], [width / 2, 0]];
        var result = new [4];
        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);

        // Transform the coordinates
        for (var i = 0; i < 4; i += 1) {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin);
            var y = (coords[i][0] * sin) + (coords[i][1] * cos);
            result[i] = [centerX + x, centerY + y];
        }

        // Draw the polygon
        dc.fillPolygon(result);
        dc.fillPolygon(result);
    }

    // Draw the hash mark symbols on the watch
    // @param dc Device context
    function drawHashMarks(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();

        // Draw hashmarks differently depending on screen geometry
        if (Sys.SCREEN_SHAPE_ROUND == screenShape) {
            var sX, sY;
            var eX, eY;
            var outerRad = width / 2;
            var innerRad = outerRad - 10;
            // Loop through each 15 minute block and draw tick marks
            for (var i = Math.PI / 6; i <= 11 * Math.PI / 6; i += (Math.PI / 3)) {
                // Partially unrolled loop to draw two tickmarks in 15 minute block
                sY = outerRad + innerRad * Math.sin(i);
                eY = outerRad + outerRad * Math.sin(i);
                sX = outerRad + innerRad * Math.cos(i);
                eX = outerRad + outerRad * Math.cos(i);
                dc.drawLine(sX, sY, eX, eY);
                i += Math.PI / 6;
                sY = outerRad + innerRad * Math.sin(i);
                eY = outerRad + outerRad * Math.sin(i);
                sX = outerRad + innerRad * Math.cos(i);
                eX = outerRad + outerRad * Math.cos(i);
                dc.drawLine(sX, sY, eX, eY);
            }
        } else {
            var coords = [0, width / 4, (3 * width) / 4, width];
            for (var i = 0; i < coords.size(); i += 1) {
                var dx = ((width / 2.0) - coords[i]) / (height / 2.0);
                var upperX = coords[i] + (dx * 10);
                // Draw the upper hash marks
                dc.fillPolygon([[coords[i] - 1, 2], [upperX - 1, 12], [upperX + 1, 12], [coords[i] + 1, 2]]);
                // Draw the lower hash marks
                dc.fillPolygon([[coords[i] - 1, height-2], [upperX - 1, height - 12], [upperX + 1, height - 12], [coords[i] + 1, height - 2]]);
            }
        }
    }

    // Handle the update event
    function onUpdate(dc) {
        var width;
        var height;
        var screenWidth = dc.getWidth();
        var clockTime = Sys.getClockTime();
        var myStats = System.getSystemStats();
        var hourHand;
        var minuteHand;
        var secondHand;
        var secondTail;
        
       
        width = dc.getWidth();
        height = dc.getHeight();

        var now = Time.now();
        var info = Calendar.info(now, Time.FORMAT_LONG);        
        var vasaloppetDate = new Time.Moment(1520146800); // Vasaloppet 2018
        
        var timeLeft = vasaloppetDate.subtract(now);

        var dateStr = Lang.format("$1$ $2$ $3$", [info.day_of_week, info.month, info.day]);
        var timeStr = Lang.format("$1$:$2$:$3$", [info.hour, info.min.format("%02d"), info.sec.format("%02d")]);
        var batStr = Lang.format("$1$%", [myStats.battery.toLong()]);
        
        var vasaString = Lang.format("$1$", [format_duration(timeLeft.value())]);
            
      

        // Clear the screen
       // dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
         dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_WHITE);
       
        dc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());

       
       
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);        // Draw the date
        dc.drawText(width / 2, 0, Gfx.FONT_MEDIUM, dateStr, Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, 20, Gfx.FONT_LARGE, timeStr, Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, 50, Gfx.FONT_SMALL, batStr, Gfx.TEXT_JUSTIFY_CENTER);
      
      
        dc.drawText(width / 2, height / 2 + 70, Gfx.FONT_MEDIUM, vasaString, Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawBitmap( 10, height / 2 - 15, vasaImage);   

        // Draw the hash marks
        drawHashMarks(dc);

        // Draw the do-not-disturb icon
        if (null != dndIcon && Sys.getDeviceSettings().doNotDisturb) {
            dc.drawBitmap( width * 0.75, height / 2 - 15, dndIcon);
        }      
        
      
    }
    
    function format_duration(seconds) {
    
    var remaindingSecondsOnHours = seconds % 3600;
    
    var left = seconds - (seconds - remaindingSecondsOnHours);
       
    var hh = seconds / 3600;
    var mm = seconds / 60 % 60;
    var ss = seconds % 60;
    
    var days = hh / 24;
    var secsLeftOnday = seconds - (days * 24 * 3600);
    var hors = secsLeftOnday / 3600;

    if (days != 0) {
        return Lang.format("$1$:$2$:$3$:$4$",
         [
                               days,
                               hors,
                               mm.format("%02d"),
                               ss.format("%02d")
                           ]);
    }
    else {
        return Lang.format("$1$:$2$", [
                               mm,
                               ss.format("%02d")
                           ]);
    }
}

    function onEnterSleep() {
        isAwake = false;
        Ui.requestUpdate();
    }

    function onExitSleep() {
        isAwake = true;
    }
}
