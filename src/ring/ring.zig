const std = @import("std");
const Allocator = std.mem.Allocator;
const RBError = error{ BufferFull, BufferEmpty, ErrShouldBePositive };

pub fn RingBufferOf(comptime T: type) type {
    return struct {
        storage: []T,
        writeIdx: usize,
        readIdx: usize,
        full: bool,

        pub fn init(cap: usize, allocator: Allocator) !RingBufferOf(T) {
            if (cap <= 0) {
                return RBError.ErrShouldBePositive;
            }
            const s = try allocator.alloc(T, cap);
            return .{
                .writeIdx = 0,
                .readIdx = 0,
                .full = false,
                .storage = s,
            };
        }

        pub fn offer(self: *RingBufferOf(T), item: T) !void {
            if (self.isFull()) {
                return RBError.BufferFull;
            }

            std.debug.print(" write at {d}  item {}", .{ self.writeIdx, item });
            self.storage[self.writeIdx] = item;

            self.*.writeIdx = self.*.advance(self.*.writeIdx);

            self.*.full = self.*.writeIdx == self.*.readIdx;
        }

        pub fn poll(self: *RingBufferOf(T)) !T {
            if (self.isEmpty()) {
                return RBError.BufferEmpty;
            }

            self.full = false;

            const i = self.readIdx;
            self.readIdx = self.advance(self.readIdx);
            return self.storage[i];
        }

        // private helpers
        //

        fn isFull(self: *RingBufferOf(T)) bool {
            return self.*.full;
        }

        fn isEmpty(self: *RingBufferOf(T)) bool {
            return (self.*.readIdx == self.*.writeIdx) and (!self.*.full);
        }

        fn advance(self: *RingBufferOf(T), i: usize) usize {
            return (i + 1) % (self.*.storage.len);
        }
    };
}

test "can create a buffer of any type" {
    const allocator = std.heap.page_allocator;
    _ = try RingBufferOf(i32).init(3, allocator);
    _ = RingBufferOf(i8).init(0, allocator) catch |err| {
        try std.testing.expect(err == RBError.ErrShouldBePositive);
    };
}

test "can offer and poll from the ring" {
    const allocator = std.heap.page_allocator;
    var buf = try RingBufferOf(i32).init(3, allocator);
    const rb = &buf;

    _ = rb.poll() catch |err| {
        try std.testing.expect(err == RBError.BufferEmpty);
    };

    // lets insert some values

    try rb.offer(10);
    try rb.offer(11);

    try rb.offer(12);

    rb.offer(10) catch |err| {
        try std.testing.expect(err == RBError.BufferFull);
    };

    const val1 = try rb.poll();
    try std.testing.expect(val1 == 10);

    try rb.offer(13);

    const val2 = try rb.poll();
    try std.testing.expect(val2 == 11);
}
