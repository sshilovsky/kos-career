// first basic implementation; API is to change
FUNCTION warp_on {
    set warp to 0. wait 0.1.
    if (body:atm:exists) and (altitude < body:atm:height) {
        set warpmode to "physics".
    } else {
        set warpmode to "rails".
    }
    until warp >= 3 {
        set warp to 3.
        wait 0.1.
    }
}
