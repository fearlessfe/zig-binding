const std = @import("std");
const User = @import("models/user.zig").User;

pub fn main() void {
    const user = User{
        .power = 9001,
        .name = "Goku",
    };
    std.debug.print("{s}'s power is {d}\n", .{ user.name, user.power });
}
