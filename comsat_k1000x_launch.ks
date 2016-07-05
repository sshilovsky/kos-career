@lazyglobal off.
// TODO 5kb limit
parameter gravity_angle.
parameter target_orbit is 1000000.
parameter low_orbit is 80000.
parameter throttle_speed is 75.
parameter angle_period is 90.

// TODO doesn't work:
lock steering to ship:facing. // crash every core except for one

set ship:control:pilotmainthrottle to 0.
sas on.

if addons:rt:available {
	local first is true.
	until addons:rt:hasconnection(ship) {
		orange("waiting for RT connection", 1, first).
		wait 1.5.
		set first to false.
	}
}
copy comsat_k1000x_lib_common from 0.
run once comsat_k1000x_lib_common.

function loadfile {
	parameter c.
	parameter fname.
	if not c:volume:create(fname):write(archive:open(fname):readall()) {
		error[""].
	}
}

function antennae_event {
	parameter evt.
	for m in ship:modulesnamed("ModuleRTAntenna") {
		if m:hasevent(evt) {
			m:doevent(evt).
		}
	}
}

function target_exists {
	parameter name.
	local targets is 0.
	list targets in targets.
	for t in targets {
		if t:name = name {
			return true.
		}
	}
	return false.
}

function cut_xdigit {
	parameter name.
	local dash is name:findlast("X").
	if dash = -1 {
		return name.
	}
	local i is dash + 1.
	if i = name:length { // no digits after X
		return name.
	}
	until i = name:length {
		if name[i] < "0" or name[i] > "9" {
			return name.
		}
		set i to i + 1.
	}
	return name:substring(0, dash).
}

wait until stage:ready.
until ship:availablethrust > 0 {
	orange("push STAGE", 1, false).
	wait 1.5.
}

local cores is 0. // setup cores
list processors in cores.
local rootname is cut_xdigit(ship:name).
local next_index is 0.
local num_probes is cores:length.
until false {
	if target_exists(rootname + "/" + next_index) {
		set next_index to next_index + 1.
	} else {
		break.
	}
}
for c in cores {
	c:volume:delete("comsat_k1000x_launch.ks").
	local idfile is c:volume:create("id.ks").
	local q is char(34).
	idfile:writeln("set low_orbit to "+low_orbit+".").
	idfile:writeln("set target_orbit to "+target_orbit+".").
	idfile:writeln("set num_probes to "+num_probes+".").
	idfile:writeln("set nameprefix to "+q+rootname+"/"+q+".").
	idfile:writeln("set newname to "+q+rootname+"/"+next_index+q+".").
	idfile:writeln("set target_angle to "+angle_period*next_index+".").
	idfile:writeln("set comsat_root to "+q+rootname+"/0"+q+".").
	set next_index to next_index + 1.
	loadfile(c, "comsat_k1000x_lo.ks").
	set c:bootfilename to "comsat_k1000x_lo.ks".
	loadfile(c, "comsat_k1000x_lib_orbit.ks").
	if c:part<>core:part {
		loadfile(c, "comsat_k1000x_lib_common.ks").
		c:deactivate.
	}
}

// booster stage
sas off.
when ship:status="FLYING" then {
	antennae_event("deactivate").
}
switch to 0.
run booster_t1(low_orbit, 90, gravity_angle, throttle_speed).
notify("apoapsis so far: " + ship:apoapsis).
notify("stage fuel left: " + stage:liquidfuel).
if ship:availablethrust > 0 {
	wait 0.5.
}

antennae_event("activate").
for c in cores {
	if c:part<>core:part {
		c:activate.
	}
}
wait until stage:ready. stage.
reboot.
