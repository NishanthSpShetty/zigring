const std = @import("std");
const ring = @import("ring/ring.zig");
pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var buffer = try ring.RingBufferOf(i32).init(10, allocator);
    const r = &buffer;
    try r.offer(10);
}
