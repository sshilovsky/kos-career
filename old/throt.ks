print "Throttle auto control script".
print "==================================================".

lock steering to up.
set my_throttle to 1.
lock throttle to my_throttle.
print "Waiting for launch...".
wait until ship:velocity:surface:mag > 1. // 1m/s

//set pid to pidloop(0.01, 1, 0).
//set pid:minoutput to 0.
//set pid:maxoutput to 1.

set prev_v to V(0, 0, 0).
set prev_t to 0.

wait until ship:velocity:surface:mag > 1.

until altitude > 70000 {
    wait 0.1.

    // follow dt and dv
    set v to ship:velocity:orbit. // vector
    set dv to v - prev_v.
    set prev_v to v.

    set t to time:seconds.
    set dt to t - prev_t.
    set prev_t to t.

    set grav_mag to constant:G * body:mass / ((body:radius + altitude) ^ 2). // scalar, m/s^2. omitting vessel:mass

    print "dt: " + dt.
    if t > dt {
        set sum_force to dv * (1.0 / dt). // vector
        set grav_force to (ship:position - body:position):normalized * grav_mag. // vector
        set air_force to sum_force - grav_force.

        print "sum: " + sum_force:mag.
        print "air:  " + air_force:mag.
        print "grav: " + grav_mag.
        //print "diff: " + (air_force:mag - grav_mag).

        if air_force:mag > grav_mag {
            set my_throttle to max(0, min(1, my_throttle - 0.1)).
        } else {
            set my_throttle to max(0, min(1, my_throttle + 0.1)).
        }

        print "new_throttle: " + my_throttle.
        print "-".
    } else {
        //set my_throttle to pid:update(t, -99999999).
        //print "start_throttle: " + my_throttle.
    }
}

print "Ending script.".
set pilotmainthrottle to 1.
unlock throttle.
sas on.
unlock steering.
print "Apoapsis: " + alt:apoapsis.
