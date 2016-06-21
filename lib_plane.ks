@lazyglobal off.
run once lib_geo.

GLOBAL lib_plane_speed_pid IS 0.
GLOBAL lib_plane_pitch_pid IS 0.
GLOBAL lib_plane_yaw_pid IS 0.
GLOBAL lib_plane_roll_pid IS 0.
GLOBAL lib_plane_roll_control_pid IS 0.
GLOBAL lib_plane_horizon_pid IS 0.
GLOBAL lib_plane_loop_step_ref IS 0.


GLOBAL lib_plane_param_target IS 0.
GLOBAL lib_plane_param_maxroll IS 30.


function plane_set_target {
    parameter tgt is 0.
    SET lib_plane_param_target TO tgt.
}

function plane_set_maxroll {
    parameter maxroll.
    SET lib_plane_param_maxroll TO maxroll.
}



function plane_loop_step {
    return lib_plane_loop_step_ref:call().
}

function lib_plane_init_roll {
    SET lib_plane_roll_control_pid TO pidloop(
        0.01,
        0.001,
        0.005,
       -1, 1).

    if lib_plane_param_target <> 0 {
        SET lib_plane_roll_pid TO pidloop(
            lib_plane_param_maxroll / 20,
            lib_plane_param_maxroll / 20 / 5,
            0,
            -lib_plane_param_maxroll, + lib_plane_param_maxroll).
    }
}

function lib_plane_step_roll {
    if sas {
        SET ship:control:roll TO 0.
        return.
    }
    if lib_plane_param_target = 0 {
        SET lib_plane_roll_control_pid:setpoint TO 0.
    } else {
        SET lib_plane_roll_pid:setpoint TO lib_plane_param_target:heading.
        LOCAL roll_input IS geo_vessel_azimuth(ship:velocity:surface, lib_plane_roll_pid:setpoint).
        LOCAL roll_output IS lib_plane_roll_pid:update(time:seconds(), roll_input).

        SET lib_plane_roll_control_pid:setpoint TO roll_output.
    }
    LOCAL roll_control_output IS lib_plane_roll_control_pid:update(time:seconds(), geo_vessel_roll(ship:facing, lib_plane_roll_control_pid:setpoint)).
    SET ship:control:roll TO roll_control_output.
}


function plane_init_cruise {
    parameter param_speed. // keep this level
    parameter param_height. // keep this level

    SET lib_plane_speed_pid TO pidloop(0, 0, 0, 0, 1).
    SET lib_plane_pitch_pid TO pidloop(0.01, 0.001, 0.005, -1, 1).
    lib_plane_init_roll().

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

    lib_plane_step_roll().
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

    // TODO eliminate 2-side feedback between these two pids:
    SET lib_plane_horizon_pid TO pidloop(-1.5, -0.12, -5, 0, 45).
    SET lib_plane_pitch_pid TO pidloop(0.06, 0.006, 0.015, 0, 1).
    lib_plane_init_roll().

    SET lib_plane_loop_step_ref TO lib_plane_step_climb@.
    SET lib_plane_horizon_pid:setpoint TO param_speed.
}

function lib_plane_step_climb {
    LOCK throttle TO 1.
    lib_plane_step_roll().
    if sas {
        SET ship:control:pitch TO 0.
    } else {
        LOCAL speed_current IS ship:velocity:surface:mag.

        LOCAL horizon_output IS lib_plane_horizon_pid:update(time:seconds(), speed_current).
        

        LOCAL horizon_current IS geo_vessel_pitch(ship:velocity:surface).
        //print horizon_current + " -> " + horizon_output.

        SET lib_plane_pitch_pid:setpoint TO horizon_output.
        LOCAL pitch_output IS lib_plane_pitch_pid:update(time:seconds(), horizon_current).
        SET ship:control:pitch TO pitch_output.
        return horizon_output.
    }
    return 0.
}
