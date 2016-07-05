function pe_vector {
	parameter vessel.
	local norm is vcrs(vessel:position-vessel:body:position,
			vessel:velocity:orbit):normalized.
	return angleaxis(-vessel:orbit:trueanomaly, norm)
			* (vessel:position - vessel:body:position).
}
function mean_anomaly {
	parameter orbit.
	// https://en.wikipedia.org/w/index.php?title=Eccentric_anomaly&oldid=721113565
	local theta is orbit:trueanomaly.
	local tanE2 is sqrt((1-orbit:eccentricity)/(1+orbit:eccentricity))
			* tan(theta/2).
	local EE is 2 * arctan(tanE2). // eccentric anomaly
	return EE - orbit:eccentricity * sin(EE).
}
function get_root_angle {
	local norm is vcrs(ship:velocity:orbit, body:position).
	//local beta0 is -signed_vangle(ship:position - body:position,
	//		comsat_root:position - body:position,
	//		norm). // orient
	local pe_self is pe_vector(ship).
	local pe_root is pe_vector(comsat_root).
	local pe_angle is signed_vangle(pe_root, pe_self, norm).

	local beta0 is pe_angle + mean_anomaly(ship:orbit) - mean_anomaly(comsat_root:orbit).

	until beta0 >= 0 {
		set beta0 to beta0 + 360.
	}
	until beta0 < 360 {
		set beta0 to beta0 - 360.
	}
	return beta0.
}
function signed_vangle {
	parameter v1, v2, orient.
	local angle is vang(v1, v2).
	local cross is vcrs(v1, v2).
	local prod is vdot(orient, cross).
	if (prod < 0) {
		SET angle TO -angle.
	}
	return angle.
}
