@lazyglobal off.
sas off.

run comsat_k1000x_lib_common.
run comsat_k1000x_lib_orbit.
run comsat_k1000x_lib_conics.
run id.
set comsat_root to vessel(comsat_root).

local first is true.
until comsat_root:orbit:periapsis > target_orbit * 0.8 {
	align_solar(0).
	orange("waiting for " + comsat_root:name + " to be set up", 1, first).
	wait 1.5.
	set first to false.
}

if ship:apoapsis < target_orbit * 0.95 {
	notify("target transition: wait").

	// determine angle between self and root comsat to start from
	local root_period is comsat_root:orbit:period.

	local lo_avg is body:radius + (ship:apoapsis + ship:periapsis) / 2.
	local tr_a is (lo_avg + body:radius + target_orbit) / 2.
	local tr_period is sqrt(tr_a^3 * 4 * constant:pi^2
			/ body:mu).
	local tr_time is tr_period / 2.

	// also need to account for the burn time. don't really need though,
	// but lets just do it
	local v_0 is sqrt(body:mu / lo_avg). // vis-viva
	local v_1 is sqrt(body:mu * (2/lo_avg - 1/tr_a)). // vis-viva
	local tr_dv is v_1 - v_0.
	local burn_time is calculate_burn_time(tr_dv).

	local gamma is 360 * (tr_time + burn_time/2) / root_period.
			// angle which root comsat gonna pass during transition of this
			// comsat
	local beta is gamma + target_angle - 180. // angle between this comsat and
			// root comsat to start transition at

	local beta0 is get_root_angle().

	local delta_angle is beta - beta0.
	until delta_angle >= 0 {
		set delta_angle to delta_angle + 360.
	}

	local omega_delta is 360*(1/ship:orbit:period - 1/root_period).
			// angular speed of this comsat relative to root comsat
	local time_before_burn is delta_angle/omega_delta.
	local node_time is time:seconds + time_before_burn + burn_time/2.


	local alarm is addalarm("Raw",
		node_time - burn_time/2 - 60,
		"Maneuver: " + ship:name, "target transition").
	set alarm:action to "KillWarp".
	// TODO delete future alarms; also check kac:available

	until time:seconds > node_time - burn_time/2 - 10 {
		align_solar(0).
		shownode(node_time - time:seconds, 0, 0, tr_dv).
	}

	notify("target transition").
	local norm is vcrs(ship:position-ship:body:position,
			ship:velocity:orbit):normalized.
	local burn_point is angleaxis(360 * (node_time-time:seconds) / ship:orbit:period, norm)
			* (ship:position - ship:body:position).
	local dv_dir is vcrs(norm, burn_point). // TODO test for errors
	sas off.
	lock steering to dv_dir.
	wait until time:seconds > node_time - burn_time/2.

	lock throttle to 1.
	wait until ship:apoapsis > target_orbit.
	lock throttle to 0.
}

if ship:periapsis < target_orbit * 0.8 {
	ap_circularize("target circularization", target_orbit * 0.8).
}

wait_rt_connection().
delete comsat_k1000x_lib_orbit.
delete comsat_k1000x_target.
copy comsat_k1000x_sync from 0.
set core:bootfilename to "comsat_k1000x_sync.ks".
reboot.
