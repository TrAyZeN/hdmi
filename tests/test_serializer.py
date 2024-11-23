import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

CLK_PERIOD_NS = 10


@cocotb.test()
async def test_rst(dut):
    assert dut.WIDTH == 10

    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD_NS, units="ns").start())

    # Fill register with ones
    dut.rst.value = 0
    dut.we.value = 1
    dut.data_in.value = 0b11_1111_1111
    await RisingEdge(dut.clk)

    # Test with we = 0
    dut.rst.value = 1
    dut.we.value = 0
    for _ in range(int(dut.WIDTH)):
        await RisingEdge(dut.clk)
        assert dut.serial_out.value == 0

    # Fill register with ones
    dut.rst.value = 0
    dut.we.value = 1
    dut.data_in.value = 0b11_1111_1111
    await RisingEdge(dut.clk)

    # Test with we = 1
    dut.rst.value = 1
    dut.we.value = 1
    for _ in range(int(dut.WIDTH)):
        await RisingEdge(dut.clk)
        assert dut.serial_out.value == 0


@cocotb.test()
async def test_basic(dut):
    assert dut.WIDTH == 10

    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD_NS, units="ns").start())

    dut.rst.value = 1
    dut.we.value = 0
    await Timer(5, units="ns")

    # Make sure data_in's first bit is not directly available on the next rising
    # edge
    dut.rst.value = 0
    dut.we.value = 1
    dut.data_in.value = 0b01_0101_0101
    await RisingEdge(dut.clk)
    assert dut.serial_out.value == 0

    dut.we.value = 0

    for i in range(int(dut.WIDTH)):
        await RisingEdge(dut.clk)
        assert dut.serial_out.value == (0b01_0101_0101 >> i) & 1

    dut.we.value = 1
    dut.data_in.value = 0b10_1010_1010
    await RisingEdge(dut.clk)
    assert dut.serial_out.value == 0

    dut.we.value = 0

    for i in range(int(dut.WIDTH)):
        await RisingEdge(dut.clk)
        assert dut.serial_out.value == (0b10_1010_1010 >> i) & 1


@cocotb.test()
async def test_random(dut):
    NUM_ITERATIONS = 1000

    assert dut.WIDTH == 10

    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD_NS, units="ns").start())

    dut.rst.value = 1
    dut.we.value = 0
    await Timer(5, units="ns")

    dut.rst.value = 0
    dut.we.value = 1
    next_data = random.randint(0, 2**10 - 1)
    dut.data_in.value = next_data
    await RisingEdge(dut.clk)
    dut.we.value = 0

    for _ in range(NUM_ITERATIONS):
        data = next_data
        for i in range(int(dut.WIDTH)):
            await RisingEdge(dut.clk)
            assert dut.serial_out.value == (data >> i) & 1

            # set dut.we for the rising edge when i == 9 so that shift register
            # next_data is available in the shift register on the next full
            # serializer iteration
            if i == 8:
                dut.we.value = 1
                next_data = random.randint(0, 2**10 - 1)
                dut.data_in.value = next_data
            else:
                dut.we.value = 0
