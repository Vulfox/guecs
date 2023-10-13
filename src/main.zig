const mach = @import("mach");

const Guecs = @import("Guecs.zig");

// The list of modules to be used in our application.
pub const modules = .{
    mach.Engine,
    Guecs,
};

pub const App = mach.App;
