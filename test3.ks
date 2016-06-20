// specific contract ship
lock steering to up.
lock speed to ship:velocity:surface:mag.
wait 1.
stage.

set warp to 0. wait 0.1. set warpmode to "physics". set warp to 3.

wait until (altitude > 12000).
set warp to 0.

wait until (altitude > 12000) and (altitude < 14000) and (120 < speed) and (speed < 200).
stage.

set warp to 0. wait 0.1. set warpmode to "physics". set warp to 3.

wait until (altitude > 70000) or (ship:verticalspeed < 0) .
if (altitude > 70000) {
    set warp to 0. wait 0.1. set warpmode to "rails". set warp to 3.

    wait until altitude < 70000.
    set warp to 0. wait 0.1. set warpmode to "physics". set warp to 3.
}

wait until (altitude < 11000) and (140 < speed) and (speed < 200).
stage.


set warp to 0. wait 0.1. set warpmode to "physics". set warp to 3.
