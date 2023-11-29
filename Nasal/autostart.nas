## 737-800 Start - Shutdown


# Autostart #

var autostart = func {
	setprop("controls/hydraulic/a-eng1-pump", 1);
	setprop("controls/hydraulic/a-elec2-pump", 1);
	setprop("controls/hydraulic/b-eng1-pump", 1);
	setprop("controls/hydraulic/b-elec2-pump", 1);
	setprop("controls/hydraulic/a-b-cross-pump", 1);
	setprop("controls/engines/engine[0]/throttle", 0);
	setprop("controls/engines/engine[1]/throttle", 0);
	setprop("controls/APU/off-start-run", 2);
	setprop("engines/APU/rpm", 100);
	setprop("controls/electric/battery-switch", 1);
	setprop("controls/electric/APU-generator", 1);
	setprop("controls/electric/external-power", 1);
	setprop("controls/electric/engine[0]/generator", 1);
	setprop("controls/electric/engine[1]/generator", 1);
    setprop("controls/engines/engine[0]/cutoff", 1);
	setprop("controls/fuel/tank[0]/pump-fwd", 1);
	setprop("controls/fuel/tank[0]/pump-aft", 1);
	setprop("controls/fuel/tank[1]/pump-fwd", 1);
	setprop("controls/fuel/tank[1]/pump-aft", 1);
	setprop("controls/fuel/crossfeed", 1);
	setprop("controls/engines/engine[0]/starter", 1);
	screen.log.write("APU, APU Generator, Battery, External Power and Engine Starters have been turned on.", 1, 1, 1);

 	var engine1listener = setlistener("engines/engine[0]/n2", func {
		if (getprop("engines/engine[0]/n2") >= 25.18) {
			settimer(func {
				setprop("controls/engines/engine[0]/cutoff", 0);
				screen.log.write("Engine 1 is starting up...", 1, 1, 1);
    		}, 1);
    		removelistener(engine1listener);
		}
	}, 0, 0);

	var engine1listener2 = setlistener("engines/engine[0]/n2", func {
		if (getprop("engines/engine[0]/n2") >= 60) {
			settimer(func {
    			setprop("controls/engines/engine[0]/starter", 0);
				screen.log.write("Engine 1 has been started and is now running.", 1, 1, 1);
				screen.log.write("Engine 1 Generator is now supplying power.", 1, 1, 1);
				setprop("controls/engines/engine[1]/starter", 1);
    			setprop("controls/engines/engine[1]/cutoff", 1);
    		}, 1);
    	removelistener(engine1listener2);
		}
	}, 0, 0);

	var engine2listener = setlistener("engines/engine[1]/n2", func {
		if (getprop("engines/engine[1]/n2") >= 25.18) {
			settimer(func {
    			setprop("controls/engines/engine[1]/cutoff", 0);
				screen.log.write("Engine 2 is starting up...", 1, 1, 1);
    		}, 1);
    		removelistener(engine2listener);
		}
	}, 0, 0);

	var engine2listener2 = setlistener("engines/engine[1]/n2", func {
		if (getprop("engines/engine[1]/n2") >= 60) {
			settimer(func {
				setprop("controls/engines/engine[1]/starter", 0);
				screen.log.write("Engine 2 has been started and is now running.", 1, 1, 1);
				screen.log.write("Engine 2 Generator is now supplying power.", 1, 1, 1);
    			setprop("engines/APU/running", 0);
    			setprop("controls/electric/APU-generator", 0);
    			setprop("controls/electric/external-power", 0);
    			setprop("controls/APU/off-start-run", 0);
    			setprop("services/fuel-truck/enable", 0);
    			setprop("services/ext-pwr/enable", 0);
    			setprop("services/deicing_truck/enable", 0);
				screen.log.write("APU, APU Generator and External Power have been turned off.", 1, 1, 1);
				screen.log.write("The aircraft has been started up, you are ready to go :D", 1, 1, 1);
    		}, 1);
    	removelistener(engine2listener2);
		}
	}, 0, 0);
};
# Shutdown #

var shutdown = func {
	setprop("controls/electric/engine[0]/generator", 0);
	setprop("controls/electric/engine[1]/generator", 0);
	setprop("controls/engines/engine[0]/cutoff", 1);
	setprop("controls/engines/engine[1]/cutoff", 1);
	setprop("controls/fuel/tank[0]/pump-fwd", 0);
	setprop("controls/fuel/tank[0]/pump-aft", 0);
	setprop("controls/fuel/tank[1]/pump-fwd", 0);
	setprop("controls/fuel/tank[1]/pump-aft", 0);
	setprop("controls/fuel/crossfeed", 0);
	setprop("controls/APU/off-start-run", 0);
	screen.log.write("The Aircraft Engines have been shut down.", 1, 1, 1);
};

# listener to activate these functions accordingly
setlistener("sim/model/start-idling", func(idle) {
	var run = idle.getBoolValue();
	if (run) {
		startup();
	} else {
		shutdown();
	}
}, 0, 0);

var inair_started = 0;
var inAirStart_check = func {
    if (inair_started == 1) return;
    inair_started = 1;
    inAirStart();
}

var inAirStart = func {
    if (getprop("position/altitude-agl-ft")>400) {
    	settimer(func {setprop("controls/gear/brake-parking",0);}, 3);
    	setprop("b737/sensors/was-in-air", "true");
    	setprop("b737/sensors/landing", 0);
		autostart();
		if(var vbaro = getprop("environment/metar/pressure-inhg")) {
            setprop("instrumentation/altimeter[0]/setting-inhg", vbaro);
            setprop("instrumentation/altimeter[1]/setting-inhg", vbaro);
            setprop("instrumentation/altimeter[2]/setting-inhg", vbaro);
        }
        setprop("it-autoflight/input/fd1", 1);
        setprop("it-autoflight/input/fd2", 1);
        var speed = boeing737.roundToNearest(getprop("sim/presets/airspeed-kt"), 1);
        setprop("it-autoflight/input/spd-kts", speed);
        setprop("it-autoflight/input/hdg", boeing737.roundToNearest(getprop("orientation/heading-magnetic-deg"), 1));
        setprop("it-autoflight/input/alt", boeing737.roundToNearest(getprop("sim/presets/altitude-ft"), 100));
		setprop("it-autoflight/input/kts-mach", 0);
		setprop("it-autoflight/input/lat", 0);
		setprop("it-autoflight/input/vert", 4);

        # set ILS frequency
        var cur_runway = getprop("sim/presets/runway");
        if (cur_runway != "") {
	        var runways = airportinfo(getprop("sim/presets/airport-id")).runways;
	        var r =runways[cur_runway];
	        if (r != nil and r.ils != nil)
	        {
	            setprop("instrumentation/nav[0]/frequencies/selected-mhz", (r.ils.frequency / 100));
	            setprop("instrumentation/nav[1]/frequencies/selected-mhz", (r.ils.frequency / 100));
	            settimer(func {
	            	var magvar = getprop("environment/magnetic-variation-deg");
		            var crs = boeing737.roundToNearest(geo.normdeg(getprop("instrumentation/nav[0]/radials/target-radial-deg") - magvar), 1);
		            setprop("instrumentation/nav[0]/radials/selected-deg", crs);
		            setprop("instrumentation/nav[1]/radials/selected-deg", crs);
		        }, 2);
	        }
    	}

        #configure flaps and gears
        var vref40 = getprop("instrumentation/fmc/v-ref-40");
        if (speed > vref40 + 70) {
        	setprop("controls/flight/flaps", 0);
        	setprop("sim/flaps/current-setting", 0);
        	setprop("controls/gear/gear-down", 0);
        } elsif (speed > vref40 + 50) {
        	setprop("controls/flight/flaps", 0.125);
        	setprop("sim/flaps/current-setting", 1);
        	setprop("controls/gear/gear-down", 0);
        } elsif (speed > vref40 + 30) {
        	setprop("controls/flight/flaps", 0.375);
        	setprop("sim/flaps/current-setting", 3);
        	setprop("controls/gear/gear-down", 0);
        } elsif (speed > vref40 + 20) {
        	setprop("controls/flight/flaps", 0.625);
        	setprop("sim/flaps/current-setting", 5);
        	setprop("controls/gear/gear-down", 1);
        } elsif (speed > vref40 + 10) {
        	setprop("controls/flight/flaps", 0.750);
        	setprop("sim/flaps/current-setting", 6);
        	setprop("controls/gear/gear-down", 1);
        } else {
        	setprop("controls/flight/flaps", 1);
        	setprop("sim/flaps/current-setting", 8);
        	setprop("controls/gear/gear-down", 1);
        }
    }
}

setlistener("sim/signals/fdm-initialized", inAirStart_check, 0, 0);
setlistener("sim/signals/reinit", inAirStart, 0, 0);

