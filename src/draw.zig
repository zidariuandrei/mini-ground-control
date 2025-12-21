const std = @import("std");
const rl = @import("raylib");

pub const Shape = enum {
    triangle,
    circle,
    square,
    pentagon,
    hexagon,
};

pub fn drawPlane(x: f32, y: f32, heading: f32, size: f32, color: rl.Color) void {
    const nose = rl.Vector2{ .x = 0, .y = -size };
    const rWing = rl.Vector2{ .x = size * 0.6, .y = size };
    const tail = rl.Vector2{ .x = 0, .y = size * 0.7 };
    const lwing = rl.Vector2{ .x = -size * 0.6, .y = size };

    const angleRad = heading * std.math.pi / 180.0;
    const cosA = std.math.cos(angleRad);
    const sinA = std.math.sin(angleRad);
    const rot = struct {
        fn apply(v: rl.Vector2, c: f32, s: f32, cx: f32, cy: f32) rl.Vector2 {
            return .{
                .x = cx + (v.x * c - v.y * s),
                .y = cy + (v.x * s + v.y * c),
            };
        }
    };

    const p1 = rot.apply(nose, cosA, sinA, x, y);
    const p2 = rot.apply(rWing, cosA, sinA, x, y);
    const p3 = rot.apply(tail, cosA, sinA, x, y);
    const p4 = rot.apply(lwing, cosA, sinA, x, y);

    // 3. Draw the lines
    // Outline
    rl.drawLineEx(p1, p2, 2.0, color); // Nose -> R_Wing
    rl.drawLineEx(p2, p3, 2.0, color); // R_Wing -> Tail
    rl.drawLineEx(p3, p4, 2.0, color); // Tail -> lwing
    rl.drawLineEx(p4, p1, 2.0, color); // lwing -> Nose

    // Center fold (optional, adds detail)
    rl.drawLineEx(p1, p3, 1.0, color);
}

pub fn drawGate(x: f32, y: f32, size: f32, shape: Shape, color: rl.Color) void {
    const pos = rl.Vector2{ .x = x, .y = y };
    switch (shape) {
        .circle => {
            rl.drawCircleV(pos, size, color);
        },
        .square => {
            rl.drawRectangleV(rl.Vector2{ .x = x - size, .y = y - size }, rl.Vector2{ .x = size * 2.0, .y = size * 2.0 }, color);
        },
        .triangle => {
            rl.drawPoly(pos, 3, size * 1.2, 0, color);
        },
        .pentagon => {
            rl.drawPoly(pos, 5, size * 1.2, 0, color);
        },
        .hexagon => {
            rl.drawPoly(pos, 6, size * 1.2, 0, color);
        },
    }
}
