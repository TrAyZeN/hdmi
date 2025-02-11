YOSYS ?= yosys
NEXTPNR ?= nextpnr-himbaechel
SBY ?= sby

BUILD_DIR ?= build

# Select video format (valid formats: 640x480, 1280x720)
VIDEO_FORMAT ?= 1280x720

.PHONY: all verify clean

all: $(BUILD_DIR)/top.fs

$(BUILD_DIR)/%.fs: $(BUILD_DIR)/%.json
	gowin_pack -d GW2A-18C -o $@ $<

$(BUILD_DIR)/%.json: $(BUILD_DIR)/%.synth.json tangnano20k.cst
	$(NEXTPNR) --json $< --write $@ --device GW2AR-LV18QN88C8/I7 --vopt family=GW2A-18C --vopt cst=$(filter %.cst,$^) --report $(BUILD_DIR)/report.json --placed-svg $(BUILD_DIR)/placed.svg --routed-svg $(BUILD_DIR)/routed.svg

$(BUILD_DIR)/top.synth.json: $(BUILD_DIR)/ src/top.v src/hdmi_pll.v src/video_format_encoder.v src/hdmi_transmitter.v src/tmds_encoder.v
	$(YOSYS) -p "verilog_defines -DVIDEO_FORMAT_${VIDEO_FORMAT}; read_verilog $(filter %.v,$^); synth_gowin -top top -json $@"

%/:
	mkdir -p $@

verify: formal/video_format_encoder.sby
	$(SBY) -f $<

clean:
	rm -r $(BUILD_DIR)
