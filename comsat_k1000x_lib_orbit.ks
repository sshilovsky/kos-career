function calculate_burn_time {
	parameter deltav.
	// calculating average isp: http://forum.kerbalspaceprogram.com/index.php?/topic/61827-11-kos-scriptable-autopilot-system-v0201-2016515/&page=59#comment-1405498
	local back_isp is 0.
	until back_isp > 0 {
		local MyEngines is list().
		LIST ENGINES in MyEngines.
		for engine in MyEngines {
			if engine:ISP > 0 { // inactive engines have 0 here
				set back_isp to back_isp
						+ (engine:availablethrustat(0) / engine:ISP).
			}
		}
	}
	local isp_avg is SHIP:availablethrustat(0) / back_isp.
	// calculating burn time: https://www.reddit.com/r/Kos/comments/3ftcwk/compute_burn_time_with_calculus/?st=iq4cy000&sh=a90bb600
	LOCAL g IS 9.80665. // used to convert ISP to non-g-dependant unit
	return g * ship:mass * isp_avg / ship:availablethrustat(0)
			* (1 - constant:e ^ (-deltav / (g * isp_avg))).
}
function shownode {
	parameter eta_, v1, v2, v3.
	// TODO add alarm
	if not (career():canmakenodes and ship=kuniverse:activevessel) {
		return.
	}
	if hasnode {
		set nextnode:eta to eta_.
		set nextnode:radialout to v1.
		set nextnode:normal to v2.
		set nextnode:prograde to v3.
	} else {
		add node(eta_, v1, v2, v3).
	}
}
function ap_circularize {
	parameter message.
	parameter periapsis_target.

	notify(message + ": wait").
	local burn_time is 0.
	local deltav is 0.
	local first is true.
	until false {
		align_solar(0).
		local obt is ship:orbit.
		// TODO simplify with vis-viva
		// calculating speed in apoapsis (energy values are divided by
		// current mass)
		local ek	is (ship:velocity:orbit:mag ^ 2) / 2.
		local eh	is -body:mu / (body:radius + altitude).
		local eh_ap is -body:mu / (body:radius + obt:apoapsis).
		local ek_ap is ek + eh - eh_ap.
		local v_ap  is sqrt(ek_ap * 2).

		// calculating desired speed for circular orbit
		local g_ap  is body:mu / (body:radius + obt:apoapsis). // g-force at
				// apoapsis height. normalized: /ship:mass, *R
		// g_ap should be equal to centrifugal force f_c = mv^2/r
		local v_target is sqrt(g_ap).
		set deltav to v_target - v_ap.
		set burn_time to calculate_burn_time(deltav).
		shownode(eta:apoapsis, 0, 0, deltav).
		if eta:apoapsis < burn_time/2 + 10 {
				// 10 seconds margin before start of the burn
			break.
		}
		if first {
			local alarm is addalarm("Raw",
				time:seconds + eta:apoapsis - burn_time/2 - 60,
				"Maneuver: " + ship:name, message).
			set first to false.
			set alarm:action to "KillWarp".
			// TODO delete future alarms; also check kac:available
		}
	}

	notify(message).
	sas off.
	local norm is vcrs(ship:position-ship:body:position,
			ship:velocity:orbit):normalized.
	local pe_vector is angleaxis(-ship:orbit:trueanomaly, norm)
			* (ship:position - ship:body:position).
	local deltav_dir is vcrs(pe_vector, norm):normalized.
	lock steering to deltav_dir.
	wait until eta:apoapsis < burn_time / 2.
	shownode(eta:apoapsis, 0, 0, deltav).
	lock throttle to 1.
	wait until ship:periapsis > periapsis_target. // TODO altitude > (ap+pe)/2 ?
	lock throttle to 0.
} // ap_circularize
