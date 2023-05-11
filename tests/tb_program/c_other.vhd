library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;


package cc_other is

    procedure shift_check (constant program : in instructions);

    procedure target_check (constant program : in instructions);

    procedure mask_check (constant program : in instructions);

    procedure imm_check (constant program : in instructions);

end package;


package body cc_other is

    procedure shift_check (constant program : in instructions) is
    begin

        assert program(2).shift = 0 report "2 Shift Failed" severity FAILURE;
        assert program(10).shift = 0 report "10 Shift Failed" severity FAILURE;
        assert program(17).shift = 0 report "17 Shift Failed" severity FAILURE;
        assert program(22).shift = 1 report "22 Shift Failed" severity FAILURE;
        assert program(26).shift = 1 report "26 Shift Failed" severity FAILURE;
        assert program(42).shift = 3 report "42 Shift Failed" severity FAILURE;
        assert program(77).shift = 3 report "77 Shift Failed" severity FAILURE;
        assert program(79).shift = 2 report "79 Shift Failed" severity FAILURE;
        assert program(88).shift = 2 report "88 Shift Failed" severity FAILURE;
        assert program(121).shift = 1 report "121 Shift Failed" severity FAILURE;
        assert program(130).shift = 3 report "130 Shift Failed" severity FAILURE;
        assert program(135).shift = 3 report "135 Shift Failed" severity FAILURE;
        assert program(157).shift = 3 report "157 Shift Failed" severity FAILURE;
        assert program(186).shift = 3 report "186 Shift Failed" severity FAILURE;
        assert program(204).shift = 3 report "204 Shift Failed" severity FAILURE;
        assert program(221).shift = 0 report "221 Shift Failed" severity FAILURE;
        assert program(227).shift = 2 report "227 Shift Failed" severity FAILURE;

    end;


    procedure target_check (constant program : in instructions) is
    begin
    
        assert program(5).target = -1 report "5 target Failed" severity FAILURE;
        assert program(19).target = 5 report "19 target Failed" severity FAILURE;
        assert program(28).target = 26 report "28 target Failed" severity FAILURE;
        assert program(37).target = 28 report "37 target Failed" severity FAILURE;
        assert program(55).target = 37 report "55 target Failed" severity FAILURE;
        assert program(59).target = 55 report "59 target Failed" severity FAILURE;
        assert program(71).target = 64 report "71 target Failed" severity FAILURE;
        assert program(72).target = 71 report "72 target Failed" severity FAILURE;
        assert program(87).target = 72 report "87 target Failed" severity FAILURE;
        assert program(113).target = 102 report "113 target Failed" severity FAILURE;
        assert program(124).target = 121 report "124 target Failed" severity FAILURE;
        assert program(141).target = 126 report "141 target Failed" severity FAILURE;
        assert program(152).target = 141 report "152 target Failed" severity FAILURE;
        assert program(159).target = 152 report "159 target Failed" severity FAILURE;
        assert program(164).target = 163 report "164 target Failed" severity FAILURE;
        assert program(187).target = 184 report "187 target Failed" severity FAILURE;
        assert program(188).target = 187 report "188 target Failed" severity FAILURE;
        assert program(195).target = 188 report "195 target Failed" severity FAILURE;
        assert program(196).target = 195 report "196 target Failed" severity FAILURE;
        assert program(197).target = 196 report "197 target Failed" severity FAILURE;
        assert program(234).target = 221 report "234 target Failed" severity FAILURE;
            
    end;


    procedure mask_check (constant program : in instructions) is
    begin
    
        assert program(0).memMask = 16376 report "0 memMask Failed" severity FAILURE;
        assert program(3).memMask = 262136 report "3 memMask Failed" severity FAILURE;
        assert program(5).memMask = 534773760 report "5 memMask Failed" severity FAILURE;
        assert program(13).memMask = 262136 report "13 memMask Failed" severity FAILURE;
        assert program(15).memMask = 16376 report "15 memMask Failed" severity FAILURE;
        assert program(16).memMask = 16376 report "16 memMask Failed" severity FAILURE;
        assert program(19).memMask = 4177920 report "19 memMask Failed" severity FAILURE;
        assert program(25).memMask = 262136 report "25 memMask Failed" severity FAILURE;
        assert program(28).memMask = 534773760 report "28 memMask Failed" severity FAILURE;
        assert program(29).memMask = 16376 report "29 memMask Failed" severity FAILURE;
        assert program(31).memMask = 16376 report "31 memMask Failed" severity FAILURE;
        assert program(33).memMask = 16376 report "33 memMask Failed" severity FAILURE;
        assert program(37).memMask = 1044480 report "37 memMask Failed" severity FAILURE;
        assert program(40).memMask = 16376 report "40 memMask Failed" severity FAILURE;
        assert program(45).memMask = 16376 report "45 memMask Failed" severity FAILURE;
        assert program(47).memMask = 16376 report "47 memMask Failed" severity FAILURE;
        assert program(54).memMask = 16376 report "54 memMask Failed" severity FAILURE;
        assert program(55).memMask = 522240 report "55 memMask Failed" severity FAILURE;
        assert program(58).memMask = 2097144 report "58 memMask Failed" severity FAILURE;
        assert program(59).memMask = 4177920 report "59 memMask Failed" severity FAILURE;
        assert program(66).memMask = 16376 report "66 memMask Failed" severity FAILURE;
        assert program(71).memMask = 2139095040 report "71 memMask Failed" severity FAILURE;
        assert program(72).memMask = 133693440 report "72 memMask Failed" severity FAILURE;
        assert program(81).memMask = 16376 report "81 memMask Failed" severity FAILURE;
        assert program(83).memMask = 16376 report "83 memMask Failed" severity FAILURE;
        assert program(84).memMask = 16376 report "84 memMask Failed" severity FAILURE;
        assert program(87).memMask = 267386880 report "87 memMask Failed" severity FAILURE;
        assert program(90).memMask = 16376 report "90 memMask Failed" severity FAILURE;
        assert program(91).memMask = 262136 report "91 memMask Failed" severity FAILURE;
        assert program(92).memMask = 16376 report "92 memMask Failed" severity FAILURE;
        assert program(95).memMask = 262136 report "95 memMask Failed" severity FAILURE;
        assert program(102).memMask = 16376 report "102 memMask Failed" severity FAILURE;
        assert program(105).memMask = 2097144 report "105 memMask Failed" severity FAILURE;
        assert program(106).memMask = 2097144 report "106 memMask Failed" severity FAILURE;
        assert program(109).memMask = 16376 report "109 memMask Failed" severity FAILURE;
        assert program(113).memMask = 267386880 report "113 memMask Failed" severity FAILURE;
        assert program(120).memMask = 16376 report "120 memMask Failed" severity FAILURE;
        assert program(123).memMask = 16376 report "123 memMask Failed" severity FAILURE;
        assert program(124).memMask = 33423360 report "124 memMask Failed" severity FAILURE;
        assert program(128).memMask = 16376 report "128 memMask Failed" severity FAILURE;
        assert program(133).memMask = 16376 report "133 memMask Failed" severity FAILURE;
        assert program(139).memMask = 262136 report "139 memMask Failed" severity FAILURE;
        assert program(141).memMask = 267386880 report "141 memMask Failed" severity FAILURE;
        assert program(144).memMask = 2097144 report "144 memMask Failed" severity FAILURE;
        assert program(146).memMask = 262136 report "146 memMask Failed" severity FAILURE;
        assert program(148).memMask = 262136 report "148 memMask Failed" severity FAILURE;
        assert program(152).memMask = 33423360 report "152 memMask Failed" severity FAILURE;
        assert program(159).memMask = 16711680 report "159 memMask Failed" severity FAILURE;
        assert program(164).memMask = 133693440 report "164 memMask Failed" severity FAILURE;
        assert program(175).memMask = 16376 report "175 memMask Failed" severity FAILURE;
        assert program(180).memMask = 262136 report "180 memMask Failed" severity FAILURE;
        assert program(181).memMask = 16376 report "181 memMask Failed" severity FAILURE;
        assert program(185).memMask = 16376 report "185 memMask Failed" severity FAILURE;
        assert program(187).memMask = 16711680 report "187 memMask Failed" severity FAILURE;
        assert program(188).memMask = 2139095040 report "188 memMask Failed" severity FAILURE;
        assert program(190).memMask = 16376 report "190 memMask Failed" severity FAILURE;
        assert program(194).memMask = 16376 report "194 memMask Failed" severity FAILURE;
        assert program(195).memMask = 2139095040 report "195 memMask Failed" severity FAILURE;
        assert program(196).memMask = 1069547520 report "196 memMask Failed" severity FAILURE;
        assert program(197).memMask = 65280 report "197 memMask Failed" severity FAILURE;
        assert program(202).memMask = 16376 report "202 memMask Failed" severity FAILURE;
        assert program(205).memMask = 16376 report "205 memMask Failed" severity FAILURE;
        assert program(206).memMask = 16376 report "206 memMask Failed" severity FAILURE;
        assert program(211).memMask = 16376 report "211 memMask Failed" severity FAILURE;
        assert program(212).memMask = 262136 report "212 memMask Failed" severity FAILURE;
        assert program(213).memMask = 16376 report "213 memMask Failed" severity FAILURE;
        assert program(217).memMask = 2097144 report "217 memMask Failed" severity FAILURE;
        assert program(220).memMask = 16376 report "220 memMask Failed" severity FAILURE;
        assert program(230).memMask = 16376 report "230 memMask Failed" severity FAILURE;
        assert program(231).memMask = 16376 report "231 memMask Failed" severity FAILURE;
        assert program(232).memMask = 16376 report "232 memMask Failed" severity FAILURE;
        assert program(234).memMask = 1069547520 report "234 memMask Failed" severity FAILURE;
        assert program(243).memMask = 262136 report "243 memMask Failed" severity FAILURE;
        assert program(245).memMask = 16376 report "245 memMask Failed" severity FAILURE;
        assert program(246).memMask = 16376 report "246 memMask Failed" severity FAILURE;
        assert program(248).memMask = 262136 report "248 memMask Failed" severity FAILURE;
        assert program(255).memMask = 16376 report "255 memMask Failed" severity FAILURE;

    end;


    procedure imm_check (constant program : in instructions) is
    begin
    
        assert program(0).imm(31 downto 0) = x"26ac2379" report "0 imm Failed" severity FAILURE;
        assert program(2).imm(31 downto 0) = x"00000000" report "2 imm Failed" severity FAILURE;
        assert program(3).imm(31 downto 0) = x"6b450c8d" report "3 imm Failed" severity FAILURE;
        assert program(5).imm(31 downto 0) = x"3beb19c8" report "5 imm Failed" severity FAILURE;
        assert program(10).imm(31 downto 0) = x"00000000" report "10 imm Failed" severity FAILURE;
        assert program(13).imm(31 downto 0) = x"87126699" report "13 imm Failed" severity FAILURE;
        assert program(14).imm = x"e41d1d8a759c6529" report "14 imm Failed" severity FAILURE;
        assert program(15).imm(31 downto 0) = x"0dfa297c" report "15 imm Failed" severity FAILURE;
        assert program(16).imm(31 downto 0) = x"c3199ea1" report "16 imm Failed" severity FAILURE;
        assert program(17).imm(31 downto 0) = x"00000000" report "17 imm Failed" severity FAILURE;
        assert program(19).imm(31 downto 0) = x"05da4da4" report "19 imm Failed" severity FAILURE;
        assert program(22).imm(31 downto 0) = x"339d818b" report "22 imm Failed" severity FAILURE;
        assert program(25).imm(31 downto 0) = x"2badc611" report "25 imm Failed" severity FAILURE;
        assert program(26).imm(31 downto 0) = x"00000000" report "26 imm Failed" severity FAILURE;
        assert program(28).imm(31 downto 0) = x"3ae0b23c" report "28 imm Failed" severity FAILURE;
        assert program(29).imm(31 downto 0) = x"f9588797" report "29 imm Failed" severity FAILURE;
        assert program(31).imm(31 downto 0) = x"3d803ff6" report "31 imm Failed" severity FAILURE;
        assert program(33).imm(31 downto 0) = x"00f577ba" report "33 imm Failed" severity FAILURE;
        assert program(34).imm(31 downto 0) = x"97678441" report "34 imm Failed" severity FAILURE;
        assert program(37).imm(31 downto 0) = x"4eedb2ce" report "37 imm Failed" severity FAILURE;
        assert program(39).imm(31 downto 0) = x"58bb64f7" report "39 imm Failed" severity FAILURE;
        assert program(40).imm(31 downto 0) = x"feb33259" report "40 imm Failed" severity FAILURE;
        assert program(42).imm(31 downto 0) = x"00000000" report "42 imm Failed" severity FAILURE;
        assert program(45).imm(31 downto 0) = x"e4d2ec84" report "45 imm Failed" severity FAILURE;
        assert program(47).imm(31 downto 0) = x"4f460407" report "47 imm Failed" severity FAILURE;
        assert program(52).imm(31 downto 0) = x"170b2d7a" report "52 imm Failed" severity FAILURE;
        assert program(54).imm(31 downto 0) = x"2aa6d813" report "54 imm Failed" severity FAILURE;
        assert program(55).imm(31 downto 0) = x"d26bd95d" report "55 imm Failed" severity FAILURE;
        assert program(58).imm(31 downto 0) = x"26d61a06" report "58 imm Failed" severity FAILURE;
        assert program(59).imm(31 downto 0) = x"680dd119" report "59 imm Failed" severity FAILURE;
        assert program(66).imm(31 downto 0) = x"31318b13" report "66 imm Failed" severity FAILURE;
        assert program(71).imm(31 downto 0) = x"9da81352" report "71 imm Failed" severity FAILURE;
        assert program(72).imm(31 downto 0) = x"6bf8be46" report "72 imm Failed" severity FAILURE;
        assert program(77).imm(31 downto 0) = x"00000000" report "77 imm Failed" severity FAILURE;
        assert program(79).imm(31 downto 0) = x"00000000" report "79 imm Failed" severity FAILURE;
        assert program(81).imm(31 downto 0) = x"72ef88af" report "81 imm Failed" severity FAILURE;
        assert program(83).imm(31 downto 0) = x"f026a233" report "83 imm Failed" severity FAILURE;
        assert program(84).imm(31 downto 0) = x"a1fbaf7f" report "84 imm Failed" severity FAILURE;
        assert program(87).imm(31 downto 0) = x"2c73952f" report "87 imm Failed" severity FAILURE;
        assert program(88).imm(31 downto 0) = x"00000000" report "88 imm Failed" severity FAILURE;
        assert program(90).imm(31 downto 0) = x"addcb395" report "90 imm Failed" severity FAILURE;
        assert program(91).imm(31 downto 0) = x"2d83d030" report "91 imm Failed" severity FAILURE;
        assert program(92).imm(31 downto 0) = x"050f7460" report "92 imm Failed" severity FAILURE;
        assert program(95).imm(31 downto 0) = x"ab60b305" report "95 imm Failed" severity FAILURE;
        assert program(102).imm(31 downto 0) = x"c0a54647" report "102 imm Failed" severity FAILURE;
        assert program(105).imm(31 downto 0) = x"bc2b742c" report "105 imm Failed" severity FAILURE;
        assert program(106).imm(31 downto 0) = x"77360861" report "106 imm Failed" severity FAILURE;
        assert program(109).imm(31 downto 0) = x"0c884f21" report "109 imm Failed" severity FAILURE;
        assert program(112).imm(31 downto 0) = x"0000002e" report "112 imm Failed" severity FAILURE;
        assert program(113).imm(31 downto 0) = x"4e515cd2" report "113 imm Failed" severity FAILURE;
        assert program(120).imm(31 downto 0) = x"9012fac6" report "120 imm Failed" severity FAILURE;
        assert program(121).imm(31 downto 0) = x"00000000" report "121 imm Failed" severity FAILURE;
        assert program(122).imm(31 downto 0) = x"a25440c7" report "122 imm Failed" severity FAILURE;
        assert program(123).imm(31 downto 0) = x"704afa29" report "123 imm Failed" severity FAILURE;
        assert program(124).imm(31 downto 0) = x"e89efc9c" report "124 imm Failed" severity FAILURE;
        assert program(128).imm(31 downto 0) = x"63b0fc8d" report "128 imm Failed" severity FAILURE;
        assert program(130).imm(31 downto 0) = x"00000000" report "130 imm Failed" severity FAILURE;
        assert program(131).imm = x"9f8de0b0ae4262bd" report "131 imm Failed" severity FAILURE;
        assert program(133).imm(31 downto 0) = x"531bf73e" report "133 imm Failed" severity FAILURE;
        assert program(134).imm = x"86bcf57839c6304b" report "134 imm Failed" severity FAILURE;
        assert program(135).imm(31 downto 0) = x"00000000" report "135 imm Failed" severity FAILURE;
        assert program(139).imm(31 downto 0) = x"6ea698a5" report "139 imm Failed" severity FAILURE;
        assert program(141).imm(31 downto 0) = x"84d71a50" report "141 imm Failed" severity FAILURE;
        assert program(144).imm(31 downto 0) = x"84a50c73" report "144 imm Failed" severity FAILURE;
        assert program(146).imm(31 downto 0) = x"cfc79011" report "146 imm Failed" severity FAILURE;
        assert program(148).imm(31 downto 0) = x"096421b5" report "148 imm Failed" severity FAILURE;
        assert program(152).imm(31 downto 0) = x"d1a617cb" report "152 imm Failed" severity FAILURE;
        assert program(157).imm(31 downto 0) = x"61982357" report "157 imm Failed" severity FAILURE;
        assert program(159).imm(31 downto 0) = x"cf0d635a" report "159 imm Failed" severity FAILURE;
        assert program(164).imm(31 downto 0) = x"2929e3a6" report "164 imm Failed" severity FAILURE;
        assert program(165).imm(31 downto 0) = x"ec057e2b" report "165 imm Failed" severity FAILURE;
        assert program(170).imm(31 downto 0) = x"ecb962ac" report "170 imm Failed" severity FAILURE;
        assert program(175).imm(31 downto 0) = x"93eec289" report "175 imm Failed" severity FAILURE;
        assert program(180).imm(31 downto 0) = x"0885e17d" report "180 imm Failed" severity FAILURE;
        assert program(181).imm(31 downto 0) = x"195f1cd1" report "181 imm Failed" severity FAILURE;
        assert program(184).imm = x"f4311b6a4612cd74" report "184 imm Failed" severity FAILURE;
        assert program(185).imm(31 downto 0) = x"71965541" report "185 imm Failed" severity FAILURE;
        assert program(186).imm(31 downto 0) = x"00000000" report "186 imm Failed" severity FAILURE;
        assert program(187).imm(31 downto 0) = x"224f713e" report "187 imm Failed" severity FAILURE;
        assert program(188).imm(31 downto 0) = x"f6a3335b" report "188 imm Failed" severity FAILURE;
        assert program(190).imm(31 downto 0) = x"4504889f" report "190 imm Failed" severity FAILURE;
        assert program(191).imm = x"937695bdd63d4fbb" report "191 imm Failed" severity FAILURE;
        assert program(192).imm(31 downto 0) = x"e58c3058" report "192 imm Failed" severity FAILURE;
        assert program(194).imm(31 downto 0) = x"a1948386" report "194 imm Failed" severity FAILURE;
        assert program(195).imm(31 downto 0) = x"f987985a" report "195 imm Failed" severity FAILURE;
        assert program(196).imm(31 downto 0) = x"ee54b327" report "196 imm Failed" severity FAILURE;
        assert program(197).imm(31 downto 0) = x"8b7a7d61" report "197 imm Failed" severity FAILURE;
        assert program(202).imm(31 downto 0) = x"a4137ba7" report "202 imm Failed" severity FAILURE;
        assert program(204).imm(31 downto 0) = x"00000000" report "204 imm Failed" severity FAILURE;
        assert program(205).imm(31 downto 0) = x"c8361f52" report "205 imm Failed" severity FAILURE;
        assert program(206).imm(31 downto 0) = x"08e20811" report "206 imm Failed" severity FAILURE;
        assert program(211).imm(31 downto 0) = x"91a4bb72" report "211 imm Failed" severity FAILURE;
        assert program(212).imm(31 downto 0) = x"8a572283" report "212 imm Failed" severity FAILURE;
        assert program(213).imm(31 downto 0) = x"9fa81ac6" report "213 imm Failed" severity FAILURE;
        assert program(215).imm = x"f98b0a3dd1976632" report "215 imm Failed" severity FAILURE;
        assert program(217).imm(31 downto 0) = x"cb18da1f" report "217 imm Failed" severity FAILURE;
        assert program(220).imm(31 downto 0) = x"8a4a35d2" report "220 imm Failed" severity FAILURE;
        assert program(221).imm(31 downto 0) = x"00000000" report "221 imm Failed" severity FAILURE;
        assert program(227).imm(31 downto 0) = x"00000000" report "227 imm Failed" severity FAILURE;
        assert program(230).imm(31 downto 0) = x"666ac358" report "230 imm Failed" severity FAILURE;
        assert program(231).imm(31 downto 0) = x"64855709" report "231 imm Failed" severity FAILURE;
        assert program(232).imm(31 downto 0) = x"ca3ccf1a" report "232 imm Failed" severity FAILURE;
        assert program(234).imm(31 downto 0) = x"b0d3aa90" report "234 imm Failed" severity FAILURE;
        assert program(236).imm(31 downto 0) = x"6c243bd3" report "236 imm Failed" severity FAILURE;
        assert program(243).imm(31 downto 0) = x"e439904e" report "243 imm Failed" severity FAILURE;
        assert program(245).imm(31 downto 0) = x"0fa783d6" report "245 imm Failed" severity FAILURE;
        assert program(246).imm(31 downto 0) = x"fcf96b79" report "246 imm Failed" severity FAILURE;
        assert program(248).imm(31 downto 0) = x"97622f97" report "248 imm Failed" severity FAILURE;
        assert program(253).imm = x"85704b7027fde99e" report "253 imm Failed" severity FAILURE;
        assert program(255).imm(31 downto 0) = x"22296387" report "255 imm Failed" severity FAILURE;
            
    end;

end cc_other;