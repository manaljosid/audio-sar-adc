from pathlib import Path

import vunit_common

# NOTE: This assumes the location of the directories relative to where this is run from
WORKSPACE = Path(__file__).parent / ".." / "workspace" / "modelsim"
LIB_ROOT = Path(__file__).parent / ".." / ".." / "lib"
SYN_ROOT = Path(__file__).parent / ".." / ".." / "rtl" / "syn"
SIM_ROOT = Path(__file__).parent / ".." / ".." / "rtl" / "sim"

vu, lib = vunit_common.init(WORKSPACE)

vunit_common.add_source(lib, LIB_ROOT / "./sv-ethernet/lib/sv-axis/syn/axis_if/axis_if.sv")
vunit_common.add_source(lib, LIB_ROOT / "./sv-ethernet/lib/sv-axis/sim/axis_bfm/axis_bfm.sv")
vunit_common.add_source(lib, SYN_ROOT / "./sar_fsm.sv")
vunit_common.add_source(lib, SIM_ROOT / "./sar_fsm_tb.sv")

# Create testbench
tb = lib.test_bench("sar_fsm_tb")

tb.add_config("TEST")

vu.main()