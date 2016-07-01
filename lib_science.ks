@lazyglobal off.

run once lib_util.

// init later:
LOCAL lib_science_modules IS 0.
LOCAL lib_science_modules_deployed IS 0.
// TODO track current transmits same way
// TODO check remotetech availability
LOCAL lib_science_data_value_threshold IS 0.

FUNCTION science_init {
    SET lib_science_modules TO util_get_vessel_modules(ship, "ModuleScienceExperiment").
    SET lib_science_modules_deployed TO list().
}

science_init().

ON ship:parts:length {
    // reinit when number of parts changes (staging or docking)
    science_init().
    preserve.
}


FUNCTION science_run_tests {
    FOR p IN ship:parts { // cannot use modulesnamed here, because when one is used, a few others may disappear
        if p:hasmodule("ModuleTestSubject") {
            LOCAL m IS p:getmodule("ModuleTestSubject").
            if m:hasevent("run test") {
                print "running test on " + p:name.
                m:doevent("run test").
            }
        }
    }
}

FUNCTION science_collect_rerunnable {
    for m in ship:modulesnamed("ModuleScienceExperiment") {
        if m:rerunnable and not m:hasdata and not m:inoperable {
            //print "deploying " + m:part:name.
            m:deploy.
        }
    }
}

FUNCTION science_transmit_rerunnable {
    PARAMETER min_ec IS 5. // minimum electricity to keep

    LOCAL ec IS util_get_resource("ElectricCharge"):amount - min_ec.

    for m in ship:modulesnamed("ModuleScienceExperiment") {
        if m:hasdata {
            if m:data[0]:transmitvalue > 0.1 {
                LOCAL transmit_ec IS 90. // TODO auto
                if ec < transmit_ec {
                    print "not enough EC to transmit " + m:part:name.
                    break.
                }
                SET ec TO ec - transmit_ec.
                print "transmitting " + m:part:name.
                m:transmit.
            } else {
                //print "dropping " + m:part:name.
                m:dump.
            }
        }
    }
}


FUNCTION science_transmit_rerunnable {
    PARAMETER data_value_threshold IS 0.1.
    // TODO deprecated

    if lib_science_modules_deployed:length {
        print "science_transmit_rerunnable: deploying in progress. abort.".
        return.
    }
    SET lib_science_data_value_threshold TO data_value_threshold.
    // TODO lib_warp integration.
    // lib_warp is needed to temporarily disable warp during the transmit.
    // push/pop is probably a reasonable approach. (with max warp allowed as
    // an argument)

    for module in lib_science_modules {
        if module:rerunnable {
            if module:hasdata {
                // TODO lib_log integration.
                // lib_log is needed to save logs between clearscreen-heavy ui
                print "science module has data already".
            } else if not module:inoperable {
                lib_science_modules_deployed:add(module).
                print "deploying".
                module:deploy.
            }
        }
    }

    if lib_science_modules_deployed:length {
        when lib_science_modules_deployed[0]:hasdata then {
            LOCAL module IS lib_science_modules_deployed[0].
            lib_science_modules_deployed:remove(0).
            
            //print "module: " + module.
            //print "threshold: " + lib_science_data_value_threshold.
            if module:data[0]:transmitvalue > lib_science_data_value_threshold {
                print "transmitting data".
                module:transmit.
            } else {
                print "dropping data".
                module:dump.
            }

            if lib_science_modules_deployed:length {
                print "preserve".
                preserve.
            }
        }
    }
}
