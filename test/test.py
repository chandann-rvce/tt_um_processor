# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, FallingEdge
import random

# Helper to build 16-bit instruction
def make_inst(opcode, func, func_i, regw, reg1, reg2_or_imm):
    inst = 0
    inst |= (opcode & 0b11)
    inst |= (func & 0b1111) << 2
    inst |= (func_i & 0b1) << 6
    inst |= (reg2_or_imm & 0b1111) << 6  # Used as reg2 or imm depending on type
    inst |= (reg1 & 0b111) << 10
    inst |= (regw & 0b111) << 13
    return inst

@cocotb.test()
async def processor_basic_test(dut):
    """Test tt_um_processor with a few ALU operations"""
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    await Timer(50, units='ns')
    dut.rst_n.value = 1
    await Timer(20, units='ns')

    # Utility for sending an instruction
    async def send_instruction(inst):
        dut.ui_in.value = inst & 0xFF
        dut.uio_in.value = (inst >> 8) & 0xFF
        await RisingEdge(dut.clk)
        await RisingEdge(dut.clk)

    # Load imm 0x3 into reg 0
    inst_li = make_inst(0b10, 0, 0, regw=0, reg1=0, reg2_or_imm=0x3)
    await send_instruction(inst_li)

    # Load imm 0x4 into reg 1
    inst_li = make_inst(0b10, 0, 0, regw=1, reg1=0, reg2_or_imm=0x4)
    await send_instruction(inst_li)

    # ADD reg 2 = reg 0 + reg 1
    inst_add = make_inst(0b11, 0b0110, 0, regw=2, reg1=0, reg2_or_imm=1)
    await send_instruction(inst_add)

    await Timer(20, units='ns')

    result = dut.uo_out.value.integer
    expected = 0x07
    assert result == expected, f"ADD result incorrect: got {result}, expected {expected}"

    # Test immediate add: reg3 = reg0 + imm(2)
    inst_addi = make_inst(0b01, 0b0110, 0, regw=3, reg1=0, reg2_or_imm=0x2)
    await send_instruction(inst_addi)

    await Timer(20, units='ns')
    result = dut.uo_out.value.integer
    expected = 0x05
    assert result == expected, f"ADDI result incorrect: got {result}, expected {expected}"

    # Test shift left: reg4 = reg0 << reg1
    inst_sll = make_inst(0b11, 0b1110, 0, regw=4, reg1=0, reg2_or_imm=1)
    await send_instruction(inst_sll)

    await Timer(20, units='ns')
    result = dut.uo_out.value.integer
    expected = 0x18  # 0x3 << 0x4 == 0x30, but upper nibble gets cut
    assert result == expected, f"SLL result incorrect: got {result}, expected {expected}"

    # Test AND: reg5 = reg0 & reg1
    inst_and = make_inst(0b11, 0b0000, 0, regw=5, reg1=0, reg2_or_imm=1)
    await send_instruction(inst_and)

    await Timer(20, units='ns')
    result = dut.uo_out.value.integer
    expected = 0x00  # 0x3 & 0x4 = 0x0
    assert result == expected, f"AND result incorrect: got {result}, expected {expected}"

    cocotb.log.info("All basic tests passed.")

###############################################################################################################
#import cocotb
#from cocotb.clock import Clock
#from cocotb.triggers import ClockCycles


#@cocotb.test()
#async def test_project(dut):
#    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
#    clock = Clock(dut.clk, 10, units="us")
#    cocotb.start_soon(clock.start())

    # Reset
#    dut._log.info("Reset")
#    dut.ena.value = 1
#    dut.ui_in.value = 0
#    dut.uio_in.value = 0
#    dut.rst_n.value = 0
#    await ClockCycles(dut.clk, 10)
#    dut.rst_n.value = 1

#    dut._log.info("Test project behavior")

    # Set the input values you want to test
#    dut.ui_in.value = 0
#    dut.uio_in.value = 0

    # Wait for one clock cycle to see the output values
#    await ClockCycles(dut.clk, 1)

    # The following assersion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:
#    assert dut.uo_out.value == 0

    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values.
##########################################################################################################
