"use strict";


var unit = require("heya-unit");

require("./test_classic");
require("./test_alternative");
require("./test_parser");
require("./test_streamer");
require("./test_packer");
require("./test_filter");
require("./test_escaped");
require("./test_source");
require("./test_emitter");
require("./test_assembler");
require("./test_stringer");
require("./test_primitives");
require("./test_sliding");
require("./test_array");
require("./test_filtered_array");
require("./test_filter_objects");
require("./test_combo");
require("./test_object");
require("./test_json_stream");


unit.run();
