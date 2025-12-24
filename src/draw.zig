const std = @import("std");
const rl = @import("raylib");

pub const Shape = enum {
    triangle,
    circle,
    square,
    pentagon,
    hexagon,
};

pub fn rotatePoint(point: rl.Vector2, center: rl.Vector2, angle_deg: f32) rl.Vector2 {
    const angle_rad = angle_deg * std.math.pi / 180.0;
    const cos_a = std.math.cos(angle_rad);
    const sin_a = std.math.sin(angle_rad);

    const dx = point.x - center.x;
    const dy = point.y - center.y;

    return .{
        .x = center.x + (dx * cos_a - dy * sin_a),
        .y = center.y + (dx * sin_a + dy * cos_a),
    };
}

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

pub fn drawPlane(x: f32, y: f32, heading: f32, size: f32, color: rl.Color) void {
    const center = rl.Vector2{ .x = x, .y = y };
    const nose = rl.Vector2{ .x = x, .y = y - size };
    const rWing = rl.Vector2{ .x = x + size * 0.6, .y = y + size };
    const tail = rl.Vector2{ .x = x, .y = y + size * 0.7 };
    const lwing = rl.Vector2{ .x = x - size * 0.6, .y = y + size };

    const p1 = rotatePoint(nose, center, heading);
    const p2 = rotatePoint(rWing, center, heading);
    const p3 = rotatePoint(tail, center, heading);
    const p4 = rotatePoint(lwing, center, heading);

    rl.drawLineEx(p1, p2, 2.0, color); // Nose -> R_Wing
    rl.drawLineEx(p2, p3, 2.0, color); // R_Wing -> Tail
    rl.drawLineEx(p3, p4, 2.0, color); // Tail -> lwing
    rl.drawLineEx(p4, p1, 2.0, color); // lwing -> Nose

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

pub fn drawBezierQuad(start: rl.Vector2, end: rl.Vector2, control: rl.Vector2, thick: f32, color: rl.Color) void {
    const segments = 20;
    const step = 1.0 / @as(f32, segments);
    var t: f32 = 0;
    var previous = start;

    while (t <= 1.0) : (t += step) {
        const invT = 1.0 - t;
        // Quadratic Bezier formula: (1-t)^2 * P0 + 2(1-t)t * P1 + t^2 * P2
        const x = (invT * invT * start.x) + (2 * invT * t * control.x) + (t * t * end.x);
        const y = (invT * invT * start.y) + (2 * invT * t * control.y) + (t * t * end.y);
        const current = rl.Vector2{ .x = x, .y = y };

        rl.drawLineEx(previous, current, thick, color);
        previous = current;
    }
    rl.drawLineEx(previous, end, thick, color);
}

pub fn drawBezierCubic(start: rl.Vector2, end: rl.Vector2, cp1: rl.Vector2, cp2: rl.Vector2, thick: f32, color: rl.Color) void {
    const segments = 24;
    const step = 1.0 / @as(f32, segments);
    var t: f32 = 0;
    var previous = start;

    while (t <= 1.0) : (t += step) {
        const invT = 1.0 - t;
        const invT2 = invT * invT;
        const invT3 = invT2 * invT;
        const t2 = t * t;
        const t3 = t2 * t;

        // Cubic Bezier: (1-t)^3*P0 + 3(1-t)^2*t*P1 + 3(1-t)t^2*P2 + t^3*P3
        const x = (invT3 * start.x) + (3 * invT2 * t * cp1.x) + (3 * invT * t2 * cp2.x) + (t3 * end.x);
        const y = (invT3 * start.y) + (3 * invT2 * t * cp1.y) + (3 * invT * t2 * cp2.y) + (t3 * end.y);
        
        const current = rl.Vector2{ .x = x, .y = y };
        rl.drawLineEx(previous, current, thick, color);
        previous = current;
    }
    rl.drawLineEx(previous, end, thick, color);
}
