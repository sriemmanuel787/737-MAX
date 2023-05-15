#737 MAX Property Tree Setup
#Israel Emmanuel (sriemmanuel787)

var Consumables = {
    Fuel:{
        right:  props.globals.getNode("consumables/fuel/tank[0]/level-kg"),
        left:   props.globals.getNode("consumables/fuel/tank[1]/level-kg"),
        center: props.globals.getNode("consumables/fuel/tank[2]/level-kg")
    }
};

var Engines = {
    egtCommand: [props.globals.getNode("controls/engines/engine[0]/throttle"), props.globals.getNode("controls/engines/engine[1]/throttle")],
	egtActual:  [props.globals.getNode("engines/engine[0]/egt-actual"), props.globals.getNode("engines/engine[1]/egt-actual")],
	eprActual:  [props.globals.getNode("engines/engine[0]/epr"), props.globals.getNode("engines/engine[1]/epr")],
	ffActual:   [props.globals.getNode("engines/engine[0]/fuel-flow_pph"), props.globals.getNode("engines/engine[1]/fuel-flow_pph")],
	n1Actual:   [props.globals.getNode("engines/engine[0]/n1"), props.globals.getNode("engines/engine[1]/n1")],
	n2Actual:   [props.globals.getNode("engines/engine[0]/n2"), props.globals.getNode("engines/engine[1]/n2")],
    startValve: [props.globals.getNode("controls/engines/engine[0]/starter"), props.globals.getNode("controls/engines/engine[1]/starter")],
	oilPsi:     [props.globals.getNode("engines/engine[0]/oil-pressure-psi"), props.globals.getNode("engines/engine[1]/oil-pressure-psi")],
	serviceable:      [props.globals.getNode("sim/failure-manager/engines/engine[0]/serviceable"), props.globals.getNode("sim/failure-manager/engines/engine[1]/serviceable")]
};

var Controls = {
    Flight: {
        aileronPos: [props.globals.getNode("surface-positions/left-aileron-pos-norm"), props.globals.getNode("surface-positions/right-aileron-pos-norm")],
		flapsPos:   props.globals.getNode("surface-positions/flap-pos-norm"),
		spoilerPos: props.globals.getNode("surface-positions/spoilers-pos-norm"),
		rudderPos:  props.globals.getNode("surface-positions/rudder-pos-norm"),
		elevPos:	props.globals.getNode("surface-positions/elevator-pos-norm")
    },

	Gear: {
		compression: [props.globals.getNode("gear/gear[0]/compression-ft"), props.globals.getNode("gear/gear[1]/compression-ft"), props.globals.getNode("gear/gear[2]/compression-ft")],
		position:    [props.globals.getNode("gear/gear[0]/position-norm"), props.globals.getNode("gear/gear[1]/position-norm"), props.globals.getNode("gear/gear[2]/position-norm")],
		rollspd:     [props.globals.getNode("gear/gear[0]/rollspeed-ms"), props.globals.getNode("gear/gear[1]/rollspeed-ms"), props.globals.getNode("gear/gear[2]/rollspeed-ms")],
		wow:         [props.globals.getNode("gear/gear[0]/wow"), props.globals.getNode("gear/gear[1]/wow"), props.globals.getNode("gear/gear[2]/wow")]
	}
};

var Orientation = {
	headingDeg:         props.globals.getNode("orientation/heading-deg"),
	headingMagneticDeg: props.globals.getNode("orientation/heading-magnetic-deg"),
	pitchDeg:           props.globals.getNode("orientation/pitch-deg"),
	rollDeg:            props.globals.getNode("orientation/roll-deg"),
	latitude:			props.globals.getNode("position/latitude-deg"),
	longitude:			props.globals.getNode("position/longitude-deg"),
	altitudeAGL:		props.globals.getNode("position/altitude-agl-ft"),
	altitudeGear:		props.globals.getNode("position/gear-agl-ft"),
	altitude:			props.globals.getNode("position/altitude-ft"),
	vSpeed:				props.globals.getNode("velocities/vertical-speed-fps")
};

var Autoflight = {
	fdPitch: 	props.globals.getNode("it-autoflight/fd/pitch-bar"),
	fdRoll: 	props.globals.getNode("it-autoflight/fd/roll-bar"),
	fd1: 		props.globals.getNode("it-autoflight/input/fd1"),
	fd2: 		props.globals.getNode("it-autoflight/input/fd2"),
	alt: 		props.globals.getNode("it-autoflight/input/alt"),
	ap1: 		props.globals.getNode("it-autoflight/input/ap1"),
	ap2: 		props.globals.getNode("it-autoflight/input/ap2"),
	aThr:	 	props.globals.getNode("it-autoflight/input/athr"),
	fltAngle: 	props.globals.getNode("it-autoflight/input/fpa"),
	heading:  	props.globals.getNode("it-autoflight/input/hdg"),
	ktsMach:  	props.globals.getNode("it-autoflight/input/kts-mach"),
	lnav: 		props.globals.getNode("it-autoflight/mode/lat"),
	vnav: 		props.globals.getNode("it-autoflight/mode/vert"),
	thr:		props.globals.getNode("it-autoflight/mode/thr"),
	spdKts: 	props.globals.getNode("it-autoflight/input/spd-kts"),
	spdMach: 	props.globals.getNode("it-autoflight/input/spd-mach"),
	togaArm: 	props.globals.getNode("it-autoflight/input/toga"),
	vSpd: 		props.globals.getNode("it-autoflight/input/vs"),
    afds: 		props.globals.getNode("autopilot/display/afds-mode")
};

var Sim = {
	day:         props.globals.getNode("sim/time/utc/day"),
	month:       props.globals.getNode("sim/time/utc/month"),
	year:        props.globals.getNode("sim/time/utc/year"),
	timeElapsed: props.globals.getNode("sim/time/elapsed-sec"),
	timeUTC:     props.globals.getNode("sim/time/gmt-string")
};

var Radio = {
    nav: [props.globals.getNode("instrumentation/nav[0]/frequencies/selected-mhz"), props.globals.getNode("instrumentation/nav[1]/frequencies/selected-mhz")]
};

var Info = {
    icao:         props.globals.getNode("sim/model/airline-code"),
    registration: props.globals.getNode("sim/model/registration"),
    selcal:       props.globals.getNode("sim/model/selcal")
};