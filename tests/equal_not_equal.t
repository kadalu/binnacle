EQUAL 10, 10, "Is this 10?"
EQUAL 10, 11, "Is this 10?"
var1 = "AAA "
EQUAL var1.strip, "AAA", "This is AAA"
EQUAL var1, "AAA", "This is AAA"
NOT_EQUAL 100, 100, "Is this not 100?"
NOT_EQUAL 100, 101, "Is this not 101?"
var2 = "BBB"
var3 = 100
NOT_EQUAL var2, var3, "var2 != var3"
