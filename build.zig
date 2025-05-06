const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const linkage = b.option(
        std.builtin.LinkMode,
        "linkage",
        "Specify static or dynamic linkage",
    ) orelse .static;

    const upstream = b.dependency("foonathan_memory", .{});

    const foo_mem = b.addLibrary(.{
        .name = "foonathan-memory",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .link_libcpp = true,
        }),
        .linkage = linkage,
    });

    // const native_endian = @import("builtin").target.cpu.arch.endian();
    // const is_bigendian: u8 = if (native_endian == .big) 1 else 0;

    const config_h = b.addConfigHeader(.{
        .style = .{ .cmake = upstream.path("src/config.hpp.in") },
        .include_path = "config_impl.hpp",
    }, .{
        .FOONATHAN_MEMORY_CHECK_ALLOCATION_SIZE = 1,
        .FOONATHAN_MEMORY_DEFAULT_ALLOCATOR = "heap_allocator",
        .FOONATHAN_MEMORY_DEBUG_ASSERT = 0,
        .FOONATHAN_MEMORY_DEBUG_FILL = 0,
        .FOONATHAN_MEMORY_DEBUG_FENCE = 0,
        .FOONATHAN_MEMORY_DEBUG_LEAK_CHECK = 0,
        .FOONATHAN_MEMORY_DEBUG_POINTER_CHECK = 0,
        .FOONATHAN_MEMORY_DEBUG_DOUBLE_DEALLOC_CHECK = 0,
        .FOONATHAN_MEMORY_EXTERN_TEMPLATE = 1,
        .FOONATHAN_MEMORY_TEMPORARY_STACK_MODE = 2,
    });
    foo_mem.addConfigHeader(config_h);
    foo_mem.installHeader(config_h.getOutput(), "foonathan/memory/config_impl.hpp");
    // TODO: this is auto-generated with a bunch of work in CMake
    foo_mem.installHeader(b.path("include/container_node_sizes_impl.hpp"), "foonathan/memory/detail/container_node_sizes_impl.hpp");

    // The source code follows very old-schools standards and does NOT namespace its own headers
    foo_mem.addIncludePath(upstream.path("include/foonathan/memory"));
    foo_mem.addIncludePath(upstream.path("include"));
    foo_mem.addCSourceFiles(.{
        .root = upstream.path("src"),
        .files = &.{
            "detail/align.cpp",
            "detail/debug_helpers.cpp",
            "detail/assert.cpp",
            "detail/free_list.cpp",
            "detail/free_list_array.cpp",
            "detail/free_list_utils.hpp",
            "detail/small_free_list.cpp",
            "debugging.cpp",
            "error.cpp",
            "heap_allocator.cpp",
            "iteration_allocator.cpp",
            "malloc_allocator.cpp",
            "memory_arena.cpp",
            "memory_pool.cpp",
            "memory_pool_collection.cpp",
            "memory_stack.cpp",
            "new_allocator.cpp",
            "static_allocator.cpp",
            "temporary_allocator.cpp",
            "virtual_memory.cpp",
        },
        .flags = &.{ "--std=c++17", "-Wall", "-Wextra", "-Werror", "-pedantic", "-Wconversion", "-Wsign-conversion" },
    });
    foo_mem.installHeadersDirectory(upstream.path("include"), "", .{ .include_extensions = &.{ ".h", ".hpp" } });

    b.installArtifact(foo_mem);
}
