-- File: comm_fpga_fx2_v2.vhd
-- Generated by MyHDL 0.9dev
-- Date: Sat Jul 13 22:29:39 2013


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;

use work.pck_myhdl_09.all;

entity comm_fpga_fx2_v2 is
    port (
        clk_in: in std_logic;
        reset_in: in std_logic;
        fx2FifoSel_out: out std_logic;
        fx2Data_in: in unsigned(7 downto 0);
        fx2Data_out: out unsigned(7 downto 0);
        fx2Data_sel: out std_logic;
        fx2Read_out: in std_logic;
        fx2GotData_in: in std_logic;
        fx2Write_out: in std_logic;
        fx2GotRoom_in: in std_logic;
        fx2PktEnd_out: in std_logic;
        chanAddr_out: in unsigned(6 downto 0);
        h2fData_out: in unsigned(7 downto 0);
        h2fValid_out: in std_logic;
        h2fReady_in: in std_logic;
        f2hData_in: in unsigned(7 downto 0);
        f2hValid_in: in std_logic;
        f2hReady_out: in std_logic
    );
end entity comm_fpga_fx2_v2;
-- Original port definition
-- This module bridges the "original" port mapping to the MyHDL
-- version.    

architecture MyHDL of comm_fpga_fx2_v2 is


constant fopREAD: integer := 2;
constant FX2_IN_FIFO: integer := 1;
constant FX2_OUT_FIFO: integer := 0;
constant fopNOP: integer := 3;
constant fopWRITE: integer := 1;



signal g_fl_bus_chan_addr: unsigned(6 downto 0);
signal g_fx2_bus_read: std_logic;
signal g_is_write: std_logic;
signal g_state: None;
signal g_fl_bus_data_i: unsigned(7 downto 0);
signal g_fx2_bus_gotroom: std_logic;
signal g_fl_bus_data_o: unsigned(7 downto 0);
signal g_fl_bus_ready_i: std_logic;
signal g_fl_bus_ready_o: std_logic;
signal g_is_aligned: std_logic;
signal g_count: unsigned(31 downto 0);
signal g_fifop: unsigned(1 downto 0);
signal g_fl_bus_valid_o: std_logic;
signal g_fx2_bus_write: std_logic;
signal g_fl_bus_valid_i: std_logic;
signal g_fx2_bus_gotdata: std_logic;
signal g_fx2_bus_pktend: std_logic;

begin

g_fl_bus_data_i <= to_unsigned(0, 8);
g_fx2_bus_gotroom <= '0';
g_fl_bus_ready_i <= '0';
g_fl_bus_valid_i <= '0';
g_fx2_bus_gotdata <= '0';



COMM_FPGA_FX2_V2_G_HDL_SM: process (clk_in, reset_in) is
begin
    if (reset_in = '0') then
        g_count <= to_unsigned(0, 32);
        g_fl_bus_chan_addr <= to_unsigned(0, 7);
        fx2Data_out <= to_unsigned(0, 8);
        fx2FifoSel_out <= '0';
        g_fifop <= to_unsigned(3, 2);
        g_is_write <= '0';
        g_fl_bus_ready_o <= '0';
        fx2Data_sel <= '0';
        g_fl_bus_valid_o <= '0';
        g_state <= IDLE;
        g_fx2_bus_pktend <= '0';
        g_fl_bus_data_o <= to_unsigned(0, 8);
        g_is_aligned <= '0';
    elsif rising_edge(clk_in) then
        case g_state is
            when GET_COUNT0 =>
                if bool(g_fx2_bus_gotdata) then
                    g_count <= shift_left(resize(fx2Data_in, 32), 24);
                    g_state <= GET_COUNT1;
                else
                    g_count <= to_unsigned(0, 32);
                end if;
            when GET_COUNT1 =>
                if bool(g_fx2_bus_gotdata) then
                    g_count <= (g_count or shift_left(resize(fx2Data_in, 32), 16));
                    g_state <= GET_COUNT2;
                end if;
            when GET_COUNT2 =>
                if bool(g_fx2_bus_gotdata) then
                    g_count <= (g_count or shift_left(resize(fx2Data_in, 32), 8));
                    g_state <= GET_COUNT3;
                end if;
            when GET_COUNT3 =>
                if bool(g_fx2_bus_gotdata) then
                    g_count <= (g_count or resize(fx2Data_in, 32));
                    if bool(g_is_write) then
                        g_state <= BEGIN_WRITE;
                    else
                        if bool(g_fl_bus_ready_i) then
                            g_fifop <= to_unsigned(fopREAD, 2);
                            g_state <= READ;
                        else
                            g_fifop <= to_unsigned(fopNOP, 2);
                            g_state <= READ_WAIT;
                        end if;
                    end if;
                end if;
            when BEGIN_WRITE =>
                fx2FifoSel_out <= stdl(FX2_IN_FIFO);
                g_fifop <= to_unsigned(fopNOP, 2);
                if (g_count(9-1 downto 0) = 0) then
                    g_is_aligned <= '1';
                else
                    g_is_aligned <= '0';
                end if;
                g_state <= WRITE;
            when WRITE =>
                if bool(g_fx2_bus_gotroom) then
                    g_fl_bus_ready_o <= '1';
                end if;
                if (bool(g_fx2_bus_gotroom) and bool(g_fl_bus_valid_i)) then
                    g_fifop <= to_unsigned(fopWRITE, 2);
                    fx2Data_out <= g_fl_bus_data_i;
                    fx2Data_sel <= '1';
                    g_count <= (g_count - 1);
                    if (g_count = 1) then
                        if bool(g_is_aligned) then
                            g_state <= END_WRITE_ALIGNED;
                        else
                            g_state <= END_WRITE_NONALIGNED;
                        end if;
                    end if;
                else
                    g_fifop <= to_unsigned(fopNOP, 2);
                end if;
            when END_WRITE_ALIGNED =>
                fx2FifoSel_out <= stdl(FX2_IN_FIFO);
                g_fifop <= to_unsigned(fopNOP, 2);
                g_state <= IDLE;
            when END_WRITE_NONALIGNED =>
                fx2FifoSel_out <= stdl(FX2_IN_FIFO);
                g_fifop <= to_unsigned(fopNOP, 2);
                g_fx2_bus_pktend <= '0';
                g_state <= IDLE;
            when READ =>
                fx2FifoSel_out <= stdl(FX2_OUT_FIFO);
                if (bool(g_fx2_bus_gotdata) and bool(g_fl_bus_ready_i)) then
                    assert (not bool(g_fx2_bus_read))
                        report "*** AssertionError ***"
                        severity error;
                    g_fl_bus_valid_o <= '1';
                    g_fl_bus_data_o <= fx2Data_in;
                    if (g_count <= 1) then
                        g_state <= IDLE;
                        g_count <= to_unsigned(0, 32);
                    else
                        g_count <= (g_count - 1);
                    end if;
                end if;
            when READ_WAIT =>
                if (bool(g_fx2_bus_gotdata) and bool(g_fl_bus_ready_i)) then
                    g_state <= READ;
                    g_fifop <= to_unsigned(fopREAD, 2);
                end if;
            when others =>
                g_fifop <= to_unsigned(fopREAD, 2);
                g_count <= to_unsigned(0, 32);
                g_fl_bus_valid_o <= '0';
                if bool(g_fx2_bus_gotdata) then
                    g_fl_bus_chan_addr <= fx2Data_in(7-1 downto 0);
                    g_is_write <= fx2Data_in(7);
                    g_state <= GET_COUNT0;
                end if;
        end case;
    end if;
end process COMM_FPGA_FX2_V2_G_HDL_SM;



g_fx2_bus_read <= g_fifop(0);
g_fx2_bus_write <= g_fifop(1);

end architecture MyHDL;
