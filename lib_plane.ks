@lazyglobal off.
run once lib_geo.

GLOBAL lib_plane_speed_pid IS 0.
GLOBAL lib_plane_pitch_pid IS 0.
GLOBAL lib_plane_yaw_pid IS 0.
GLOBAL lib_plane_roll_pid IS 0.
GLOBAL lib_plane_roll_control_pid IS 0.
GLOBAL lib_plane_horizon_pid IS 0.
GLOBAL lib_plane_azimuth_pid IS 0.

GLOBAL lib_plane_loop_step_ref IS 0.

GLOBAL lib_plane_param_target IS 0. // target vector for roll pid
GLOBAL lib_plane_param_align IS 0. // align vector for roll pid
GLOBAL lib_plane_param_maxroll IS 30. // +- to both sides
GLOBAL lib_plane_param_speed IS 0.
GLOBAL lib_plane_param_height IS 10000.
GLOBAL lib_plane_param_minpitch IS -30.


function plane_set_target {
    parameter tgt is 0.
    SET lib_plane_param_target TO tgt.
}

function plane_set_align {
    parameter align is 0.
    SET lib_plane_param_align TO align.
}

function plane_set_maxroll {
    parameter maxroll.
    SET lib_plane_param_maxroll TO maxroll.
}

function plane_set_speed {
    parameter speed.
    SET lib_plane_param_speed TO speed.
}

function plane_set_height {
    parameter height.
    SET lib_plane_param_height TO height.
}

function plane_set_minpitch {
    parameter minpitch.
    SET lib_plane_param_minpitch TO minpitch.
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
        if lib_plane_param_align <> 0 {
            LOCAL align_azimuth IS geo_vessel_azimuth(lib_plane_param_align).
            SET lib_plane_azimuth_pid TO pidloop(
                10/100,
                10/100 / 16,
                10/100 * 8,
                align_azimuth-90, align_azimuth+90
                ).

            SET lib_plane_roll_pid TO pidloop(
                lib_plane_param_maxroll / 20,
                lib_plane_param_maxroll / 20 / 16,
                lib_plane_param_maxroll / 20 * 8,
                -lib_plane_param_maxroll, lib_plane_param_maxroll).
            SET lib_plane_roll_pid:setpoint TO align_azimuth.
        } else {
            SET lib_plane_roll_pid TO pidloop(
                lib_plane_param_maxroll / 20,
                lib_plane_param_maxroll / 20 / 5,
                0,
                -lib_plane_param_maxroll, lib_plane_param_maxroll).
        }
    }
    // TODO case when target = 0 but align <> 0
}

function lib_plane_step_roll {
    //if sas {
    //    SET ship:control:roll TO 0.
    //    return.
    //}
    if lib_plane_param_target = 0 {
        SET lib_plane_roll_control_pid:setpoint TO 0.
    } else {
        LOCAL roll_input IS 0.
        if lib_plane_param_align = 0 {
            SET lib_plane_roll_pid:setpoint TO lib_plane_param_target:heading.
        } else {
            LOCAL aligner IS vcrs(lib_plane_param_align,
                    ship:up:forevector):normalized.
            LOCAL dist_x IS vdot(aligner,
                    lib_plane_param_target:position).
            LOCAL azimuth_output IS lib_plane_azimuth_pid:update(
                    time:seconds(), dist_x).
            print dist_x + " ; " + azimuth_output.
            
            SET lib_plane_roll_pid:setpoint TO azimuth_output.
        }
        SET roll_input TO geo_vessel_azimuth(ship:velocity:surface, lib_plane_roll_pid:setpoint).
        LOCAL roll_output IS lib_plane_roll_pid:update(time:seconds(), roll_input).

        if sas {
            SET ship:control:roll TO 0.
            return.
        }
        SET lib_plane_roll_control_pid:setpoint TO roll_output.
    }
    LOCAL roll_control_output IS lib_plane_roll_control_pid:update(time:seconds(), geo_vessel_roll(ship:facing, lib_plane_roll_control_pid:setpoint)).
    SET ship:control:roll TO roll_control_output.
}


function plane_init_cruise {
    parameter param_speed IS lib_plane_param_speed. // keep this level
    parameter param_height IS lib_plane_param_height. // keep this level
    SET lib_plane_param_speed TO param_speed.
    SET lib_plane_param_height TO param_height.


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
    parameter param_speed IS lib_plane_param_speed. // keep this level
    SET lib_plane_param_speed TO param_speed.

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



function plane_init_lower {
    parameter param_speed is lib_plane_param_speed. // minimum speed allowed. needed due to extreme rolling
    parameter param_height is lib_plane_param_height.
    parameter param_minpitch is lib_plane_param_minpitch.
    SET lib_plane_param_speed TO param_speed.
    SET lib_plane_param_height TO param_height.
    SET lib_plane_param_minpitch TO param_minpitch.

    SET lib_plane_speed_pid TO pidloop(0, 0, 0, 0, 1).
    SET lib_plane_speed_pid:setpoint TO param_speed.

    lib_plane_init_roll().

    SET lib_plane_horizon_pid TO pidloop(
        1/100,
        0.1/100,
        -3 * (lib_plane_param_minpitch / 30)/100,
        lib_plane_param_minpitch, 10).
    SET lib_plane_horizon_pid:setpoint TO lib_plane_param_height.

    SET lib_plane_pitch_pid TO pidloop(
        0.06, 0.006, 0.015, -1, 1).

    SET lib_plane_loop_step_ref TO lib_plane_step_lower@.
}

function lib_plane_step_lower {
    LOCAL speed_input IS ship:velocity:surface:mag.
    SET lib_plane_speed_pid:kp TO ship:mass / ship:maxthrust.
    SET lib_plane_speed_pid:ki TO lib_plane_speed_pid:kp / 10.
    LOCK throttle TO lib_plane_speed_pid:update(time:seconds(), speed_input).

    lib_plane_step_roll().
    if sas {
        SET ship:control:pitch TO 0.
    } else {
        LOCAL horizon_output IS lib_plane_horizon_pid:update(time:seconds(), altitude).

        LOCAL horizon_current IS geo_vessel_pitch(ship:velocity:surface).
        //print "(" + altitude + "): " + horizon_current + " -> " + horizon_output.

        SET lib_plane_pitch_pid:setpoint TO horizon_output.
        LOCAL pitch_output IS lib_plane_pitch_pid:update(time:seconds(), horizon_current).
        SET ship:control:pitch TO pitch_output.
        return horizon_output.
    }
    return 0.
}
