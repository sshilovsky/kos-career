@lazyglobal off.
// Functions to (re)schedule multiple actions on time
//
// Scheduling functions accept time parameter, delagate and a list of arguments

run once lib_list.

LOCAL lib_timer_timepoint IS -1.

// lib_timer_queue is a list of records.
//
// Each record is a list of values: (timestamp, delegate, args).
LOCAL lib_timer_queue IS list().

WHEN (lib_timer_timepoint <> -1) and
    (time:seconds >= lib_timer_timepoint)
THEN {
    LOCAL rec IS lib_timer_queue[0].
    lib_timer_queue:remove(0).
    LOCAL ref IS rec[1].
    LOCAL args IS rec[2].
    LOCAL repeat IS rec[3].
    LOCAL res IS list_call(ref, args).
    IF repeat <> 0 {
        if repeat > 0 {
            SET repeat TO repeat - 1.
        }
        timer_schedule_at(res, ref, args, repeat).
    } ELSE IF res {
        timer_schedule_at(res, ref, args).
    } ELSE {
        
        IF lib_timer_queue:length = 0 {
            SET lib_timer_timepoint TO -1.
        } ELSE {
            SET lib_timer_timepoint TO lib_timer_queue[0][0].
        }
    }
    preserve.
    // TODO do not preserve when no events
}

FUNCTION timer_schedule_at {
    PARAMETER time_at.
    PARAMETER ref.
    PARAMETER args IS list().
    PARAMETER repeat IS 0. // rehandle

    LOCAL n IS lib_timer_queue:length.
    LOCAL i IS 0.
    UNTIL (i >= n) {
        LOCAL ts IS lib_timer_queue[i][0].
        IF ts >= time_at {
            BREAK.
        }
        SET i TO i + 1.
    }

    lib_timer_queue:insert(i, list_def(4, time_at, ref, args, repeat)).
    SET lib_timer_timepoint TO lib_timer_queue[0][0].
}

