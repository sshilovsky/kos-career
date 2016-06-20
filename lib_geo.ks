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
    UNTIL result > average - 180 {
        SET result TO result + 360.
    }
    UNTIL result <= average + 180 {
        SET result TO result - 360.
    }

    return result.
}

