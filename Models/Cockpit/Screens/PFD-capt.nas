# ==============================================================================
# 737 MAX Primary Flight Display
# Israel Emmanuel
# ==============================================================================

var PFDC_canvas = nil;
var PFDC_display = nil;
var months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];

var canvas_PFDC = {
	new: func(canvas_group) {
		var m = {parents: [canvas_PFDC]};
		var PFDC = canvas_group;
		var font_mapper = func(family, weight) {
			return "OCRBMT.TTF";
		};
		
		canvas.parsesvg(PFDC, "Aircraft/737-MAX/Models/Cockpit/Screens/PFD-capt.svg" , {'font-mapper': font_mapper});
		
		var svg_keys = ["ground", "sky", "attitude", "turn-coordinator", "max-attitude", "afds-mode", "single-ch-back", "single-ch", "vor1", "vor2", "dme1", "dme2", "flt-no", "xpdr", "selcal", "registration", "day", "month", "year", "elapsed", "utc", "timer-arm", "timer-analog", "back-trans", "compass-text", "compass", "ap-heading", "sel-hdg", "hdg-type", "press-set", "wind-arrow", "wind-speed", "wind-heading","wing-stats", "ground-speed", "true-airspeed", "fd-horizontal", "fd-vertical", "alt-ground", "ap-alt-tape", "alt-tape0", "alt-tape1", "alt-tape2", "alt-tape3", "alt-tape4", "alt-tape5", "alt-tape6", "alt-tape7", "alt-tape8", "alt-tape9", "alt-neg", "alt-20", "alt-100", "alt-1000", "alt-10000", "alt-00000", "alt-m", "alt-final-box", "alt-final", "ap-alt-thousand", "ap-alt-hundred", "ap-alt-meter", "spd-box", "spd-tape", "mach", "spd-1", "spd-10", "spd-100", "spd-ap", "spd-limitUR", "spd-limitUB", "spd-limitLR", "spd-limitLB", "spd-limitY", "aoa-needle", "vs-neg", "vs-pos", "vnav", "lnav", "a-throttle", "ap-mode"];
		foreach(var key; svg_keys)
			m[key] = PFDC.getElementById(key);

        m["alt-tape0"].set("clip", "rect(58, 864, 406, 803)");
        m["alt-tape1"].set("clip", "rect(58, 864, 406, 803)");
        m["alt-tape2"].set("clip", "rect(58, 864, 406, 803)");
        m["alt-tape3"].set("clip", "rect(58, 864, 406, 803)");
        m["alt-tape4"].set("clip", "rect(58, 864, 406, 803)");
        m["alt-tape5"].set("clip", "rect(58, 864, 406, 803)");
        m["alt-tape6"].set("clip", "rect(58, 864, 406, 803)");
        m["alt-tape7"].set("clip", "rect(58, 864, 406, 803)");
        m["alt-tape8"].set("clip", "rect(58, 864, 406, 803)");
        m["alt-tape9"].set("clip", "rect(58, 864, 406, 803)");
        m["alt-ground"].set("clip", "rect(58, 864, 406, 803)");
        m["alt-20"].set("clip", "rect(210, 885, 254, 822)");
        m["alt-100"].set("clip", "rect(210, 885, 254, 822)");
        m["alt-1000"].set("clip", "rect(210, 885, 254, 822)");
        m["alt-10000"].set("clip", "rect(210, 885, 254, 822)");
        m["spd-1"].set("clip", "rect(207, 481, 256, 437)");
        m["spd-10"].set("clip", "rect(207, 481, 256, 437)");
        m["spd-100"].set("clip", "rect(207, 481, 256, 437)");
        m["spd-limitUR"].set("clip", "rect(58, 506, 406, 500)");
        m["spd-limitUB"].set("clip", "rect(58, 506, 406, 500)");
        m["spd-limitLR"].set("clip", "rect(58, 506, 406, 500)");
        m["spd-limitLB"].set("clip", "rect(58, 506, 406, 500)");
        m["spd-limitY"].set("clip", "rect(58, 506, 406, 500)");
        m["spd-tape"].set("clip", "rect(58, 500, 406, 439)");
        m["aoa-needle"].set("clip", "rect(112, 917, 352, 894)");

        # Center Setting
        m["turn-coordinator"].setCenter(647, 232);
        m["ap-heading"].setCenter(647, 654);
        m.timers=[];

		return m;
	},

	update: func() {
        #Setup stuff
        me["back-trans"].setColorFill(0, 0, 0, 0.3);

        # Variables
        var pitchDeg = getprop("orientation/pitch-deg");
        var rollDeg = getprop("orientation/roll-deg");
        var afds = getprop("autopilot/display/afds-mode");
        var nav = [getprop("instrumentation/nav[0]/frequencies/selected-mhz"), getprop("instrumentation/nav[1]/frequencies/selected-mhz")];
        var elapsedSec = getprop("instrumentation/nav[0]/frequencies/selected-mhz");
        var headingDeg = getprop("orientation/heading-deg");
        var headingAP = getprop("it-autoflight/input/hdg");
        var windHeading = getprop("environment/wind-from-heading-deg");
        var altitude = getprop("position/altitude-ft");
        var altitudeAGL = getprop("position/altitude-agl-ft");
        var altitudeAP = getprop("it-autoflight/input/alt");
        var ias = getprop("instrumentation/airspeed-indicator/indicated-speed-kt");
        var stall = getprop("instrumentation/weu/state/stall-speed");
        var vSpeed = getprop("velocities/vertical-speed-fps");
        var vsi = getprop("instrumentation/pfd/vsi-needle-deg");
        


		# Artificial Horizon
        me["ground"].setTranslation(0, pitchDeg*4.8).setCenter(647, 232-(pitchDeg*4.8)).setRotation(-rollDeg*D2R);
        me["sky"].setTranslation(0, pitchDeg*4.8).setCenter(647, 232-(pitchDeg*4.8)).setRotation(-rollDeg*D2R);
        me["attitude"].setTranslation(0, pitchDeg*4.8).setCenter(647, 232-(pitchDeg*4.8)).setRotation(-rollDeg*D2R);
        if (rollDeg > 60)
            me["turn-coordinator"].setRotation(-60*D2R);
        elsif (rollDeg < -60)
            me["turn-coordinator"].setRotation(60*D2R);
        else
            me["turn-coordinator"].setRotation(-rollDeg*D2R);

        # AFDS Mode
        if(afds == "SINGLE CH") {
            me["single-ch"].show();
            me["single-ch-back"].show();
            me["afds-mode"].hide();
        } else {
            me["single-ch"].hide();
            me["single-ch-back"].hide();
            me["afds-mode"].show();
            me["afds-mode"].setText(afds);
        }

        # NAV Radio
        me["dme1"].setText(sprintf("%.03d", nav[0]));
        me["dme2"].setText(sprintf("%0.3d", nav[1]));
        if(getprop("instrumentation/nav[0]/nav-id") == "")
            me["vor1"].setText("------");
        else
            me["vor1"].setText(getprop("instrumentation/nav[0]/nav-id"));
        if(getprop("instrumentation/nav[1]/nav-id") == "")
            me["vor2"].setText("------");
        else
            me["vor2"].setText(getprop("instrumentation/nav[1]/nav-id"));

        # Auxiliary Panel
        me["flt-no"].setText(getprop("sim/model/airline-code"));
        me["xpdr"].setText(getprop("instrumentation/transponder/id-code"));
        me["selcal"].setText(getprop("sim/model/selcal"));
        me["registration"].setText(getprop("sim/model/registration"));
        me["elapsed"].setText(sprintf("%i:%02i", elapsedSec/60, math.mod(elapsedSec, 60)));
        me["day"].setText(sprintf("%02i", getprop("sim/time/utc/day")));
        me["month"].setText(months[getprop("sim/time/utc/month") - 1]);
        me["year"].setText(sprintf("%02i", math.mod(getprop("sim/time/utc/year"), 100)));
        me["utc"].setText(sprintf("%sz", getprop("sim/time/gmt-string")));

        # Heading
        me["compass-text"].setRotation(-headingDeg*D2R);
        me["compass"].setRotation(-headingDeg*D2R);
        me["ap-heading"].setRotation(-headingAP*D2R);
        me["ap-heading"].setRotation(-headingDeg*D2R);
        me["sel-hdg"].setText(sprintf("%i", headingAP));

        # Wind and Speeds
        me["ground-speed"].setText(sprintf("%i", getprop("velocities/groundspeed-kt")));
        me["true-airspeed"].setText(sprintf("%i", getprop("velocities/airspeed-kt")));
        me["wind-heading"].setText(sprintf("%03i", windHeading));
        me["wind-speed"].setText(sprintf("%i", getprop("environment/wind-speed-kt")));
        me["wind-arrow"].setRotation(windHeading*D2R);

        # Flight Director
        if(getprop("it-autoflight/input/fd1")) {
            me["fd-horizontal"].show();
            me["fd-vertical"].show();
            me["fd-horizontal"].setTranslation(0, getprop("it-autoflight/fd/pitch-bar"));
            me["fd-vertical"].setTranslation(getprop("it-autoflight/fd/roll-bar"), 0);
        } else {
            me["fd-horizontal"].hide();
            me["fd-vertical"].hide();
        }
        
        # Altitude and VNAV
        if(altitude-altitudeAP > 400)
            me["ap-alt-tape"].setTranslation(0, 174);
        elsif(altitude-altitudeAP < -400)
            me["ap-alt-tape"].setTranslation(0, -174);
        else
            me["ap-alt-tape"].setTranslation(0, 174/400*(altitude-altitudeAP));
        
        # Hiding upper tapes by default
        me["alt-tape0"].hide();
        me["alt-tape1"].hide();
        me["alt-tape2"].hide();
        me["alt-tape3"].hide();
        me["alt-tape4"].hide();
        me["alt-tape5"].hide();
        me["alt-tape6"].hide();
        me["alt-tape7"].hide();
        me["alt-tape8"].hide();
        me["alt-tape9"].hide();

        # Moving the tapes
        me["alt-ground"].show().setTranslation(0, altitudeAGL*0.44);

        if(altitude < 4600) {
            me["alt-tape0"].show().setTranslation(0, altitude*0.44);
            me["alt-tape1"].show().setTranslation(0, altitude*0.44);
        } elsif (altitude < 9600) {
            me["alt-tape1"].show().setTranslation(0, altitude*0.44);
            me["alt-tape2"].show().setTranslation(0, (altitude-4600)*0.44);
        } elsif (altitude < 14600) {
            me["alt-tape2"].show().setTranslation(0, (altitude-4600)*0.44);
            me["alt-tape3"].show().setTranslation(0, (altitude-9600)*0.44);
        } elsif (altitude < 19600) {
            me["alt-tape3"].show().setTranslation(0, (altitude-9600)*0.44);
            me["alt-tape4"].show().setTranslation(0, (altitude-14600)*0.44);
        } elsif (altitude < 24600) {
            me["alt-tape4"].show().setTranslation(0, (altitude-14600)*0.44);
            me["alt-tape5"].show().setTranslation(0, (altitude-19600)*0.44);
        } elsif (altitude < 29600) {
            me["alt-tape5"].show().setTranslation(0, (altitude-19600)*0.44);
            me["alt-tape6"].show().setTranslation(0, (altitude-24600)*0.44);
        } elsif (altitude < 34600) {
            me["alt-tape6"].show().setTranslation(0, (altitude-24600)*0.44);
            me["alt-tape7"].show().setTranslation(0, (altitude-29600)*0.44);
        } elsif (altitude < 39600) {
            me["alt-tape7"].show().setTranslation(0, (altitude-29600)*0.44);
            me["alt-tape8"].show().setTranslation(0, (altitude-34600)*0.44);
        } elsif (altitude < 44600) {
            me["alt-tape8"].show().setTranslation(0, (altitude-34600)*0.44);
            me["alt-tape9"].show().setTranslation(0, (altitude-39600)*0.44);
        }

        # Low-altitude box
        if(altitudeAGL < 100)
            me["alt-final"].setText(sprintf("%i", math.round(altitudeAGL, 2)));
        elsif (altitudeAGL < 500)
            me["alt-final"].setText(sprintf("%i", math.round(altitudeAGL, 10)));
        elsif (altitudeAGL < 2520)
            me["alt-final"].setText(sprintf("%i", math.round(altitudeAGL, 20)));
        else {
            me["alt-final"].hide();
            me["alt-final-box"].hide();
        }

        # Altitude box
        if(altitude < 0)
            me["alt-neg"].show();
        else
            me["alt-neg"].hide();
        
        if(altitude < 10000)
            me["alt-00000"].show();
        else
            me["alt-00000"].hide();

        me["alt-20"].setTranslation(0, math.mod(altitude, 100)*0.86);

        if(math.mod(altitude, 100) > 80)
            me["alt-100"].setTranslation(0, math.mod((altitude - math.mod(altitude, 100)) * 0.2755, 248) + ((math.mod(altitude, 100) - 80) * 1.385));
        else
            me["alt-100"].setTranslation(0, math.mod((altitude - math.mod(altitude, 100)) * 0.2755, 248));

        if(math.mod(altitude, 1000) > 900)
            me["alt-1000"].setTranslation(0, math.mod((altitude - math.mod(altitude, 1000)) * 0.3, 270.2) + ((math.mod(altitude, 1000) - 900) * 0.303));
        else
            me["alt-1000"].setTranslation(0, math.mod((altitude - math.mod(altitude, 1000)) * 0.3, 270.2));

        if(math.mod(altitude, 10000) > 9000)
            me["alt-10000"].setTranslation(0, math.mod((altitude - math.mod(altitude, 10000)) * 0.03, 270.2) + ((math.mod(altitude, 10000) - 9000) * 0.0303));
        else
            me["alt-10000"].setTranslation(0, math.mod((altitude - math.mod(altitude, 10000)) * 0.03, 270.2));

        me["alt-m"].setText(sprintf("%i", altitude * FT2M));
        me["ap-alt-meter"].setText(sprintf("%i", altitudeAP * FT2M));
        me["ap-alt-thousand"].setText(sprintf("%i", altitudeAP / 1000));
        me["ap-alt-hundred"].setText(sprintf("%03i", math.mod(altitudeAP, 1000)));

        # Speed Tape
        me["spd-tape"].setTranslation(0, ias * 2.9);
        me["spd-limitLR"].setTranslation(0, ias * 2.9);
        me["spd-limitLB"].setTranslation(0, ias * 2.9);
        me["spd-limitUR"].setTranslation(0, ias * 2.9);
        me["spd-limitUB"].setTranslation(0, ias * 2.9);
        me["spd-limitY"].setTranslation(0, ias * 2.9);

        if (getprop("controls/flight/flaps") > 0) {
            me["spd-limitUR"].setTranslation(0, getprop(sprintf("limits/max-flap-extension-speed[%s]/speed", getprop("controls/flight/flaps") * 8)) * 2.9);
            me["spd-limitUB"].setTranslation(0, getprop(sprintf("limits/max-flap-extension-speed[%s]/speed", getprop("controls/flight/flaps") * 8)) * 2.9);
        }

        if (stall != nil) {
            me["spd-limitLR"].setTranslation(0,-stall * 2.9);
            me["spd-limitLB"].setTranslation(0,-stall * 2.9);
            me["spd-limitY"].setTranslation(0,-stall * 2.9);
        }
        
        if (ias < 45) {
            me["spd-1"].setTranslation(0, 105);
            me["spd-10"].setTranslation(0, 136.2);
        } else {
            me["spd-1"].setTranslation(0, math.mod(ias, 10) * 21.3);
            if(math.mod(ias, 10) > 9)
                me["spd-10"].setTranslation(0, math.mod(ias-math.mod(ias, 10), 100) * 3.43 + (math.mod(ias, 10) - 9) * 34.3);
            else
                me["spd-10"].setTranslation(0, math.mod(ias-math.mod(ias, 10), 100) * 3.43);

            if(math.mod(ias, 100) > 90)
                me["spd-100"].setTranslation(0, math.mod(ias-math.mod(ias, 100), 1000) * 0.343 + (math.mod(ias, 100) - 90) * 3.43);
            else
                me["spd-100"].setTranslation(0, math.mod(ias-math.mod(ias, 100), 1000) * 0.343);
        }
		if (getprop("velocities/mach") != nil) {
        me["mach"].setText(sprintf(".%.03d", getprop("velocities/mach")));
		}

        if (getprop("it-autoflight/input/kts-mach"))
            me["spd-ap"].setText(sprintf(".%.03d", getprop("it-autoflight/input/spd-mach")));
        else
            me["spd-ap"].setText(sprintf("%i", getprop("it-autoflight/input/spd-kts")));

        
        
        # AOA Indicator
		if (vsi != nil) {
            me["aoa-needle"].setRotation(vsi*D2R);
        }
        if(vSpeed*60 > 500) {
            me["vs-pos"].show().setText(sprintf("%i", vSpeed*60 - math.mod(vSpeed*60, 50)));
            me["vs-neg"].hide();
        } elsif (vSpeed*60 < -500) {
            me["vs-neg"].show().setText(sprintf("%i", -vSpeed*60 + math.mod(vSpeed*60, 50)));
            me["vs-pos"].hide();
        } else {
            me["vs-pos"].hide();
            me["vs-neg"].hide();
        }

        # Autopilot Modes
        me["a-throttle"].setText(getprop("autopilot/display/throttle-mode"));
        me["lnav"].setText(getprop("it-autoflight/mode/lat"));
        me["vnav"].setText(getprop("it-autoflight/mode/vert"));
	},
};

setlistener("sim/signals/fdm-initialized", func() {
	PFDC_display = canvas.new({
		"name": "PFDC",
		"size": [1940, 1452],
		"view": [970, 726],
		"mipmapping": 1
	});
	PFDC_display.addPlacement({"node": "screen1.full"});
	var group = PFDC_display.createGroup();
	PFDC_canvas = canvas_PFDC.new(group);
	update_timer = maketimer(0.1, func PFDC_canvas.update());
 	update_timer.start();
 	PFDC_canvas.update();
}, 0, 0);

#setlistener("sim/signals/reinit", func PFDC_display.del());

var showPFDC = func() {
	var dlg = canvas.Window.new([485, 363], "dialog").set("resize", 0.5);
	dlg.setCanvas(PFDC_display);
}