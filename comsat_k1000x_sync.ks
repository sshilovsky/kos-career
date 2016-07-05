@lazyglobal off.
sas off.

run comsat_k1000x_lib_common.
run comsat_k1000x_lib_conics.
run id.
set comsat_root to vessel(comsat_root).

function get_root_angle_error {
	local beta0 is get_root_angle().
	local err is beta0 - target_angle.
	until err > -180 {
		set err to err + 360.
	}
	until err <= 180 {
		set err to err - 360.
	}
	return err.
}

local target_period is comsat_root:orbit:period.
local max_angle_error is 5.
local period_acceptable_error is 0.001.
{
	// if angle is far from 90deg, increase/decrease the period so that
	// angles would eventually synchronize. add alarm on that moment.  Use
	// max_angle_error
	local root_angle_error is get_root_angle_error().
	print "angle error: " + root_angle_error.
	if abs(root_angle_error) > max_angle_error {
		set period_acceptable_error to 1.
		if root_angle_error > 0 {
			set target_period to target_period + 10.
		} else {
			set target_period to target_period - 10.
		}
	}
}

if abs(ship:orbit:period - target_period) > period_acceptable_error {
	notify("orbital period synchronizing").
	print ship:orbit:period + " vs. " + target_period.
	local const is 1. // 1 if the period is too low, -1 if too big
	if ship:orbit:period > target_period {
		set const to -1.
	}
	lock_steering(const * prograde:forevector).
	lock steering to const * prograde:forevector.
	local time0 is time:seconds.
	local period0 is ship:orbit:period.
	lock throttle to 0.000000001.
	until const * (target_period - period0) < period_acceptable_error/100 {
		//print target_period - period0 + " : " + throttle.
		wait 0.
		local newtime is time:seconds.
		local period is ship:orbit:period.
		if newtime > time0 {
			local deltat is newtime - time0.
			local delta_period is const * (period - period0).
			if delta_period > 0 {
				local error is const * (target_period - period).

				local newthrottle is throttle.
				if error / delta_period > 10 {
					set newthrottle to min(1, throttle * 1.1).
				} else {
					set newthrottle to 0.000000001.
				}
				lock throttle to newthrottle.
				set time0 to newtime.
			}
		}
		set period0 to period.
	}
	lock throttle to 0.
	//print "#"+(target_period - period0).
	//print "#"+(target_period - ship:orbit:period).
}

notify("solar aligning").
align_solar().

notify("orbital periods: " + ship:orbit:period + " vs. "
		+ comsat_root:orbit:period).
local error is get_root_angle_error().
notify("root angle error: " + error).
local omega_diff is -360 * (1/ship:orbit:period - 1/comsat_root:orbit:period).
print "omega_diff: " + omega_diff.
local alarm is 0.
local neta is 0.
if abs(error) > max_angle_error {
	print "more".
	set neta to error / (omega_diff).
	set alarm to addalarm("Raw", time:seconds + neta, "Sync " + ship:name, ship:name
			+ " synced root comsat angle. Adjust orbital period").
} else {
	print "less".
	if omega_diff > 0 {
		set neta to (error + max_angle_error) / omega_diff.
	} else {
		set neta to (error - max_angle_error) / omega_diff.
	}
	set alarm to addalarm("Raw", time:seconds + neta, "Desync " + ship:name, ship:name
			+ " desynced root comsat angle. Adjust orbital period").
}
local resync_time is time:seconds + neta.
notify("resync in " + neta + "s").
if alarm="" {
	orange("error creating (de)sync alarm", 30, true).
	if career():canmakenodes {
		add node(time:seconds + neta, 0, 0, 0).
	}
} else {
	set alarm:action to "PauseGame".
	// TODO delete future alarms; check kac:available
}

notify("finished").
wait until time:seconds > resync_time. // TODO fix: overshooting/undershooting
reboot.
