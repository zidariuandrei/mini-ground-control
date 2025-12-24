//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const rl = @import("raylib");
pub const draw = @import("draw.zig");

pub const TileType = enum { empty, runway, terminal, gate, taxiway };
pub const Tile = struct {
    type: TileType,
    gate_shape: ?draw.Shape = null,
};

pub fn drawDashedGrid(screenWidth: i32, screenHeight: i32, spacing: f32, thick: f32, color: rl.Color) void {
    const width_f = @as(f32, @floatFromInt(screenWidth));
    const height_f = @as(f32, @floatFromInt(screenHeight));

    var x: f32 = 0;
    while (x <= width_f) : (x += spacing) {
        draw.drawDashedLine(rl.Vector2{ .x = x, .y = 0 }, rl.Vector2{ .x = x, .y = height_f }, thick, color, 20.0, 0);
    }
    var y: f32 = 0;
    while (y <= height_f) : (y += spacing) {
        draw.drawDashedLine(rl.Vector2{ .x = 0, .y = y }, rl.Vector2{ .x = width_f, .y = y }, thick, color, 20.0, 0.0);
    }
}

pub fn initTiles(allocator: std.mem.Allocator, w: i32, h: i32, size: i32) ![]Tile {
    const cols = @divTrunc(w, size);
    const rows = @divTrunc(h, size);
    const count = @as(usize, @intCast(cols * rows));

    const tiles = try allocator.alloc(Tile, count);
    for (tiles) |*t| {
        t.* = Tile{ .type = .empty, .gate_shape = null };
    }

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

pub fn markRunway(tiles: []Tile, w: i32, size: i32, start_col: i32, start_row: i32, len_cols: i32, width_rows: i32) void {
    const cols_count = @divTrunc(w, size);
    var r: i32 = 0;
    while (r < width_rows) : (r += 1) {
        var c: i32 = 0;
        while (c < len_cols) : (c += 1) {
            const index = (start_row + r) * cols_count + (start_col + c);
            if (index < tiles.len) {
                tiles[@intCast(index)].type = .runway;
            }
        }
    }
}

pub fn markTerminal(tiles: []Tile, w: i32, size: i32, start_col: i32, start_row: i32, len_cols: i32, width_rows: i32) void {
    const cols_count = @divTrunc(w, size);
    var r: i32 = 0;
    while (r < width_rows) : (r += 1) {
        var c: i32 = 0;
        while (c < len_cols) : (c += 1) {
            const index = (start_row + r) * cols_count + (start_col + c);
            if (index < tiles.len) {
                tiles[@intCast(index)].type = .terminal;
            }
        }
    }
}

pub fn setGate(tiles: []Tile, index: usize, shape: draw.Shape) void {
    if (index >= tiles.len) return;
    tiles[index].type = .gate;
    tiles[index].gate_shape = shape;
}

// --- Rendering Helpers ---

const Direction = enum { North, South, East, West };

fn getNeighborType(tiles: []const Tile, index: usize, cols: i32, dir: Direction) ?TileType {
    const i_i32 = @as(i32, @intCast(index));
    const row = @divTrunc(i_i32, cols);
    const col = @rem(i_i32, cols);
    const total_tiles = @as(i32, @intCast(tiles.len));

    return switch (dir) {
        .North => if (row > 0) tiles[@intCast(i_i32 - cols)].type else null,
        .South => if (i_i32 + cols < total_tiles) tiles[@intCast(i_i32 + cols)].type else null,
        .East => if (col < cols - 1) tiles[@intCast(i_i32 + 1)].type else null,
        .West => if (col > 0) tiles[@intCast(i_i32 - 1)].type else null,
    };
}

fn isTerminalArea(t: ?TileType) bool {
    const type_ = t orelse return false;
    return type_ == .terminal or type_ == .gate;
}

fn drawRunwayTile(tiles: []const Tile, index: usize, x: f32, y: f32, size: f32, cols: i32, color: rl.Color) void {
    // 1. Draw solid borders at the edges of the runway block
    // Top
    if (getNeighborType(tiles, index, cols, .North) != .runway) {
        rl.drawLineEx(.{ .x = x, .y = y }, .{ .x = x + size, .y = y }, 2.0, color);
    }
    // Bottom
    if (getNeighborType(tiles, index, cols, .South) != .runway) {
        rl.drawLineEx(.{ .x = x, .y = y + size }, .{ .x = x + size, .y = y + size }, 2.0, color);
    }
    // Left
    if (getNeighborType(tiles, index, cols, .West) != .runway) {
        rl.drawLineEx(.{ .x = x, .y = y }, .{ .x = x, .y = y + size }, 2.0, color);
    }
    // Right
    if (getNeighborType(tiles, index, cols, .East) != .runway) {
        rl.drawLineEx(.{ .x = x + size, .y = y }, .{ .x = x + size, .y = y + size }, 2.0, color);
    }

    // 2. Centerline logic (simplified for 2-tile wide runway logic)
    // If I have a runway below me, and I am the "top" of a vertical pair (or similar logic for median)
    // For general robustness, we check: if South is runway AND North is NOT runway -> I am top edge of a block
    // This is specific to the "2-tile wide" look we established.
    const s_type = getNeighborType(tiles, index, cols, .South);
    const n_type = getNeighborType(tiles, index, cols, .North);

    if (s_type == .runway and n_type != .runway) {
        draw.drawDashedLine(.{ .x = x, .y = y + size }, .{ .x = x + size, .y = y + size }, 2.0, color, 20.0, 10.0);
    }
}

fn drawTaxiwayTile(tiles: []const Tile, index: usize, x: f32, y: f32, size: f32, cols: i32, color: rl.Color) void {
    // Configuration
    const pavement_width = size * 0.75;
    const radius = pavement_width / 2.0;
    const cx = x + size / 2.0;
    const cy = y + size / 2.0;

    // Blueprint Palette Colors
    const pavement_color = rl.Color.init(35, 65, 50, 255); // Blueprint Pavement
    const curb_color = rl.Color.init(20, 45, 35, 255); // Darker curb
    const mark_curb = rl.Color.init(10, 30, 20, 255); // Outline for the green line

    // Neighbor Check
    const n = getNeighborType(tiles, index, cols, .North) == .taxiway;
    const s = getNeighborType(tiles, index, cols, .South) == .taxiway;
    const e = getNeighborType(tiles, index, cols, .East) == .taxiway;
    const w = getNeighborType(tiles, index, cols, .West) == .taxiway;

    // --- Layer 1: Pavement Body ---
    rl.drawCircleV(.{ .x = cx, .y = cy }, radius, pavement_color);

    if (n) rl.drawRectangleV(.{ .x = cx - radius, .y = y }, .{ .x = pavement_width, .y = size / 2.0 }, pavement_color);
    if (s) rl.drawRectangleV(.{ .x = cx - radius, .y = cy }, .{ .x = pavement_width, .y = size / 2.0 }, pavement_color);
    if (e) rl.drawRectangleV(.{ .x = cx, .y = cy - radius }, .{ .x = size / 2.0, .y = pavement_width }, pavement_color);
    if (w) rl.drawRectangleV(.{ .x = x, .y = cy - radius }, .{ .x = size / 2.0, .y = pavement_width }, pavement_color);

    // --- Layer 2: Curb Edges ---
    const thick = 1.5;
    if (n) {
        rl.drawLineEx(.{ .x = cx - radius, .y = y }, .{ .x = cx - radius, .y = cy }, thick, curb_color);
        rl.drawLineEx(.{ .x = cx + radius, .y = y }, .{ .x = cx + radius, .y = cy }, thick, curb_color);
    }
    if (s) {
        rl.drawLineEx(.{ .x = cx - radius, .y = cy }, .{ .x = cx - radius, .y = y + size }, thick, curb_color);
        rl.drawLineEx(.{ .x = cx + radius, .y = cy }, .{ .x = cx + radius, .y = y + size }, thick, curb_color);
    }
    if (e) {
        rl.drawLineEx(.{ .x = cx, .y = cy - radius }, .{ .x = x + size, .y = cy - radius }, thick, curb_color);
        rl.drawLineEx(.{ .x = cx, .y = cy + radius }, .{ .x = x + size, .y = cy + radius }, thick, curb_color);
    }
    if (w) {
        rl.drawLineEx(.{ .x = x, .y = cy - radius }, .{ .x = cx, .y = cy - radius }, thick, curb_color);
        rl.drawLineEx(.{ .x = x, .y = cy + radius }, .{ .x = cx, .y = cy + radius }, thick, curb_color);
    }

    // --- Layer 3: Markings (The Green Line at the middle) ---
    // We draw with "curbing" (an outline) to make it pop
    const p_n = rl.Vector2{ .x = cx, .y = y };
    const p_s = rl.Vector2{ .x = cx, .y = y + size };
    const p_e = rl.Vector2{ .x = x + size, .y = cy };
    const p_w = rl.Vector2{ .x = x, .y = cy };

    const line_thick = 2.0;
    const curb_thick = 4.0; // Slightly thicker for the outline

    // Straight Passages with Outlines
    if (n and s and !e and !w) {
        rl.drawLineEx(p_n, p_s, curb_thick, mark_curb);
        rl.drawLineEx(p_n, p_s, line_thick, color);
        return;
    }
    if (e and w and !n and !s) {
        rl.drawLineEx(p_w, p_e, curb_thick, mark_curb);
        rl.drawLineEx(p_w, p_e, line_thick, color);
        return;
    }

    // Turns (Cubic Bezier for perfect Circular Arcs)
    // We use the magic number 0.55228475 for quarter-circle approximation
    const R = size / 2.0;
    const k = 0.55228 * R;

    if (n and e) {
        // North (Top) -> East (Right)
        // Start: Top Center (cx, y). Tangent: Down (0, 1)
        // End: Right Center (x+size, cy). Tangent: Left (-1, 0) relative to end, or Right (1, 0) if flow direction
        // CP1 = Start + (0, k)
        // CP2 = End - (k, 0)
        const cp1 = rl.Vector2{ .x = cx, .y = y + k };
        const cp2 = rl.Vector2{ .x = x + size - k, .y = cy };

        draw.drawBezierCubic(p_n, p_e, cp1, cp2, curb_thick, mark_curb);
        draw.drawBezierCubic(p_n, p_e, cp1, cp2, line_thick, color);
    }
    if (n and w) {
        // North (Top) -> West (Left)
        // CP1 = Start + (0, k)
        // CP2 = End + (k, 0)
        const cp1 = rl.Vector2{ .x = cx, .y = y + k };
        const cp2 = rl.Vector2{ .x = x + k, .y = cy };

        draw.drawBezierCubic(p_n, p_w, cp1, cp2, curb_thick, mark_curb);
        draw.drawBezierCubic(p_n, p_w, cp1, cp2, line_thick, color);
    }
    if (s and e) {
        // South (Bottom) -> East (Right)
        // CP1 = Start - (0, k)
        // CP2 = End - (k, 0)
        const cp1 = rl.Vector2{ .x = cx, .y = y + size - k };
        const cp2 = rl.Vector2{ .x = x + size - k, .y = cy };

        draw.drawBezierCubic(p_s, p_e, cp1, cp2, curb_thick, mark_curb);
        draw.drawBezierCubic(p_s, p_e, cp1, cp2, line_thick, color);
    }
    if (s and w) {
        // South (Bottom) -> West (Left)
        // CP1 = Start - (0, k)
        // CP2 = End + (k, 0)
        const cp1 = rl.Vector2{ .x = cx, .y = y + size - k };
        const cp2 = rl.Vector2{ .x = x + k, .y = cy };

        draw.drawBezierCubic(p_s, p_w, cp1, cp2, curb_thick, mark_curb);
        draw.drawBezierCubic(p_s, p_w, cp1, cp2, line_thick, color);
    }

    // Junctions
    const count = @as(u8, @intFromBool(n)) + @as(u8, @intFromBool(s)) + @as(u8, @intFromBool(e)) + @as(u8, @intFromBool(w));
    if (count != 2 or (n and s) or (e and w)) {
        if (n) {
            rl.drawLineEx(p_n, .{ .x = cx, .y = cy }, curb_thick, mark_curb);
            rl.drawLineEx(p_n, .{ .x = cx, .y = cy }, line_thick, color);
        }
        if (s) {
            rl.drawLineEx(p_s, .{ .x = cx, .y = cy }, curb_thick, mark_curb);
            rl.drawLineEx(p_s, .{ .x = cx, .y = cy }, line_thick, color);
        }
        if (e) {
            rl.drawLineEx(p_e, .{ .x = cx, .y = cy }, curb_thick, mark_curb);
            rl.drawLineEx(p_e, .{ .x = cx, .y = cy }, line_thick, color);
        }
        if (w) {
            rl.drawLineEx(p_w, .{ .x = cx, .y = cy }, curb_thick, mark_curb);
            rl.drawLineEx(p_w, .{ .x = cx, .y = cy }, line_thick, color);
        }
    }
}

fn drawTerminalTile(tiles: []const Tile, index: usize, x: f32, y: f32, size: f32, cols: i32, color: rl.Color) void {
    _ = color; // We use specific terminal colors
    // Blueprint Terminal Theme
    const fill_color = rl.Color.init(40, 60, 90, 200); // Glassy Blue
    const line_color = rl.Color.init(150, 200, 255, 255); // Blueprint Cyan
    const thick = 2.0;
    const r = size * 0.25; // Corner radius

    // Neighbor Check
    const n = isTerminalArea(getNeighborType(tiles, index, cols, .North));
    const s = isTerminalArea(getNeighborType(tiles, index, cols, .South));
    const e = isTerminalArea(getNeighborType(tiles, index, cols, .East));
    const w = isTerminalArea(getNeighborType(tiles, index, cols, .West));

    // Fill
    rl.drawRectangleV(.{ .x = x, .y = y }, .{ .x = size, .y = size }, fill_color);

    // --- Edges & Corners ---
    // Helper to draw rounded corners (Quarter Circles)
    // CP magic number for 90deg arc is 0.55228 * r
    const k = 0.55228 * r;

    // 1. Top Edge
    if (!n) {
        const start_x = if (!w) x + r else x;
        const end_x = if (!e) x + size - r else x + size;
        rl.drawLineEx(.{ .x = start_x, .y = y }, .{ .x = end_x, .y = y }, thick, line_color);
    }

    // 2. Bottom Edge
    if (!s) {
        const start_x = if (!w) x + r else x;
        const end_x = if (!e) x + size - r else x + size;
        rl.drawLineEx(.{ .x = start_x, .y = y + size }, .{ .x = end_x, .y = y + size }, thick, line_color);
    }

    // 3. Left Edge
    if (!w) {
        const start_y = if (!n) y + r else y;
        const end_y = if (!s) y + size - r else y + size;
        rl.drawLineEx(.{ .x = x, .y = start_y }, .{ .x = x, .y = end_y }, thick, line_color);
    }

    // 4. Right Edge
    if (!e) {
        const start_y = if (!n) y + r else y;
        const end_y = if (!s) y + size - r else y + size;
        rl.drawLineEx(.{ .x = x + size, .y = start_y }, .{ .x = x + size, .y = end_y }, thick, line_color);
    }

    // --- Rounded Corners (Outer) ---
    // Top-Left
    if (!n and !w) {
        const start = rl.Vector2{ .x = x, .y = y + r };
        const end = rl.Vector2{ .x = x + r, .y = y };
        const cp1 = rl.Vector2{ .x = x, .y = y + r - k };
        const cp2 = rl.Vector2{ .x = x + r - k, .y = y };
        draw.drawBezierCubic(start, end, cp1, cp2, thick, line_color);
    }
    // Top-Right
    if (!n and !e) {
        const start = rl.Vector2{ .x = x + size - r, .y = y };
        const end = rl.Vector2{ .x = x + size, .y = y + r };
        const cp1 = rl.Vector2{ .x = x + size - r + k, .y = y };
        const cp2 = rl.Vector2{ .x = x + size, .y = y + r - k };
        draw.drawBezierCubic(start, end, cp1, cp2, thick, line_color);
    }
    // Bottom-Left
    if (!s and !w) {
        const start = rl.Vector2{ .x = x, .y = y + size - r };
        const end = rl.Vector2{ .x = x + r, .y = y + size };
        const cp1 = rl.Vector2{ .x = x, .y = y + size - r + k };
        const cp2 = rl.Vector2{ .x = x + r - k, .y = y + size };
        draw.drawBezierCubic(start, end, cp1, cp2, thick, line_color);
    }
    // Bottom-Right
    if (!s and !e) {
        const start = rl.Vector2{ .x = x + size - r, .y = y + size };
        const end = rl.Vector2{ .x = x + size, .y = y + size - r };
        const cp1 = rl.Vector2{ .x = x + size - r + k, .y = y + size };
        const cp2 = rl.Vector2{ .x = x + size, .y = y + size - r + k };
        draw.drawBezierCubic(start, end, cp1, cp2, thick, line_color);
    }

    // --- Gate Specifics ---
    if (tiles[index].type == .gate) {
        const shape = tiles[index].gate_shape orelse .circle;

        // Determine Orientation (Face the Airside / Non-Terminal side)
        var gate_x = x + size / 2.0;
        var gate_y = y + size / 2.0;
        const offset = size * 0.1;

        // Face the first available open side
        if (!n) {
            gate_y -= offset;
        } else if (!s) {
            gate_y += offset;
        } else if (!e) {
            gate_x += offset;
        } else if (!w) {
            gate_x -= offset;
        }

        draw.drawGate(gate_x, gate_y, size * 0.25, shape, rl.Color.orange);
    }
}

pub fn drawTiles(tiles: []const Tile, screen_width: i32, tile_size: i32, color: rl.Color) void {
    const cols = @divTrunc(screen_width, tile_size);

    for (tiles, 0..) |tile, i| {
        if (tile.type == .empty) continue;

        const i_i32 = @as(i32, @intCast(i));
        const col = @rem(i_i32, cols);
        const row = @divTrunc(i_i32, cols);

        const x_f = @as(f32, @floatFromInt(col * tile_size));
        const y_f = @as(f32, @floatFromInt(row * tile_size));
        const size_f = @as(f32, @floatFromInt(tile_size));

        switch (tile.type) {
            .taxiway => drawTaxiwayTile(tiles, i, x_f, y_f, size_f, cols, color),
            .runway => drawRunwayTile(tiles, i, x_f, y_f, size_f, cols, color),
            .terminal, .gate => drawTerminalTile(tiles, i, x_f, y_f, size_f, cols, color),
            .empty => {},
        }
    }
}
