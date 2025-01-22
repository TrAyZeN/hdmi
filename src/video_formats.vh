`ifndef _video_formats_vh_
`define _video_formats_vh_

// Definition video format parameters, based on CEA-861-D, for
// video_format_encoder. See video_format_encoder.v for documentation on
// parameters.

`ifdef VIDEO_FORMAT_640x480
`define HORIZONTAL_ACTIVE 640
`define HORIZONTAL_BLANKING 160
`define HSYNC_START 16
`define HSYNC_LEN 96
`define VERTICAL_ACTIVE_START 35
`define VERTICAL_ACTIVE 480
`define VERTICAL_BLANKING 45
`define VSYNC_START 0
`define VSYNC_LEN 2
`define SYNC_EN_POLARITY 0
`endif // VIDEO_FORMAT_640x480

`ifdef VIDEO_FORMAT_1280x720
`define HORIZONTAL_ACTIVE 1280
`define HORIZONTAL_BLANKING 370
`define HSYNC_START 110
`define HSYNC_LEN 40
`define VERTICAL_ACTIVE_START 25
`define VERTICAL_ACTIVE 720
`define VERTICAL_BLANKING 30
`define VSYNC_START 0
`define VSYNC_LEN 5
`define SYNC_EN_POLARITY 1
`endif // VIDEO_FORMAT_1280x720

`endif // _video_formats_vh_
