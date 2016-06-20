@lazyglobal off.

local old_thrust is 0.
local stop_staging is False.

function autostage_enable {
    set stop_staging to False.
    when old_thrust = 0 or ship:maxthrust < old_thrust / 2 then {
        if not stop_staging {
            stage.
            set old_thrust to ship:maxthrust.
            preserve.
        }
    }
}

function autostage_disable {
    set stop_staging to True.
}

function autostage_interactive_launch {
    print "Waiting for thrust activated.".
    when ship:maxthrust > 0 then {
        set old_thrust to ship:maxthrust.
        autostage_enable().
    }
}
