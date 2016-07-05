if addons:rt:available {
    local first is true.
    until addons:rt:hasconnection(ship) {
        hudtext(ship:name + ": waiting for RT connection",
            1, //delayseconds - blinking message
            2, // upper center
            40, // size modifier
            rgb(1, 0.5, 0), // orange
            first).
        wait 1.5.
        set first to false.
    }
}
copy boot_comsat_k1000x from 0.
run boot_comsat_k1000x.
