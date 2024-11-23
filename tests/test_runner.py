import os
from pathlib import Path
from typing import Mapping, Optional, Sequence, Union

from cocotb.runner import get_runner


def run_tests(
    name: str,
    sources: list[Path],
    test_case: Optional[Union[str, Sequence[str]]] = None,
    parameters: Mapping[str, object] = {},
):
    sim = os.getenv("SIM", "icarus")

    root_dir = Path(__file__).resolve().parent.parent
    build_dir = root_dir / "sim_builds" / name

    runner = get_runner(sim)
    runner.build(
        verilog_sources=sources,
        hdl_toplevel=name,
        build_dir=build_dir,
        parameters=parameters,
        timescale=("1ns", "1ps"),
        waves=True,
    )

    runner.test(
        hdl_toplevel=name,
        test_module=f"test_{name}",
        testcase=test_case,
        build_dir=build_dir,
        parameters=parameters,
        waves=True,
    )


if __name__ == "__main__":
    root_dir = Path(__file__).resolve().parent.parent
    src_dir = root_dir / "src"

    run_tests("tmds_encoder", [src_dir / "tmds_encoder.v"])
    run_tests(
        "serializer",
        [src_dir / "serializer.v"],
        parameters={"WIDTH": 10},
    )
