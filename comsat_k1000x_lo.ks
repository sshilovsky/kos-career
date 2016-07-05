@lazyglobal off.
sas off.
until false {
	local cores is 0.
	list processors in cores.
	if cores:length=1 {
		break.
	}
}

run comsat_k1000x_lib_common.
run comsat_k1000x_lib_orbit.
run id.

function align_prograde {
	parameter vess.
	wait until vectorangle(vess:velocity:orbit, vess:facing:forevector) < 5
		and vectorexclude(vess:facing:forevector, vess:angularvel):mag < 0.1.
}

if periapsis < body:atm:height and apoapsis < low_orbit {
	lock steering to -ship:velocity:orbit.
	wait 1.
	lock steering to ship:velocity:orbit.
	notify("renamed to "+newname).
	set ship:name to newname.

	// align steering on all probes
	local tgts is 0.
	align_prograde(ship).
	local n is 0.
	until n=num_probes {
		set n to 1.
		list targets in tgts.
		for t in tgts {
			if t:name:startswith(nameprefix) and t:position:mag < 1000 {
				set n to n + 1.
				align_prograde(t).
				notify("aligned vs " + t:name).
			}
		}
	}

	notify("suborbital insertion").
	lock throttle to 1.
	if target_angle = 0 and kuniverse:activevessel <> ship {
		notify("switching to "+ship:name).
		kuniverse:forcesetactivevessel(ship).
	}
	wait until ship:apoapsis > low_orbit
			or ship:periapsis > body:atm:height.
	lock throttle to 0.
}

if ship:periapsis < body:atm:height {
	ap_circularize("LO circularization", body:atm:height).
}

if target_angle = 0 {
	align_solar(0).  sas off. // in case already aligned
	local first is true.
	until ship:ElectricCharge > 50 {
		orange("charging").
		wait 1.5.
		set first to false.
	}

	if ship:apoapsis < target_orbit * 0.9 {
		notify("target transition").
		lock_steering(ship:velocity:orbit).
		lock steering to ship:velocity:orbit.
		lock throttle to 1.
		wait until ship:apoapsis > target_orbit.
		lock throttle to 0.
	}

	if ship:periapsis < target_orbit * 0.9 {
		ap_circularize("target circularization", ship:apoapsis * 0.95).
	}
	align_solar().
	notify("finished").
} else { // target_angle > 0
	wait_rt_connection().
	delete "comsat_k1000x_lo.ks".
	copy comsat_k1000x_lib_conics from 0.
	copy comsat_k1000x_target from 0.
	set core:bootfilename to "comsat_k1000x_target.ks".
	reboot.
}

