@lazyglobal off.

parameter target_apoapsis is 80000.
parameter ascent_compass is 90. // TODO default 90

parameter pitch_angle is 5. // pitch angle
parameter low_twr is 1.8. // low atm twr
parameter high_twr is 2.5. // high atm twr

parameter throttle_speed is 75. // speed before pitch maneuver
parameter regain_control_alt is 32000.


LOCAL script_name IS "Booster T1".
run once lib_geo.
run once lib_util.

function booster_notify {
    parameter message.
    parameter size is 1.0.

    if script_name <> "" {
        set message to script_name + ": " + message.
    }

    hudtext(message,
        15, //delayseconds
        2, // upper center
        25 * size, // size modifier
        white,
        true).
}

lock steering to geo_side_heading(ascent_compass, 90).
until ship:airspeed < 0.01 {
    wait until ship:airspeed < 0.01.
    wait 0.1.
}

booster_notify("launch").
lock throttle to 1.
lock steering to geo_side_heading(ascent_compass, 90).
if ship:maxthrust = 0 {
    wait until stage:ready.
    stage.
}
wait until ship:airspeed > throttle_speed.

booster_notify("pitch maneuver").
lock throttle to util_twr_throttle(low_twr).
local pitch_angle_plus is 90 - pitch_angle * 1.2.
lock steering to geo_side_heading(ascent_compass, pitch_angle_plus).
wait until geo_vessel_pitch(ship:velocity:surface) < 90 - pitch_angle.

booster_notify("pitch maneuver: velocity aligning").
lock throttle to util_twr_throttle(low_twr).
lock steering to geo_side_heading(ascent_compass,
        geo_vessel_pitch(ship:velocity:surface)).
wait until vectorangle(ship:velocity:surface,
        ship:facing:forevector) < 0.1.

booster_notify("gravity turn").
lock throttle to util_twr_throttle(low_twr).
unlock steering.
// TODO maintain ascent_compass stability with pitch control
// TODO probably also maintain roll stability
wait until altitude > regain_control_alt.

booster_notify("regain control").
lock throttle to util_twr_throttle(high_twr).
lock steering to geo_side_heading(ascent_compass,
        geo_vessel_pitch(ship:velocity:orbit)).
wait until ship:apoapsis > target_apoapsis or maxthrust=0.

booster_notify("finished").
lock throttle to 0.
unlock steering.
