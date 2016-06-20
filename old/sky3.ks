print "Project Sky III.".
print "Solid fuel rocket".
print "for Kerbal high atmosphere survey contracts.".
print "====================".

copy lib_autostage from archive.
run once lib_autostage.

print "waiting for a waypoint...".
until allwaypoints():length > 0 {
    wait 1.
}

// TODO interactive selection of waypoint and height.
local waypoint is allwaypoints()[0].
local target_height is 19000.
local estimated_time is 45.
local turn_height is 1000.
local turn_angle is 10.

local gp to waypoint:geoposition.
print " ".
print "             Waypoint: " + waypoint:name.
print "          Geoposition: " + gp:lat + " : " + gp:lng.
print "     Target height, m: " + target_height.
print "        Time guess, s: " + estimated_time.

set lng_correction to estimated_time / ship:body:rotationperiod * 360.
set gp to latlng(gp:lat, gp:lng + lng_correction).
set dir to gp:heading.

print " Longitude correction: " + lng_correction.
print "          Geoposition: " + gp:lat + " : " + gp:lng.
print "              Heading: " + dir.

set angle_k to gp:distance / (constant:pi * body:radius) * 70000 / target_height.
print "angle_k = " + angle_k.

print " ".
lock steering to up.
print "waiting for launch...".

wait until altitude > 100.

set angle to 0.
lock steering to heading(dir, 90 - angle).

print "initial turn...".

set start_altitude to altitude.
set end_altitude to 1000.
set start_angle to 0.
set end_angle to angle_k * 10.

lock angle to (end_angle-start_angle) * (altitude-start_altitude) / (end_altitude-start_altitude) + start_angle.
wait until altitude > end_altitude.

print "estimating turn...".
lock angle to end_angle.

set start_altitude to 1000.
set end_altitude to target_height.
set start_angle to end_angle.
set end_angle to angle_k * 45.

lock angle to (end_angle-start_angle) * (alt:apoapsis-start_altitude) / (end_altitude-start_altitude) + start_angle.
wait until altitude > end_altitude.

print "finishing turn...".

set angle to angle.


//lock angle to (end_angle-start_angle) * (alt:apoapsis-start_altitude) / (end_altitude-start_altitude) + start_angle.
//
//set start_angle to 45.
//set end_altitude to 75000.
//set start_altitude to alt:apoapsis.
//set end_angle to 90.


print "not implemented. halt.".
wait until false.
