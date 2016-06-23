@lazyglobal off.
parameter param_azimuth is 90.

run once lib_geo.
SET ship:control:pilotmainthrottle TO 0.

GLOBAL speed_pid IS pidloop(0.1, 0.005, 0.5, 0, 1).

GLOBAL wheel_pid IS pidloop(-0.1, -0.001, 0, -1, 1).



print "turning at " + param_azimuth.
SET wheel_pid:setpoint TO param_azimuth.
LOCK wheel_input TO geo_vessel_azimuth(ship:facing:forevector,
    param_azimuth). // azimuth

set speed_pid:setpoint to 2.
LOCK speed_input TO ship:velocity:surface:mag.

brakes off.
sas off.

lock steering to up.
wait 0.1.
unlock steering.
until false {
    LOCAL wheel_output IS wheel_pid:update(time:seconds(), wheel_input).
    SET ship:control:wheelsteer TO wheel_output.

    IF abs(wheel_pid:error) < 1 {
        // TODO check for turning speed ~= 0
        BREAK.
    }

    set speed_pid:kp to ship:mass / ship:maxthrust.
    set speed_pid:ki to speed_pid:kp / 10.
    LOCAL speed_output IS speed_pid:update(time:seconds(), speed_input).
    LOCK throttle TO speed_output.
}
SET ship:control:wheelsteer TO 0.



print "accelerating".
LOCK throttle TO 1.
SET ship:control:pitch TO 1.
GLOBAL alt_target IS alt:radar + 5.

// TODO steer wheels based on current momentum
// TODO roll based on current momentum
wait until alt:radar > alt_target.



print "take-off!".
SET ship:control:pitch to 0.
SET ship:control:pilotmainthrottle TO 1.
sas on.
gear off.
