const std = @import("std");
const mgc = @import("mini_ground_control");
const rl = @import("raylib");

pub fn main() !void {
    const SCREEN_WIDTH = 1920;
    const SCREEN_HEIGHT = 1080;
    const TILE_SIZE = 50;

    const blueprintDark = rl.Color.init(15, 32, 24, 255);
    const blueprintGrid = rl.Color.init(50, 100, 80, 80);
    const blueprintMint = rl.Color.init(120, 255, 180, 255);
    const royalGreen = rl.Color.init(30, 60, 45, 255);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const tiles = try mgc.initTiles(allocator, SCREEN_WIDTH, SCREEN_HEIGHT, TILE_SIZE);
    mgc.markRunway(tiles, SCREEN_WIDTH, TILE_SIZE, 7, 19, 16, 2);
    // Add a terminal block (4x3) to demonstrate the smart border logic
    mgc.markTerminal(tiles, SCREEN_WIDTH, TILE_SIZE, 10, 10, 4, 3);
    
    // Add Gates
    const cols = @divTrunc(SCREEN_WIDTH, TILE_SIZE);
    // Gate 1: Top Edge (Row 10, Col 11)
    mgc.setGate(tiles, @intCast(10 * cols + 11), .circle);
    // Gate 2: Right Edge (Row 11, Col 13)
    mgc.setGate(tiles, @intCast(11 * cols + 13), .triangle);

    defer allocator.free(tiles);
    rl.setConfigFlags(rl.ConfigFlags{ .msaa_4x_hint = true });
    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Mini Ground Control");
    const noiseImage = rl.genImageWhiteNoise(SCREEN_WIDTH, SCREEN_HEIGHT, 0.5);

    const paperTexture = try rl.loadTextureFromImage(noiseImage);

    rl.unloadImage(noiseImage);
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        rl.clearBackground(blueprintDark);

        mgc.drawTiles(tiles, SCREEN_WIDTH, TILE_SIZE, blueprintMint);
        mgc.drawDashedGrid(SCREEN_WIDTH, SCREEN_HEIGHT, TILE_SIZE, 1.0, blueprintGrid);

        if (rl.isMouseButtonPressed(.left)) {
            const mousePos = rl.getMousePosition();
            const clickedTile = mgc.posToTile(SCREEN_WIDTH, TILE_SIZE, mousePos);
            mgc.setAsTaxiway(tiles, clickedTile);
            std.debug.print("clicked at: x->{}, y->{}\n", .{ mousePos.x, mousePos.y });
            std.debug.print("pos {} {}\n", .{ clickedTile, tiles[clickedTile] });
        }

        rl.drawTexture(paperTexture, 0, 0, rl.fade(royalGreen, 0.1));
        rl.drawCircleGradient(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2, @as(f32, @floatFromInt(SCREEN_HEIGHT)) * 1.1, rl.fade(rl.Color.blank, 0), rl.fade(rl.Color.blank, 0.6));
        rl.endDrawing();
    }
}
