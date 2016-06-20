// specific contract ship
lock steering to up.
wait 1.

set engine to ship:partstagged("pseudoStage1")[0]:getmodule("ModuleEngines").

stage.
warp_on().

wait until maxthrust = 0.
stage. // decouple
engine:doevent("activate engine").

wait until (altitude > 70000).
warp_on().

wait until (altitude > 170000).
set warp to 0.
wait 0.2.
stage.
wait 0.2.
warp_on().

wait until (altitude < 90000).
set warp to 0.
wait 0.2.
stage.
wait 0.2.
warp_on().

wait until altitude < 70000.
warp_on().

wait until alt:radar < 50.
set warp to 0.
