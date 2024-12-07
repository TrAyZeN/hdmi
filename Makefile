YOSYS ?= yosys
NEXTPNR ?= nextpnr-himbaechel

.PHONY: all clean

all: top.fs

%.fs: %.json
	gowin_pack -d GW2A-18C -o $@ $<

%.json: %.synth.json tangnano20k.cst
	$(NEXTPNR) --json $< --write $@ --device GW2AR-LV18QN88C8/I7 --vopt family=GW2A-18C --vopt cst=tangnano20k.cst --report report.json --placed-svg placed.svg --routed-svg routed.svg

top.synth.json: src/top.v src/hdmi_pll.v src/video_format_encoder.v src/hdmi_transmitter.v src/tmds_encoder.v
	$(YOSYS) -p "read_verilog $^; synth_gowin -top top -json $@"

clean:
	rm -f *.json *.fs
