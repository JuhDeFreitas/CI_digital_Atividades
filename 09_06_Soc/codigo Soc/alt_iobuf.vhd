Library ieee;
use ieee.std_logic_1164.all;
entity alt_iobuf is
    generic(
        io_standard           : string  := "NONE";
        current_strength      : string  := "NONE";
        current_strength_new  : string  := "NONE";
        slew_rate             : integer := -1;
        slow_slew_rate        : string  := "NONE";
        location              : string  := "NONE";
        enable_bus_hold       : string  := "NONE";
        weak_pull_up_resistor : string  := "NONE";
        termination           : string  := "NONE";
        input_termination     : string  := "NONE";
        output_termination    : string  := "NONE";
        lpm_type              : string := "alt_iobuf" );
    port(
        i  : in    std_logic;
        oe : in    std_logic;
        io : inout std_logic;
        o  : out   std_logic);
end alt_iobuf;
architecture BEHAVIOR of alt_iobuf is
begin
    process(i, io, oe)
    begin
        if oe = '1' then
            io <= i;
        else
            io <= 'Z';
        end if;
        o <= io;
    end process;
end BEHAVIOR;