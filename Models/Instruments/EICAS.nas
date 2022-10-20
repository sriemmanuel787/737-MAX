# ==============================================================================
# For 737-800 by Michael Soitanen
# Updated and Expanded according to FCOM by Jonathan Redpath
# ==============================================================================

var roundToNearest = func(n, m) {
	var x = int(n/m)*m;
	if((math.mod(n,m)) > (m/2) and n > 0)
			x = x + m;
	if((m - (math.mod(n,m))) > (m/2) and n < 0)
			x = x - m;
	return x;
}

var EICAS_canvas = nil;
var EICAS_display = nil;

var canvas_EICAS = {
	new: func(canvas_group){
		var m = { parents: [canvas_EICAS] };
		var EICAS = canvas_group;
		# var font_mapper = func(){
		# 	return "Aircraft/737-MAX/Fonts/OCRBMT.ttf";
		# };
		
		canvas.parsesvg(EICAS, "Aircraft/737-MAX/Models/Instruments/res/EICAS.svg"
		# , {'font-mapper': font_mapper}
		);
		
		var svg_keys = ["fuel-flow1", "fuel-flow2", "oil-press1", "oil-press2", "oil-temp1", "oil-temp2", "oil-qty1", "oil-qty2", "vib1", "vib2", "oil-press-meter1", "oil-press-meter2", "vib-meter1", "vib-meter2", "throttle-num1", "throttle-num2", "throttle-n1", "throttle-n2", "n1.text1", "n1-dial1", "n1.text2", "n1-dial2", "egt-text1", "egt-dial1", "egt-text2", "egt-dial2", "motoring1", "motoring2", "n2-text1", "n2-dial1", "n2-text2", "n2-dial2", "fuel-flow", "thrust", "low-oil-pressure", "oil-filter-bypass", "start-valve-open", "fuel-flow2", "thrust2", "low-oil-pressure2", "oil-filter-bypass2", "start-valve-open2", "tank-right", "tank-c", "tank-l", "total", "flt-mode", "air-temp", "flap-trans", "flap-ext", "flap-dial"];
		foreach(var key; svg_keys) {
			m[key] = EICAS.getElementById(key);
		}
		
                 m.timers = [];
 
		return m;
	},
    newMFD: func(){
 		me.update_timer = maketimer(0.2, func me.update());
 		me.update_timer.start();
    },
	update: func(){
		var SCALE = 256/121; # constant for expansion to 2-factor res

		# center setting
		me["n1-dial1"].setCenter(72*SCALE,106*SCALE);
		me["throttle-n1"].setCenter(72*SCALE,106*SCALE);
		me["n2-dial1"].setCenter(197*SCALE,106*SCALE);
		me["throttle-n2"].setCenter(197*SCALE,106*SCALE);
		me["egt-dial1"].setCenter(72*SCALE,196*SCALE);
		me["egt-dial2"].setCenter(197*SCALE,196*SCALE);
		me["n2-dial1"].setCenter(72*SCALE,196*SCALE);
		me["n2-dial2"].setCenter(197*SCALE,296*SCALE);
		me["flap-dial"].setCenter(363*SCALE,408*SCALE);

		# Fuel
		me["tank-right"].setText(sprintf("%0.2f", getprop("/consumables/fuel/tank[0]/level-kg")/1000));
		me["tank-c"].setText(sprintf("%0.2f", getprop("/consumables/fuel/tank[2]/level-kg")/1000));
		me["tank-l"].setText(sprintf("%0.2f", getprop("/consumables/fuel/tank[1]/level-kg")/1000));
		#var totalFuel = getprop("/consumables/fuel/tank[0]/level-kg") + getprop("/consumables/fuel/tank[1]/level-kg") + getprop("/consumables/fuel/tank[2]/level-kg")
		#me["total"].setText(sprintf("%0.1f", totalFuel/1000));
		
		#N1
		me["n1-dial1"].setRotation(getprop("/engines/engine[0]/n1")*2*D2R);
		me["n1-dial2"].setRotation(getprop("/engines/engine[1]/n1")*2*D2R);
		me["throttle-n1"].setRotation(getprop("/controls/engines/engine[0]/throttle")*2*D2R);
		me["throttle-n2"].setRotation(getprop("/controls/engines/engine[1]/throttle")*2*D2R);
		me["n1.text1"].setText(sprintf("%0.1f", getprop("/engines/engine[0]/n1")));
		me["n1.text2"].setText(sprintf("%0.1f", getprop("/engines/engine[1]/n1")));
		me["throttle-num1"].setText(sprintf("%0.1f", getprop("/controls/engines/engine[0]/throttle")));
		me["throttle-num2"].setText(sprintf("%0.1f", getprop("/controls/engines/engine[1]/throttle")));

		#EGT
		me["egt-dial1"].setRotation(getprop("/engines/engine[0]/egt-actual")*0.2015*D2R);
		me["egt-dial2"].setRotation(getprop("/engines/engine[1]/egt-actual")*0.2015*D2R);
		me["egt-text1"].setText(sprintf("%i", getprop("/engines/engine[0]/egt-actual")));
		me["egt-text2"].setText(sprintf("%i", getprop("/engines/engine[1]/egt-actual")));
		
		#N2
		me["n2-dial1"].setRotation(getprop("/engines/engine[0]/n2")*2*D2R);
		me["n2-dial2"].setRotation(getprop("/engines/engine[1]/n2")*2*D2R);
		me["n2-text1"].setText(sprintf("%0.1f", getprop("/engines/engine[0]/n2")));
		me["n2-text2"].setText(sprintf("%0.1f", getprop("/engines/engine[1]/n2")));
		if (getprop("/engines/engine[0]/n2") > 18 and getprop("/engines/engine[0]/n2") < 24){
			me["motoring1"].show();
		}else{
			me["motoring1"].hide();
		}
		if (getprop("/engines/engine[1]/n2") > 18 and getprop("/engines/engine[1]/n2") < 24){
			me["motoring2"].show();
		}else{
			me["motoring2"].hide();
		}
		
		#Oil and Fuel Flow
		me["fuel-flow1"].setText(sprintf("%0.2f", getprop("/engines/engine[0]/fuel-flow_pph")*LB2KG/1000));
		me["fuel-flow2"].setText(sprintf("%0.1f", getprop("/engines/engine[1]/fuel-flow_pph")*LB2KG/1000));
		me["oil-press1"].setText(sprintf("%i", getprop("/engines/engine[0]/oil-pressure-psi")));
		me["oil-press2"].setText(sprintf("%i", getprop("/engines/engine[1]/oil-pressure-psi")));
		# me["oil-press-meter1"].setTranslation(0, getprop("/engines/engine[0]/oil-pressure-psi")*(-2))
		# me["oil-press-meter2"].setTranslation(0, getprop("/engines/engine[1]/oil-pressure-psi")*(-2))
		
		#Warnings
		if (getprop("/controls/engines/engine[0]/starter") > 0)
			me["start-valve-open"].show();
		else
			me["start-valve-open"].hide();
		
		if (getprop("/controls/engines/engine[1]/starter") > 0)
			me["start-valve-open2"].show();
		else
			me["start-valve-open2"].hide();
		
		if(getprop("/engines/engine[0]/oil-pressure-psi") < 20)
			me["low-oil-pressure"].show();
		else
			me["low-oil-pressure"].hide();
		
		if(getprop("/engines/engine[1]/oil-pressure-psi") < 20)
			me["low-oil-pressure2"].show();
		else
			me["low-oil-pressure2"].hide();
		
		if(math.abs(getprop("/engines/engine[0]/n1")-getprop("/engines/engine[0]/n1")) > 10)
			me["thrust"].show();
		else
			me["thrust"].hide();
		
		if(math.abs(getprop("/engines/engine[1]/n1")-getprop("/engines/engine[1]/n1")) > 10)
			me["thrust2"].show();
		else
			me["thrust2"].hide();

		if(getprop("/engines/engine[0]/fuel-flow_pph")*LB2KG > 3)
			me["fuel-flow"].show();
		else
			me["fuel-flow"].hide();
		
		if(getprop("/engines/engine[1]/fuel-flow_pph")*LB2KG > 3)
			me["fuel-flow2"].show();
		else
			me["fuel-flow2"].hide();

		#Flap indicator
		if (getprop("/surface-positions/flap-pos-norm[0]") <= 0.125)
			me["flap-dial"].setRotation(getprop("/surface-positions/flap-pos-norm[0]")*272*D2R);
		else if (getprop("/surface-positions/flap-pos-norm[0]") <= 0.25)
			me["flap-dial"].setRotation(getprop("/surface-positions/flap-pos-norm[0]")*311.2*D2R);
		else if (getprop("/surface-positions/flap-pos-norm[0]") <= 0.375)
			me["flap-dial"].setRotation(getprop("/surface-positions/flap-pos-norm[0]")*306.7*D2R);
		else if (getprop("/surface-positions/flap-pos-norm[0]") <= 0.5)
			me["flap-dial"].setRotation(getprop("/surface-positions/flap-pos-norm[0]")*309*D2R);
		else if (getprop("/surface-positions/flap-pos-norm[0]") <= 0.625)
			me["flap-dial"].setRotation(getprop("/surface-positions/flap-pos-norm[0]")*288*D2R);
		else if (getprop("/surface-positions/flap-pos-norm[0]") <= 0.75)
			me["flap-dial"].setRotation(getprop("/surface-positions/flap-pos-norm[0]")*159.3*D2R);
		else if (getprop("/surface-positions/flap-pos-norm[0]") <= 0.875)
			me["flap-dial"].setRotation(getprop("/surface-positions/flap-pos-norm[0]")*221.7*D2R);
		else
			me["flap-dial"].setRotation(getprop("/surface-positions/flap-pos-norm[0]")*270*D2R);
		
		# if (getprop("/surface-positions/flap-pos-norm[0]") = 0.125 or getprop("/surface-positions/flap-pos-norm[0]") = 0.25 or getprop("/surface-positions/flap-pos-norm[0]") = 0.375 or getprop("/surface-positions/flap-pos-norm[0]") = 0.5 or or getprop("/surface-positions/flap-pos-norm[0]") = 0.625 or getprop("/surface-positions/flap-pos-norm[0]") = 0.75 or getprop("/surface-positions/flap-pos-norm[0]") = 0.825 or getprop("/surface-positions/flap-pos-norm[0]") = 1){
			# me["flaps-ext"].show();
			# me["flaps-trans"].hide();
		# } else if(getprop("/surface-positions/flap-pos-norm[0]") = 0){
			# me["flaps-ext"].hide();
			# me["flaps-trans"].hide();
		# } else {
			# me["flaps-ext"].hide();
			# me["flaps-trans"].show();
		# }
		
		#Misc
		me["air-temp"].setText(sprintf("%+i" ,getprop("/fdm/jsbsim/propulsion/tat-c")) + "c");
		
		if (getprop("/it-autoflight/input/thrustStg") == "G/A" or getprop("/it-autoflight/input/thrustStg") == "TO") 
			me["flt-mode"].setText(sprintf("%s",getprop("/it-autoflight/input/thrustStg")));
		else
      		me["flt-mode"].setText(sprintf("%s","CRZ"));

	},
};

setlistener("sim/signals/fdm-initialized", func() {
	EICAS_display = canvas.new({
		"name": "EICAS",
		"size": [1, 1],
		"view": [1024, 1515],
		"mipmapping": 1
	});
	EICAS_display.addPlacement({"node": "EICAS.captL"});
	var group = EICAS_display.createGroup();
	EICAS_canvas = canvas_EICAS.new(group);
        EICAS_canvas.newMFD();
 	#EICAS_canvas.update();
}, 0, 0);

#setlistener("sim/signals/reinit", func EICAS_display.del());

var showEICAS = func() {
	var dlg = canvas.Window.new([1024, 1515], "dialog").set("resize", 1);
	dlg.setCanvas(EICAS_display);
}