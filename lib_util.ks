@lazyglobal off.
run once lib_list.

FUNCTION util_get_vessel_modules {
    PARAMETER vessel.
    PARAMETER modulename.

    LOCAL res IS list().
    for part in vessel:parts {
        if part:modules:contains(modulename) {
            res:add(part:getmodule(modulename)).
        }
    }
    return res.
}

GLOBAL lib_util_draw_drawn IS list_def(6, 
    vecdraw(v(0,0,0), up:forevector, red, "UP:FORE", 15, 0, 0.01),
    vecdraw(v(0,0,0), up:topvector, red, "UP:TOP", 15, 0, 0.01),
    vecdraw(v(0,0,0), up:starvector, red, "UP:STAR", 15, 0, 0.01),

    vecdraw(v(0,0,0), ship:facing:forevector, green, "SHIP:FORE", 15, 0, 0.01),
    vecdraw(v(0,0,0), ship:facing:topvector, green, "SHIP:TOP", 15, 0, 0.01),
    vecdraw(v(0,0,0), ship:facing:starvector, green, "SHIP:STAR", 15, 0, 0.01),

    vecdraw(v(0,0,0), v(0,0,0), black, "", 0, 0, 0) //
).

FUNCTION util_draw {
    SET lib_util_draw_drawn[0]:vec TO up:forevector.
    SET lib_util_draw_drawn[1]:vec TO up:topvector.
    SET lib_util_draw_drawn[2]:vec TO up:starvector.
    SET lib_util_draw_drawn[3]:vec TO ship:facing:forevector.
    SET lib_util_draw_drawn[4]:vec TO ship:facing:topvector.
    SET lib_util_draw_drawn[5]:vec TO ship:facing:starvector.

    for vd in lib_util_draw_drawn {
        SET vd:show TO true.
    }
}

FUNCTION util_draw_off {
    for vd in lib_util_draw_drawn {
        SET vd:show TO false.
    }
}
