const std = @import("std");
const mgc = @import("mini_ground_control");
const rl = @import("raylib");

pub fn main() !void {
    const SCREEN_WIDTH = 1920;
    const SCREEN_HEIGHT = 1080;
    const TILE_SIZE = 50;

    const resolutionBlue = rl.Color.init(0, 32, 130, 1);
    const royalBlue = rl.Color.init(48, 87, 225, 255);
    // const lightRoyalBlue = rl.Color.init(74, 109, 229, 255);
    const lavanderBlue = rl.Color.init(206, 216, 247, 1);
    const lavanderBlueGrid = lavanderBlue.alpha(0.2);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const tiles = try mgc.initTiles(allocator, SCREEN_WIDTH, SCREEN_HEIGHT, TILE_SIZE);

    defer allocator.free(tiles);

    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Mini Ground Control");
    const noiseImage = rl.genImageWhiteNoise(SCREEN_WIDTH, SCREEN_HEIGHT, 0.5);

    const paperTexture = try rl.loadTextureFromImage(noiseImage);

    rl.unloadImage(noiseImage);
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        rl.clearBackground(resolutionBlue);
        mgc.drawDashedGrid(SCREEN_WIDTH, SCREEN_HEIGHT, TILE_SIZE, 1.0, lavanderBlueGrid);
        if (rl.isMouseButtonPressed(.left)) {
            const mousePos = rl.getMousePosition();
            const clickedTile = mgc.posToTile(SCREEN_WIDTH, TILE_SIZE, mousePos);
            mgc.setAsTaxiway(tiles, clickedTile);
            std.debug.print("clicked at: x->{}, y->{}\n", .{ mousePos.x, mousePos.y });
            std.debug.print("pos {} {}\n", .{ clickedTile, tiles[clickedTile] });
        }

        rl.drawTexture(paperTexture, 0, 0, rl.fade(royalBlue, 0.08));
        // Draw this last, after all planes and taxiways
        rl.drawCircleGradient(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2, @as(f32, @floatFromInt(SCREEN_HEIGHT)) * 1.1, rl.fade(rl.Color.blank, 0), // Center
            rl.fade(rl.Color.blank, 0.6) // Outer edge (alpha 0.4 for subtlety)
        );
        rl.endDrawing();
    }
}
