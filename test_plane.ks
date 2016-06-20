@lazyglobal off.
switch to 0.
clearvecdraws().
run once lib_plane.
run once lib_util.
global min_aoa is -10.
global max_aoa is 10.

//if ship:verticalspeed < 0 {
//    set ship:control:pitch to 1.
//    wait until ship:verticalspeed > 0.
//}
//plane_init_cruise(200, ship:apoapsis).
//until abs(ship:velocity:surface:mag - 200) < 5 {
//    plane_loop_step().
//}

plane_init_climb(250).
GLOBAL drawvec IS vecdraw(v(0,0,0), v(0,0,0), white, "HORIZON TGT", 15, true, 0.01).
until false {
    util_draw().
    local hor_target is plane_loop_step().

    LOCAL en IS vcrs(up:forevector, ship:facing:forevector).
    LOCAL tau IS vcrs(en, up:forevector).
    LOCAL target IS sin(hor_target) * up:forevector:normalized + cos(hor_target) * tau:normalized.
    SET drawvec:vec TO target.
    //SET drawvec:vec TO target:normalized.
}
