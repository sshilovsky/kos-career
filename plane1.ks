run once lib_plane.
run once lib_util.
run once lib_science.


// FLY OVER ALL WAYPOINTS
function nearest_waypoint {
    LOCAL waypoints IS allwaypoints().
    LOCAL best IS 0.
    LOCAL best_distance IS (body:radius + body:atm:height) * 2.
    FOR w IN waypoints {
        if w:body=body and not w:grounded and w:nearsurface {
            // considering waypoint.
            LOCAL distance IS w:position:mag.
            if distance < best_distance {
                SET best_distance TO distance.
                SET best TO w.
            }
        }
    }
    return best.
}

GLOBAL target_waypoints IS 0.

GLOBAL tgt IS 0.
ON (target_waypoints * allwaypoints():length) {
    IF target_waypoints {
        LOCAL candidate IS nearest_waypoint().
        IF candidate <> tgt {
            SET tgt TO candidate.
            if tgt <> 0 {
                print "targeting: " + tgt:name.
                plane_set_target(tgt:geoposition).
            } else {
                print "targeting KSC".
                plane_set_target(
                        LATLNG(-0.0500549371498348, -74.5036458341024)).
            }
        }
    } ELSE {
        plane_set_target(0).
    }
    PRESERVE.
}

// COLLECT ALL SCIENCE DATA
GLOBAL science_timestamp IS 0.
WHEN time:seconds > science_timestamp THEN {
    science_run_tests().
    science_collect_rerunnable().
    science_transmit_rerunnable().
    SET science_timestamp TO time:seconds + 5.

    PRESERVE.
}

plane_set_maxroll(60).
if ship:status <> "FLYING" {
    //stage. // engines on
    run plane_takeoff(180).
    sas off.
}

if ship:altitude < 1000 and ship:velocity:surface:mag < 150 {
    print "initial air acceleration to 150".
    plane_init_cruise(1000, max(300, max(ship:apoapsis, altitude))).
    until ship:velocity:surface:mag > 150 {
        plane_loop_step().
    }
}

SET target_waypoints TO 1.
wait 0.

if ship:velocity:surface:mag < 250 {
    print "initial air acceleration to 250".
    plane_init_cruise(1000, max(1000, max(ship:apoapsis, altitude))).
    until ship:velocity:surface:mag > 250 {
        plane_loop_step().
    }
}

if ship:apoapsis < 7000 {
    print "climb to 8000".
    plane_init_climb(250).
    until (ship:verticalspeed > 0) and (ship:apoapsis > 8000) {
        plane_loop_step().
    }
}

print "cruising".
plane_init_cruise(250, 8000).
until allwaypoints():length = 0 { // add low on fuel condition
    plane_loop_step().
}

SET target_waypoints TO 0.

run plane_landing("ksc-off").
