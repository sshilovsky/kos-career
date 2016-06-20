// staging, throttle, steering, go
WHEN STAGE:LIQUIDFUEL < 0.1 THEN {
    STAGE.
    PRESERVE.
}
LOCK THROTTLE TO 1.
LOCK STEERING TO R(0,0,-90) + HEADING(90,90).
STAGE.
WAIT UNTIL SHIP:ALTITUDE > 1000.

// P-loop setup
SET g TO KERBIN:MU / KERBIN:RADIUS^2.
LOCK accvec TO SHIP:SENSORS:ACC - SHIP:SENSORS:GRAV.
LOCK gforce TO accvec:MAG / g.
LOCK dthrott TO 0.05 * (1.2 - gforce).

SET thrott TO 1.
LOCK THROTTLE to thrott.

UNTIL SHIP:ALTITUDE > 40000 {
    SET thrott to thrott + dthrott.
    WAIT 0.1.
}

LOCK THROTTLE to 1.
