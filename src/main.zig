const mach = @import("mach");

const Guecs = @import("Guecs.zig");
const Gui = @import("Gui.zig");
const Input = @import("Input.zig");

// The list of modules to be used in our application.
pub const modules = .{
    mach.Engine,
    Input,
    Gui,
    Guecs,
};

pub const App = mach.App;
