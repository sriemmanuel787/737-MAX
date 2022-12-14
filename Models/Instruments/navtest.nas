# ==============================================================================
# Boeing Navigation Display by Gijs de Rooy
# See: http://wiki.flightgear.org/Canvas_ND_Framework
# ==============================================================================



##
# this file contains a hash that declares features in a generic fashion
# we want to get rid of the bloated update() method sooner than later
# PLEASE DO NOT ADD any code to update() !! 
# Instead, help clean up the file and move things over to the navdisplay.styles file
# 
# This is the only sane way to keep on generalizing the framework, so that we can
# also support different makes/models of NDs in the future
#
# a huge bloated update() method is going to make that basically IMPOSSIBLE
#
io.include("Nasal/canvas/map/navdisplay.styles");

##
# encapsulate hdg/lat/lon source, so that the ND may also display AI/MP aircraft in a pilot-view at some point (aka stress-testing)
# TODO: this predates aircraftpos.controller (MapStructure) should probably be unified to some degree ...

var wxr_live_tree = "/instrumentation/wxr";

var NDSourceDriver = {};
NDSourceDriver.new = func {
	var m = {parents:[NDSourceDriver]};
	m.get_hdg_mag= func getprop("orientation/heading-magnetic-deg");
	m.get_hdg_tru= func getprop("orientation/heading-deg");
	m.get_hgg = func getprop("instrumentation/afds/settings/heading");
	m.get_trk_mag= func
	{
		if(getprop("velocities/groundspeed-kt") > 80)
			getprop("orientation/track-magnetic-deg");
		else
			getprop("orientation/heading-magnetic-deg");
	};
	m.get_trk_tru = func
	{
		if(getprop("velocities/groundspeed-kt") > 80)
			getprop("orientation/track-deg");
		else
			getprop("orientation/heading-deg");
	};
	m.get_lat= func getprop("position/latitude-deg");
	m.get_lon= func getprop("position/longitude-deg");
	m.get_spd= func getprop("instrumentation/airspeed-indicator/true-speed-kt");
	m.get_gnd_spd= func getprop("velocities/groundspeed-kt");
	m.get_vspd= func getprop("velocities/vertical-speed-fps");
	return m;
}

##
# configure aircraft specific cockpit switches here
# these are some defaults, can be overridden when calling NavDisplay.new() -
# see the 744 ND.nas file the backend code should never deal directly with
# aircraft specific properties using getprop.
# To get started implementing your own ND, just copy the switches hash to your
# ND.nas file and map the keys to your cockpit properties - and things will just work.

# TODO: switches are ND specific, so move to the NDStyle hash!

var default_switches = {
	'toggle_range':        {path: '/inputs/range-nm', value:40, type:'INT'},
	'toggle_weather':      {path: '/inputs/wxr', value:0, type:'BOOL'},
	'toggle_airports':     {path: '/inputs/arpt', value:0, type:'BOOL'},
	'toggle_stations':     {path: '/inputs/sta', value:0, type:'BOOL'},
	'toggle_waypoints':    {path: '/inputs/wpt', value:0, type:'BOOL'},
	'toggle_position':     {path: '/inputs/pos', value:0, type:'BOOL'},
	'toggle_data':         {path: '/inputs/data',value:0, type:'BOOL'},
	'toggle_terrain':      {path: '/inputs/terr',value:0, type:'BOOL'},
	'toggle_traffic':      {path: '/inputs/tfc',value:0, type:'BOOL'},
	'toggle_centered':     {path: '/inputs/nd-centered',value:0, type:'BOOL'},
	'toggle_lh_vor_adf':   {path: '/inputs/lh-vor-adf',value:0, type:'INT'},
	'toggle_rh_vor_adf':   {path: '/inputs/rh-vor-adf',value:0, type:'INT'},
	'toggle_display_mode': {path: '/mfd/display-mode', value:'MAP', type:'STRING'}, # valid values are: APP, MAP, PLAN or VOR
	'toggle_display_type': {path: '/mfd/display-type', value:'CRT', type:'STRING'}, # valid values are: CRT or LCD
	'toggle_true_north':   {path: '/mfd/true-north', value:0, type:'BOOL'},
	'toggle_rangearc':     {path: '/mfd/rangearc', value:0, type:'BOOL'},
	'toggle_track_heading':{path: '/trk-selected', value:0, type:'BOOL'},
	'toggle_weather_live': {path: '/mfd/wxr-live-enabled', value: 0, type: 'BOOL'},
	'toggle_chrono': {path: '/inputs/CHRONO', value: 0, type: 'INT'},
	'toggle_xtrk_error': {path: '/mfd/xtrk-error', value: 0, type: 'BOOL'},
	'toggle_trk_line': {path: '/mfd/trk-line', value: 0, type: 'BOOL'},
	'toggle_hdg_bug_only': {path: '/mfd/hdg-bug-only', value: 0, type: 'BOOL'},
};

##
# TODO:
# - introduce a MFD class (use it also for PFD/EICAS)
# - introduce a SGSubsystem class and use it  here
# - introduce a Boeing NavDisplay class
var NavDisplay = {
	# static
	id:0,

	del: func {
		print("Cleaning up NavDisplay");
		# shut down all timers and other loops here
		me.update_timer.stop();
		foreach(var t; me.timers)
			t.stop();
		foreach(var l; me.listeners)
			removelistener(l);
		# clean up MapStructure
		me.map.del();
		# call(canvas.Map.del, [], me.map);
		# destroy the canvas
		if (me.canvas_handle != nil)
			me.canvas_handle.del();
		me.inited = 0;
		NavDisplay.id -= 1;
	},

	addtimer: func(interval, cb) {
		append(me.timers, var job=maketimer(interval, cb));
		return job; # so that we can directly work with the timer (start/stop)
	},

	listen: func(p,c) {
		append(me.listeners, setlistener(p,c));
	},

	# listeners for cockpit switches
	listen_switch: func(s,c) {
		# print("event setup for: ", id(c));
		if (!contains(me.efis_switches, s)) {
			print('EFIS Switch not defined: '~ s);
			return;
		}
		me.listen( me.get_full_switch_path(s), func {
			# print("listen_switch triggered:", s, " callback id:", id(c) );
			c();
		});
	},

	# get the full property path for a given switch
	get_full_switch_path: func (s) {
		# debug.dump( me.efis_switches[s] );
		return me.efis_path ~ me.efis_switches[s].path; # FIXME: should be using props.nas instead of ~
	},

	# helper method for getting configurable cockpit switches (which are usually different in each aircraft)
	get_switch: func(s) {
		var switch = me.efis_switches[s];
		if(switch == nil) return nil;
		var path = me.efis_path ~ switch.path ;
		#print(s,":Getting switch prop:", path);

		return getprop( path );
	},
		
	# helper method for setting configurable cockpit switches (which are usually different in each aircraft)
	set_switch: func(s, v) {
		var switch = me.efis_switches[s];
		if(switch == nil) return nil;
		var path = me.efis_path ~ switch.path ;
		#print(s,":Getting switch prop:", path);

		setprop( path, v );
	},

	# for creating NDs that are driven by AI traffic instead of the main aircraft (generalization rocks!)
	connectAI: func(source=nil) {
		me.aircraft_source = {
			get_hdg_mag: func source.getNode('orientation/heading-magnetic-deg').getValue(),
			get_trk_mag: func source.getNode('orientation/track-magnetic-deg').getValue(),
			get_lat: func source.getNode('position/latitude-deg').getValue(),
			get_lon: func source.getNode('position/longitude-deg').getValue(),
			get_spd: func source.getNode('velocities/true-airspeed-kt').getValue(),
			get_gnd_spd: func source.getNode('velocities/groundspeed-kt').getValue(),
		};
	}, # of connectAI

	setTimerInterval: func(update_time=0.05) me.update_timer.restart(update_time),
    onDisplay: func {me.setTimerInterval();},
    offDisplay: func {me.update_timer.stop();},
	# TODO: the ctor should allow customization, for different aircraft
	# especially properties and SVG files/handles (747, 757, 777 etc)
	new : func(prop1, switches=default_switches, style='Boeing') {
		NavDisplay.id +=1;
		var m = { parents : [NavDisplay]};

		var df_toggles = keys(default_switches);
		foreach(var toggle_name; df_toggles){
			if(!contains(switches, toggle_name))
			switches[toggle_name] = default_switches[toggle_name];
		}
		
		m.inited = 0;

		m.timers=[]; 
		m.listeners=[]; # for cleanup handling
		m.aircraft_source = NDSourceDriver.new(); # uses the main aircraft as the driver/source (speeds, position, heading)

		m.nd_style = NDStyles[style]; # look up ND specific stuff (file names etc)
		m.style_name = style;

		m.radio_list=["instrumentation/comm/frequencies","instrumentation/comm[1]/frequencies",
		              "instrumentation/nav/frequencies", "instrumentation/nav[1]/frequencies"];
		m.mfd_mode_list=["APP","VOR","MAP","PLAN"];

		m.efis_path = prop1;
		m.efis_switches = switches;

		# just an alias, to avoid having to rewrite the old code for now
		m.rangeNm = func m.get_switch('toggle_range');

		m.efis = props.globals.initNode(prop1);
		m.mfd = m.efis.initNode("mfd");

		# TODO: unify this with switch handling
		m.mfd_mode_num     = m.mfd .initNode("mode-num",2,"INT");
		m.std_mode         = m.efis.initNode("inputs/setting-std",0,"BOOL");
		m.previous_set     = m.efis.initNode("inhg-previous",29.92);
		m.kpa_mode         = m.efis.initNode("inputs/kpa-mode",0,"BOOL");
		m.kpa_output       = m.efis.initNode("inhg-kpa",29.92);
		m.kpa_prevoutput   = m.efis.initNode("inhg-kpa-previous",29.92);
		m.temp             = m.efis.initNode("fixed-temp",0);
		m.alt_meters       = m.efis.initNode("inputs/alt-meters",0,"BOOL");
		m.fpv              = m.efis.initNode("inputs/fpv",0,"BOOL");

		m.mins_mode     = m.efis.initNode("inputs/minimums-mode",0,"BOOL");
		m.mins_mode_txt = m.efis.initNode("minimums-mode-text","RADIO","STRING");
		m.minimums      = m.efis.initNode("minimums",250,"INT");
		m.mk_minimums   = props.globals.getNode("instrumentation/mk-viii/inputs/arinc429/decision-height");

		# TODO: these are switches, can be unified with switch handling hash above (eventually):
		m.nd_plan_wpt = m.efis.initNode("inputs/plan-wpt-index", -1, "INT"); # not yet in switches hash

		###
		# initialize all switches based on the defaults specified in the switch hash
		#
		foreach(var switch; keys( m.efis_switches ) )
			props.globals.initNode
				(	m.get_full_switch_path (switch),
					m.efis_switches[switch].value,
					m.efis_switches[switch].type
				);


		return m;
	},
	newMFD: func(canvas_group, parent=nil, nd_options=nil, update_time=0.05)
	{
		if (me.inited) die("MFD already was added to scene");
		me.inited = 1;
		me.range_dependant_layers = [];
		me.always_update_layers = {};
		me.update_timer = maketimer(update_time, func me.update() );
		me.nd = canvas_group;
		me.canvas_handle = parent;
		me.df_options = nil;
		if (contains(me.nd_style, 'options'))
			me.df_options = me.nd_style.options;
		nd_options = canvas.default_hash(nd_options, me.df_options);
		me.options = nd_options;
		me.route_driver = nil;
		if (me.options == nil) me.options = {};
		if (contains(me.options, 'route_driver')) {
			me.route_driver = me.options.route_driver;
		}
		elsif (contains(me.options, 'defaults')) {
			if(contains(me.options.defaults, 'route_driver'))
				me.route_driver = me.options.defaults.route_driver;
		}

		# load the specified SVG file into the me.nd group and populate all sub groups

		canvas.parsesvg(me.nd, me.nd_style.svg_filename, {'font-mapper': me.nd_style.font_mapper});
		me.symbols = {}; # storage for SVG elements, to avoid namespace pollution (all SVG elements end up  here)

		foreach(var feature; me.nd_style.features ) {
			me.symbols[feature.id] = me.nd.getElementById(feature.id).updateCenter();
			if(contains(feature.impl,'init')) feature.impl.init(me.nd, feature); # call The element's init code (i.e. updateCenter)
		}

		me.nd_style.initialize_elements(me);


		var map_rect = [124, 1024, 1024, 0];
		var map_opts = me.options['map'];
		if (map_opts == nil) map_opts = {};
		if (typeof(map_opts['rect']) == 'vector')
			map_rect = map_opts.rect;
		map_rect = string.join(', ', map_rect);

		me.map = me.nd.createChild("map","map")
			.set("clip", map_rect)
			.set("screen-range", 700);
		var z_idx = map_opts['z-index'];
		if (z_idx != nil) me.map.set('z-index', z_idx);

		me.update_sub(); # init some map properties based on switches

		# predicate for the draw controller
		var is_tuned = func(freq) {
			var nav1=getprop("instrumentation/nav[0]/frequencies/selected-mhz");
			var nav2=getprop("instrumentation/nav[1]/frequencies/selected-mhz");
			if (freq == nav1 or freq == nav2) return 1;
			return 0;
		}

		# another predicate for the draw controller
		var get_course_by_freq = func(freq) {
			if (freq == getprop("instrumentation/nav[0]/frequencies/selected-mhz"))
				return getprop("instrumentation/nav[0]/radials/selected-deg");
			else
				return getprop("instrumentation/nav[1]/radials/selected-deg");
		}

		var get_current_position = func {
			delete(caller(0)[0], "me"); # remove local me, inherit outer one
			return [
				me.aircraft_source.get_lat(), me.aircraft_source.get_lon()
			];
		}

		# a hash with controller callbacks, will be passed onto draw routines to customize behavior/appearance
		# the point being that draw routines don't know anything about their frontends (instrument or GUI dialog)
		# so we need some simple way to communicate between frontend<->backend until we have real controllers
		# for now, a single controller hash is shared by most layers - unsupported callbacks are simply ignored by the draw files
		#

		var controller = {
			parents: [canvas.Map.Controller],
			_pos: nil, _time: nil,
			is_tuned:is_tuned,
			get_tuned_course:get_course_by_freq,
			get_position: get_current_position,
			new: func(map) return { parents:[controller], map:map },
			del: func() {print("cleaning up nd controller");},
			should_update_all: func {
				# TODO: this is just copied from aircraftpos.controller,
				# it really should be moved to somewhere common and reused
				# and extended to fully differentiate between "static"
				# and "volatile" layers.
				var pos = me.map.getPosCoord();
				if (pos == nil) return 0;
				var time = systime();
				if (me._pos == nil)
					me._pos = geo.Coord.new(pos);
				else {
					var dist_m = me._pos.direct_distance_to(pos);
					# 2 NM until we update again
					if (dist_m < 2 * NM2M) return 0;
					# Update at most every 4 seconds to avoid excessive stutter:
					elsif (time - me._time < 4) return 0;
				}
				#print("update aircraft position");
				var (x,y,z) = pos.xyz();
				me._pos.set_xyz(x,y,z);
				me._time = time;
				return 1;
			},
		};
		me.map.setController(controller);

		###
		# set up various layers, controlled via callbacks in the controller hash
		# revisit this code once Philosopher's "Smart MVC Symbols/Layers" work is committed and integrated

		# helper / closure generator
		var make_event_handler = func(predicate, layer) func predicate(me, layer);

		me.layers={}; # storage container for all ND specific layers
		# look up all required layers as specified per the NDStyle hash and do the initial setup for event handling
		var default_opts = me.options != nil and contains(me.options, 'defaults') ? me.options.defaults : nil;
		foreach(var layer; me.nd_style.layers) {
			if(layer['disabled']) continue; # skip this layer
			#print("newMFD(): Setting up ND layer:", layer.name);

			var the_layer = nil;
			if(!layer['isMapStructure']) # set up an old INEFFICIENT and SLOW layer
				the_layer = me.layers[layer.name] = canvas.MAP_LAYERS[layer.name].new( me.map, layer.name, controller );
			else {
				logprint(canvas._MP_dbg_lvl, "Setting up MapStructure-based layer for ND, name:", layer.name);
				var opt = me.options != nil and me.options[layer.name] != nil ? me.options[layer.name] : nil;
				if (opt == nil and contains(layer, 'options'))
					opt = layer.options;
				if (opt != nil and default_opts != nil)
					opt = canvas.default_hash(opt, default_opts);
				#elsif(default_opts != nil)
				#    opt = default_opts;
				var style = nil;
				if(contains(layer, 'style'))
					style = layer.style;
				#print("Options is: ", opt!=nil?"enabled":"disabled");
				#debug.dump(opt);
				me.map.addLayer(
					factory: canvas.SymbolLayer,
					type_arg: layer.name,
					opts: opt,
					visible:0,
					style: style,
					priority: layer['z-index']
				);
				the_layer = me.layers[layer.name] = me.map.getLayer(layer.name);
				if(opt != nil and contains(opt, 'range_dependant')){
					if(opt.range_dependant)
						append(me.range_dependant_layers, the_layer);
				}
				if(contains(layer, 'always_update'))
					me.always_update_layers[layer.name] = layer.always_update;
				if (1) (func {
					var l = layer;
					var _predicate = l.predicate;
					l.predicate = func {
						var t = systime();
						call(_predicate, arg, me);
						logprint(canvas._MP_dbg_lvl, "Took "~((systime()-t)*1000)~"ms to update layer "~l.name);
					}
				})();
			}

			# now register all layer specific notification listeners and their corresponding update predicate/callback
			# pass the ND instance and the layer handle to the predicate when it is called
			# so that it can directly access the ND instance and its own layer (without having to know the layer's name)
			var event_handler = make_event_handler(layer.predicate, the_layer);
			foreach(var event; layer.update_on) {
				# this handles timers
				if (typeof(event)=='hash' and contains(event, 'rate_hz')) {
					#print("FIXME: navdisplay.mfd timer handling is broken ATM");
					var job=me.addtimer(1/event.rate_hz, event_handler);	
					job.start();
				}
				# and this listeners	
				else
				# print("Setting up subscription:", event, " for ", layer.name, " handler id:", id(event_handler) );
				me.listen_switch(event, event_handler);
			} # foreach event subscription
			# and now update/init each layer once by calling its update predicate for initialization
			event_handler();
		} # foreach layer

		#print("navdisplay.mfd:ND layer setup completed");

		# start the update timer, which makes sure that the update() will be called
		me.update_timer.start();

		# TODO: move this to RTE.lcontroller ?
		me.listen("autopilot/route-manager/current-wp", func(activeWp) {
			canvas.updatewp( activeWp.getValue() );
		});

	},

	in_mode:func(switch, modes)
	{
		foreach(var m; modes) if(me.get_switch(switch)==m) return 1;
		return 0;
	},
	# Helper function for below (update()) and above (newMFD())
	# to ensure position etc. are correct.
	update_sub: func()
	{
		# Variables:
		var userLat = me.aircraft_source.get_lat();
		var userLon = me.aircraft_source.get_lon();
		var userGndSpd = me.aircraft_source.get_gnd_spd();
		var userVSpd = me.aircraft_source.get_vspd();
		var dispLCD = me.get_switch('toggle_display_type') == "LCD";
		# Heading update
		var userHdgMag = me.aircraft_source.get_hdg_mag();
		var userHdgTru = me.aircraft_source.get_hdg_tru();
		var userTrkMag = me.aircraft_source.get_trk_mag();
		var userTrkTru = me.aircraft_source.get_trk_tru();
		
		if(me.get_switch('toggle_true_north')) {
			var userHdg=userHdgTru;
			me.userHdg=userHdgTru;
			var userTrk=userTrkTru;
			me.userTrk=userTrkTru;
		} else {
			var userHdg=userHdgMag;
			me.userHdg=userHdgMag;
			var userTrk=userTrkMag;
			me.userTrk=userTrkMag;
		}
		# this should only ever happen when testing the experimental AI/MP ND driver hash (not critical)
		# or when an error occurs (critical)
		if (!userHdg or !userTrk or !userLat or !userLon) {
			print("aircraft source invalid, returning !");
			return;
		}
		if (me.aircraft_source.get_gnd_spd() < 80) {
			userTrk = userHdg;
			me.userTrk=userHdg;
		}
		
		if((me.in_mode('toggle_display_mode', ['MAP']) and me.get_switch('toggle_display_type') == "CRT")
		    or (me.get_switch('toggle_track_heading') and me.get_switch('toggle_display_type') == "LCD"))
		{
			userHdgTrk = userTrk;
			me.userHdgTrk = userTrk;
			userHdgTrkTru = userTrkTru;
			me.symbols.hdgTrk.setText("TRK");
		} else {
			userHdgTrk = userHdg;
			me.userHdgTrk = userHdg;
			userHdgTrkTru = userHdgTru;
			me.symbols.hdgTrk.setText("HDG");
		}

		# First, update the display position of the map
		var oldRange = me.map.getRange();
		var pos = {
			lat: nil, lon: nil,
			alt: nil, hdg: nil,
			range: nil,
		};
		# reposition the map, change heading & range:
		var pln_wpt_idx = getprop(me.efis_path ~ "/inputs/plan-wpt-index");
		if(me.in_mode('toggle_display_mode', ['PLAN'])  and pln_wpt_idx >= 0) {
			if(me.route_driver != nil){
				var wp = me.route_driver.getPlanModeWP(pln_wpt_idx);
				if(wp != nil){
					pos.lat = wp.wp_lat;
					pos.lon = wp.wp_lon;
				} else {
					pos.lat = getprop("autopilot/route-manager/route/wp["~pln_wpt_idx~"]/latitude-deg");
					pos.lon = getprop("autopilot/route-manager/route/wp["~pln_wpt_idx~"]/longitude-deg");
				}
			} else {
				pos.lat = getprop("autopilot/route-manager/route/wp["~pln_wpt_idx~"]/latitude-deg");
				pos.lon = getprop("autopilot/route-manager/route/wp["~pln_wpt_idx~"]/longitude-deg");
			}
		} else {
			pos.lat = userLat;
			pos.lon = userLon;
		}
		if(me.in_mode('toggle_display_mode', ['PLAN'])) {
			pos.hdg = 0;
			pos.range = me.rangeNm()*2
		} else {
			pos.range = me.rangeNm(); # avoid this  here, use a listener instead
			pos.hdg = userHdgTrkTru;
		}
		if(me.options != nil and (var pos_callback = me.options['position_callback']) != nil)
			pos_callback(me, pos);
		call(me.map.setPos, [pos.lat, pos.lon], me.map, pos);
		if(pos.range != oldRange){
			foreach(l; me.range_dependant_layers){
				l.update();
			}
		}
	},
	# each model should keep track of when it last got updated, using current lat/lon
	# in update(), we can then check if the aircraft has traveled more than 0.5-1 nm (depending on selected range)
	# and update each model accordingly
	# TODO: Hooray is still waiting for a really rainy weekend to clean up all the mess here... so plz don't add to it!
	update: func() # FIXME: This stuff is still too aircraft specific, cannot easily be reused by other aircraft
	{
		var _time = systime();
		# Disables WXR Live if it's not enabled. The toggle_weather_live should be common to all 
		# ND instances.
		var wxr_live_enabled = getprop(wxr_live_tree~'/enabled');
		if(wxr_live_enabled == nil or wxr_live_enabled == '') 
			wxr_live_enabled = 0;
		me.set_switch('toggle_weather_live', wxr_live_enabled);
		
		call(me.update_sub, nil, nil, caller(0)[0]); # call this in the same namespace to "steal" its variables

		# MapStructure update!
		if (me.map.controller.should_update_all()) {
			me.map.update();
		} else {
			# TODO: ugly list here
			# FIXME: use a VOLATILE layer helper here that handles TFC, APS, WXR etc ?
			var update_layers = me.always_update_layers;
			me.map.update(func(layer) contains(update_layers, layer.type));
		}

		# Other symbol update
		# TODO: should be refactored!
		var translation_callback = nil;
		if(me.options != nil)
			translation_callback = me.options['translation_callback'];
		if(typeof(translation_callback) == 'func'){
			var trsl = translation_callback(me);
			me.map.setTranslation(trsl.x, trsl.y);
		} else {
			if(me.in_mode('toggle_display_mode', ['PLAN']))
				me.map.setTranslation(512,512);
			elsif(me.get_switch('toggle_centered'))
				me.map.setTranslation(512,565);
			else
				me.map.setTranslation(512,824);	
		}

		if(me.get_switch('toggle_rh_vor_adf') == 1) {
			me.symbols.vorR.setText("VOR R");
			me.symbols.vorR.setColor(0.195,0.96,0.097);
			me.symbols.dmeR.setText("DME");
			me.symbols.dmeR.setColor(0.195,0.96,0.097);
			if(getprop("instrumentation/nav[1]/in-range"))
				me.symbols.vorRId.setText(getprop("instrumentation/nav[1]/nav-id"));
			else
				me.symbols.vorRId.setText(getprop("instrumentation/nav[1]/frequencies/selected-mhz-fmt"));
			me.symbols.vorRId.setColor(0.195,0.96,0.097);
			if(getprop("instrumentation/dme[1]/in-range"))
				me.symbols.dmeRDist.setText(sprintf("%3.1f",getprop("instrumentation/dme[1]/indicated-distance-nm")));
			else me.symbols.dmeRDist.setText(" ---");
			me.symbols.dmeRDist.setColor(0.195,0.96,0.097);
		} elsif(me.get_switch('toggle_rh_vor_adf') == -1) {
			me.symbols.vorR.setText("ADF R");
			me.symbols.vorR.setColor(0,0.6,0.85);
			me.symbols.dmeR.setText("");
			me.symbols.dmeR.setColor(0,0.6,0.85);
			if((var navident=getprop("instrumentation/adf[1]/ident")) != "")
				me.symbols.vorRId.setText(navident);
			else me.symbols.vorRId.setText(sprintf("%3d",getprop("instrumentation/adf[1]/frequencies/selected-khz")));
			me.symbols.vorRId.setColor(0,0.6,0.85);
			me.symbols.dmeRDist.setText("");
			me.symbols.dmeRDist.setColor(0,0.6,0.85);
		} else {
			me.symbols.vorR.setText("");
			me.symbols.dmeR.setText("");
			me.symbols.vorRId.setText("");
			me.symbols.dmeRDist.setText("");
		}

		# Hide heading bug 10 secs after change
		var vhdg_bug = getprop("autopilot/settings/heading-bug-deg") or 0;
		var hdg_bug_active = getprop("autopilot/settings/heading-bug-active");
		if (hdg_bug_active == nil)
			hdg_bug_active = 1;
						
		if((me.in_mode('toggle_display_mode', ['MAP']) and me.get_switch('toggle_display_type') == "CRT")
			or (me.get_switch('toggle_track_heading') and me.get_switch('toggle_display_type') == "LCD"))
		{
			me.symbols.trkInd.setRotation(0);
			me.symbols.curHdgPtr.setRotation((userHdg-userTrk)*D2R);
			me.symbols.curHdgPtr2.setRotation((userHdg-userTrk)*D2R);
		}
		else
		{
			me.symbols.trkInd.setRotation((userTrk-userHdg)*D2R);
			me.symbols.curHdgPtr.setRotation(0);
			me.symbols.curHdgPtr2.setRotation(0);
		}
		if(!me.in_mode('toggle_display_mode', ['PLAN']))
		{
			var hdgBugRot = (vhdg_bug-userHdgTrk)*D2R;
			me.symbols.selHdgLine.setRotation(hdgBugRot);
			me.symbols.hdgBug.setRotation(hdgBugRot);
			me.symbols.hdgBug2.setRotation(hdgBugRot);
			me.symbols.selHdgLine2.setRotation(hdgBugRot);
		}

		var staPtrVis = !me.in_mode('toggle_display_mode', ['PLAN']);
		if((me.in_mode('toggle_display_mode', ['MAP']) and me.get_switch('toggle_display_type') == "CRT")
		    or (me.get_switch('toggle_track_heading') and me.get_switch('toggle_display_type') == "LCD"))
		{
			var vorheading = userTrkTru;
			var adfheading = userTrkMag;
		}
		else
		{
			var vorheading = userHdgTru;
			var adfheading = userHdgMag;
		}
		if(getprop("instrumentation/nav/heading-deg") != nil)
			var nav0hdg=getprop("instrumentation/nav/heading-deg") - vorheading;
		if(getprop("instrumentation/nav[1]/heading-deg") != nil)
			var nav1hdg=getprop("instrumentation/nav[1]/heading-deg") - vorheading;
		var adf0hdg=getprop("instrumentation/adf/indicated-bearing-deg");
		var adf1hdg=getprop("instrumentation/adf[1]/indicated-bearing-deg");
		if(!me.get_switch('toggle_centered'))
		{
			if(me.in_mode('toggle_display_mode', ['PLAN']))
				me.symbols.trkInd.hide();
			else
				me.symbols.trkInd.show();
			if((getprop("instrumentation/nav/in-range") and me.get_switch('toggle_lh_vor_adf') == 1)) {
				me.symbols.staArrowL.setVisible(staPtrVis);
				me.symbols.staToL.setColor(0.195,0.96,0.097);
				me.symbols.staFromL.setColor(0.195,0.96,0.097);
				me.symbols.staArrowL.setRotation(nav0hdg*D2R);
			}
			elsif(getprop("instrumentation/adf/in-range") and (me.get_switch('toggle_lh_vor_adf') == -1)) {
				me.symbols.staArrowL.setVisible(staPtrVis);
				me.symbols.staToL.setColor(0,0.6,0.85);
				me.symbols.staFromL.setColor(0,0.6,0.85);
				me.symbols.staArrowL.setRotation(adf0hdg*D2R);
			} else {
				me.symbols.staArrowL.hide();
			}
			if((getprop("instrumentation/nav[1]/in-range") and me.get_switch('toggle_rh_vor_adf') == 1)) {
				me.symbols.staArrowR.setVisible(staPtrVis);
				me.symbols.staToR.setColor(0.195,0.96,0.097);
				me.symbols.staFromR.setColor(0.195,0.96,0.097);
				me.symbols.staArrowR.setRotation(nav1hdg*D2R);
			} elsif(getprop("instrumentation/adf[1]/in-range") and (me.get_switch('toggle_rh_vor_adf') == -1)) {
				me.symbols.staArrowR.setVisible(staPtrVis);
				me.symbols.staToR.setColor(0,0.6,0.85);
				me.symbols.staFromR.setColor(0,0.6,0.85);
				me.symbols.staArrowR.setRotation(adf1hdg*D2R);
			} else {
				me.symbols.staArrowR.hide();
			}
			me.symbols.staArrowL2.hide();
			me.symbols.staArrowR2.hide();
			me.symbols.curHdgPtr2.hide();
			me.symbols.HdgBugCRT2.hide();
			me.symbols.TrkBugLCD2.hide();
			me.symbols.HdgBugLCD2.hide();
			me.symbols.selHdgLine2.hide();
			me.symbols.curHdgPtr.setVisible(staPtrVis);
			me.symbols.HdgBugCRT.setVisible(staPtrVis and !dispLCD);
			if(me.get_switch('toggle_track_heading') and !me.get_switch('toggle_hdg_bug_only'))
			{
				me.symbols.HdgBugLCD.hide();
				me.symbols.TrkBugLCD.setVisible(staPtrVis and dispLCD);
			}
			else
			{
				me.symbols.TrkBugLCD.hide();
				me.symbols.HdgBugLCD.setVisible(staPtrVis and dispLCD);
			}
			me.symbols.selHdgLine.setVisible(staPtrVis and hdg_bug_active);
		} else {
			me.symbols.trkInd.hide();
			if((getprop("instrumentation/nav/in-range")	and me.get_switch('toggle_lh_vor_adf') == 1)) {
				me.symbols.staArrowL2.setVisible(staPtrVis);
				me.symbols.staFromL2.setColor(0.195,0.96,0.097);
				me.symbols.staToL2.setColor(0.195,0.96,0.097);
				me.symbols.staArrowL2.setRotation(nav0hdg*D2R);
			} elsif(getprop("instrumentation/adf/in-range") and (me.get_switch('toggle_lh_vor_adf') == -1)) {
				me.symbols.staArrowL2.setVisible(staPtrVis);
				me.symbols.staFromL2.setColor(0,0.6,0.85);
				me.symbols.staToL2.setColor(0,0.6,0.85);
				me.symbols.staArrowL2.setRotation(adf0hdg*D2R);
			} else {
				me.symbols.staArrowL2.hide();
			}
			if((getprop("instrumentation/nav[1]/in-range") and me.get_switch('toggle_rh_vor_adf') == 1)) {
				me.symbols.staArrowR2.setVisible(staPtrVis);
				me.symbols.staFromR2.setColor(0.195,0.96,0.097);
				me.symbols.staToR2.setColor(0.195,0.96,0.097);
				me.symbols.staArrowR2.setRotation(nav1hdg*D2R);
			} elsif(getprop("instrumentation/adf[1]/in-range") and (me.get_switch('toggle_rh_vor_adf') == -1)) {
				me.symbols.staArrowR2.setVisible(staPtrVis);
				me.symbols.staFromR2.setColor(0,0.6,0.85);
				me.symbols.staToR2.setColor(0,0.6,0.85);
				me.symbols.staArrowR2.setRotation(adf1hdg*D2R);
			} else {
				me.symbols.staArrowR2.hide();
			}
			me.symbols.staArrowL.hide();
			me.symbols.staArrowR.hide();
			me.symbols.curHdgPtr.hide();
			me.symbols.HdgBugCRT.hide();
			me.symbols.TrkBugLCD.hide();
			me.symbols.HdgBugLCD.hide();
			me.symbols.selHdgLine.hide();
			me.symbols.curHdgPtr2.setVisible(staPtrVis);
			me.symbols.HdgBugCRT2.setVisible(staPtrVis and !dispLCD);
			if(me.get_switch('toggle_track_heading') and !me.get_switch('toggle_hdg_bug_only'))
			{
				me.symbols.HdgBugLCD2.hide();
				me.symbols.TrkBugLCD2.setVisible(staPtrVis and dispLCD);
			}
			else
			{
				me.symbols.TrkBugLCD2.hide();
				me.symbols.HdgBugLCD2.setVisible(staPtrVis and dispLCD);
			}
			me.symbols.selHdgLine2.setVisible(staPtrVis and hdg_bug_active);
		}

		## run all predicates in the NDStyle hash and evaluate their true/false behavior callbacks
		## this is in line with the original design, but normally we don't need to getprop/poll here,
		## using listeners or timers would be more canvas-friendly whenever possible
		## because running setprop() on any group/canvas element at framerate means that the canvas
		## will be updated at frame rate too - wasteful ... (check the performance monitor!)

		foreach(var feature; me.nd_style.features ) {
			# for stuff that always needs to be updated
			if (contains(feature.impl, 'common')) feature.impl.common(me);
			# conditional stuff
			if(!contains(feature.impl, 'predicate')) continue; # no conditional stuff
			if ( var result=feature.impl.predicate(me) )
				feature.impl.is_true(me, result); # pass the result to the predicate
			else
				feature.impl.is_false( me, result ); # pass the result to the predicate
		}

		## update the status flags shown on the ND (wxr, wpt, arpt, sta)
		# this could/should be using listeners instead ...
		me.symbols['status.wxr'].setVisible( me.get_switch('toggle_weather') and me.in_mode('toggle_display_mode', ['MAP']));
		me.symbols['status.wpt'].setVisible( me.get_switch('toggle_waypoints') and me.in_mode('toggle_display_mode', ['MAP']));
		me.symbols['status.arpt'].setVisible( me.get_switch('toggle_airports') and me.in_mode('toggle_display_mode', ['MAP']));
		me.symbols['status.sta'].setVisible( me.get_switch('toggle_stations') and  me.in_mode('toggle_display_mode', ['MAP']));
		# Okay, _how_ do we hook this up with FGPlot?
		logprint(canvas._MP_dbg_lvl, "Total ND update took "~((systime()-_time)*100)~"ms");
		setprop("instrumentation/navdisplay["~ NavDisplay.id ~"]/update-ms", systime() - _time);
	} # of update() method (50% of our file ...seriously?)
};