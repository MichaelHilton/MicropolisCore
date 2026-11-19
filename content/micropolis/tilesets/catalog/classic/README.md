# Original Micropolis tile catalog

Original artwork from the [classic atlas](../../png/classic.png), with **one complete building or zone per row**. Its component tiles are assembled in the same order used by the engine, rather than shown as separate fragments. Standalone tiles retain their own rows.

This table contains **64 assembled groups** and **386 standalone tiles**, covering all **1,024 source tile IDs** exactly once. All images are enlarged **4× without smoothing**: each source tile remains an exact 16 × 16 pixel image. The original atlas has not been modified.

The **Tile IDs** column identifies every component in a group; **Footprint** is measured in map tiles. Value tiers and density levels are numbered from 1 for readability and follow the engine’s variant ordering. Alternative single-tile animation frames remain separate rows; consecutive animation frames are not spatial building fragments.

Group boundaries and dimensions follow the engine’s [`Tiles` enum](../../../../../packages/micropolis-engine/src/micropolis.h), [zone placement](../../../../../packages/micropolis-engine/src/zone.cpp), and [building definitions](../../../../../packages/micropolis-engine/src/tool.cpp). Engine names include range markers and aliases; “—” means no explicit individual name.

For the unassembled reference, see [every original tile individually](ALL-TILES.md).

| Tile IDs | Original graphic (4× preview) | Building / tile | Footprint | Engine name(s) |
| --- | :---: | --- | :---: | --- |
| 0 | ![Standalone tile, tiles 0](tiles/tile-0000.png) | Standalone tile | 1 × 1 | `DIRT` |
| 1 | ![Standalone tile, tiles 1](tiles/tile-0001.png) | Standalone tile | 1 × 1 | — |
| 2 | ![Standalone tile, tiles 2](tiles/tile-0002.png) | Standalone tile | 1 × 1 | `RIVER`, `WATER_LOW` |
| 3 | ![Standalone tile, tiles 3](tiles/tile-0003.png) | Standalone tile | 1 × 1 | `REDGE` |
| 4 | ![Standalone tile, tiles 4](tiles/tile-0004.png) | Standalone tile | 1 × 1 | `CHANNEL` |
| 5 | ![Standalone tile, tiles 5](tiles/tile-0005.png) | Standalone tile | 1 × 1 | `FIRSTRIVEDGE` |
| 6 | ![Standalone tile, tiles 6](tiles/tile-0006.png) | Standalone tile | 1 × 1 | — |
| 7 | ![Standalone tile, tiles 7](tiles/tile-0007.png) | Standalone tile | 1 × 1 | — |
| 8 | ![Standalone tile, tiles 8](tiles/tile-0008.png) | Standalone tile | 1 × 1 | — |
| 9 | ![Standalone tile, tiles 9](tiles/tile-0009.png) | Standalone tile | 1 × 1 | — |
| 10 | ![Standalone tile, tiles 10](tiles/tile-0010.png) | Standalone tile | 1 × 1 | — |
| 11 | ![Standalone tile, tiles 11](tiles/tile-0011.png) | Standalone tile | 1 × 1 | — |
| 12 | ![Standalone tile, tiles 12](tiles/tile-0012.png) | Standalone tile | 1 × 1 | — |
| 13 | ![Standalone tile, tiles 13](tiles/tile-0013.png) | Standalone tile | 1 × 1 | — |
| 14 | ![Standalone tile, tiles 14](tiles/tile-0014.png) | Standalone tile | 1 × 1 | — |
| 15 | ![Standalone tile, tiles 15](tiles/tile-0015.png) | Standalone tile | 1 × 1 | — |
| 16 | ![Standalone tile, tiles 16](tiles/tile-0016.png) | Standalone tile | 1 × 1 | — |
| 17 | ![Standalone tile, tiles 17](tiles/tile-0017.png) | Standalone tile | 1 × 1 | — |
| 18 | ![Standalone tile, tiles 18](tiles/tile-0018.png) | Standalone tile | 1 × 1 | — |
| 19 | ![Standalone tile, tiles 19](tiles/tile-0019.png) | Standalone tile | 1 × 1 | — |
| 20 | ![Standalone tile, tiles 20](tiles/tile-0020.png) | Standalone tile | 1 × 1 | `LASTRIVEDGE`, `WATER_HIGH` |
| 21 | ![Standalone tile, tiles 21](tiles/tile-0021.png) | Standalone tile | 1 × 1 | `TREEBASE`, `WOODS_LOW` |
| 22 | ![Standalone tile, tiles 22](tiles/tile-0022.png) | Standalone tile | 1 × 1 | — |
| 23 | ![Standalone tile, tiles 23](tiles/tile-0023.png) | Standalone tile | 1 × 1 | — |
| 24 | ![Standalone tile, tiles 24](tiles/tile-0024.png) | Standalone tile | 1 × 1 | — |
| 25 | ![Standalone tile, tiles 25](tiles/tile-0025.png) | Standalone tile | 1 × 1 | — |
| 26 | ![Standalone tile, tiles 26](tiles/tile-0026.png) | Standalone tile | 1 × 1 | — |
| 27 | ![Standalone tile, tiles 27](tiles/tile-0027.png) | Standalone tile | 1 × 1 | — |
| 28 | ![Standalone tile, tiles 28](tiles/tile-0028.png) | Standalone tile | 1 × 1 | — |
| 29 | ![Standalone tile, tiles 29](tiles/tile-0029.png) | Standalone tile | 1 × 1 | — |
| 30 | ![Standalone tile, tiles 30](tiles/tile-0030.png) | Standalone tile | 1 × 1 | — |
| 31 | ![Standalone tile, tiles 31](tiles/tile-0031.png) | Standalone tile | 1 × 1 | — |
| 32 | ![Standalone tile, tiles 32](tiles/tile-0032.png) | Standalone tile | 1 × 1 | — |
| 33 | ![Standalone tile, tiles 33](tiles/tile-0033.png) | Standalone tile | 1 × 1 | — |
| 34 | ![Standalone tile, tiles 34](tiles/tile-0034.png) | Standalone tile | 1 × 1 | — |
| 35 | ![Standalone tile, tiles 35](tiles/tile-0035.png) | Standalone tile | 1 × 1 | — |
| 36 | ![Standalone tile, tiles 36](tiles/tile-0036.png) | Standalone tile | 1 × 1 | `LASTTREE` |
| 37 | ![Standalone tile, tiles 37](tiles/tile-0037.png) | Standalone tile | 1 × 1 | `WOODS` |
| 38 | ![Standalone tile, tiles 38](tiles/tile-0038.png) | Standalone tile | 1 × 1 | `UNUSED_TRASH1` |
| 39 | ![Standalone tile, tiles 39](tiles/tile-0039.png) | Standalone tile | 1 × 1 | `UNUSED_TRASH2`, `WOODS_HIGH` |
| 40 | ![Standalone tile, tiles 40](tiles/tile-0040.png) | Standalone tile | 1 × 1 | `WOODS2` |
| 41 | ![Standalone tile, tiles 41](tiles/tile-0041.png) | Standalone tile | 1 × 1 | `WOODS3` |
| 42 | ![Standalone tile, tiles 42](tiles/tile-0042.png) | Standalone tile | 1 × 1 | `WOODS4` |
| 43 | ![Standalone tile, tiles 43](tiles/tile-0043.png) | Standalone tile | 1 × 1 | `WOODS5` |
| 44 | ![Standalone tile, tiles 44](tiles/tile-0044.png) | Standalone tile | 1 × 1 | `RUBBLE` |
| 45 | ![Standalone tile, tiles 45](tiles/tile-0045.png) | Standalone tile | 1 × 1 | — |
| 46 | ![Standalone tile, tiles 46](tiles/tile-0046.png) | Standalone tile | 1 × 1 | — |
| 47 | ![Standalone tile, tiles 47](tiles/tile-0047.png) | Standalone tile | 1 × 1 | `LASTRUBBLE` |
| 48 | ![Standalone tile, tiles 48](tiles/tile-0048.png) | Standalone tile | 1 × 1 | `FLOOD` |
| 49 | ![Standalone tile, tiles 49](tiles/tile-0049.png) | Standalone tile | 1 × 1 | — |
| 50 | ![Standalone tile, tiles 50](tiles/tile-0050.png) | Standalone tile | 1 × 1 | — |
| 51 | ![Standalone tile, tiles 51](tiles/tile-0051.png) | Standalone tile | 1 × 1 | `LASTFLOOD` |
| 52 | ![Standalone tile, tiles 52](tiles/tile-0052.png) | Standalone tile | 1 × 1 | `RADTILE` |
| 53 | ![Standalone tile, tiles 53](tiles/tile-0053.png) | Standalone tile | 1 × 1 | `UNUSED_TRASH3` |
| 54 | ![Standalone tile, tiles 54](tiles/tile-0054.png) | Standalone tile | 1 × 1 | `UNUSED_TRASH4` |
| 55 | ![Standalone tile, tiles 55](tiles/tile-0055.png) | Standalone tile | 1 × 1 | `UNUSED_TRASH5` |
| 56 | ![Standalone tile, tiles 56](tiles/tile-0056.png) | Standalone tile | 1 × 1 | `FIRE`, `FIREBASE` |
| 57 | ![Standalone tile, tiles 57](tiles/tile-0057.png) | Standalone tile | 1 × 1 | — |
| 58 | ![Standalone tile, tiles 58](tiles/tile-0058.png) | Standalone tile | 1 × 1 | — |
| 59 | ![Standalone tile, tiles 59](tiles/tile-0059.png) | Standalone tile | 1 × 1 | — |
| 60 | ![Standalone tile, tiles 60](tiles/tile-0060.png) | Standalone tile | 1 × 1 | — |
| 61 | ![Standalone tile, tiles 61](tiles/tile-0061.png) | Standalone tile | 1 × 1 | — |
| 62 | ![Standalone tile, tiles 62](tiles/tile-0062.png) | Standalone tile | 1 × 1 | — |
| 63 | ![Standalone tile, tiles 63](tiles/tile-0063.png) | Standalone tile | 1 × 1 | `LASTFIRE` |
| 64 | ![Standalone tile, tiles 64](tiles/tile-0064.png) | Standalone tile | 1 × 1 | `HBRIDGE`, `ROADBASE` |
| 65 | ![Standalone tile, tiles 65](tiles/tile-0065.png) | Standalone tile | 1 × 1 | `VBRIDGE` |
| 66 | ![Standalone tile, tiles 66](tiles/tile-0066.png) | Standalone tile | 1 × 1 | `ROADS` |
| 67 | ![Standalone tile, tiles 67](tiles/tile-0067.png) | Standalone tile | 1 × 1 | `ROADS2` |
| 68 | ![Standalone tile, tiles 68](tiles/tile-0068.png) | Standalone tile | 1 × 1 | `ROADS3` |
| 69 | ![Standalone tile, tiles 69](tiles/tile-0069.png) | Standalone tile | 1 × 1 | `ROADS4` |
| 70 | ![Standalone tile, tiles 70](tiles/tile-0070.png) | Standalone tile | 1 × 1 | `ROADS5` |
| 71 | ![Standalone tile, tiles 71](tiles/tile-0071.png) | Standalone tile | 1 × 1 | `ROADS6` |
| 72 | ![Standalone tile, tiles 72](tiles/tile-0072.png) | Standalone tile | 1 × 1 | `ROADS7` |
| 73 | ![Standalone tile, tiles 73](tiles/tile-0073.png) | Standalone tile | 1 × 1 | `ROADS8` |
| 74 | ![Standalone tile, tiles 74](tiles/tile-0074.png) | Standalone tile | 1 × 1 | `ROADS9` |
| 75 | ![Standalone tile, tiles 75](tiles/tile-0075.png) | Standalone tile | 1 × 1 | `ROADS10` |
| 76 | ![Standalone tile, tiles 76](tiles/tile-0076.png) | Standalone tile | 1 × 1 | `INTERSECTION` |
| 77 | ![Standalone tile, tiles 77](tiles/tile-0077.png) | Standalone tile | 1 × 1 | `HROADPOWER` |
| 78 | ![Standalone tile, tiles 78](tiles/tile-0078.png) | Standalone tile | 1 × 1 | `VROADPOWER` |
| 79 | ![Standalone tile, tiles 79](tiles/tile-0079.png) | Standalone tile | 1 × 1 | `BRWH` |
| 80 | ![Standalone tile, tiles 80](tiles/tile-0080.png) | Standalone tile | 1 × 1 | `LTRFBASE` |
| 81 | ![Standalone tile, tiles 81](tiles/tile-0081.png) | Standalone tile | 1 × 1 | — |
| 82 | ![Standalone tile, tiles 82](tiles/tile-0082.png) | Standalone tile | 1 × 1 | — |
| 83 | ![Standalone tile, tiles 83](tiles/tile-0083.png) | Standalone tile | 1 × 1 | — |
| 84 | ![Standalone tile, tiles 84](tiles/tile-0084.png) | Standalone tile | 1 × 1 | — |
| 85 | ![Standalone tile, tiles 85](tiles/tile-0085.png) | Standalone tile | 1 × 1 | — |
| 86 | ![Standalone tile, tiles 86](tiles/tile-0086.png) | Standalone tile | 1 × 1 | — |
| 87 | ![Standalone tile, tiles 87](tiles/tile-0087.png) | Standalone tile | 1 × 1 | — |
| 88 | ![Standalone tile, tiles 88](tiles/tile-0088.png) | Standalone tile | 1 × 1 | — |
| 89 | ![Standalone tile, tiles 89](tiles/tile-0089.png) | Standalone tile | 1 × 1 | — |
| 90 | ![Standalone tile, tiles 90](tiles/tile-0090.png) | Standalone tile | 1 × 1 | — |
| 91 | ![Standalone tile, tiles 91](tiles/tile-0091.png) | Standalone tile | 1 × 1 | — |
| 92 | ![Standalone tile, tiles 92](tiles/tile-0092.png) | Standalone tile | 1 × 1 | — |
| 93 | ![Standalone tile, tiles 93](tiles/tile-0093.png) | Standalone tile | 1 × 1 | — |
| 94 | ![Standalone tile, tiles 94](tiles/tile-0094.png) | Standalone tile | 1 × 1 | — |
| 95 | ![Standalone tile, tiles 95](tiles/tile-0095.png) | Standalone tile | 1 × 1 | `BRWV` |
| 96 | ![Standalone tile, tiles 96](tiles/tile-0096.png) | Standalone tile | 1 × 1 | — |
| 97 | ![Standalone tile, tiles 97](tiles/tile-0097.png) | Standalone tile | 1 × 1 | — |
| 98 | ![Standalone tile, tiles 98](tiles/tile-0098.png) | Standalone tile | 1 × 1 | — |
| 99 | ![Standalone tile, tiles 99](tiles/tile-0099.png) | Standalone tile | 1 × 1 | — |
| 100 | ![Standalone tile, tiles 100](tiles/tile-0100.png) | Standalone tile | 1 × 1 | — |
| 101 | ![Standalone tile, tiles 101](tiles/tile-0101.png) | Standalone tile | 1 × 1 | — |
| 102 | ![Standalone tile, tiles 102](tiles/tile-0102.png) | Standalone tile | 1 × 1 | — |
| 103 | ![Standalone tile, tiles 103](tiles/tile-0103.png) | Standalone tile | 1 × 1 | — |
| 104 | ![Standalone tile, tiles 104](tiles/tile-0104.png) | Standalone tile | 1 × 1 | — |
| 105 | ![Standalone tile, tiles 105](tiles/tile-0105.png) | Standalone tile | 1 × 1 | — |
| 106 | ![Standalone tile, tiles 106](tiles/tile-0106.png) | Standalone tile | 1 × 1 | — |
| 107 | ![Standalone tile, tiles 107](tiles/tile-0107.png) | Standalone tile | 1 × 1 | — |
| 108 | ![Standalone tile, tiles 108](tiles/tile-0108.png) | Standalone tile | 1 × 1 | — |
| 109 | ![Standalone tile, tiles 109](tiles/tile-0109.png) | Standalone tile | 1 × 1 | — |
| 110 | ![Standalone tile, tiles 110](tiles/tile-0110.png) | Standalone tile | 1 × 1 | — |
| 111 | ![Standalone tile, tiles 111](tiles/tile-0111.png) | Standalone tile | 1 × 1 | `BRWXXX1` |
| 112 | ![Standalone tile, tiles 112](tiles/tile-0112.png) | Standalone tile | 1 × 1 | — |
| 113 | ![Standalone tile, tiles 113](tiles/tile-0113.png) | Standalone tile | 1 × 1 | — |
| 114 | ![Standalone tile, tiles 114](tiles/tile-0114.png) | Standalone tile | 1 × 1 | — |
| 115 | ![Standalone tile, tiles 115](tiles/tile-0115.png) | Standalone tile | 1 × 1 | — |
| 116 | ![Standalone tile, tiles 116](tiles/tile-0116.png) | Standalone tile | 1 × 1 | — |
| 117 | ![Standalone tile, tiles 117](tiles/tile-0117.png) | Standalone tile | 1 × 1 | — |
| 118 | ![Standalone tile, tiles 118](tiles/tile-0118.png) | Standalone tile | 1 × 1 | — |
| 119 | ![Standalone tile, tiles 119](tiles/tile-0119.png) | Standalone tile | 1 × 1 | — |
| 120 | ![Standalone tile, tiles 120](tiles/tile-0120.png) | Standalone tile | 1 × 1 | — |
| 121 | ![Standalone tile, tiles 121](tiles/tile-0121.png) | Standalone tile | 1 × 1 | — |
| 122 | ![Standalone tile, tiles 122](tiles/tile-0122.png) | Standalone tile | 1 × 1 | — |
| 123 | ![Standalone tile, tiles 123](tiles/tile-0123.png) | Standalone tile | 1 × 1 | — |
| 124 | ![Standalone tile, tiles 124](tiles/tile-0124.png) | Standalone tile | 1 × 1 | — |
| 125 | ![Standalone tile, tiles 125](tiles/tile-0125.png) | Standalone tile | 1 × 1 | — |
| 126 | ![Standalone tile, tiles 126](tiles/tile-0126.png) | Standalone tile | 1 × 1 | — |
| 127 | ![Standalone tile, tiles 127](tiles/tile-0127.png) | Standalone tile | 1 × 1 | `BRWXXX2` |
| 128 | ![Standalone tile, tiles 128](tiles/tile-0128.png) | Standalone tile | 1 × 1 | — |
| 129 | ![Standalone tile, tiles 129](tiles/tile-0129.png) | Standalone tile | 1 × 1 | — |
| 130 | ![Standalone tile, tiles 130](tiles/tile-0130.png) | Standalone tile | 1 × 1 | — |
| 131 | ![Standalone tile, tiles 131](tiles/tile-0131.png) | Standalone tile | 1 × 1 | — |
| 132 | ![Standalone tile, tiles 132](tiles/tile-0132.png) | Standalone tile | 1 × 1 | — |
| 133 | ![Standalone tile, tiles 133](tiles/tile-0133.png) | Standalone tile | 1 × 1 | — |
| 134 | ![Standalone tile, tiles 134](tiles/tile-0134.png) | Standalone tile | 1 × 1 | — |
| 135 | ![Standalone tile, tiles 135](tiles/tile-0135.png) | Standalone tile | 1 × 1 | — |
| 136 | ![Standalone tile, tiles 136](tiles/tile-0136.png) | Standalone tile | 1 × 1 | — |
| 137 | ![Standalone tile, tiles 137](tiles/tile-0137.png) | Standalone tile | 1 × 1 | — |
| 138 | ![Standalone tile, tiles 138](tiles/tile-0138.png) | Standalone tile | 1 × 1 | — |
| 139 | ![Standalone tile, tiles 139](tiles/tile-0139.png) | Standalone tile | 1 × 1 | — |
| 140 | ![Standalone tile, tiles 140](tiles/tile-0140.png) | Standalone tile | 1 × 1 | — |
| 141 | ![Standalone tile, tiles 141](tiles/tile-0141.png) | Standalone tile | 1 × 1 | — |
| 142 | ![Standalone tile, tiles 142](tiles/tile-0142.png) | Standalone tile | 1 × 1 | — |
| 143 | ![Standalone tile, tiles 143](tiles/tile-0143.png) | Standalone tile | 1 × 1 | `BRWXXX3` |
| 144 | ![Standalone tile, tiles 144](tiles/tile-0144.png) | Standalone tile | 1 × 1 | `HTRFBASE` |
| 145 | ![Standalone tile, tiles 145](tiles/tile-0145.png) | Standalone tile | 1 × 1 | — |
| 146 | ![Standalone tile, tiles 146](tiles/tile-0146.png) | Standalone tile | 1 × 1 | — |
| 147 | ![Standalone tile, tiles 147](tiles/tile-0147.png) | Standalone tile | 1 × 1 | — |
| 148 | ![Standalone tile, tiles 148](tiles/tile-0148.png) | Standalone tile | 1 × 1 | — |
| 149 | ![Standalone tile, tiles 149](tiles/tile-0149.png) | Standalone tile | 1 × 1 | — |
| 150 | ![Standalone tile, tiles 150](tiles/tile-0150.png) | Standalone tile | 1 × 1 | — |
| 151 | ![Standalone tile, tiles 151](tiles/tile-0151.png) | Standalone tile | 1 × 1 | — |
| 152 | ![Standalone tile, tiles 152](tiles/tile-0152.png) | Standalone tile | 1 × 1 | — |
| 153 | ![Standalone tile, tiles 153](tiles/tile-0153.png) | Standalone tile | 1 × 1 | — |
| 154 | ![Standalone tile, tiles 154](tiles/tile-0154.png) | Standalone tile | 1 × 1 | — |
| 155 | ![Standalone tile, tiles 155](tiles/tile-0155.png) | Standalone tile | 1 × 1 | — |
| 156 | ![Standalone tile, tiles 156](tiles/tile-0156.png) | Standalone tile | 1 × 1 | — |
| 157 | ![Standalone tile, tiles 157](tiles/tile-0157.png) | Standalone tile | 1 × 1 | — |
| 158 | ![Standalone tile, tiles 158](tiles/tile-0158.png) | Standalone tile | 1 × 1 | — |
| 159 | ![Standalone tile, tiles 159](tiles/tile-0159.png) | Standalone tile | 1 × 1 | `BRWXXX4` |
| 160 | ![Standalone tile, tiles 160](tiles/tile-0160.png) | Standalone tile | 1 × 1 | — |
| 161 | ![Standalone tile, tiles 161](tiles/tile-0161.png) | Standalone tile | 1 × 1 | — |
| 162 | ![Standalone tile, tiles 162](tiles/tile-0162.png) | Standalone tile | 1 × 1 | — |
| 163 | ![Standalone tile, tiles 163](tiles/tile-0163.png) | Standalone tile | 1 × 1 | — |
| 164 | ![Standalone tile, tiles 164](tiles/tile-0164.png) | Standalone tile | 1 × 1 | — |
| 165 | ![Standalone tile, tiles 165](tiles/tile-0165.png) | Standalone tile | 1 × 1 | — |
| 166 | ![Standalone tile, tiles 166](tiles/tile-0166.png) | Standalone tile | 1 × 1 | — |
| 167 | ![Standalone tile, tiles 167](tiles/tile-0167.png) | Standalone tile | 1 × 1 | — |
| 168 | ![Standalone tile, tiles 168](tiles/tile-0168.png) | Standalone tile | 1 × 1 | — |
| 169 | ![Standalone tile, tiles 169](tiles/tile-0169.png) | Standalone tile | 1 × 1 | — |
| 170 | ![Standalone tile, tiles 170](tiles/tile-0170.png) | Standalone tile | 1 × 1 | — |
| 171 | ![Standalone tile, tiles 171](tiles/tile-0171.png) | Standalone tile | 1 × 1 | — |
| 172 | ![Standalone tile, tiles 172](tiles/tile-0172.png) | Standalone tile | 1 × 1 | — |
| 173 | ![Standalone tile, tiles 173](tiles/tile-0173.png) | Standalone tile | 1 × 1 | — |
| 174 | ![Standalone tile, tiles 174](tiles/tile-0174.png) | Standalone tile | 1 × 1 | — |
| 175 | ![Standalone tile, tiles 175](tiles/tile-0175.png) | Standalone tile | 1 × 1 | `BRWXXX5` |
| 176 | ![Standalone tile, tiles 176](tiles/tile-0176.png) | Standalone tile | 1 × 1 | — |
| 177 | ![Standalone tile, tiles 177](tiles/tile-0177.png) | Standalone tile | 1 × 1 | — |
| 178 | ![Standalone tile, tiles 178](tiles/tile-0178.png) | Standalone tile | 1 × 1 | — |
| 179 | ![Standalone tile, tiles 179](tiles/tile-0179.png) | Standalone tile | 1 × 1 | — |
| 180 | ![Standalone tile, tiles 180](tiles/tile-0180.png) | Standalone tile | 1 × 1 | — |
| 181 | ![Standalone tile, tiles 181](tiles/tile-0181.png) | Standalone tile | 1 × 1 | — |
| 182 | ![Standalone tile, tiles 182](tiles/tile-0182.png) | Standalone tile | 1 × 1 | — |
| 183 | ![Standalone tile, tiles 183](tiles/tile-0183.png) | Standalone tile | 1 × 1 | — |
| 184 | ![Standalone tile, tiles 184](tiles/tile-0184.png) | Standalone tile | 1 × 1 | — |
| 185 | ![Standalone tile, tiles 185](tiles/tile-0185.png) | Standalone tile | 1 × 1 | — |
| 186 | ![Standalone tile, tiles 186](tiles/tile-0186.png) | Standalone tile | 1 × 1 | — |
| 187 | ![Standalone tile, tiles 187](tiles/tile-0187.png) | Standalone tile | 1 × 1 | — |
| 188 | ![Standalone tile, tiles 188](tiles/tile-0188.png) | Standalone tile | 1 × 1 | — |
| 189 | ![Standalone tile, tiles 189](tiles/tile-0189.png) | Standalone tile | 1 × 1 | — |
| 190 | ![Standalone tile, tiles 190](tiles/tile-0190.png) | Standalone tile | 1 × 1 | — |
| 191 | ![Standalone tile, tiles 191](tiles/tile-0191.png) | Standalone tile | 1 × 1 | `BRWXXX6` |
| 192 | ![Standalone tile, tiles 192](tiles/tile-0192.png) | Standalone tile | 1 × 1 | — |
| 193 | ![Standalone tile, tiles 193](tiles/tile-0193.png) | Standalone tile | 1 × 1 | — |
| 194 | ![Standalone tile, tiles 194](tiles/tile-0194.png) | Standalone tile | 1 × 1 | — |
| 195 | ![Standalone tile, tiles 195](tiles/tile-0195.png) | Standalone tile | 1 × 1 | — |
| 196 | ![Standalone tile, tiles 196](tiles/tile-0196.png) | Standalone tile | 1 × 1 | — |
| 197 | ![Standalone tile, tiles 197](tiles/tile-0197.png) | Standalone tile | 1 × 1 | — |
| 198 | ![Standalone tile, tiles 198](tiles/tile-0198.png) | Standalone tile | 1 × 1 | — |
| 199 | ![Standalone tile, tiles 199](tiles/tile-0199.png) | Standalone tile | 1 × 1 | — |
| 200 | ![Standalone tile, tiles 200](tiles/tile-0200.png) | Standalone tile | 1 × 1 | — |
| 201 | ![Standalone tile, tiles 201](tiles/tile-0201.png) | Standalone tile | 1 × 1 | — |
| 202 | ![Standalone tile, tiles 202](tiles/tile-0202.png) | Standalone tile | 1 × 1 | — |
| 203 | ![Standalone tile, tiles 203](tiles/tile-0203.png) | Standalone tile | 1 × 1 | — |
| 204 | ![Standalone tile, tiles 204](tiles/tile-0204.png) | Standalone tile | 1 × 1 | — |
| 205 | ![Standalone tile, tiles 205](tiles/tile-0205.png) | Standalone tile | 1 × 1 | — |
| 206 | ![Standalone tile, tiles 206](tiles/tile-0206.png) | Standalone tile | 1 × 1 | `LASTROAD` |
| 207 | ![Standalone tile, tiles 207](tiles/tile-0207.png) | Standalone tile | 1 × 1 | `BRWXXX7` |
| 208 | ![Standalone tile, tiles 208](tiles/tile-0208.png) | Standalone tile | 1 × 1 | `HPOWER`, `POWERBASE` |
| 209 | ![Standalone tile, tiles 209](tiles/tile-0209.png) | Standalone tile | 1 × 1 | `VPOWER` |
| 210 | ![Standalone tile, tiles 210](tiles/tile-0210.png) | Standalone tile | 1 × 1 | `LHPOWER` |
| 211 | ![Standalone tile, tiles 211](tiles/tile-0211.png) | Standalone tile | 1 × 1 | `LVPOWER` |
| 212 | ![Standalone tile, tiles 212](tiles/tile-0212.png) | Standalone tile | 1 × 1 | `LVPOWER2` |
| 213 | ![Standalone tile, tiles 213](tiles/tile-0213.png) | Standalone tile | 1 × 1 | `LVPOWER3` |
| 214 | ![Standalone tile, tiles 214](tiles/tile-0214.png) | Standalone tile | 1 × 1 | `LVPOWER4` |
| 215 | ![Standalone tile, tiles 215](tiles/tile-0215.png) | Standalone tile | 1 × 1 | `LVPOWER5` |
| 216 | ![Standalone tile, tiles 216](tiles/tile-0216.png) | Standalone tile | 1 × 1 | `LVPOWER6` |
| 217 | ![Standalone tile, tiles 217](tiles/tile-0217.png) | Standalone tile | 1 × 1 | `LVPOWER7` |
| 218 | ![Standalone tile, tiles 218](tiles/tile-0218.png) | Standalone tile | 1 × 1 | `LVPOWER8` |
| 219 | ![Standalone tile, tiles 219](tiles/tile-0219.png) | Standalone tile | 1 × 1 | `LVPOWER9` |
| 220 | ![Standalone tile, tiles 220](tiles/tile-0220.png) | Standalone tile | 1 × 1 | `LVPOWER10` |
| 221 | ![Standalone tile, tiles 221](tiles/tile-0221.png) | Standalone tile | 1 × 1 | `RAILHPOWERV` |
| 222 | ![Standalone tile, tiles 222](tiles/tile-0222.png) | Standalone tile | 1 × 1 | `RAILVPOWERH`, `LASTPOWER` |
| 223 | ![Standalone tile, tiles 223](tiles/tile-0223.png) | Standalone tile | 1 × 1 | `UNUSED_TRASH6` |
| 224 | ![Standalone tile, tiles 224](tiles/tile-0224.png) | Standalone tile | 1 × 1 | `HRAIL`, `RAILBASE` |
| 225 | ![Standalone tile, tiles 225](tiles/tile-0225.png) | Standalone tile | 1 × 1 | `VRAIL` |
| 226 | ![Standalone tile, tiles 226](tiles/tile-0226.png) | Standalone tile | 1 × 1 | `LHRAIL` |
| 227 | ![Standalone tile, tiles 227](tiles/tile-0227.png) | Standalone tile | 1 × 1 | `LVRAIL` |
| 228 | ![Standalone tile, tiles 228](tiles/tile-0228.png) | Standalone tile | 1 × 1 | `LVRAIL2` |
| 229 | ![Standalone tile, tiles 229](tiles/tile-0229.png) | Standalone tile | 1 × 1 | `LVRAIL3` |
| 230 | ![Standalone tile, tiles 230](tiles/tile-0230.png) | Standalone tile | 1 × 1 | `LVRAIL4` |
| 231 | ![Standalone tile, tiles 231](tiles/tile-0231.png) | Standalone tile | 1 × 1 | `LVRAIL5` |
| 232 | ![Standalone tile, tiles 232](tiles/tile-0232.png) | Standalone tile | 1 × 1 | `LVRAIL6` |
| 233 | ![Standalone tile, tiles 233](tiles/tile-0233.png) | Standalone tile | 1 × 1 | `LVRAIL7` |
| 234 | ![Standalone tile, tiles 234](tiles/tile-0234.png) | Standalone tile | 1 × 1 | `LVRAIL8` |
| 235 | ![Standalone tile, tiles 235](tiles/tile-0235.png) | Standalone tile | 1 × 1 | `LVRAIL9` |
| 236 | ![Standalone tile, tiles 236](tiles/tile-0236.png) | Standalone tile | 1 × 1 | `LVRAIL10` |
| 237 | ![Standalone tile, tiles 237](tiles/tile-0237.png) | Standalone tile | 1 × 1 | `HRAILROAD` |
| 238 | ![Standalone tile, tiles 238](tiles/tile-0238.png) | Standalone tile | 1 × 1 | `VRAILROAD`, `LASTRAIL` |
| 239 | ![Standalone tile, tiles 239](tiles/tile-0239.png) | Standalone tile | 1 × 1 | `ROADVPOWERH` |
| 240–248 | ![Empty residential zone, tiles 240–248](groups/group-0240.png) | Empty residential zone | 3 × 3 | `RESBASE`, `FREEZ` |
| 249 | ![Standalone tile, tiles 249](tiles/tile-0249.png) | Standalone tile | 1 × 1 | `HOUSE`, `LHTHR` |
| 250 | ![Standalone tile, tiles 250](tiles/tile-0250.png) | Standalone tile | 1 × 1 | — |
| 251 | ![Standalone tile, tiles 251](tiles/tile-0251.png) | Standalone tile | 1 × 1 | — |
| 252 | ![Standalone tile, tiles 252](tiles/tile-0252.png) | Standalone tile | 1 × 1 | — |
| 253 | ![Standalone tile, tiles 253](tiles/tile-0253.png) | Standalone tile | 1 × 1 | — |
| 254 | ![Standalone tile, tiles 254](tiles/tile-0254.png) | Standalone tile | 1 × 1 | — |
| 255 | ![Standalone tile, tiles 255](tiles/tile-0255.png) | Standalone tile | 1 × 1 | — |
| 256 | ![Standalone tile, tiles 256](tiles/tile-0256.png) | Standalone tile | 1 × 1 | — |
| 257 | ![Standalone tile, tiles 257](tiles/tile-0257.png) | Standalone tile | 1 × 1 | — |
| 258 | ![Standalone tile, tiles 258](tiles/tile-0258.png) | Standalone tile | 1 × 1 | — |
| 259 | ![Standalone tile, tiles 259](tiles/tile-0259.png) | Standalone tile | 1 × 1 | — |
| 260 | ![Standalone tile, tiles 260](tiles/tile-0260.png) | Standalone tile | 1 × 1 | `HHTHR` |
| 261–269 | ![Residential — value tier 1, density level 1, tiles 261–269](groups/group-0261.png) | Residential — value tier 1, density level 1 | 3 × 3 | `RZB` |
| 270–278 | ![Residential — value tier 1, density level 2, tiles 270–278](groups/group-0270.png) | Residential — value tier 1, density level 2 | 3 × 3 | — |
| 279–287 | ![Residential — value tier 1, density level 3, tiles 279–287](groups/group-0279.png) | Residential — value tier 1, density level 3 | 3 × 3 | — |
| 288–296 | ![Residential — value tier 1, density level 4, tiles 288–296](groups/group-0288.png) | Residential — value tier 1, density level 4 | 3 × 3 | — |
| 297–305 | ![Residential — value tier 2, density level 1, tiles 297–305](groups/group-0297.png) | Residential — value tier 2, density level 1 | 3 × 3 | — |
| 306–314 | ![Residential — value tier 2, density level 2, tiles 306–314](groups/group-0306.png) | Residential — value tier 2, density level 2 | 3 × 3 | — |
| 315–323 | ![Residential — value tier 2, density level 3, tiles 315–323](groups/group-0315.png) | Residential — value tier 2, density level 3 | 3 × 3 | — |
| 324–332 | ![Residential — value tier 2, density level 4, tiles 324–332](groups/group-0324.png) | Residential — value tier 2, density level 4 | 3 × 3 | — |
| 333–341 | ![Residential — value tier 3, density level 1, tiles 333–341](groups/group-0333.png) | Residential — value tier 3, density level 1 | 3 × 3 | — |
| 342–350 | ![Residential — value tier 3, density level 2, tiles 342–350](groups/group-0342.png) | Residential — value tier 3, density level 2 | 3 × 3 | — |
| 351–359 | ![Residential — value tier 3, density level 3, tiles 351–359](groups/group-0351.png) | Residential — value tier 3, density level 3 | 3 × 3 | — |
| 360–368 | ![Residential — value tier 3, density level 4, tiles 360–368](groups/group-0360.png) | Residential — value tier 3, density level 4 | 3 × 3 | — |
| 369–377 | ![Residential — value tier 4, density level 1, tiles 369–377](groups/group-0369.png) | Residential — value tier 4, density level 1 | 3 × 3 | — |
| 378–386 | ![Residential — value tier 4, density level 2, tiles 378–386](groups/group-0378.png) | Residential — value tier 4, density level 2 | 3 × 3 | — |
| 387–395 | ![Residential — value tier 4, density level 3, tiles 387–395](groups/group-0387.png) | Residential — value tier 4, density level 3 | 3 × 3 | — |
| 396–404 | ![Residential — value tier 4, density level 4, tiles 396–404](groups/group-0396.png) | Residential — value tier 4, density level 4 | 3 × 3 | — |
| 405–413 | ![Hospital, tiles 405–413](groups/group-0405.png) | Hospital | 3 × 3 | `HOSPITALBASE`, `HOSPITAL` |
| 414–422 | ![Church — original, tiles 414–422](groups/group-0414.png) | Church — original | 3 × 3 | `CHURCHBASE`, `CHURCH0BASE`, `CHURCH`, `CHURCH0` |
| 423–431 | ![Empty commercial zone, tiles 423–431](groups/group-0423.png) | Empty commercial zone | 3 × 3 | `COMBASE`, `COMCLR` |
| 432–440 | ![Commercial — value tier 1, density level 1, tiles 432–440](groups/group-0432.png) | Commercial — value tier 1, density level 1 | 3 × 3 | `CZB` |
| 441–449 | ![Commercial — value tier 1, density level 2, tiles 441–449](groups/group-0441.png) | Commercial — value tier 1, density level 2 | 3 × 3 | — |
| 450–458 | ![Commercial — value tier 1, density level 3, tiles 450–458](groups/group-0450.png) | Commercial — value tier 1, density level 3 | 3 × 3 | — |
| 459–467 | ![Commercial — value tier 1, density level 4, tiles 459–467](groups/group-0459.png) | Commercial — value tier 1, density level 4 | 3 × 3 | — |
| 468–476 | ![Commercial — value tier 1, density level 5, tiles 468–476](groups/group-0468.png) | Commercial — value tier 1, density level 5 | 3 × 3 | — |
| 477–485 | ![Commercial — value tier 2, density level 1, tiles 477–485](groups/group-0477.png) | Commercial — value tier 2, density level 1 | 3 × 3 | — |
| 486–494 | ![Commercial — value tier 2, density level 2, tiles 486–494](groups/group-0486.png) | Commercial — value tier 2, density level 2 | 3 × 3 | — |
| 495–503 | ![Commercial — value tier 2, density level 3, tiles 495–503](groups/group-0495.png) | Commercial — value tier 2, density level 3 | 3 × 3 | — |
| 504–512 | ![Commercial — value tier 2, density level 4, tiles 504–512](groups/group-0504.png) | Commercial — value tier 2, density level 4 | 3 × 3 | — |
| 513–521 | ![Commercial — value tier 2, density level 5, tiles 513–521](groups/group-0513.png) | Commercial — value tier 2, density level 5 | 3 × 3 | — |
| 522–530 | ![Commercial — value tier 3, density level 1, tiles 522–530](groups/group-0522.png) | Commercial — value tier 3, density level 1 | 3 × 3 | — |
| 531–539 | ![Commercial — value tier 3, density level 2, tiles 531–539](groups/group-0531.png) | Commercial — value tier 3, density level 2 | 3 × 3 | — |
| 540–548 | ![Commercial — value tier 3, density level 3, tiles 540–548](groups/group-0540.png) | Commercial — value tier 3, density level 3 | 3 × 3 | — |
| 549–557 | ![Commercial — value tier 3, density level 4, tiles 549–557](groups/group-0549.png) | Commercial — value tier 3, density level 4 | 3 × 3 | — |
| 558–566 | ![Commercial — value tier 3, density level 5, tiles 558–566](groups/group-0558.png) | Commercial — value tier 3, density level 5 | 3 × 3 | — |
| 567–575 | ![Commercial — value tier 4, density level 1, tiles 567–575](groups/group-0567.png) | Commercial — value tier 4, density level 1 | 3 × 3 | — |
| 576–584 | ![Commercial — value tier 4, density level 2, tiles 576–584](groups/group-0576.png) | Commercial — value tier 4, density level 2 | 3 × 3 | — |
| 585–593 | ![Commercial — value tier 4, density level 3, tiles 585–593](groups/group-0585.png) | Commercial — value tier 4, density level 3 | 3 × 3 | — |
| 594–602 | ![Commercial — value tier 4, density level 4, tiles 594–602](groups/group-0594.png) | Commercial — value tier 4, density level 4 | 3 × 3 | — |
| 603–611 | ![Commercial — value tier 4, density level 5, tiles 603–611](groups/group-0603.png) | Commercial — value tier 4, density level 5 | 3 × 3 | `COMLAST` |
| 612–620 | ![Empty industrial zone, tiles 612–620](groups/group-0612.png) | Empty industrial zone | 3 × 3 | `INDBASE`, `INDCLR`, `LASTIND` |
| 621–629 | ![Industrial — value tier 1, density level 1, tiles 621–629](groups/group-0621.png) | Industrial — value tier 1, density level 1 | 3 × 3 | `IND1`, `IZB` |
| 630–638 | ![Industrial — value tier 1, density level 2, tiles 630–638](groups/group-0630.png) | Industrial — value tier 1, density level 2 | 3 × 3 | — |
| 639–647 | ![Industrial — value tier 1, density level 3, tiles 639–647](groups/group-0639.png) | Industrial — value tier 1, density level 3 | 3 × 3 | `IND2`, `IND3` |
| 648–656 | ![Industrial — value tier 1, density level 4, tiles 648–656](groups/group-0648.png) | Industrial — value tier 1, density level 4 | 3 × 3 | `IND4`, `IND5` |
| 657–665 | ![Industrial — value tier 2, density level 1, tiles 657–665](groups/group-0657.png) | Industrial — value tier 2, density level 1 | 3 × 3 | — |
| 666–674 | ![Industrial — value tier 2, density level 2, tiles 666–674](groups/group-0666.png) | Industrial — value tier 2, density level 2 | 3 × 3 | — |
| 675–683 | ![Industrial — value tier 2, density level 3, tiles 675–683](groups/group-0675.png) | Industrial — value tier 2, density level 3 | 3 × 3 | `IND6`, `IND7` |
| 684–692 | ![Industrial — value tier 2, density level 4, tiles 684–692](groups/group-0684.png) | Industrial — value tier 2, density level 4 | 3 × 3 | `IND8`, `IND9` |
| 693–708 | ![Seaport, tiles 693–708](groups/group-0693.png) | Seaport | 4 × 4 | `PORTBASE`, `PORT`, `LASTPORT` |
| 709–744 | ![Airport, tiles 709–744](groups/group-0709.png) | Airport | 6 × 6 | `AIRPORTBASE`, `RADAR`, `AIRPORT` |
| 745–760 | ![Coal power plant, tiles 745–760](groups/group-0745.png) | Coal power plant | 4 × 4 | `COALBASE`, `POWERPLANT`, `LASTPOWERPLANT` |
| 761–769 | ![Fire station, tiles 761–769](groups/group-0761.png) | Fire station | 3 × 3 | `FIRESTBASE`, `FIRESTATION` |
| 770–778 | ![Police station, tiles 770–778](groups/group-0770.png) | Police station | 3 × 3 | `POLICESTBASE`, `POLICESTATION` |
| 779–794 | ![Stadium — empty, tiles 779–794](groups/group-0779.png) | Stadium — empty | 4 × 4 | `STADIUMBASE`, `STADIUM` |
| 795–810 | ![Stadium — game in progress, tiles 795–810](groups/group-0795.png) | Stadium — game in progress | 4 × 4 | `FULLSTADIUM` |
| 811–826 | ![Nuclear power plant, tiles 811–826](groups/group-0811.png) | Nuclear power plant | 4 × 4 | `NUCLEARBASE`, `NUCLEAR`, `LASTZONE` |
| 827 | ![Standalone tile, tiles 827](tiles/tile-0827.png) | Standalone tile | 1 × 1 | `LIGHTNINGBOLT` |
| 828 | ![Standalone tile, tiles 828](tiles/tile-0828.png) | Standalone tile | 1 × 1 | `HBRDG0` |
| 829 | ![Standalone tile, tiles 829](tiles/tile-0829.png) | Standalone tile | 1 × 1 | `HBRDG1` |
| 830 | ![Standalone tile, tiles 830](tiles/tile-0830.png) | Standalone tile | 1 × 1 | `HBRDG2` |
| 831 | ![Standalone tile, tiles 831](tiles/tile-0831.png) | Standalone tile | 1 × 1 | `HBRDG3` |
| 832 | ![Standalone tile, tiles 832](tiles/tile-0832.png) | Standalone tile | 1 × 1 | `HBRDG_END`, `RADAR0` |
| 833 | ![Standalone tile, tiles 833](tiles/tile-0833.png) | Standalone tile | 1 × 1 | `RADAR1` |
| 834 | ![Standalone tile, tiles 834](tiles/tile-0834.png) | Standalone tile | 1 × 1 | `RADAR2` |
| 835 | ![Standalone tile, tiles 835](tiles/tile-0835.png) | Standalone tile | 1 × 1 | `RADAR3` |
| 836 | ![Standalone tile, tiles 836](tiles/tile-0836.png) | Standalone tile | 1 × 1 | `RADAR4` |
| 837 | ![Standalone tile, tiles 837](tiles/tile-0837.png) | Standalone tile | 1 × 1 | `RADAR5` |
| 838 | ![Standalone tile, tiles 838](tiles/tile-0838.png) | Standalone tile | 1 × 1 | `RADAR6` |
| 839 | ![Standalone tile, tiles 839](tiles/tile-0839.png) | Standalone tile | 1 × 1 | `RADAR7` |
| 840 | ![Standalone tile, tiles 840](tiles/tile-0840.png) | Standalone tile | 1 × 1 | `FOUNTAIN` |
| 841 | ![Standalone tile, tiles 841](tiles/tile-0841.png) | Standalone tile | 1 × 1 | — |
| 842 | ![Standalone tile, tiles 842](tiles/tile-0842.png) | Standalone tile | 1 × 1 | — |
| 843 | ![Standalone tile, tiles 843](tiles/tile-0843.png) | Standalone tile | 1 × 1 | — |
| 844 | ![Standalone tile, tiles 844](tiles/tile-0844.png) | Standalone tile | 1 × 1 | `INDBASE2`, `TELEBASE` |
| 845 | ![Standalone tile, tiles 845](tiles/tile-0845.png) | Standalone tile | 1 × 1 | — |
| 846 | ![Standalone tile, tiles 846](tiles/tile-0846.png) | Standalone tile | 1 × 1 | — |
| 847 | ![Standalone tile, tiles 847](tiles/tile-0847.png) | Standalone tile | 1 × 1 | — |
| 848 | ![Standalone tile, tiles 848](tiles/tile-0848.png) | Standalone tile | 1 × 1 | — |
| 849 | ![Standalone tile, tiles 849](tiles/tile-0849.png) | Standalone tile | 1 × 1 | — |
| 850 | ![Standalone tile, tiles 850](tiles/tile-0850.png) | Standalone tile | 1 × 1 | — |
| 851 | ![Standalone tile, tiles 851](tiles/tile-0851.png) | Standalone tile | 1 × 1 | `TELELAST` |
| 852 | ![Standalone tile, tiles 852](tiles/tile-0852.png) | Standalone tile | 1 × 1 | `SMOKEBASE` |
| 853 | ![Standalone tile, tiles 853](tiles/tile-0853.png) | Standalone tile | 1 × 1 | — |
| 854 | ![Standalone tile, tiles 854](tiles/tile-0854.png) | Standalone tile | 1 × 1 | — |
| 855 | ![Standalone tile, tiles 855](tiles/tile-0855.png) | Standalone tile | 1 × 1 | — |
| 856 | ![Standalone tile, tiles 856](tiles/tile-0856.png) | Standalone tile | 1 × 1 | — |
| 857 | ![Standalone tile, tiles 857](tiles/tile-0857.png) | Standalone tile | 1 × 1 | — |
| 858 | ![Standalone tile, tiles 858](tiles/tile-0858.png) | Standalone tile | 1 × 1 | — |
| 859 | ![Standalone tile, tiles 859](tiles/tile-0859.png) | Standalone tile | 1 × 1 | — |
| 860 | ![Standalone tile, tiles 860](tiles/tile-0860.png) | Standalone tile | 1 × 1 | `TINYEXP` |
| 861 | ![Standalone tile, tiles 861](tiles/tile-0861.png) | Standalone tile | 1 × 1 | — |
| 862 | ![Standalone tile, tiles 862](tiles/tile-0862.png) | Standalone tile | 1 × 1 | — |
| 863 | ![Standalone tile, tiles 863](tiles/tile-0863.png) | Standalone tile | 1 × 1 | — |
| 864 | ![Standalone tile, tiles 864](tiles/tile-0864.png) | Standalone tile | 1 × 1 | `SOMETINYEXP` |
| 865 | ![Standalone tile, tiles 865](tiles/tile-0865.png) | Standalone tile | 1 × 1 | — |
| 866 | ![Standalone tile, tiles 866](tiles/tile-0866.png) | Standalone tile | 1 × 1 | — |
| 867 | ![Standalone tile, tiles 867](tiles/tile-0867.png) | Standalone tile | 1 × 1 | `LASTTINYEXP` |
| 868 | ![Standalone tile, tiles 868](tiles/tile-0868.png) | Standalone tile | 1 × 1 | — |
| 869 | ![Standalone tile, tiles 869](tiles/tile-0869.png) | Standalone tile | 1 × 1 | — |
| 870 | ![Standalone tile, tiles 870](tiles/tile-0870.png) | Standalone tile | 1 × 1 | — |
| 871 | ![Standalone tile, tiles 871](tiles/tile-0871.png) | Standalone tile | 1 × 1 | — |
| 872 | ![Standalone tile, tiles 872](tiles/tile-0872.png) | Standalone tile | 1 × 1 | — |
| 873 | ![Standalone tile, tiles 873](tiles/tile-0873.png) | Standalone tile | 1 × 1 | — |
| 874 | ![Standalone tile, tiles 874](tiles/tile-0874.png) | Standalone tile | 1 × 1 | — |
| 875 | ![Standalone tile, tiles 875](tiles/tile-0875.png) | Standalone tile | 1 × 1 | — |
| 876 | ![Standalone tile, tiles 876](tiles/tile-0876.png) | Standalone tile | 1 × 1 | — |
| 877 | ![Standalone tile, tiles 877](tiles/tile-0877.png) | Standalone tile | 1 × 1 | — |
| 878 | ![Standalone tile, tiles 878](tiles/tile-0878.png) | Standalone tile | 1 × 1 | — |
| 879 | ![Standalone tile, tiles 879](tiles/tile-0879.png) | Standalone tile | 1 × 1 | — |
| 880 | ![Standalone tile, tiles 880](tiles/tile-0880.png) | Standalone tile | 1 × 1 | — |
| 881 | ![Standalone tile, tiles 881](tiles/tile-0881.png) | Standalone tile | 1 × 1 | — |
| 882 | ![Standalone tile, tiles 882](tiles/tile-0882.png) | Standalone tile | 1 × 1 | — |
| 883 | ![Standalone tile, tiles 883](tiles/tile-0883.png) | Standalone tile | 1 × 1 | `TINYEXPLAST` |
| 884 | ![Standalone tile, tiles 884](tiles/tile-0884.png) | Standalone tile | 1 × 1 | — |
| 885 | ![Standalone tile, tiles 885](tiles/tile-0885.png) | Standalone tile | 1 × 1 | — |
| 886 | ![Standalone tile, tiles 886](tiles/tile-0886.png) | Standalone tile | 1 × 1 | — |
| 887 | ![Standalone tile, tiles 887](tiles/tile-0887.png) | Standalone tile | 1 × 1 | — |
| 888 | ![Standalone tile, tiles 888](tiles/tile-0888.png) | Standalone tile | 1 × 1 | — |
| 889 | ![Standalone tile, tiles 889](tiles/tile-0889.png) | Standalone tile | 1 × 1 | — |
| 890 | ![Standalone tile, tiles 890](tiles/tile-0890.png) | Standalone tile | 1 × 1 | — |
| 891 | ![Standalone tile, tiles 891](tiles/tile-0891.png) | Standalone tile | 1 × 1 | — |
| 892 | ![Standalone tile, tiles 892](tiles/tile-0892.png) | Standalone tile | 1 × 1 | — |
| 893 | ![Standalone tile, tiles 893](tiles/tile-0893.png) | Standalone tile | 1 × 1 | — |
| 894 | ![Standalone tile, tiles 894](tiles/tile-0894.png) | Standalone tile | 1 × 1 | — |
| 895 | ![Standalone tile, tiles 895](tiles/tile-0895.png) | Standalone tile | 1 × 1 | — |
| 896 | ![Standalone tile, tiles 896](tiles/tile-0896.png) | Standalone tile | 1 × 1 | — |
| 897 | ![Standalone tile, tiles 897](tiles/tile-0897.png) | Standalone tile | 1 × 1 | — |
| 898 | ![Standalone tile, tiles 898](tiles/tile-0898.png) | Standalone tile | 1 × 1 | — |
| 899 | ![Standalone tile, tiles 899](tiles/tile-0899.png) | Standalone tile | 1 × 1 | — |
| 900 | ![Standalone tile, tiles 900](tiles/tile-0900.png) | Standalone tile | 1 × 1 | — |
| 901 | ![Standalone tile, tiles 901](tiles/tile-0901.png) | Standalone tile | 1 × 1 | — |
| 902 | ![Standalone tile, tiles 902](tiles/tile-0902.png) | Standalone tile | 1 × 1 | — |
| 903 | ![Standalone tile, tiles 903](tiles/tile-0903.png) | Standalone tile | 1 × 1 | — |
| 904 | ![Standalone tile, tiles 904](tiles/tile-0904.png) | Standalone tile | 1 × 1 | — |
| 905 | ![Standalone tile, tiles 905](tiles/tile-0905.png) | Standalone tile | 1 × 1 | — |
| 906 | ![Standalone tile, tiles 906](tiles/tile-0906.png) | Standalone tile | 1 × 1 | — |
| 907 | ![Standalone tile, tiles 907](tiles/tile-0907.png) | Standalone tile | 1 × 1 | — |
| 908 | ![Standalone tile, tiles 908](tiles/tile-0908.png) | Standalone tile | 1 × 1 | — |
| 909 | ![Standalone tile, tiles 909](tiles/tile-0909.png) | Standalone tile | 1 × 1 | — |
| 910 | ![Standalone tile, tiles 910](tiles/tile-0910.png) | Standalone tile | 1 × 1 | — |
| 911 | ![Standalone tile, tiles 911](tiles/tile-0911.png) | Standalone tile | 1 × 1 | — |
| 912 | ![Standalone tile, tiles 912](tiles/tile-0912.png) | Standalone tile | 1 × 1 | — |
| 913 | ![Standalone tile, tiles 913](tiles/tile-0913.png) | Standalone tile | 1 × 1 | — |
| 914 | ![Standalone tile, tiles 914](tiles/tile-0914.png) | Standalone tile | 1 × 1 | — |
| 915 | ![Standalone tile, tiles 915](tiles/tile-0915.png) | Standalone tile | 1 × 1 | — |
| 916 | ![Standalone tile, tiles 916](tiles/tile-0916.png) | Standalone tile | 1 × 1 | `COALSMOKE1` |
| 917 | ![Standalone tile, tiles 917](tiles/tile-0917.png) | Standalone tile | 1 × 1 | — |
| 918 | ![Standalone tile, tiles 918](tiles/tile-0918.png) | Standalone tile | 1 × 1 | — |
| 919 | ![Standalone tile, tiles 919](tiles/tile-0919.png) | Standalone tile | 1 × 1 | — |
| 920 | ![Standalone tile, tiles 920](tiles/tile-0920.png) | Standalone tile | 1 × 1 | `COALSMOKE2` |
| 921 | ![Standalone tile, tiles 921](tiles/tile-0921.png) | Standalone tile | 1 × 1 | — |
| 922 | ![Standalone tile, tiles 922](tiles/tile-0922.png) | Standalone tile | 1 × 1 | — |
| 923 | ![Standalone tile, tiles 923](tiles/tile-0923.png) | Standalone tile | 1 × 1 | — |
| 924 | ![Standalone tile, tiles 924](tiles/tile-0924.png) | Standalone tile | 1 × 1 | `COALSMOKE3` |
| 925 | ![Standalone tile, tiles 925](tiles/tile-0925.png) | Standalone tile | 1 × 1 | — |
| 926 | ![Standalone tile, tiles 926](tiles/tile-0926.png) | Standalone tile | 1 × 1 | — |
| 927 | ![Standalone tile, tiles 927](tiles/tile-0927.png) | Standalone tile | 1 × 1 | — |
| 928 | ![Standalone tile, tiles 928](tiles/tile-0928.png) | Standalone tile | 1 × 1 | `COALSMOKE4` |
| 929 | ![Standalone tile, tiles 929](tiles/tile-0929.png) | Standalone tile | 1 × 1 | — |
| 930 | ![Standalone tile, tiles 930](tiles/tile-0930.png) | Standalone tile | 1 × 1 | — |
| 931 | ![Standalone tile, tiles 931](tiles/tile-0931.png) | Standalone tile | 1 × 1 | — |
| 932 | ![Standalone tile, tiles 932](tiles/tile-0932.png) | Standalone tile | 1 × 1 | `FOOTBALLGAME1` |
| 933 | ![Standalone tile, tiles 933](tiles/tile-0933.png) | Standalone tile | 1 × 1 | — |
| 934 | ![Standalone tile, tiles 934](tiles/tile-0934.png) | Standalone tile | 1 × 1 | — |
| 935 | ![Standalone tile, tiles 935](tiles/tile-0935.png) | Standalone tile | 1 × 1 | — |
| 936 | ![Standalone tile, tiles 936](tiles/tile-0936.png) | Standalone tile | 1 × 1 | — |
| 937 | ![Standalone tile, tiles 937](tiles/tile-0937.png) | Standalone tile | 1 × 1 | — |
| 938 | ![Standalone tile, tiles 938](tiles/tile-0938.png) | Standalone tile | 1 × 1 | — |
| 939 | ![Standalone tile, tiles 939](tiles/tile-0939.png) | Standalone tile | 1 × 1 | — |
| 940 | ![Standalone tile, tiles 940](tiles/tile-0940.png) | Standalone tile | 1 × 1 | `FOOTBALLGAME2` |
| 941 | ![Standalone tile, tiles 941](tiles/tile-0941.png) | Standalone tile | 1 × 1 | — |
| 942 | ![Standalone tile, tiles 942](tiles/tile-0942.png) | Standalone tile | 1 × 1 | — |
| 943 | ![Standalone tile, tiles 943](tiles/tile-0943.png) | Standalone tile | 1 × 1 | — |
| 944 | ![Standalone tile, tiles 944](tiles/tile-0944.png) | Standalone tile | 1 × 1 | — |
| 945 | ![Standalone tile, tiles 945](tiles/tile-0945.png) | Standalone tile | 1 × 1 | — |
| 946 | ![Standalone tile, tiles 946](tiles/tile-0946.png) | Standalone tile | 1 × 1 | — |
| 947 | ![Standalone tile, tiles 947](tiles/tile-0947.png) | Standalone tile | 1 × 1 | — |
| 948 | ![Standalone tile, tiles 948](tiles/tile-0948.png) | Standalone tile | 1 × 1 | `VBRDG0` |
| 949 | ![Standalone tile, tiles 949](tiles/tile-0949.png) | Standalone tile | 1 × 1 | `VBRDG1` |
| 950 | ![Standalone tile, tiles 950](tiles/tile-0950.png) | Standalone tile | 1 × 1 | `VBRDG2` |
| 951 | ![Standalone tile, tiles 951](tiles/tile-0951.png) | Standalone tile | 1 × 1 | `VBRDG3` |
| 952 | ![Standalone tile, tiles 952](tiles/tile-0952.png) | Standalone tile | 1 × 1 | `NUKESWIRL1` |
| 953 | ![Standalone tile, tiles 953](tiles/tile-0953.png) | Standalone tile | 1 × 1 | `NUKESWIRL2` |
| 954 | ![Standalone tile, tiles 954](tiles/tile-0954.png) | Standalone tile | 1 × 1 | `NUKESWIRL3` |
| 955 | ![Standalone tile, tiles 955](tiles/tile-0955.png) | Standalone tile | 1 × 1 | `NUKESWIRL4` |
| 956–964 | ![Church — variant 1, tiles 956–964](groups/group-0956.png) | Church — variant 1 | 3 × 3 | `CHURCH1BASE`, `CHURCH1` |
| 965–973 | ![Church — variant 2, tiles 965–973](groups/group-0965.png) | Church — variant 2 | 3 × 3 | `CHURCH2BASE`, `CHURCH2` |
| 974–982 | ![Church — variant 3, tiles 974–982](groups/group-0974.png) | Church — variant 3 | 3 × 3 | `CHURCH3BASE`, `CHURCH3` |
| 983–991 | ![Church — variant 4, tiles 983–991](groups/group-0983.png) | Church — variant 4 | 3 × 3 | `CHURCH4BASE`, `CHURCH4` |
| 992–1000 | ![Church — variant 5, tiles 992–1000](groups/group-0992.png) | Church — variant 5 | 3 × 3 | `CHURCH5BASE`, `CHURCH5` |
| 1001–1009 | ![Church — variant 6, tiles 1001–1009](groups/group-1001.png) | Church — variant 6 | 3 × 3 | `CHURCH6BASE`, `CHURCH6` |
| 1010–1018 | ![Church — variant 7, tiles 1010–1018](groups/group-1010.png) | Church — variant 7 | 3 × 3 | `CHURCH7BASE`, `CHURCH7`, `CHURCH7LAST` |
| 1019 | ![Standalone tile, tiles 1019](tiles/tile-1019.png) | Standalone tile | 1 × 1 | — |
| 1020 | ![Standalone tile, tiles 1020](tiles/tile-1020.png) | Standalone tile | 1 × 1 | — |
| 1021 | ![Standalone tile, tiles 1021](tiles/tile-1021.png) | Standalone tile | 1 × 1 | — |
| 1022 | ![Standalone tile, tiles 1022](tiles/tile-1022.png) | Standalone tile | 1 × 1 | — |
| 1023 | ![Standalone tile, tiles 1023](tiles/tile-1023.png) | Standalone tile | 1 × 1 | — |
