library ieee;
use ieee.std_logic_1164.all;
use work.aes_sbox.all;


package aes_core is

    function aesenc (
        key : in std_logic_vector(127 downto 0);
        input : in std_logic_vector(127 downto 0)
    )
    return std_logic_vector;


    function aesdec (
        key : in std_logic_vector(127 downto 0);
        input : in std_logic_vector(127 downto 0)
    )
    return std_logic_vector;

end package;


package body aes_core is

    function aesenc (
        key : in std_logic_vector(127 downto 0);
        input : in std_logic_vector(127 downto 0)
    )
    return std_logic_vector is 
        variable output : std_logic_vector(127 downto 0);
        variable s0, s1, s2, s3 : std_logic_vector(31 downto 0);
        variable out0, out1, out2, out3 : std_logic_vector(31 downto 0);
    begin
        s3 := input(31 downto 0);
        s2 := input(63 downto 32);
        s1 := input(95 downto 64);
        s0 := input(127 downto 96);

        out0 := lutEnc0(s0(7 downto 0)) xor
                lutEnc1(s3(15 downto 8)) xor
                lutEnc2(s2(23 downto 16)) xor
                lutEnc3(s1(31 downto 24));

        out1 := lutEnc0(s1(7 downto 0)) xor
                lutEnc1(s0(15 downto 8)) xor
                lutEnc2(s3(23 downto 16)) xor
                lutEnc3(s2(31 downto 24));

        out2 := lutEnc0(s2(7 downto 0)) xor
                lutEnc1(s1(15 downto 8)) xor
                lutEnc2(s0(23 downto 16)) xor
                lutEnc3(s3(31 downto 24));

        out3 := lutEnc0(s3(7 downto 0)) xor
                lutEnc1(s2(15 downto 8)) xor
                lutEnc2(s1(23 downto 16)) xor
                lutEnc3(s0(31 downto 24));

        output := (out0 & out1 & out2 & out3) xor key;

        return output;
    end;


    function aesdec (
        key : in std_logic_vector(127 downto 0);
        input : in std_logic_vector(127 downto 0)
    )
    return std_logic_vector is 
        variable output : std_logic_vector(127 downto 0);
        variable s0, s1, s2, s3 : std_logic_vector(31 downto 0);
        variable out0, out1, out2, out3 : std_logic_vector(31 downto 0);
    begin
        s3 := input(31 downto 0);
        s2 := input(63 downto 32);
        s1 := input(95 downto 64);
        s0 := input(127 downto 96);

        out0 := lutDec0(s0(7 downto 0)) xor
                lutDec1(s1(15 downto 8)) xor
                lutDec2(s2(23 downto 16)) xor
                lutDec3(s3(31 downto 24));

        out1 := lutDec0(s1(7 downto 0)) xor
                lutDec1(s2(15 downto 8)) xor
                lutDec2(s3(23 downto 16)) xor
                lutDec3(s0(31 downto 24));

        out2 := lutDec0(s2(7 downto 0)) xor
                lutDec1(s3(15 downto 8)) xor
                lutDec2(s0(23 downto 16)) xor
                lutDec3(s1(31 downto 24));

        out3 := lutDec0(s3(7 downto 0)) xor
                lutDec1(s0(15 downto 8)) xor
                lutDec2(s1(23 downto 16)) xor
                lutDec3(s2(31 downto 24));

        output := (out0 & out1 & out2 & out3) xor key;

        return output;
    end;

end aes_core;