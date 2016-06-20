@lazyglobal off.

function list_def {
    parameter n.
    parameter arg1 is 0.
    parameter arg2 is 0.
    parameter arg3 is 0.
    parameter arg4 is 0.
    parameter arg5 is 0.
    parameter arg6 is 0.
    parameter arg7 is 0.
    parameter arg8 is 0.
    parameter arg9 is 0.
    parameter arg10 is 0.
    // TODO ...

    local res is list().
    if n < 1 { return res. }
    res:add(arg1).
    if n < 2 { return res. }
    res:add(arg2).
    if n < 3 { return res. }
    res:add(arg3).
    if n < 4 { return res. }
    res:add(arg4).
    if n < 5 { return res. }
    res:add(arg5).
    if n < 6 { return res. }
    res:add(arg6).
    if n < 7 { return res. }
    res:add(arg7).
    if n < 8 { return res. }
    res:add(arg8).
    if n < 9 { return res. }
    res:add(arg9).
    if n < 10 { return res. }
    res:add(arg10).
    if n < 11 { return res. }
    print "list_def: list is too long" at (1, 1).
    error.
}

function list_call {
    parameter ref.
    parameter args is list().

    local n is args:length.
    if n = 0 {
        return ref:call().
    }
    if n = 1 {
        return ref:call(args[0]).
    }
    if n = 2 {
        return ref:call(args[0], args[1]).
    }
    if n = 3 {
        return ref:call(args[0], args[1], args[2]).
    }
    if n = 4 {
        return ref:call(args[0], args[1], args[2], args[3]).
    }
    print "list_call: list is too long" at (1, 1).
    error.
}
