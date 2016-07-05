function orange {
	parameter message.
	parameter time.
	parameter echo is true.
	hudtext(ship:name + ": " + message, time, 2, 35, rgb(1, 0.5, 0), echo).
}
function notify {
	parameter message.
	hudtext(ship:name + ": " + message, 15, 2, 25, white, true).
}
function wait_rt_connection {
	if addons:rt:available {
		local first is true.
		align_solar(0).
		until addons:rt:hasconnection(ship) {
			align_solar(0).
			orange("waiting for RT connection", 1, first).
			wait 1.5.
			set first to false.
		}
	}
}
function lock_steering {
		// returns true if achieved; false on time limit
	parameter tgt, time_limit is -1.
	sas off.
	local tgt_v is tgt.
	if tgt:typename = "Direction" {
		set tgt_v to tgt:forevector.
	}
	else if tgt:typename = "Vector" {
	} else {
		error["only Directions and Vectors are accepted"].
	}
	lock steering to tgt.
	until vectorangle(ship:facing:forevector, tgt_v) < 1
			and vectorexclude(tgt_v, ship:angularvel):mag < 0.01 {
		if time_limit >= 0 and time:seconds >= time_limit {
			return false.
		}
	}
	if tgt:typename = "Vector" {
		set tgt to lookdirup(tgt_v, ship:facing:topvector).
		lock steering to tgt.
	}
	until vectorangle(ship:facing:forevector, tgt_v) < 1
			and vectorangle(ship:facing:topvector, tgt:topvector) < 1
			and ship:angularvel:mag < 0.01 {
		if time_limit >= 0 and time:seconds >= time_limit {
			return false.
		}
	}
	return true.
}
function align_solar {
	parameter time_limit is -1.
	// assert solar panel is on the eastern side of the ship
	if sas {
		return true.
	}
	local solar_dir is vcrs(body:prograde:forevector,
			sun:position - body:position):normalized.
	local solar_dir_top is vcrs(solar_dir,
			sun:position - body:position):normalized.
	local dir is lookdirup(solar_dir, solar_dir_top).
	local res is lock_steering(dir, time_limit). // sas off
	if res {
		// if achieved, use sas instead (for PersistentRotation)
		unlock steering.
		sas on.
		if sas { // TODO check if this works
			return res.
		}
	}
	// relock to functional expression
	lock steering to lookdirup(
		vcrs(body:prograde:forevector, sun:position-body:position):normalized,
		vcrs(vcrs(body:prograde:forevector, sun:position-body:position),
				 sun:position-body:position):normalized).
	return res.
}
