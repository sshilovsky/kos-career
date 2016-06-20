// specific contract ship
lock steering to up.
lock speed to ship:velocity:surface:mag.
wait 1.
stage.

set warp to 0. wait 0.1. set warpmode to "physics". set warp to 3.

wait until maxthrust = 0.  stage.

wait until altitude > 70000.
set warp to 0. wait 0.1. set warpmode to "rails". set warp to 3.

wait until altitude < 70000.
set warp to 0. wait 0.1. set warpmode to "physics". set warp to 3.
