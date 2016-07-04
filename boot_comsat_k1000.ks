@lazyglobal off.
// TODO split by 5kb files
// equatorial kerbin comsat network
parameter target_orbit is 1000000. // accounted for kerbin radius
parameter angle_period is 90.
parameter max_angle_error is 5.  // when this is exceeded, increase/decrease
            // period sligtly to synchronize angles slowly

parameter low_orbit is 80000.

set ship:control:pilotmainthrottle to 0.
clearvecdraws().
print "wait until career():canmakenodes.".
wait until career():canmakenodes.
until not hasnode {
    wait 0.1.
    if hasnode {
        local nd is nextnode.
        remove nd.
    }
}
sas off.

function pe_vector {
    parameter vessel.

    local norm is vcrs(vessel:position-vessel:body:position,
            vessel:velocity:orbit):normalized.
    local res is angleaxis(-vessel:orbit:trueanomaly, norm)
            * (vessel:position - vessel:body:position).

    return res.
}

function mean_anomaly {
    parameter orbit.

    // https://en.wikipedia.org/w/index.php?title=Eccentric_anomaly&oldid=721113565
    local theta is orbit:trueanomaly.
    local tanE2 is sqrt((1-orbit:eccentricity)/(1+orbit:eccentricity))
            * tan(theta/2).
    local EE is 2 * arctan(tanE2). // eccentric anomaly
    return EE - orbit:eccentricity * sin(EE).
}

function get_root_angle {
    local norm is vcrs(ship:velocity:orbit, body:position).
    //local beta0 is -signed_vangle(ship:position - body:position,
    //        comsat_root:position - body:position,
    //        norm). // orient
    local pe_self is pe_vector(ship).
    local pe_root is pe_vector(comsat_root).
    local pe_angle is signed_vangle(pe_root, pe_self, norm).
    print "pe_angle: " + pe_angle.

    local beta0 is pe_angle + mean_anomaly(ship:orbit) - mean_anomaly(comsat_root:orbit).

    until beta0 >= 0 {
        set beta0 to beta0 + 360.
    }
    until beta0 < 360 {
        set beta0 to beta0 - 360.
    }
    print "root_angle: " + beta0.
    return beta0.
}

function get_root_angle_error {
    local beta0 is get_root_angle().
    local err is beta0 - comsat_index * angle_period.
    until err > -180 {
        set err to err + 360.
    }
    until err <= 180 {
        set err to err - 360.
    }
    print "root_angle_error: " + err.
    return err.
}
function wait_rt_connection {
    if not addons:rt:available {
        return.
    }
    local first is true.
    until addons:rt:hasconnection(ship) {
        hudtext(ship:name + ": waiting for RT connection",
            1, //delayseconds - blinking message
            2, // upper center
            40, // size modifier
            rgb(1, 0.5, 0), // orange
            first).
        wait 1.5.
        set first to false.
    }
}

function wait_comsat_root_ready {
    local first is true.
    until comsat_root:orbit:periapsis > target_orbit * 0.9 {
        hudtext(ship:name + ": waiting for " + comsat_root:name
                + " to be set up",
            1, //delayseconds - blinking message
            2, // upper center
            40, // size modifier
            rgb(1, 0.5, 0), // orange
            first).
        wait 1.5.
        set first to false.
    }
}

function signed_vangle {
    parameter v1.
    parameter v2.
    parameter orient.

    local angle is vang(v1, v2).
    local cross is vcrs(v1, v2).
    local prod is vdot(orient, cross).
    if (prod < 0) {
        SET angle TO -angle.
    }
    return angle.
}

function calculate_burn_time {
    parameter deltav.

    // calculating average isp: http://forum.kerbalspaceprogram.com/index.php?/topic/61827-11-kos-scriptable-autopilot-system-v0201-2016515/&page=59#comment-1405498
    local back_isp is 0.
    local MyEngines is list().
    LIST ENGINES in MyEngines.
    for engine in MyEngines {
        if engine:ISP > 0 { // inactive engines have 0 here
            set back_isp to back_isp
                    + (engine:availablethrustat(0) / engine:ISP).
        }
    }
    local isp_avg is SHIP:availablethrustat(0) / back_isp.

    // calculating burn time: https://www.reddit.com/r/Kos/comments/3ftcwk/compute_burn_time_with_calculus/?st=iq4cy000&sh=a90bb600
    // LOCAL f IS en[0]:MAXTHRUST * 1000.  // Engine Thrust (kg * m/s²)
    // LOCAL m IS SHIP:MASS * 1000.        // Starting mass (kg)
    // LOCAL e IS CONSTANT():E.            // Base of natural log
    // LOCAL p IS en[0]:ISP.               // Engine ISP (s)
    LOCAL g IS 9.80665. // used to convert ISP to non-g-dependant unit
    // RETURN g * m * p * (1 - e^(-dV/(g*p))) / f.:

    return g * ship:mass * isp_avg / ship:availablethrustat(0)
            * (1 - constant:e ^ (-deltav / (g * isp_avg))).
}

function lock_steering {
    // can steer to vector or direction
    // if vector is given, tries to ignore roll factor
    parameter tgt.
    parameter time_limit is -1.

    local tgt_v is tgt.
    if tgt:typename = "Direction" {
        set tgt_v to tgt:forevector.
    }
    else if tgt:typename = "Vector" {
        // ok
    } else {
        error["only Direction or Vector are accepted"].
    }

    lock steering to tgt.
    wait until (vectorangle(ship:facing:forevector, tgt_v) < 1
            and vectorexclude(tgt_v, ship:angularvel):mag < 0.01)
            or (time_limit >= 0 and time:seconds >= time_limit).

    if tgt:typename = "Vector" {
        set tgt to lookdirup(tgt_v, ship:facing:topvector).
        lock steering to tgt.
    }

    wait until (vectorangle(ship:facing:forevector, tgt_v) < 1
            and vectorangle(ship:facing:topvector, tgt:topvector) < 1
            and ship:angularvel:mag < 0.01)
            or (time_limit >= 0 and time:seconds >= time_limit).
}

function align_solar {
    parameter time_limit is -1.

    // assert solar panel is on the eastern side of the ship
    local solar_dir is vcrs(body:prograde:forevector,
            sun:position - body:position):normalized.
    local solar_dir_top is vcrs(solar_dir,
            sun:position - body:position):normalized.
    local dir is lookdirup(solar_dir, solar_dir_top).

    lock_steering(dir, time_limit).

    lock steering to lookdirup( // relock to functional expression
        vcrs(body:prograde:forevector, sun:position-body:position):normalized,
        vcrs(vcrs(body:prograde:forevector, sun:position-body:position),
                 sun:position-body:position):normalized).
}

function notify {
    parameter message.
    parameter size is 1.0.

    set message to ship:name + ": " + message.

    hudtext(message,
        15, //delayseconds
        2, // upper center
        25 * size, // size modifier
        white,
        true).
}

function rename_self {
    parameter index is 0.

    local desired_name is ship:name.
    if index > 0 {
        set desired_name to desired_name + "-" + index.
    }

    // check if there is a vessel named like this
    local targets is list().
    list targets in targets.
    for t in targets {
        if t:name = desired_name {
            rename_self(index + 1).
            return.
        }
    }

    if index > 0 {
        notify("renaming to " + desired_name).
        set ship:name to desired_name.
    }
}

function parse_index {
    parameter name is ship:name.

    local dash is name:findlast("-").
    local index_str is name:substring(dash+1, name:length-dash-1).
    if index_str:length = 0 {
        return 0.
    }
    local index is 0.
    local i is 0.
    for i in range(0, index_str:length) {
        local ch is index_str[i].
        if ("0" <= ch) and (ch <= "9") {
            local unch is 0.
            if ch="1" { set unch to 1. }
            if ch="2" { set unch to 2. }
            if ch="3" { set unch to 3. }
            if ch="4" { set unch to 4. }
            if ch="5" { set unch to 5. }
            if ch="6" { set unch to 6. }
            if ch="7" { set unch to 7. }
            if ch="8" { set unch to 8. }
            if ch="9" { set unch to 9. }
            set index to index * 10 + unch.
        } else {
            return 0.
        }
    }
    return index.
}

function parse_root {
    parameter name is ship:name.
    // asserting index > 0

    local dash is name:findlast("-").
    return name:substring(0, dash).
}

wait_rt_connection().
if ship:status="PRELAUNCH" {
    rename_self().
}

local comsat_index is parse_index().
local comsat_root is 0.
if comsat_index > 0 {
    set comsat_root to vessel(parse_root()).
}

function antennas_event {
    parameter evt.

    for m in ship:modulesnamed("ModuleRTAntenna") {
        if m:hasevent(evt) {
            m:doevent(evt).
        }
    }
}

if ship:status="PRELAUNCH" or ship:status="LANDED" {
    // launch
    antennas_event("activate").
    wait_rt_connection().
    switch to 0.
    when ship:verticalspeed > 5 then {
        antennas_event("deactivate").
    }
    run booster_t1(low_orbit, 90, 7.0).

    notify("apoapsis so far: " + ship:apoapsis).
    notify("stage fuel left: " + stage:liquidfuel).
    wait 0.1. wait until stage:ready. stage. // separate booster
    antennas_event("activate").
}

if apoapsis < low_orbit {
    notify("suborbital transition").
    lock_steering(ship:velocity:orbit).
    lock steering to ship:velocity:orbit.
    lock throttle to 1.
    wait until ship:apoapsis > low_orbit
            or ship:periapsis > body:atm:height.
    lock throttle to 0.
    unlock steering.
}

function ap_circularize {
    parameter message.
    parameter periapsis_target.

    notify(message + ": wait").

    local obt is ship:orbit.
    // calculating speed in apoapsis (energy values are divided by
    // current mass)
    local ek    is (ship:velocity:orbit:mag ^ 2) / 2.
    local eh    is -body:mu / (body:radius + altitude).
    local eh_ap is -body:mu / (body:radius + obt:apoapsis).
    local ek_ap is ek + eh - eh_ap.
    local v_ap  is sqrt(ek_ap * 2).

    // calculating desired speed for circular orbit
    local g_ap  is body:mu / (body:radius + obt:apoapsis). // g-force at
            // apoapsis height. normalized: /ship:mass, *R
    // g_ap should be equal to centrifugal force f_c = mv^2/r
    local v_desired is sqrt(g_ap).

    local nd is node(time:seconds + eta:apoapsis, 0, 0, v_desired - v_ap).
    add nd. // TODO calculate deltav direction manually
    local deltav is nd:deltav.

    local burn_time is calculate_burn_time(deltav:mag).
    local wait_till is time:seconds + nd:eta - burn_time/2
            - 10. // 10 seconds margin before start of the burn
    align_solar(wait_till).
    wait until time:seconds > wait_till.

    notify(message).
    lock steering to deltav.
    wait until nd:eta < burn_time / 2.
    lock throttle to 1.
    wait until ship:periapsis > periapsis_target.
    lock throttle to 0.
    remove nd.
} // ap_circularize

if ship:periapsis < body:atm:height {
    ap_circularize("LO circularization", body:atm:height).
}

align_solar(0).
if ship:ElectricCharge < 50 {
    local first is true.
    until ship:ElectricCharge > 50 {
        hudtext(ship:name + ": charging",
            1, //delayseconds - blinking message
            2, // upper center
            40, // size modifier
            rgb(1, 0.5, 0), // orange
            first).
        wait 1.5.
        set first to false.
    }
    wait until ship:ElectricCharge > 50.
}

if comsat_index = 0 {
    if ship:apoapsis < target_orbit * 0.9 {
        notify("target transition").
        lock_steering(prograde:forevector).
        lock steering to prograde:forevector. // changeable
        lock throttle to 1.
        wait until ship:apoapsis > target_orbit.
        lock throttle to 0.
    }

    if ship:periapsis < target_orbit * 0.9 {
        ap_circularize("target circularization", target_orbit * 0.95).
    }
} else { // comsat_index > 0
    wait_comsat_root_ready().

    if ship:apoapsis < target_orbit * 0.95 {
        notify("target transition: wait").

        align_solar(0). // lock steering, but don't wait for it

        // determine angle between self and root comsat to start from
        local root_period is comsat_root:orbit:period.

        local lo_avg is body:radius + (ship:apoapsis + ship:periapsis) / 2.
        local transition_ap is target_orbit.
        local transition_a is (lo_avg + body:radius + transition_ap) / 2.
        local transition_period is sqrt(transition_a^3 * 4 * constant:pi^2
                / body:mu).
        local transition_time is transition_period / 2.

        // also need to account for the burn time. don't really need though,
        // but lets just do it
        local v_0 is sqrt(body:mu / lo_avg). // vis-viva
        local v_1 is sqrt(body:mu * (2/lo_avg - 1/transition_a)). // vis-viva
        local transition_dv is v_1 - v_0.
        local burn_time is calculate_burn_time(transition_dv).

        local alpha is comsat_index * angle_period. // target angle between
                // root comsat and this comsat
        local gamma is 360 * (transition_time + burn_time/2) / root_period.
                // angle which root comsat gonna pass during transition of this
                // comsat
        local beta is gamma + alpha - 180. // angle between this comsat and
                // root comsat to start transition at

        local omega_delta is 360*(1/ship:orbit:period - 1/root_period).
                // angular speed of this comsat relative to root comsat

        local beta0 is get_root_angle().

        local delta_angle is beta - beta0.
        until delta_angle >= 0 {
            set delta_angle to delta_angle + 360.
        }
        local time_before_burn is delta_angle/omega_delta.
        local nd is node(time:seconds + time_before_burn + burn_time/2,
                0, 0, transition_dv).
        add nd.

        local wait_till is time:seconds + nd:eta - burn_time/2
                - 10. // 10 seconds margin before start of the burn
        align_solar(wait_till).
        wait until time:seconds > wait_till.
        notify("target transition").
        local deltav is nd:deltav.
        lock steering to deltav.
        wait until nd:eta < burn_time/2.

        lock throttle to 1.
        wait until ship:apoapsis > target_orbit.
        lock throttle to 0.
        remove nd.
    }

    if ship:periapsis < target_orbit * 0.8 {
        ap_circularize("target circularization", target_orbit * 0.8).
    }
    local target_period is comsat_root:orbit:period.
    local period_acceptable_error is 0.001.
    {
        // if angle is far from 90deg, increase/decrease the period so that
        // angles would eventually synchronize. add alarm on that moment.  Use
        // max_angle_error
        local root_angle_error is get_root_angle_error().
        if abs(root_angle_error) > max_angle_error {
            set period_acceptable_error to 1.
            if root_angle_error > 0 {
                set target_period to target_period + 10.
            } else {
                set target_period to target_period - 10.
            }
        }
    }

    if abs(ship:orbit:period - target_period) > period_acceptable_error {
        notify("orbital period synchronizing").
        //print ship:orbit:period + " vs. " + target_period.
        local const is 1. // 1 if the period is too low, -1 if too big
        if ship:orbit:period > target_period {
            set const to -1.
        }
        lock_steering(const * prograde:forevector).
        lock steering to const * prograde:forevector.
        local time0 is time:seconds.
        local period0 is ship:orbit:period.
        lock throttle to 0.000000001.
        until const * (target_period - period0) < period_acceptable_error/100 {
            //print target_period - period0 + " : " + throttle.
            wait 0.
            local newtime is time:seconds.
            local period is ship:orbit:period.
            if newtime > time0 {
                local deltat is newtime - time0.
                local delta_period is const * (period - period0).
                if delta_period > 0 {
                    local error is const * (target_period - period).

                    local newthrottle is throttle.
                    if error / delta_period > 10 {
                        set newthrottle to min(1, throttle * 1.1).
                    } else {
                        set newthrottle to 0.000000001.
                    }
                    lock throttle to newthrottle.
                    set time0 to newtime.
                }
            }
            set period0 to period.
        }
        lock throttle to 0.
        //print "#"+(target_period - period0).
        //print "#"+(target_period - ship:orbit:period).
    }
}

notify("solar aligning").
align_solar().

notify("finished").

if comsat_index > 0 {
    notify("orbital periods: " + ship:orbit:period + " vs. "
            + comsat_root:orbit:period).
    local error is get_root_angle_error().
    notify("root angle error: " + error).
    local period_delta is -360 * (1/ship:orbit:period - 1/comsat_root:orbit:period).
    print period_delta.
    local alarm is 0.
    local neta is 0.
    if abs(error) > max_angle_error {
        print "more".
        set neta to error / (period_delta).
        set alarm to addalarm("Raw", time:seconds + neta, "Sync " + ship:name, ship:name
                + " synced root comsat angle. Adjust orbital period").
    } else {
        print "less".
        if period_delta > 0 {
            set neta to (error + max_angle_error) / period_delta.
        } else {
            set neta to (error - max_angle_error) / period_delta.
        }
        set alarm to addalarm("Raw", time:seconds + neta, "Desync " + ship:name, ship:name
                + " desynced root comsat angle. Adjust orbital period").
    }
    notify("resync in " + neta + "s").
    if alarm="" {
        hudtext(ship:name + ": error creating (de)sync alarm",
            30, //delayseconds - blinking message
            2, // upper center
            30, // size modifier
            rgb(1, 0.5, 0), // orange
            true).
        add node(time:seconds + neta, 0, 0, 0).
    } else {
        set alarm:action to "PauseGame".
        // TODO delete future alarms; check kac:available
    }
}

unlock steering.
sas on.
hudtext(ship:name + ": mind directing PersistentRotation to Kerbol",
    30, //delayseconds - blinking message
    2, // upper center
    30, // size modifier
    rgb(1, 0.5, 0), // orange
    true).
