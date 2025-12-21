//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const rl = @import("raylib");

pub const TileType = enum { empty, runway, terminal, gate, taxiway };
pub const Tile = struct { type: TileType };

pub fn drawDashedLine(start: rl.Vector2, end: rl.Vector2, thick: f32, color: rl.Color, dash_length: f32, gap_length: f32) void {
    const dx = end.x - start.x;
    const dy = end.y - start.y;
    const length = std.math.sqrt(dx * dx + dy * dy);
    if (length == 0) return;
    const dir_x = dx / length;
    const dir_y = dy / length;
    var current_dist: f32 = 0;
    while (current_dist < length) {
        var draw_len = dash_length;
        if (current_dist + draw_len > length) {
            draw_len = length - current_dist;
        }
        const p1 = rl.Vector2{ .x = start.x + dir_x * current_dist, .y = start.y + dir_y * current_dist };
        const p2 = rl.Vector2{ .x = start.x + dir_x * (current_dist + draw_len), .y = start.y + dir_y * (current_dist + draw_len) };
        rl.drawLineEx(p1, p2, thick, color);
        current_dist += dash_length + gap_length;
    }
}

pub fn drawDashedGrid(screenWidth: i32, screenHeight: i32, spacing: f32, thick: f32, color: rl.Color) void {
    const width_f = @as(f32, @floatFromInt(screenWidth));
    const height_f = @as(f32, @floatFromInt(screenHeight));

    var x: f32 = 0;
    while (x <= width_f) : (x += spacing) {
        drawDashedLine(rl.Vector2{ .x = x, .y = 0 }, rl.Vector2{ .x = x, .y = height_f }, thick, color, 20.0, 0);
    }
    var y: f32 = 0;
    while (y <= height_f) : (y += spacing) {
        drawDashedLine(rl.Vector2{ .x = 0, .y = y }, rl.Vector2{ .x = width_f, .y = y }, thick, color, 20.0, 0.0);
    }
}

pub fn initTiles(allocator: std.mem.Allocator, w: i32, h: i32, size: i32) ![]Tile {
    const cols = @divTrunc(w, size);
    const rows = @divTrunc(h, size);
    const count = @as(usize, @intCast(cols * rows));

    const tiles = try allocator.alloc(Tile, count);
    @memset(tiles, Tile{ .type = .empty });

    return tiles;
}

pub fn posToTile(w: i32, size: i32, mousePos: rl.Vector2) usize {
    const x = @as(i32, @intFromFloat(mousePos.x));
    const y = @as(i32, @intFromFloat(mousePos.y));

    const col = @divTrunc(x, size);
    const row = @divTrunc(y, size);
    const cols_count = @divTrunc(w, size);

    const index = row * cols_count + col;

    return @intCast(index);
}

pub fn setAsTaxiway(tiles: []Tile, index: usize) void {
    if (index >= tiles.len) return;
    tiles[index].type = .taxiway;
}
pub const draw = @import("draw.zig");
