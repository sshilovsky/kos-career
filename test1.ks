// specific contract ship
lock steering to up.
lock speed to ship:velocity:surface:mag.
wait 1.
stage.
set warp to 0. wait 0.1. set warpmode to "physics". set warp to 3.

wait until (altitude > 35000) and (370 < speed) and (speed < 1270).
set warp to 0.
wait 0.2.
stage.

set warp to 0. wait 0.1. set warpmode to "physics". set warp to 3.
wait until (altitude > 48000) and (910 < speed) and (speed < 1440).
set warp to 0.
wait 0.2.
stage.

// die
set warp to 0. wait 0.1. set warpmode to "physics". set warp to 3.
