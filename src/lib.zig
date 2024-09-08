const std = @import("std");

const mdbx = @cImport({
    @cInclude("../../work/libmdbxmdbx.h");
});

pub fn main() void {
    std.debug.print("%d", mdbx.MDBX_debug_flags_t.MDBX_DBG_NONE);
}
