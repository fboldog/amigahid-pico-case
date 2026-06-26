// amigahid-pico case
// Two-part snap-fit enclosure: bottom shell + top lid
//
// PCB dimensions from KiCad Edge.Cuts layer:
//   Board: 61.722 x 72.39 mm
//   Front notch (RPi Pico USB cable): x 19.94-27.05 mm, 3.81 mm deep
//
// Connectors (positions taken from connector BODY centres in the .kicad_pcb):
//   USB-A Molex 67643 Horizontal  -> front wall cutout (body overhangs front edge)
//   IDC 2x5 x2 (Amiga ports)     -> top lid windows (long axis along Y)
//   PinHeader 1x08 vertical       -> top lid window (long axis along Y)
//   RPi Pico micro-USB            -> internal, no opening (firmware only)
//   PinHeader 1x04 vertical       -> internal, no opening (future display)
//   PinHeader 1x06 horizontal     -> internal, no opening (debug pins)
//
// PCB mounting: 2 bosses for M3 x 5 x 4 Voron heat-set inserts (4.4 mm holes);
// PCB screws down from above with M3 screws. Lid is snap-only (no lid screws).
//
// Closure: 4 snap-fit wedge bumps on the lid's CONTINUOUS alignment lip
// (2 front wall, 2 back wall). Each bump is a sturdy wedge backed by the full
// lip wall (no thin breakable tip). Short relief slits beside each bump stop
// below the top rim, so the lip edge stays continuous while the bump segment
// can flex to snap into a blind pocket on the inner wall face. Exterior stays
// smooth.

// Curve resolution (built-in OpenSCAD specials -- names are fixed, can't rename).
// Together they set how finely every cylinder/arc here (bosses, studs, corners)
// is faceted; OpenSCAD uses whichever yields FEWER fragments (min 5 per circle).
$fa = 4;     // max angle per facet, degrees  -> a circle gets at most 360/4 = 90 sides
$fs = 0.3;   // min facet edge length, mm      -> arc segments never shorter than 0.3 mm
// (Defaults are 12 / 2, which would leave the 4.4 mm insert bores visibly faceted
//  and slightly undersized between facets -> these tighter values keep bores round.
//  Affects only the STL/CSG mesh; FreeCAD rebuilds true round B-rep for the STEP.)

// ── PCB ──────────────────────────────────────────────────────────────────────
pcb_width     = 61.722;
pcb_depth     = 72.390;
pcb_thickness = 1.600;
pcb_clearance = 0.5;    // clearance per side between PCB edge and cavity wall

// ── Case walls ────────────────────────────────────────────────────────────────
wall_thickness  = 2.2;
floor_thickness = 3.0;   // thick enough to host the insert blind hole + ~1 mm base
lid_thickness   = 2.5;

pcb_clear_below = 3.0;   // gap below PCB (back-side SMD + insert boss depth)
pcb_clear_above = 14.5;  // gap above PCB (IDC headers ~12 mm)
corner_radius   = 2.5;

// ── USB-A front-wall opening (Molex 67643 horizontal) ───────────────────────
usba_cx           = 47.50;  // connector body centre, PCB-relative X (mirrored via board_x())
usba_width        = 14.5;   // opening width  (X)
usba_height       = 7.0;    // opening height (Z) -- verify vs connector datasheet
usba_z_above_pcb  = 4.6;    // opening centre, height above the PCB top face (raise to taste)

// ── Alignment lip (continuous; centres lid and carries the snap bumps) ───────
lip_height         = 5.0;   // lip depth (hangs down from lid into shell)
lip_gap            = 0.20;  // clearance: lip outer face <-> inner wall face
lip_wall_thickness = 1.2;   // lip wall thickness

// ── Heat-set insert bosses (Voron M3 x 5 x 4: L=4.0, D1=5.0, D2=4.4, W=1.6) ──
insert_length     = 4.0;    // insert length
insert_bore_dia   = 4.4;    // melt/press hole diameter (CNC Kitchen spec)
insert_wall_min   = 1.6;    // min wall around the insert
insert_hole_depth = 5.0;    // blind hole depth from PCB-rest plane (L + 1 mm)

boss_height       = pcb_clear_below;                    // boss height above floor (PCB stand-off)
boss_radius_outer = insert_bore_dia/2 + insert_wall_min; // 3.8 mm -> 7.6 mm boss OD
boss_radius_inner = insert_bore_dia/2;                  // 2.2 mm -> 4.4 mm bore
// floor left below the bore = floor_thickness + pcb_clear_below - insert_hole_depth = 1.0 mm

// M3 mounting holes (PCB-relative)
mount_holes = [[57.785, 3.937], [57.785, 68.453]];

// ── Derived ───────────────────────────────────────────────────────────────────
cavity_width  = pcb_width + 2 * pcb_clearance;   // interior cavity footprint (PCB + clearance)
cavity_depth  = pcb_depth + 2 * pcb_clearance;
outer_width   = cavity_width + 2 * wall_thickness;
outer_depth   = cavity_depth + 2 * wall_thickness;
shell_height  = floor_thickness + pcb_clear_below + pcb_thickness + pcb_clear_above;

pcb_x0 = wall_thickness + pcb_clearance;   // PCB nominal origin (board is located by the bosses)
pcb_y0 = wall_thickness + pcb_clearance;

// KiCad is Y-down and its STEP exporter negates Y. We keep the case oriented
// with USB-A on the front wall, so the board sits 180deg-rotated vs the KiCad
// STEP frame -> every board-referenced X is mirrored through board_x().
function board_x(x_rel) = pcb_x0 + pcb_width - x_rel;

// Lip footprint (nests inside the cavity with lip_gap clearance)
lip_x0     = wall_thickness + lip_gap;
lip_y0     = wall_thickness + lip_gap;        // front lip outer face
lip_width  = cavity_width - 2 * lip_gap;
lip_depth  = cavity_depth - 2 * lip_gap;
lip_y_back = lip_y0 + lip_depth;              // back lip outer face

// ── Snap-fit wedge bump ───────────────────────────────────────────────────────
//
//  A wedge bump sits on the OUTER face of the (continuous) lip wall and snaps
//  into a blind pocket on the inner wall face. The bump is wide and solid,
//  backed by the lip behind it, so there is no thin free-standing tip to break.
//  Cross-section (wall-normal / vertical), front wall shown:
//
//      interior                       | wall |
//        lip wall ||                  |      |
//                 ||                  |      |
//                 ||___               |======|
//                 ||   \  shelf  ----->] POCKET   (catches the pocket top edge)
//                 ||    |  tip        ]      |
//                 ||___/  ramp        |======|
//                 ||                  |      |  ramp = lead-in as lid descends
//
//  Relief slits flank each bump (stopping slit_top_band below the top rim) so the
//  bump segment flexes inward to snap, while the rim stays continuous.
//
//  Insertion: push lid down; the wall's top inner edge rides the ramp, flexing
//             the bump segment inward until the bump drops into the pocket.
//  Retention: the catch corner sits under the pocket's top edge -> blocks lift-off.
//  Release:   press the lip inward at the bump to disengage.

snap_width        = 9.0;    // bump width along the wall (X)
snap_protrusion   = 0.7;    // bump protrusion toward the wall
snap_ramp_rise    = 2.4;    // ramp rise -> lead-in angle = atan(snap_protrusion/snap_ramp_rise) ~= 16 deg
snap_catch_height = 1.0;    // height of the retention bevel
slit_width        = 0.9;    // relief slit width
slit_top_band     = 1.2;    // continuous lip band left above the slits (rim stays whole)

// Blind pocket in the inner wall face
snap_pocket_depth = 0.8;            // < wall (leaves ~1.4 mm of wall)
snap_pocket_width = snap_width + 0.6; // width tolerance
seat_clearance    = 0.10;           // vertical seating clearance

// Pocket vertical extents in SHELL coords (lid plate bottom seats at z = shell_height).
// The bump's retention bevel makes its catch CORNER sit snap_protrusion below the
// lip-face top (zt). Align the pocket ceiling to that corner so a seated lid has only
// seat_clearance of vertical play. (Previously the ceiling sat snap_protrusion too
// high, so the lid could lift ~snap_protrusion before the corner engaged -> "loose".)
catch_corner_z_local = -lip_height + snap_ramp_rise + snap_catch_height - snap_protrusion; // bump catch corner (lid-local)
snap_pocket_z_top    = shell_height + catch_corner_z_local + seat_clearance;
snap_pocket_height   = snap_ramp_rise + snap_catch_height + 1.0;
snap_pocket_z_bot    = snap_pocket_z_top - snap_pocket_height;

// Clip centre X positions (avoid corners and connector cutouts).
// After the X-mirror the front USB-A opening sits at case-X ~9-24, so the front
// clips live to the right of it; the back wall is clear.
clip_x_front = [32, 55];
clip_x_back  = [outer_width * 0.22, outer_width * 0.78];

// ── 3-D rounded box ───────────────────────────────────────────────────────────
// Built from primitive 3-D unions (boxes + corner cylinders) instead of an
// offset()/extruded 2-D profile, so it survives FreeCAD's OpenSCAD/CSG importer
// when converting to STEP.
module rounded_box(width, depth, height, radius) {
    union() {
        translate([radius, 0, 0]) cube([width - 2*radius, depth, height]);
        translate([0, radius, 0]) cube([width, depth - 2*radius, height]);
        for (cx = [radius, width - radius], cy = [radius, depth - radius])
            translate([cx, cy, 0]) cylinder(h = height, r = radius);
    }
}

// ── Snap bump (added onto the lip outer face) ─────────────────────────────────
//  out = -1 -> protrude in -Y (front wall);  out = +1 -> protrude in +Y (back).
//  The polygon is drawn in (y, z); multmatrix maps it onto world Y/Z and the
//  extrude runs along world X (bump width), centred on cx.
module snap_bump(out, face_y, cx) {
    y0 = face_y;
    y1 = face_y + out * snap_protrusion;
    zb = -lip_height;                                       // ramp start (bottom of lip)
    zm = -lip_height + snap_ramp_rise;                      // full protrusion (lead-in apex)
    zt = -lip_height + snap_ramp_rise + snap_catch_height;  // top of retention bevel (at lip face)
    // Retention face is a 45deg bevel (outer corner at zt - snap_protrusion) instead
    // of a flat shelf, so when the lid prints lip-up it has no downward overhang.
    pts = (out < 0)
        ? [[y0, zb], [y0, zt], [y1, zt - snap_protrusion], [y1, zm]]   // CCW for front
        : [[y0, zb], [y1, zm], [y1, zt - snap_protrusion], [y0, zt]];  // CCW for back
    multmatrix([[0,0,1,0],
                [1,0,0,0],
                [0,1,0,0],
                [0,0,0,1]])
        translate([0, 0, cx - snap_width/2])
            linear_extrude(snap_width)
                polygon(pts);
}

// Relief slits beside a bump (subtracted from the lid; stop below the top rim).
// Each slit sits just OUTSIDE the bump edge (inner edge flush with the bump) so
// it never cuts the lip out from under the bump -> no overhang at the bump sides.
module snap_slits(ring_y0, cx) {
    for (s = [-1, 1]) {
        x0 = (s > 0) ? cx + snap_width/2 : cx - snap_width/2 - slit_width;
        translate([x0, ring_y0 - 0.1, -lip_height - 0.1])
            cube([slit_width, lip_wall_thickness + 0.2, lip_height - slit_top_band + 0.1]);
    }
}

// Blind pockets cut into the inner wall faces (subtracted from the shell)
module clip_pocket_front(cx) {   // front wall, cut from inner face (y=wall) outward
    translate([cx - snap_pocket_width/2, wall_thickness - snap_pocket_depth, snap_pocket_z_bot])
        cube([snap_pocket_width, snap_pocket_depth + 0.2, snap_pocket_height]);
}
module clip_pocket_back(cx) {    // back wall, cut from inner face outward (+Y)
    translate([cx - snap_pocket_width/2, outer_depth - wall_thickness - 0.1, snap_pocket_z_bot])
        cube([snap_pocket_width, snap_pocket_depth + 0.2, snap_pocket_height]);
}

// ── Bottom shell ──────────────────────────────────────────────────────────────
module bottom_shell() {
    difference() {
        // Outer body
        rounded_box(outer_width, outer_depth, shell_height, corner_radius);

        // Interior cavity (PCB footprint + clearance)
        translate([wall_thickness, wall_thickness, floor_thickness])
            linear_extrude(shell_height)
                square([cavity_width, cavity_depth]);

        // USB-A front wall cutout (Molex 67643 horizontal; body overhangs front
        // edge, opening faces front). Sizing/position params at top of file.
        usba_zc = floor_thickness + pcb_clear_below + pcb_thickness + usba_z_above_pcb;
        translate([board_x(usba_cx) - usba_width/2, -0.1, usba_zc - usba_height/2])
            cube([usba_width, wall_thickness + 0.2, usba_height]);

        // (Pico USB is firmware-only -> no opening; PCB is notched/recessed there)
        // (1x08 is a vertical header -> lid window, see top_lid)
        // (1x06 is internal -> no case opening)

        // Snap pockets
        for (cx = clip_x_front) clip_pocket_front(cx);
        for (cx = clip_x_back)  clip_pocket_back(cx);

        // Heat-set insert holes bored down into the floor (boss is added below)
        for (mh = mount_holes)
            translate([board_x(mh[0]), pcb_y0 + mh[1], floor_thickness + pcb_clear_below - insert_hole_depth])
                cylinder(h = insert_hole_depth, r = boss_radius_inner);
    }

    // Heat-set insert bosses (bore continues up through the boss to the PCB face)
    for (mh = mount_holes)
        translate([board_x(mh[0]), pcb_y0 + mh[1], floor_thickness])
            difference() {
                cylinder(h = boss_height, r = boss_radius_outer);
                translate([0, 0, -0.1])
                    cylinder(h = boss_height + 0.2, r = boss_radius_inner);
            }

    // PCB support studs (no insert) mirroring the bosses on the opposite side,
    // so the board rests on exactly four features (2 bosses + 2 studs).
    for (mh = mount_holes)
        translate([pcb_x0 + mh[0], pcb_y0 + mh[1], floor_thickness])
            cylinder(h = boss_height, r = 2.5);
}

// ── Top lid ───────────────────────────────────────────────────────────────────
module top_lid() {
    difference() {
        union() {
            // Lid plate
            rounded_box(outer_width, outer_depth, lid_thickness, corner_radius);

            // Continuous alignment lip
            translate([lip_x0, lip_y0, -lip_height])
                linear_extrude(lip_height)
                    difference() {
                        square([lip_width, lip_depth]);
                        translate([lip_wall_thickness, lip_wall_thickness])
                            square([lip_width - 2*lip_wall_thickness, lip_depth - 2*lip_wall_thickness]);
                    }

            // Snap bumps on the lip outer faces
            for (cx = clip_x_front) snap_bump(-1, lip_y0, cx);     // front
            for (cx = clip_x_back)  snap_bump(+1, lip_y_back, cx); // back
        }

        // Relief slits beside each bump (rim stays continuous above them)
        for (cx = clip_x_front) snap_slits(lip_y0, cx);                       // front ring band
        for (cx = clip_x_back)  snap_slits(lip_y_back - lip_wall_thickness, cx); // back ring band

        // IDC 2x5 box-header windows
        // Footprint rotation 0: 2-pin axis along X, 5-pin axis along Y, so the
        // shroud is long in Y. Body (F.Fab) = 8.9 x 20.36 mm, centred on the
        // pad-field centre (pin1 + (1.27, 5.08)). Window = courtyard-ish + gap.
        // Centres below are PCB-relative to the board origin (body centres).
        idc_x = 9.8;     // short side (2-pin direction, X)
        idc_y = 21.0;    // long side  (5-pin direction, Y)
        for (idc = [[6.604, 60.198], [45.212, 60.325]])
            translate([board_x(idc[0]) - idc_x/2, pcb_y0 + idc[1] - idc_y/2, -lip_height - 0.1])
                cube([idc_x, idc_y, lip_height + lid_thickness + 0.2]);

        // (1x04 is internal -> no lid opening; reserved for a future display)

        // PinHeader 1x08 window (vertical header near left edge -> 8 pins along Y)
        // Body centre PCB-rel (2.54, 12.06), body 2.54 x 20.32 mm.
        ph8_x = 5.5;    // short side
        ph8_y = 21.0;   // long side (8-pin direction, Y)
        translate([board_x(2.54) - ph8_x/2, pcb_y0 + 12.06 - ph8_y/2, -lip_height - 0.1])
            cube([ph8_x, ph8_y, lip_height + lid_thickness + 0.2]);
    }
}

// ── Assembled (lid mated onto shell) ─────────────────────────────────────────
module assembled() {
    color("Tan")       bottom_shell();
    color("SteelBlue") translate([0, 0, shell_height])
        top_lid();
}

// ── Output ────────────────────────────────────────────────────────────────────
// view = "print"     -> both parts laid flat for printing (default)
//        "parts"     -> shell + lid upright, side by side (clean STEP export)
//        "assembled" -> lid mated onto shell
//        "section"   -> assembled, sliced through a clip to inspect the wedge
view = "print";

if (view == "print") {
    bottom_shell();
    translate([outer_width + 10, 0, lid_thickness])
        rotate([180, 0, 0])
            top_lid();
}
else if (view == "parts") {
    bottom_shell();
    translate([outer_width + 10, 0, lip_height])   // lid upright, lip resting on z=0
        top_lid();
}
else if (view == "assembled") {
    assembled();
}
else if (view == "section") {
    sx = clip_x_back[0];
    difference() {
        assembled();
        translate([-200, -200, -200])
            cube([200 + sx, 400, 400]);
    }
}
else if (view == "boss_section") {
    // Slice through an insert boss to inspect the blind hole
    bxpos = board_x(mount_holes[0][0]);
    difference() {
        bottom_shell();
        translate([bxpos, -200, -200])
            cube([400, 400, 400]);
    }
}
