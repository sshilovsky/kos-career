copy lib_autostage from archive.
run once lib_autostage.

// autostaging.
autostage_interactive_launch().

// 1a. Ascending: 10deg at 1km alt
set start_altitude to altitude.
set end_altitude to 1000.
set start_angle to 0.
set end_angle to 10.

lock angle to (end_angle-start_angle) * (altitude-start_altitude) / (end_altitude-start_altitude) + start_angle.

lock steering to up + R(0, -angle, 180).

lock throttle to 1.

wait until altitude >= end_altitude.

// 1b. Ascending: 45deg at 10km alt
set start_angle to 10.
set end_altitude to 10000.
set start_altitude to 1000.
set end_angle to 45.

wait until altitude >= end_altitude.

// 1c. Ascending: 90deg at 75km apo
lock angle to (end_angle-start_angle) * (alt:apoapsis-start_altitude) / (end_altitude-start_altitude) + start_angle.

set start_angle to 45.
set end_altitude to 75000.
set start_altitude to alt:apoapsis.
set end_angle to 90.

wait until alt:apoapsis >= end_altitude.

// 1d. Ascending: wait for out of atmosphere
lock throttle to 0.

wait until altitude >= 70000.

// 2a. Circularization: calculations

set apoapsis_height to alt:apoapsis + ship:body:radius.
// use vis-viva equation to calculate velocities
set expected_velocity to sqrt(constant:G * ship:body:mass * (2 / apoapsis_height - 1 / obt:semimajoraxis)).
set target_velocity to sqrt(constant:G * ship:body:mass / apoapsis_height).
set delta_v to target_velocity - expected_velocity.

// 2b. Circularization: visualize maneuver

set node to node(eta:apoapsis + time:seconds, 0, 0, delta_v).
if career():canmakenodes {
    add node.
}.

// 2c. Circularization: estimate burn time.

lock max_acc to ship:maxthrust / ship:mass.
set burn_duration to delta_v / max_acc.
print "estimated burn duration: " + burn_duration.

// set node_prograde to node:deltav. // save node vector from changing while burning.

lock steering to node:deltav.
wait node:eta - burn_duration/2.
lock throttle to 1.
wait until node:deltav:mag < max_acc * 1. // 1sec
lock throttle to 0.2.
wait until node:deltav:mag < max_acc * 0.1. // 0.1sec
lock throttle to 0.05.
wait until node:deltav:mag < max_acc * 0.01. // 0.01sec

//lock steering to up + R(0, 90, 180).

if career():canmakenodes {
    remove node.
}.

unlock steering.
unlock throttle.
set ship:control:pilotmainthrottle to 0.

print "done".
