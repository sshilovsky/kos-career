@lazyglobal off.
run once lib_geo.

GLOBAL lib_plane_speed_pid IS 0.
GLOBAL lib_plane_aoa_pid IS 0.
GLOBAL lib_plane_pitch_pid IS 0.
GLOBAL lib_plane_horizon_pid IS 0.
GLOBAL lib_plane_loop_step_ref IS 0.



function plane_loop_step {
    return lib_plane_loop_step_ref:call().
}



function plane_init_cruise {
    parameter param_speed. // keep this level
    parameter param_height. // keep this level

    SET lib_plane_speed_pid TO pidloop(0, 0, 0, 0, 1).
    SET lib_plane_pitch_pid TO pidloop(0.01, 0.001, 0.005, -1, 1).

    SET lib_plane_loop_step_ref TO lib_plane_step_cruise@.
    SET lib_plane_speed_pid:setpoint TO param_speed.
    SET lib_plane_pitch_pid:setpoint TO param_height.
}



function lib_plane_step_cruise {
    LOCAL speed_input IS ship:velocity:surface:mag.
    SET lib_plane_speed_pid:kp TO ship:mass / ship:maxthrust.
    SET lib_plane_speed_pid:ki TO lib_plane_speed_pid:kp / 10.
    LOCAL speed_output IS lib_plane_speed_pid:update(time:seconds(), speed_input).
    lock throttle to speed_output.

    if sas {
        SET ship:control:pitch TO 0.
    } else {
        LOCAL pitch_input IS 0.
        if ship:verticalspeed < 0 {
            SET pitch_input TO ship:altitude.
        } else {
            SET pitch_input TO ship:apoapsis.
        }
        local pitch_output is lib_plane_pitch_pid:update(time:seconds(), pitch_input).
        set ship:control:pitch to pitch_output.

    }
}



function plane_init_climb {
    parameter param_speed. // maximum pitch while maintaining this speed

    //SET lib_plane_aoa_pid TO pidloop(-0.2, 0, -0.01, min_aoa, max_aoa).
    SET lib_plane_horizon_pid TO pidloop(-1.5, -0.12, -5, 0, 45).
    SET lib_plane_pitch_pid TO pidloop(0.06, 0.006, 0.015, 0, 1).

    SET lib_plane_loop_step_ref TO lib_plane_step_climb@.
    //SET lib_plane_aoa_pid:setpoint TO param_speed.
    SET lib_plane_horizon_pid:setpoint TO param_speed.
}



function lib_plane_step_climb {
    LOCK throttle TO 1.
    //if ship:verticalspeed < 0 {
    //    print "pitch 1!".
    //    SET ship:control:pitch TO 1.
    //} else 
    if sas {
        SET ship:control:pitch TO 0.
    } else {
        LOCAL speed_current IS ship:velocity:surface:mag.
        //LOCAL aoa_output IS lib_plane_aoa_pid:update(time:seconds(), speed_current).

        LOCAL horizon_output IS lib_plane_horizon_pid:update(time:seconds(), speed_current).
        print lib_plane_horizon_pid:input + " -> " + lib_plane_horizon_pid:setpoint.
        

        //SET lib_plane_pitch_pid:setpoint TO aoa_output.
        //LOCAL aoa_current IS signed_vangle(ship:facing:forevector, ship:velocity:surface, ship:facing:starvector).
        //print aoa_current + " -> " + aoa_output.
        LOCAL horizon_current IS 90 + signed_vangle(ship:facing:forevector, ship:up:forevector, ship:up:starvector).
        print horizon_current + " -> " + horizon_output.

        SET lib_plane_pitch_pid:setpoint TO horizon_output.
        SET ship:control:pitch TO lib_plane_pitch_pid:update(time:seconds(), horizon_current).
        print lib_plane_pitch_pid:output.
        return horizon_output.
    }
    return 0.
}
