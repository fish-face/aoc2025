const std = @import("std");
const Build = std.Build;
const CompileStep = std.Build.Step.Compile;

// GRIPE why the everloving fuck is the build file written in the language itself
// UNGRIPE the zig build system is optional... OK

const CUR_DAY = 5;

/// set this to true to link libc
const should_link_libc = false;
const required_zig_version = std.SemanticVersion.parse("0.15.2") catch unreachable;

fn linkObject(b: *Build, obj: *CompileStep) void {
    if (should_link_libc) obj.linkLibC();
    _ = b;

    // Add linking for packages or third party libraries here
}

pub fn build(b: *Build) void {
    if (comptime @import("builtin").zig_version.order(required_zig_version) == .lt) {
        std.debug.print("Warning: Your version of Zig too old. You will need to download a newer build\n", .{});
        std.process.exit(1);
    }

    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{});

    const install_all = b.step("install_all", "Install all days");
    const run_all = b.step("run_all", "Run all days");
    const test_all = b.step("test_all", "Run all tests");

    // const generate = b.step("generate", "Generate stub files from template/template.zig");
    // const build_generate = b.addExecutable(.{
    //     .name = "generate",
    //     .root_source_file = b.path("template/generate.zig"),
    //     .target = target,
    //     .optimize = .ReleaseSafe,
    // });

    // const run_generate = b.addRunArtifact(build_generate);
    // run_generate.setCwd(b.path("")); // This could probably be done in a more idiomatic way
    // generate.dependOn(&run_generate.step);

    // Set up an exe for each day
    var day: u32 = 1;
    const lib = b.addModule("aoc", .{
        .root_source_file = b.path("common/root.zig"),
        // GRIPE which utter moron thought it would be good to need to explicitly pass target and flags to every single build object?
        .target = target,
        .optimize = mode,
    });

    {
        const test_lib = b.step("test_lib", "Run tests of library");
        const test_ = b.addTest(.{
            .root_module = lib,
        });
        const run_test = b.addRunArtifact(test_);
        linkObject(b, test_);
        test_lib.dependOn(&run_test.step);
        test_all.dependOn(&run_test.step);
    }

    // UNGRIPE BUT it is pretty cool you can do this...
    while (day <= CUR_DAY) : (day += 1) {
        const dayString = b.fmt("day{:0>2}", .{day});
        const zigFile = b.fmt("src/{:0>2}.zig", .{day});

        const mod = b.addModule(dayString, .{
            .root_source_file = b.path(zigFile),
            .target = target,
            .optimize = mode,
            .imports = &.{
                .{ .name = "aoc", .module = lib },
            },
        });
        const exe = b.addExecutable(.{
            .name = dayString,
            .root_module = mod,
        });
        linkObject(b, exe);

        const install_cmd = b.addInstallArtifact(exe, .{});

        const build_test = b.addTest(.{
            .root_module = mod,
        });
        linkObject(b, build_test);

        const run_test = b.addRunArtifact(build_test);

        {
            const step_key = b.fmt("install_{s}", .{dayString});
            const step_desc = b.fmt("Install {s}.exe", .{dayString});
            const install_step = b.step(step_key, step_desc);
            install_step.dependOn(&install_cmd.step);
            install_all.dependOn(&install_cmd.step);
        }

        {
            const step_key = b.fmt("test_{s}", .{dayString});
            const step_desc = b.fmt("Run tests for {s}", .{zigFile});
            const step = b.step(step_key, step_desc);
            step.dependOn(&run_test.step);
        }

        const run_cmd = b.addRunArtifact(exe);
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_desc = b.fmt("Run {s}", .{dayString});
        const run_step = b.step(dayString, run_desc);
        run_step.dependOn(&run_cmd.step);
        run_all.dependOn(&run_cmd.step);
        test_all.dependOn(&run_test.step);
    }
}
