@lazyglobal off.

PARAMETER sitename IS "ksc".
PARAMETER land_speed IS 90.
PARAMETER meet_distance IS 25000.
PARAMETER meet_height IS 1000.
PARAMETER meet_speed IS 150.
PARAMETER meet_radius IS 2000.
PARAMETER land_pitch IS 10.

run once lib_plane.

LOCAL landing_sites IS list(
    list("ksc", // ksc runway (lvl 2)
    LATLNG(-0.0500549371498348, -74.5036458341024),
    LATLNG(-0.0486220093664327, -74.7109400247869)),

    list("ksc-off", // grass parallel to ksc runway
    LATLNG(-0.017, -74.5016756992899),
    LATLNG(-0.017, -74.7141261624968)),

    list("none", 0, 0)).

LOCAL point_a IS 0.
LOCAL point_b IS 0.
for site in landing_sites {
    if sitename = site[0] {
        SET point_a TO site[1].
        SET point_b TO site[2].
        break.
    }
}

if point_a = 0 {
    print "Langing site '" + sitename + "' is unknown".
} else {
    print "Landing at " + sitename.

    LOCK runway_vector TO point_b:position - point_a:position.
    LOCAL runway_draw IS vecdraw(v(0,0,0), runway_vector:normalized,
            white, "", 15, true, 0.01).

    LOCK meet_position TO point_a:position - meet_distance * runway_vector:normalized.
    LOCAL meet_geo IS ship:body:geopositionof(meet_position).

    plane_set_target(meet_geo).
    print "- cruising to meet position: " + meet_geo.
    plane_init_cruise(). // use previous settings
    until meet_geo:altitudeposition(altitude):mag < meet_radius {
        plane_loop_step().
    }

    print "- lowering".
    plane_init_lower(meet_speed, meet_height, -30).
    until altitude < meet_height + 150 {
        plane_loop_step().
    }

    print "- dropping speed".
    plane_init_cruise(meet_speed, meet_height).
    until abs(ship:velocity:surface:mag - meet_speed) < 20 {
        plane_loop_step().
    }

    print "- turning to the runway".
    plane_set_target(point_a).
    LOCAL runway_azimuth IS geo_vessel_azimuth(runway_vector).
    until abs(
            geo_vessel_azimuth(ship:velocity:surface, runway_azimuth)
            - runway_azimuth) < 60 {
        plane_loop_step().
    }

    print "- aligning to the runway".
    gear on.
    brakes off.
    plane_set_align(runway_vector).
    plane_set_target(point_b).
    lib_plane_init_roll().
    local workaround_flag is true.
    until false {
        if workaround_flag { // workaround
            LOCAL aligner IS vcrs(lib_plane_param_align,
                    ship:up:forevector):normalized.
            LOCAL dist_x IS vdot(aligner,
                    lib_plane_param_target:position).
            LOCAL v_x IS vdot(aligner,
                    ship:velocity:surface).
            if abs(dist_x) < 1 and abs(v_x) < 0.1 {
                print "houray!".
                plane_set_align(0).
                lib_plane_init_roll().
                set workaround_flag to false.
            }
        }

        SET runway_draw:vec to runway_vector:normalized.
        LOCAL distance IS vdot(point_a:position,
                runway_vector:normalized).
        if alt:radar < 5 {
            break.
        }
        if distance < 0 {
            break.
        }
        LOCAL height_setpoint IS min(meet_height,
                distance / meet_distance * meet_height +
                (1 - distance / meet_distance) * point_a:terrainheight+5).
        LOCAL speed_setpoint IS min(meet_speed,
                distance / meet_distance * meet_speed + 
                (1 - distance / meet_distance) * land_speed).
        plane_set_speed(speed_setpoint).
        plane_set_height(height_setpoint).
        //print speed_setpoint  + "m/s; " + height_setpoint + "m".
        plane_loop_step().
    }

    
    print "- braking".
    lock throttle to 0.
    set ship:control:pilotmainthrottle to 0.
    plane_set_target(0).
    plane_set_align(0).
    sas on.

    //LOCAL runway_azimuth IS geo_vessel_azimuth(ship:velocity:surface).
    //set ship:control:pitch to 0.
    //set ship:control:roll to 0.
    //LOCK steering TO lookdirup(
    //        heading(runway_azimuth, land_pitch):forevector,
    //        ship:up:forevector).

    until ship:velocity:surface:mag < 70 {
        wait 0.1.
    }

    //unlock steering.
    sas on.
    brakes on.
    until ship:velocity:surface:mag < 0.01 {
        wait 0.1.
    }
}
print "done.".
