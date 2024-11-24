YOSYS ?= yosys
NEXTPNR ?= nextpnr-himbaechel

.PHONY: all clean

all: top2.fs

%.fs: %.json
	gowin_pack -d GW2A-18C -o $@ $<

%.json: %.synth.json tangnano20k.cst
	$(NEXTPNR) --json $< --write $@ --device GW2AR-LV18QN88C8/I7 --vopt family=GW2A-18C --vopt cst=tangnano20k.cst --report report.json --placed-svg placed.svg --routed-svg routed.svg

top2.synth.json: src/top2.v src/hdmi_pll.v
	$(YOSYS) -p "read_verilog $^; synth_gowin -json $@"

clean: 
	rm -f *.json *.fs *-unpacked.v
