const std = @import("std");
const mgc = @import("mini_ground_control");
const raylib = @import("raylib");

pub fn main() !void {
    const SCREEN_WIDTH = 1920;
    const SCREEN_HEIGHT = 1080;
    const TILE_SIZE = 50;
    const resolutionBlue = raylib.Color.init(0, 32, 130, 1);
    // const royalBlue = raylib.Color.init(48, 87, 225, 255);
    // const lightRoyalBlue = raylib.Color.init(74, 109, 229, 255);
    const lavanderBlue = raylib.Color.init(206, 216, 247, 1);
    const lavanderBlueGrid = lavanderBlue.alpha(0.2);
    raylib.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Mini Ground Control");
    while (!raylib.windowShouldClose()) {
        raylib.beginDrawing();
        raylib.clearBackground(resolutionBlue);
        mgc.drawDashedGrid(SCREEN_WIDTH, SCREEN_HEIGHT, TILE_SIZE, 1.0, lavanderBlueGrid);
        raylib.endDrawing();
    }
}
