# Thanksgiving Pumpkins

![Thanksgiving Pumpkins on Tall Yard Stakes](images/pumpkins_1.jpg)

Two flat harvest pumpkins on tall push-in stakes. They're made to stand
behind the designer's **Happy Thanksgiving** yard sign (a separate model)
and show above it, one at each end, but they stand fine on their own in a bed or a
planter.

Each pumpkin has raised art on a backing board, with the lobes, stem line and
leaf rib cut in as grooves and a curled tendril. The squat one is 179 × 179 mm
and the round one 154 × 193 mm, both 13 mm thick. On their stakes they sit
265 mm off the ground, which clears the top of a 200 mm sign standing 50 mm
up. That puts their tops about 445 and 460 mm high.

## Files

| file | colour | what it is |
|---|---|---|
| `pumpkin_1_board.stl`, `pumpkin_2_board.stl` | brown (or any dark colour) | the backing, 10 mm, with a pocket for the stake |
| `pumpkin_1_art.stl`, `pumpkin_2_art.stl` | orange (or white) | the raised art, 3 mm |
| `stakes.stl` | brown (anything) | all four stake pieces, one plate |
| `stake_lower.stl`, `stake_upper.stl` | | one stake piece each, if you'd rather print them separately |
| `pumpkin_1.stl`, `pumpkin_2.stl` | | each pumpkin as ONE STL, both colours together, for a filament change by layer instead |

`pumpkin_1` is the squat one, `pumpkin_2` the round one.

## Printing

**PLA, 0.4 mm nozzle, 0.2 mm layers, no supports, no brim, prime tower
off.** Three plates: each pumpkin, then the stakes. Each is about 2 h 45 min
on a P1S, and the whole set takes about 320 g.

A pumpkin fits any 220 mm bed. The stake pieces are 229.5 mm long and need a
256 mm bed (P1S, X1, A1, H2D and the like).

Each pumpkin prints flat, face up:

1. Import `pumpkin_N_board.stl` and `pumpkin_N_art.stl` together and load
   them as **one object with several parts**. They're already positioned;
   don't move them.
2. Board: brown. Art: orange. The photos also show the other way round in
   lighter colours: white art on an orange board.
3. The colours only meet at 10 mm up, so there is one filament change per
   plate. A Bambu printer purges it into the waste chute, so the prime tower
   isn't needed.

**One colour at a time instead:** import `pumpkin_N.stl` alone and add a
filament change at the first layer above **10.0 mm** in the slicer's layer
view.

**The stakes** print flat in one colour: two lower pieces (pointed, with a
tongue on top) and two upper pieces (a sleeve at the bottom, a tongue on
top).

Studio may warn about separate bodies in the art parts and the stakes plate.
The art is several separate pieces sitting on the board, and the plate holds
four stakes, so that's expected.

## Assembly

Every flat side (the side that was on the bed) faces the **front**: the
stakes' and the pumpkins'. Each joint is a tongue in a pocket with 0.22 mm of
clearance a side, and the pockets are 2 mm deeper than the tongues so a
little grit won't stop one seating.

1. Push the upper piece's sleeve down over the lower piece's tongue.
2. Push the stake's top tongue up into the pocket in the pumpkin's bottom
   tab, until the tab sits on the stake's shoulders.
3. Push the stake into the ground up to where the taper ends: 110 mm, the
   pointed part. The pumpkin's bottom is then 265 mm up.

Behind the sign, put one pumpkin near each end. The stake joints are 78 to
133 mm up, so the sign hides them. Glue isn't needed, but a drop in each
joint keeps a stake from coming apart when you pull it up.

## Remixing

Everything is `pumpkins.scad`, a single OpenSCAD file with no fonts or
includes. At the top:

- `pumpkin_1`, `pumpkin_2`: each pumpkin's width and body height. The lobes,
  stem, leaf and tendril follow.
- `sign_h`, `sign_shank`, `over_sign`: the sign the pumpkins stand behind.
  The stake height comes from these, so change them for a different sign.
- `board_t`, `relief`, `groove`, `border`: the same as the sign's.

The file asserts that the skin over the stake pocket is thick enough, that
both stake pieces fit a 230 mm print length, and that the stake joint stays
hidden behind the sign. `./build.sh` regenerates every STL with OpenSCAD.

**What's in the download:** the STLs and the OpenSCAD source.

## Licence

CC BY-NC-SA 4.0, see `LICENSE`.
