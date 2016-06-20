run once lib_plane.
run once lib_util.
if alt:radar < 10 {
    stage. // engines on
    run plane_takeoff(180).
    sas off.

    print "initial air acceleration to 270".
    plane_init_cruise(1000, 200).
    until ship:velocity:surface:mag > 270 {
        util_draw().
        plane_loop_step().
    }
}

print "climb to 5000".
plane_init_climb(250).
until (ship:verticalspeed > 0) and (ship:apoapsis > 5000) {
    plane_loop_step().
}

print "cruising".
plane_init_cruise(250, 5000).
until false {
    plane_loop_step().
}


//print "climb to 8000".
//plane_init_climb(200).
//until (ship:verticalspeed > 0) and (ship:apoapsis > 8000) {
//    plane_loop_step().
//}
