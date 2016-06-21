run once lib_plane.
run once lib_util.

if alt:radar < 5 {
    stage. // engines on
    run plane_takeoff(180).
    sas off.

    print "initial air acceleration to 150".
    plane_init_cruise(1000, 300).
    until ship:velocity:surface:mag > 150 {
        plane_loop_step().
    }
}

if allwaypoints():length > 0 {
    local tgt is allwaypoints()[0].
    print "targeting: " + tgt:name.
    plane_set_target(tgt:geoposition).
}
plane_set_maxroll(60).

if ship:apoapsis < 1000 {
    print "initial air acceleration to 250".
    plane_init_cruise(1000, 1000).
    until ship:velocity:surface:mag > 250 {
        plane_loop_step().
    }
}

GLOBAL drawvec IS vecdraw(v(0,0,0), v(0,0,0), white, "HORIZON TGT", 15, true, 0.01).
if ship:apoapsis < 8000 {
    print "climb to 8000".
    plane_init_climb(250).
    until (ship:verticalspeed > 0) and (ship:apoapsis > 8000) {
        util_draw().
        local hor_target is plane_loop_step().

        LOCAL en IS vcrs(up:forevector, ship:facing:forevector).
        LOCAL tau IS vcrs(en, up:forevector).
        LOCAL target IS sin(hor_target) * up:forevector:normalized + cos(hor_target) * tau:normalized.
        SET drawvec:vec TO target.
    }
}

print "cruising".
plane_init_cruise(250, 8000).
until false {
    plane_loop_step().
}
