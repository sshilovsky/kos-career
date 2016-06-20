// 
// print "old loaddistance:".
// print loaddistance.
set loaddistance to 30000.
// print "updated".
// print "ok".
// 

set lights to false. // decouple
set lights to true. // decouple

wait 0.5.

print "decoupled".

wait 3. // wait for separatron to burn out.
// TODO wait for nearest ship to be far enough

wait until ship:velocity:surface:mag < 250.

set gear to false. // deploy fairings
set gear to true. // deploy fairings
set chutes to false.
set chutes to true.
print "parachuting".

wait until ship:velocity:surface:mag < 10.

//set brakes to false. // activate antenna
//set brakes to true. // activate antenna
//set panels to false.
//set panels to true.
//print "".

until ship:velocity:surface:mag < 0.1 {
    print "velocity zero?".
    wait until ship:velocity:surface:mag < 0.1.
    wait 0.5.
}.

print "yes. executing".

set brakes to false.
set brakes to true.

print "done. repeat in 5 sec".

wait 5.

print "executing".

set brakes to false.
set brakes to true.

print "done finally".

