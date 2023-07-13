# Terrain Sampler
# Classic dirt is 82, 67, 45

var terr = props.globals.initNode("instrumentation/terrain/type", "", "STRING");
var streak = [props.globals.initNode("instrumentation/terrain/red", 0.0, "DOUBLE"), props.globals.initNode("instrumentation/terrain/green", 0.0, "DOUBLE"), props.globals.initNode("instrumentation/terrain/blue", 0.0, "DOUBLE"), props.globals.initNode("instrumentation/terrain/alpha", 1.0, "DOUBLE")];
latDeg = props.globals.getNode("position/latitude-deg");
longDeg = props.globals.getNode("position/longitude-deg");
season = props.globals.getNode("sim/startup/season");

var terrUpdate = func {
    var info = geodinfo(latDeg.getValue(), longDeg.getValue());
    var ground = info[1].names;
    var region = info[1].region;
    terr.setValue(ground[0]);
    if (ground[0] == "BuiltUpCover" or ground[0] == "Town" or ground[0] == "Freeway" or ground[0] == "pa_taxiway" or ground[0] == "pa_tiedown" or ground[0] == "pc_taxiway" or ground[0] == "pc_tiedown") {
        streak[3].setValue(0);
    } elsif (season.getValue() == "winter") {
        streak[0].setValue(1);
        streak[1].setValue(1);
        streak[2].setValue(1);
    } elsif (region == "African desert") {
        if(ground[0] == "Grass") {
            streak[0].setValue(189/255);
            streak[1].setValue(179/255);
            streak[2].setValue(146/255);
        } elsif (ground[0] == "DryLake") {
            streak[0].setValue(146/255);
            streak[1].setValue(146/255);
            streak[2].setValue(128/255);
        } elsif (ground[0] == "Landmass") {
            streak[0].setValue(168/255);
            streak[1].setValue(163/255);
            streak[2].setValue(135/255);
        } elsif (ground[0] == "Lava") {
            streak[0].setValue(96/255);
            streak[1].setValue(73/255);
            streak[2].setValue(52/255);
        } elsif (ground[0] == "BarrenCover") {
            streak[0].setValue(142/255);
            streak[1].setValue(120/255);
            streak[2].setValue(102/255);
        } elsif (ground[0] == "EvergreenBroadCover") {
            streak[0].setValue(200/255);
            streak[1].setValue(184/255);
            streak[2].setValue(158/255);
        } elsif (ground[0] == "DryCropPastureCover" or ground[0] == "IrrCropPastureCover" or ground[0] == "GrassCover") {
            streak[0].setValue(82/255);
            streak[1].setValue(67/255);
            streak[2].setValue(45/255);
        }
    } elsif (region == "Africa: Kilimanjaro") {
        if (ground[0] == "ScrubCover" or ground[0] == "EvergreenBroadCover") {
            streak[0].setValue(82/255);
            streak[1].setValue(67/255);
            streak[2].setValue(45/255);
        }
    } elsif (region == "African mediterranean") {
        if (ground[0] == "Grass") {
            streak[0].setValue(166/255);
            streak[1].setValue(122/255);
            streak[2].setValue(86/255);
        } elsif (ground[0] == "RainForest" or ground[0] == "EvergreenBroadCover" or ground[0] == "Grassland" or ground[0] == "Shrub" or ground[0] == "Orchard" or ground[0] == "IrrCropPastureCover") {
            streak[0].setValue(82/255);
            streak[1].setValue(67/255);
            streak[2].setValue(45/255);
        } elsif (ground[0] == "Sclerophyllous" or ground[0] == "DryCropPastureCover") {
            streak[0].setValue(166/255);
            streak[1].setValue(122/255);
            streak[2].setValue(86/255);
        } elsif (ground[0] == "DryLake") {
            streak[0].setValue(146/255);
            streak[1].setValue(146/255);
            streak[2].setValue(122/255);
        } elsif (ground[0] == "BarrenCover") {
            streak[0].setValue(236/255);
            streak[1].setValue(224/255);
            streak[2].setValue(192/255);
        }
    } elsif (region == "African rainforest") {
        if (ground[0] == "Grass" or ground[0] == "MixedForestCover" or ground[0] == "MixedCrop" or ground[0] == "EvergreenBroadCover") {
            streak[0].setValue(166/255);
            streak[1].setValue(122/255);
            streak[2].setValue(86/255);
        } elsif (ground[0] == "dirt_rwy") {
            streak[0].setValue(136/255);
            streak[1].setValue(106/255);
            streak[2].setValue(73/255);
        }
    } elsif (region == "Africa: savanna") {
        if (ground[0] == "RainForest" or ground[0] == "EvergreenBroadCover" or ground[0] == "ShrubCover" or ground[0] == "DryCropPastureCover") {
            streak[0].setValue(82/255);
            streak[1].setValue(67/255);
            streak[2].setValue(45/255);
        }
    } elsif (region == "Alaska and NW Territories") {
        if (ground[0] == "MixedForestCover" or ground[0] == "DeciduousBroadCover" or ground[0] == "ShrubCover" or ground[0] == "EvergreenBroadCover") {
            streak[0].setValue(82/255);
            streak[1].setValue(67/255);
            streak[2].setValue(45/255);
        }
    } elsif (region == "Arctic and Antarctic") {
        if(ground[0] == "Grass") {
            streak[0].setValue(1);
            streak[1].setValue(1);
            streak[2].setValue(1);
        } elsif (ground[0] == "dirt_rwy") {
            streak[0].setValue(136/255);
            streak[1].setValue(106/255);
            streak[2].setValue(73/255);
        }
    } elsif (region == "Ascension Island") {
        if (ground[0] == "Scrub" or ground[0] == "Grass") {
            streak[0].setValue(96/255);
            streak[1].setValue(73/255);
            streak[2].setValue(52/255);
        }
    } elsif (region == "Asia") {
        if (ground[0] == "IrrCropPastureCover" or ground[0] == "MixedCropPastureCover" or ground[0] == "Grassland" or ground[0] == "DeciduousBroadCover" or ground[0] == "ShrubCover") {
            streak[0].setValue(82/255);
            streak[1].setValue(67/255);
            streak[2].setValue(45/255);
        }
    }
    
};

var timer = maketimer(0.1, terrUpdate);
timer.simulatedTime = 1;
timer.start();