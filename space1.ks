// ship init
lock steering to up.

wait until altitude > 200.
//set warp to 0. set warpmode to "physics". set warp to 3.
science_transmit_rerunnable().
// TODO science into each biome

wait until altitude > 18000.
science_transmit_rerunnable().

wait until altitude > 70000.
unlock steering.
science_transmit_rerunnable().

// TODO wait for antenna inactivity and warp in rails
// TODO use libwarp to increase warp after 120km

wait until altitude < 70000.
//set warp to 0. set warpmode to "physics". set warp to 3.

wait until altitude < 18000.
science_transmit_rerunnable().

wait until false.
