import random

import cocotb
from cocotb.triggers import Timer


@cocotb.test()
async def test_blanking_patterns(dut):
    dut.d.value = 0b00011111
    dut.de.value = 0
    dut.cnt_prev.value = 5

    dut.c0.value = 0
    dut.c1.value = 0
    await Timer(5, units="ns")
    assert dut.q_out.value == 0b0010101011
    assert dut.cnt.value == 0

    dut.c0.value = 1
    dut.c1.value = 0
    await Timer(5, units="ns")
    assert dut.q_out.value == 0b1101010100
    assert dut.cnt.value == 0

    dut.c0.value = 0
    dut.c1.value = 1
    await Timer(5, units="ns")
    assert dut.q_out.value == 0b0010101010
    assert dut.cnt.value == 0

    dut.c0.value = 1
    dut.c1.value = 1
    await Timer(5, units="ns")
    assert dut.q_out.value == 0b1101010101
    assert dut.cnt.value == 0


@cocotb.test()
async def test_basic(dut):
    dut.de.value = 1

    dut.d.value = 0b00011111
    dut.cnt_prev.value = 0
    await Timer(5, units="ns")
    assert dut.q_m.value == 0b001011111
    assert dut.q_out.value == 0b1010100000
    assert dut.cnt.value.signed_integer == (0 + (2 - 6))

    dut.d.value = 0b11100000
    dut.cnt_prev.value = 0
    await Timer(5, units="ns")
    assert dut.q_m.value == 0b110100000
    assert dut.q_out.value == 0b0110100000
    assert dut.cnt.value.signed_integer == (0 + (2 - 6))

    dut.d.value = 0b00011111
    dut.cnt_prev.value = 1
    await Timer(5, units="ns")
    assert dut.q_m.value == 0b001011111
    assert dut.q_out.value == 0b1010100000
    assert dut.cnt.value.signed_integer == (1 + 2 * 0 + (2 - 6))

    dut.d.value = 0b00011111
    dut.cnt_prev.value = 0b11111  # -1
    await Timer(5, units="ns")
    assert dut.q_m.value == 0b001011111
    assert dut.q_out.value == 0b0001011111
    assert dut.cnt.value.signed_integer == (-1 - 2 * 1 + (6 - 2))


@cocotb.test()
async def test_random(dut):
    NUM_ITERATIONS = 1000

    dut.de.value = 1
    dut.c0.value = 0
    dut.c1.value = 0

    dut.cnt_prev.value = 0
    for i in range(NUM_ITERATIONS):
        dut.d.value = random.randint(0, 255)

        await Timer(5, units="ns")
        expected_q_out, expected_q_m, expected_cnt = encode_tmds(
            dut.d.value.integer, dut.cnt_prev.value.signed_integer
        )
        assert dut.q_m.value.integer == expected_q_m
        assert dut.q_out.value.integer == expected_q_out
        assert dut.cnt.value.signed_integer == expected_cnt

        dut.cnt_prev.value = dut.cnt.value


def encode_tmds(d: int, cnt_prev: int) -> tuple[int, int, int]:
    """
    Encode tmds without DE == 0 case
    """
    assert d >= 0 and d < 256
    d: list[int] = [int(x) for x in bin(d)[2:].zfill(8)][::-1]
    assert len(d) == 8 and all(x in (0, 1) for x in d)

    lnot = lambda x: 1 - x
    xnor = lambda x, y: int(x == y)

    q_m = [d[0]]
    if d.count(1) > 4 or (d.count(1) == 4 and d[0] == 0):
        for i in range(7):
            q_m.append(xnor(q_m[i], d[i + 1]))  # XNOR
        q_m.append(0)
    else:
        for i in range(7):
            q_m.append(q_m[i] ^ d[i + 1])
        q_m.append(1)

    n1_q_m = q_m[0 : 7 + 1].count(1)
    n0_q_m = q_m[0 : 7 + 1].count(0)

    q_out = []
    cnt = None
    if cnt_prev == 0 or (n1_q_m == n0_q_m):
        q_out = [x if q_m[8] == 1 else lnot(x) for x in q_m[0 : 7 + 1]]
        q_out.append(q_m[8])
        q_out.append(1 - q_m[8])
        if q_m[8] == 0:
            cnt = cnt_prev + (n0_q_m - n1_q_m)
        else:
            cnt = cnt_prev + (n1_q_m - n0_q_m)
    else:
        if (cnt_prev > 0 and (n1_q_m > n0_q_m)) or (cnt_prev < 0 and (n0_q_m > n1_q_m)):
            q_out = [lnot(x) for x in q_m[0 : 7 + 1]]
            q_out.append(q_m[8])
            q_out.append(1)
            cnt = cnt_prev + 2 * q_m[8] + (n0_q_m - n1_q_m)
        else:
            q_out = q_m[0 : 7 + 1]
            q_out.append(q_m[8])
            q_out.append(0)
            cnt = cnt_prev - 2 * lnot(q_m[8]) + (n1_q_m - n0_q_m)

    assert len(q_out) == 10
    assert cnt is not None
    to_int = lambda q: sum(x * 2**i for i, x in enumerate(q))
    return to_int(q_out), to_int(q_m), cnt
