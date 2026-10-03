import Testing
import CoreFoundation
@testable import MicropolisMac

struct TileAtlasTests {
    @Test
    func loadAndCropTiles() throws {
        let atlasURL = Assets.tileAtlas
        let atlas = try TileAtlas(atlasURL: atlasURL)

        #expect(atlas.tileCount == 1024)
        #expect(atlas.tileSize == 16)
        #expect(atlas.tilesPerRow == 32)
    }

    @Test
    func tile0IsNotFullyTransparent() throws {
        let atlasURL = Assets.tileAtlas
        let atlas = try TileAtlas(atlasURL: atlasURL)

        let tile0 = atlas.image(for: 0)
        #expect(tile0.width == 16)
        #expect(tile0.height == 16)

        var foundNonTransparent = false
        if let pixelData = tile0.dataProvider?.data {
            let bytes = CFDataGetBytePtr(pixelData)
            let dataLength = CFDataGetLength(pixelData)
            for i in stride(from: 3, to: dataLength, by: 4) {
                if bytes?[i] ?? 0 > 0 {
                    foundNonTransparent = true
                    break
                }
            }
        }

        #expect(foundNonTransparent)
    }

    @Test
    func tile1023DoesNotCrash() throws {
        let atlasURL = Assets.tileAtlas
        let atlas = try TileAtlas(atlasURL: atlasURL)

        let tile1023 = atlas.image(for: 1023)
        #expect(tile1023.width == 16)
        #expect(tile1023.height == 16)
    }

    @Test
    func atlasHasRawBytes() throws {
        let atlasURL = Assets.tileAtlas
        let atlas = try TileAtlas(atlasURL: atlasURL)

        let bytes = atlas.bytes
        let expectedSize = 512 * 512 * 4
        #expect(bytes.count == expectedSize)
    }
}
