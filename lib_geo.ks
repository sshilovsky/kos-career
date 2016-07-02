function geo_side_heading {
    parameter compass. // 0..180
    parameter pitch. // -90..90
    parameter vessel is ship.

    local v_up is vessel:up:forevector.
    local v_north is vessel:north:forevector.
    local v_east is vcrs(v_up, v_north).

    local lookat is (v_north * cos(compass) + v_east * sin(compass))
            * cos(pitch) + v_up * sin(pitch).

    local compass2 is compass + 90.

    local lookup is v_north * cos(compass2) + v_east * sin(compass2).

    return lookdirup(lookat, lookup).
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
    
    //angle = acos(dotProduct(Va.normalize(), Vb.normalize()));
    //cross = crossProduct(Va, Vb);
    //if (dotProduct(Vn, cross) < 0) { // Or > 0
    //  angle = -angle;
    //}
}

//LOCAL lib_geo_vecdraw IS vecdraw(v(0,0,0), v(0, 0, 0), white, "geo_prod", 10, true, 0.01).

function geo_vessel_azimuth {
    parameter vector. // ship-raw
    parameter average is 0. // do +-360 until near this value. also, the default value to return if vector is facing up
    parameter vessel is ship.
    // return geo angle of the vector applied to a ship

    //LOCAL angle IS signed_vangle(vessel:up:
    LOCAL plane_v IS vcrs(vector, vessel:up:forevector).
    //SET lib_geo_vecdraw:vec TO plane_v.
    IF plane_v:mag = 0 {
        return average.
    }
    LOCAL result IS signed_vangle(vessel:up:starvector, plane_v, vessel:up:forevector).
    SET result TO geo_angle_average(result, average).
    // TODO compare to vectorexclude/ship:up/ship:north implementation

    return result.
}

function geo_vessel_roll {
    parameter direction. // ship-raw
    parameter average is 0. // do +-360 until near this value. also, the default value to return if vector is facing up
    parameter vessel is ship.
    // return direction roll value relative to the vessel

    LOCAL plane_v IS vcrs(vcrs(direction:forevector, vessel:up:forevector), direction:forevector). // normal of the plane to find the angle with
    if plane_v:mag = 0 { // TODO eps
        return average.
    }
    LOCAL result IS signed_vangle(direction:topvector, plane_v, direction:forevector).
    SET result TO geo_angle_average(result, average).
    return result.
}

function geo_vessel_pitch {
    parameter vector. // ship-raw
    parameter average is 0. // do +-360 until near this value. also, the default value to return if vector is facing up
    parameter vessel is ship.
    // return vector pitch value relative to the vessel

    LOCAL result IS 90 - vectorangle(vessel:up:forevector, vector).
    SET result TO geo_angle_average(result, average).
    return result.
}

function geo_angle_average {
    parameter input. // degrees
    parameter average is 0. // do +-360 until near this value. also, the default value to return if vector is facing up
    parameter vessel is ship.

    UNTIL input > average - 180 {
        SET input TO input + 360.
    }
    UNTIL input <= average + 180 {
        SET input TO input - 360.
    }
    return input.    
}
