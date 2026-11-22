 rem ============================================================
 rem  COSMOBLAST
 rem  Defender-style laser: one solid beam, base to edge
 rem ============================================================

 set smartbranching on
 set romsize 4k
 set kernel_options pfheights

 dim aim = a
 dim threatdir = b
 dim threatspd = c
 dim beamon = d
 dim ships = e
 dim threatacc = f
 dim kills = g
 dim state = h
 dim frame = i
 dim satstep = j
 dim invuln = k
 dim spawndelay = l
 dim diff = m
 dim beamdir = n
 dim beamlen = o
 dim lastk = p
 dim brkq = q
 dim shardx = r
 dim shardy = s
 dim brkt = t
 dim zapt = u
 dim boomt = v
 dim boomkind = w
 dim prevjoy = x
 dim joynow = y
 dim sc0 = score
 dim sc1 = score+1
 dim sc2 = score+2
 dim satalive = z
 rem breakup-only variables double as satellite state during play
 dim satmask = q
 dim divep = r
 dim satdraw = s

 rem aim/beamdir/threatdir: 0=up 1=right 2=down 3=left
 rem diff: 0=easy 1=normal 2=hard 3=expert (shown as game 1-4)
 rem state: 0=title 1=play 2=sat 3=die 4=over 5=breakup
 rem beamlen counts down the frames the beam stays on screen

 rem base is a double-width 5x9 diamond; its center column/row line up
 rem with beamx and beamrow. It sits right of center to meet the right
 rem playfield half.
 const centerx = 79
 const centery = 45
 const tipx = 85
 rem 8-wide enemy sprites centered on the vertical beam
 const threatx = 81
 rem frames on screen; 1 frame = 1/60 s
 const beamtime = 2
 const beamrow = 5
 const beamx = 85
 const beamuptop = 36
 const beamdowntop = 45
 const beambottom = 86
 rem ball bridges the playfield gap between base and the right half
 const bridgex = 90
 const beamrowy = 41

 diff = 1

boot
 aim = 0

 rem -------------------- TITLE --------------------
title
 player0x = centerx : player0y = centery
 player1y = 200 : missile1y = 200
 rem COSMO on top, BLAST at the bottom, base between; reflect for text
 CTRLPF = $01
 pfheights:
 4
 4
 4
 4
 4
 48
 4
 4
 4
 4
 4
end
 playfield:
 .......XXX.XXX.XXX.X.X.XXX......
 .......X...X.X.X...XXX.X.X......
 .......X...X.X.XXX.XXX.X.X......
 .......X...X.X...X.X.X.X.X......
 .......XXX.XXX.XXX.X.X.XXX......
 ................................
 .......XX..X...XXX.XXX.XXX......
 .......X.X.X...X.X.X....X.......
 .......XX..X...XXX.XXX..X.......
 .......X.X.X...X.X...X..X.......
 .......XX..XXX.X.X.XXX..X.......
end
 COLUBK = $00
 rem title shows only the game number; other digits blank
 sc0 = $AA : sc1 = $AA
 rem ignore fire briefly so a held button from game over doesn't skip select
 brkq = 30
 scorecolor = $1A

title_loop
 frame = frame + 1
 rem hue steps every 16 frames
 temp4 = frame & $F0
 COLUPF = temp4 | $0A
 gosub hide_beam
 gosub draw_base
 if brkq > 0 then brkq = brkq - 1
 rem left/right picks difficulty, one step per push
 temp1 = 0
 if joy0left then temp1 = 1
 if joy0right then temp1 = 2
 if temp1 = prevjoy then goto title_shown
 prevjoy = temp1
 if temp1 = 1 && diff > 0 then diff = diff - 1
 if temp1 = 2 && diff < 3 then diff = diff + 1
title_shown
 sc2 = diff + $A1
 drawscreen
 if brkq = 0 && joy0fire then goto start_game
 if switchreset then reboot
 goto title_loop

start_game
 score = 0
 ships = 3
 threatacc = 0
 kills = 0
 threatspd = spdstart[diff]
 invuln = 60
 rem beam is already off, satmask (= brkq) is 0 and the base is placed by the title
 zapt = 0 : boomt = 0
 lastk = 0
 spawndelay = 20
 pfclear
 rem row beamrow is thin so the horizontal beam matches the vertical one
 pfheights:
 8
 8
 8
 8
 8
 2
 9
 9
 9
 9
 10
end
 gosub spawn_threat

 rem -------------------- PLAY --------------------
play
 state = 1
 scorecolor = $0E

play_loop
 frame = frame + 1
 gosub pause_check
 if invuln > 0 then invuln = invuln - 1
 gosub sound_tick
 gosub read_aim
 gosub race_beam
 gosub move_threat
 gosub orbit_sat
 gosub check_base_hit
 gosub draw_base
 gosub draw_threat
 gosub draw_beam
 gosub show_ships
 drawscreen
 if switchreset then reboot
 if ships = 0 then goto breakup
 if state = 3 then goto dieflash
 goto play_loop

 rem -------------------- DEATH --------------------
dieflash
 COLUBK = $42
 drawscreen
 COLUBK = $00
 gosub spawn_threat
 goto play

 rem -------------------- BREAKUP (last hit) --------------------
 rem 30 frames of cracking, then the burst; 2 seconds total
breakup
 brkq = 0
 AUDV1 = 0
 player1y = 200 : missile1y = 200
 player1:
 %11000000
 %11000000
end

brk_loop
 frame = frame + 1
 brkq = brkq + 1
 NUSIZ0 = $15
 NUSIZ1 = $10
 CTRLPF = $10
 missile0height = 1
 missile1height = 1
 ballheight = 1
 if brkq < 31 then gosub brk_crack
 if brkq > 30 then gosub brk_burst
 drawscreen
 if switchreset then reboot
 if brkq > 120 then goto gameover
 goto brk_loop

brk_crack
 COLUBK = $00
 if brkq{2} then COLUBK = $40
 COLUP0 = $1E
 if brkq{0} then COLUP0 = $0E
 player0x = centerx - 1
 if brkq{1} then player0x = centerx + 1
 player0y = centery
 AUDC0 = 4 : AUDV0 = 8 : AUDF0 = 31 - brkq
 if brkq < 16 then gosub spr_crack1 : return
 gosub spr_crack2
 return

brk_burst
 brkt = brkq - 31
 COLUBK = $00
 if brkt < 6 then COLUBK = $42
 if brkt < 4 then COLUBK = $46
 if brkt < 2 then COLUBK = $0E
 temp3 = frame & 3
 temp4 = flashcols[temp3]
 COLUP0 = temp4 : COLUP1 = temp4 : COLUPF = temp4
 AUDC0 = 8 : AUDF0 = brkt / 4 + 4
 temp5 = brkt / 8
 AUDV0 = 15 - temp5
 AUDC1 = 15 : AUDF1 = 28 : AUDV1 = 0
 temp5 = brkt / 4
 if brkt < 48 then AUDV1 = 12 - temp5
 rem split/shard art is 7 bits wide, so shift left one double-width bit
 player0x = centerx - 2 : player0y = centery
 if brkt < 8 then gosub spr_split : goto brk_fly
 if brkt < 24 then gosub spr_shards : goto brk_fly
 if brkt < 44 then gosub spr_dust : goto brk_fly
 player0y = 200
brk_fly
 rem off-screen y hides an object; x alone wraps to the left edge
 if brkt > 34 then missile0y = 200 : missile1y = 200 : bally = 200 : player1y = 200 : return
 shardx = brkt * 2 : shardy = brkt
 missile0x = beamx - shardx : missile0y = beamrowy - shardy
 missile1x = beamx + shardx : missile1y = beamrowy - shardy
 ballx = beamx - shardx : bally = beamrowy + shardy
 player1x = beamx - 1 + shardx : player1y = beamrowy + shardy
 return

 rem -------------------- GAME OVER --------------------
gameover
 pfclear
 AUDV0 = 0 : AUDV1 = 0
 scorecolor = $44
 brkq = 0
 rem the kernel stores the right half pre-mirrored, so text needs reflect on
 CTRLPF = $01
 rem tall blank row 0, letters on rows 1-5; pfclear blanks the rest
 pfheights:
 36
 4
 4
 4
 4
 4
 8
 8
 8
 4
 4
end
 playfield:
 ................................
 XXX.XXX.X.X.XXX..XXX.X.X.XXX.XX.
 X...X.X.XXX.X....X.X.X.X.X...X.X
 X.X.XXX.XXX.XX...X.X.X.X.XX..XX.
 X.X.X.X.X.X.X....X.X.X.X.X...X.X
 XXX.X.X.X.X.XXX..XXX..X..XXX.X.X
end

over_loop
 frame = frame + 1
 rem slow red glow on the text
 temp4 = frame / 4
 temp4 = temp4 & 15
 if temp4 > 7 then temp4 = 15 - temp4
 COLUPF = temp4 * 2 + $40
 rem ignore fire for 1 second so a held button doesn't skip game over
 if brkq < 60 then brkq = brkq + 1
 drawscreen
 if brkq > 59 && joy0fire then goto boot
 if switchreset then reboot
 goto over_loop

 rem ============================================================
 rem  SOUND — ch0 beam zap; ch1 pop (0), explosion (1), chime (2), sat whirl
 rem ============================================================

 rem B&W switch pauses the game (Stella: F4 pause, F3 resume)
pause_check
 if !switchbw then return
 AUDV0 = 0 : AUDV1 = 0
pause_hold
 drawscreen
 if switchbw then goto pause_hold
 return

sound_tick
 AUDV0 = 0
 rem zap: bass "wom" sliding down from about 200 Hz to 70 Hz
 if zapt > 0 then zapt = zapt - 1 : AUDC0 = 6 : AUDF0 = 13 - zapt : AUDV0 = zapt + 3
 AUDV1 = 0
 if boomt > 0 then goto sound_boom
 rem satellite whirl: a warbling tone while it orbits and channel 1 is free
 if !satmask then return
 temp5 = frame & 15
 if temp5 > 7 then temp5 = 15 - temp5
 AUDC1 = 12 : AUDF1 = temp5 + 10 : AUDV1 = 5
 return
sound_boom
 boomt = boomt - 1
 rem kind 2: extra-hit chime rising in pitch
 if boomkind = 2 then AUDC1 = 4 : AUDF1 = boomt : AUDV1 = 8 : return
 AUDC1 = 8
 if boomkind = 0 then AUDF1 = 10 - boomt : AUDV1 = boomt + 6 : return
 rem explosion: noise that deepens and fades
 temp5 = boomt / 2
 AUDF1 = 31 - temp5
 AUDV1 = temp5
 return

 rem ============================================================
 rem  INPUT
 rem ============================================================

read_aim
 rem joystick port bits, active high: 1=up 2=down 4=left 8=right
 joynow = SWCHA / 16
 joynow = joynow ^ $0F
 rem a newly pressed direction always wins, even while another is held
 temp2 = prevjoy ^ $FF
 temp2 = temp2 & joynow
 rem prevjoy bits 4-5 count pulses fired, bit 6 marks a new press seen for one frame
 temp4 = prevjoy & $30
 if temp2 = 0 then prevjoy = joynow | temp4 : goto aim_keep
 rem analog sticks: ignore a new press while on a diagonal, and only accept a
 rem single direction once it holds for 2 frames, so drift blips never fire
 temp3 = joynow - 1
 temp3 = temp3 & joynow
 if temp3 > 0 then return
 temp5 = prevjoy & $40
 if temp5 > 0 then goto aim_new
 prevjoy = prevjoy | $40
 return
aim_new
 prevjoy = joynow
 goto aim_pick
aim_keep
 rem nothing new: keep aim while its direction is still held
 temp3 = aimbits[aim]
 temp3 = temp3 & joynow
 if temp3 > 0 then goto aim_fire
 temp2 = joynow
aim_pick
 if temp2{0} then aim = 0
 if temp2{1} then aim = 2
 if temp2{2} then aim = 3
 if temp2{3} then aim = 1
aim_fire
 rem only a pushed direction fires, 3 pulses per press
 if joynow = 0 then return
 temp4 = prevjoy & $30
 if temp4 = $30 then return
 gosub start_beam
 return

 data aimbits
 1, 8, 2, 4
end

start_beam
 rem only one beam on screen; a new pulse waits until the current one ends
 if beamon then return
start_beam_go
 prevjoy = prevjoy + 16
 beamon = 1
 beamdir = aim
 beamlen = beamtime
 rem a held direction re-fires every 2 frames; restart the zap only near its end
 if zapt < 4 then zapt = 10
 pfclear
 rem left half ends at column 15; right half begins at column 16
 if beamdir = 1 then pfhline 16 beamrow 31 on
 if beamdir = 3 then pfhline 0 beamrow 15 on
 return

 rem ============================================================
 rem  BEAM — one solid line, base to screen edge, ~1 second
 rem ============================================================

race_beam
 if !beamon then return
 rem stop on the frame after the last one drawn, so beamtime = 1 still shows
 if beamlen = 0 then gosub stop_beam : return
 gosub beam_hitscan
 beamlen = beamlen - 1
 return

stop_beam
 beamon = 0
 beamlen = 0
 gosub hide_beam
 pfclear
 return

 rem missile1 belongs to the satellite, so it isn't hidden here
hide_beam
 missile0x = 200 : missile0y = 200
 ballx = 200 : bally = 200
 missile0height = 1
 return

 rem ============================================================
 rem  DRAW — playfield row for left/right, ball strip for up/down
 rem ============================================================

draw_beam
 if !beamon then gosub hide_beam : return

 rem flash; ball and playfield share COLUPF, base/enemy keep their colors
 temp3 = frame & 3
 temp4 = flashcols[temp3]
 COLUPF = temp4

 rem no reflect (asymmetric playfield); ball 2 clocks wide for up/down
 CTRLPF = $10
 rem hide with off-screen y; an x of 200 wraps to the left edge
 missile0y = 200
 bally = 200

 rem ball y is its bottom edge; it extends ballheight upward
 if beamdir = 0 then ballx = beamx : bally = beamuptop : ballheight = beamuptop
 if beamdir = 2 then ballx = beamx : bally = beambottom : ballheight = beambottom - beamdowntop
 rem right: 8-clock ball fills the gap before the right playfield half
 if beamdir = 1 then CTRLPF = $30 : ballx = bridgex : bally = beamrowy - 1 : ballheight = 0
 rem playfield rows are an odd line count, the ball an even one; missile0 is
 rem drawn one line out of phase with the ball and fills the missing line
 if beamdir = 1 then NUSIZ0 = $35 : COLUP0 = temp4 : missile0x = bridgex : missile0y = beamrowy : missile0height = 0
 return

 rem ============================================================
 rem  HITSCAN — the whole lane from base to edge
 rem ============================================================

beam_hitscan
 rem a fresh spawn waits at the edge, so it can't die the frame it appears
 if spawndelay > 0 then goto scan_sat
 temp1 = player1x : temp2 = player1y
 gosub lane_hit
 if temp3 then gosub kill_threat
scan_sat
 if !satmask then return
 for temp4 = 0 to 2
 temp5 = satbit[temp4] & satmask
 if temp5 = 0 then goto scan_next
 gosub sat_pos
 rem convert the 4-wide missile to the threat sprite's coordinates
 temp1 = temp1 - 3 : temp2 = temp2 + 2
 gosub lane_hit
 if temp3 then gosub kill_sat
scan_next
 next
 return

 rem temp1/temp2 = target x/y; temp3 = 1 if inside the beam's lane
lane_hit
 temp3 = 0
 if beamdir = 1 then goto lane_right
 if beamdir = 3 then goto lane_left
 if temp1 < 60 then return
 if temp1 > 96 then return
 if beamdir = 0 && temp2 > 39 then return
 if beamdir = 2 && temp2 < 49 then return
 temp3 = 1
 return
lane_right
 if temp1 < tipx then return
 goto lane_row
lane_left
 if temp1 > 76 then return
lane_row
 if temp2 < 28 then return
 if temp2 > 60 then return
 temp3 = 1
 return

 data flashcols
 $0E, $1E, $44, $CE
end

 rem ============================================================
 rem  THREATS
 rem ============================================================

spawn_threat
 spawndelay = 20
 threatdir = rand & 3
 player1x = spawnx[threatdir] : player1y = spawny[threatdir]
 return

 data spawnx
 threatx, 140, threatx, 10
end
 data spawny
 2, 44, 80, 44
end

move_threat
 if spawndelay > 0 then spawndelay = spawndelay - 1 : return
 rem threatspd/256 steps per frame; the add wraps when a step is due
 temp5 = threatacc
 threatacc = threatacc + threatspd
 if threatacc >= temp5 then return
 temp6 = steptab[diff]
 if threatdir = 0 then player1y = player1y + temp6
 if threatdir = 1 then player1x = player1x - temp6
 if threatdir = 2 then player1y = player1y - temp6
 if threatdir = 3 then player1x = player1x + temp6
 return

 rem per difficulty: start speed, speed gained per kill, pixels per step
 data spdstart
 40, 100, 100, 128
end
 data ramptab
 3, 8, 8, 12
end
 data steptab
 1, 1, 2, 3
end

 rem table index = game + one step per 64 speed gained; satellites pay 5x
points_now
 temp6 = spdstart[diff]
 temp6 = threatspd - temp6
 temp6 = temp6 / 64
 temp6 = temp6 + diff
 temp6 = ptstab[temp6]
 return
 data ptstab
 1, 1, 1, 2, 4
end

 rem up to 3 satellites share one orbit (satmask bits 0-2); one is drawn per frame
orbit_sat
 if !satmask then missile1y = 200 : return
 rem 4-clock-wide missile block; player1 stays single width
 NUSIZ1 = $20
 missile1height = 2
 rem satalive low nibble counts orbits left; at 1 they all dive at the base
 temp3 = satalive & $0F
 if temp3 = 1 then goto sat_dive
 rem satstep is an orbit phase (top 3 bits = position)
 rem speed 3-12: grows with game and threat speed, plus a random 0-3 per wave
 temp1 = satstep
 temp2 = threatspd / 64
 temp3 = satalive / 16
 temp2 = temp2 + temp3 + diff + 3
 satstep = satstep + temp2
 if satstep < temp1 then satalive = satalive - 1
 goto sat_next
sat_dive
 divep = divep + 1
 if divep < 24 then goto sat_next
 satmask = 0 : missile1y = 200
 goto hit_base
sat_next
 satdraw = satdraw + 1
 if satdraw > 2 then satdraw = 0
 temp5 = satbit[satdraw] & satmask
 if temp5 = 0 then goto sat_next
 temp4 = satdraw
 gosub sat_pos
 missile1x = temp1 : missile1y = temp2
 return

 rem temp4 = satellite 0-2; returns its x/y in temp1/temp2
sat_pos
 temp3 = satoff[temp4] + satstep
 temp3 = temp3 / 32
 temp1 = satx[temp3] : temp2 = saty[temp3]
 temp5 = satalive & $0F
 if temp5 <> 1 then return
 rem diving: each 4 frames halves the distance to the base
 temp5 = divep / 4
 if temp5 = 0 then return
 for temp6 = 1 to temp5
 temp1 = temp1 + 84 : temp1 = temp1 / 2
 temp2 = temp2 + 42 : temp2 = temp2 / 2
 next
 return

 data satbit
 1, 2, 4
end
 data satoff
 0, 128, 64
end

 data satx
 84, 108, 116, 108, 84, 60, 52, 60
end
 data saty
 17, 25, 42, 60, 68, 60, 42, 25
end

 rem digit 1 = hits left, digit 2 = blank (font digit $A), digits 3-6 = score
show_ships
 rem extra hit each time the thousands digit rolls over (max 9 hits)
 temp1 = sc1 / 16
 if temp1 = lastk then goto show_digits
 lastk = temp1
 if ships < 9 then ships = ships + 1
 boomt = 20 : boomkind = 2
show_digits
 temp2 = ships * 16
 sc0 = temp2 | $0A
 return

check_base_hit
 if invuln > 0 then return
 if collision(player0,player1) then gosub hit_base
 return

kill_threat
 rem adds stop at 9,900 so 4 digits never overflow
 gosub points_now
 for temp5 = 1 to temp6
 if sc1 < $99 then score = score + 1
 next
 kills = kills + 1
 boomt = 8 : boomkind = 0
 temp5 = threatspd
 threatspd = threatspd + ramptab[diff]
 if threatspd < temp5 then threatspd = 255
 rem every 8th kill launches satellites that orbit while threats keep coming
 temp5 = kills & 7
 if temp5 > 0 then goto spawn_threat
 rem satalive low nibble: 2 to 4 orbits before they dive; bits 4-5: random speed
 satalive = (rand & 3) + 3 : satstep = 0 : divep = 0
 if satalive = 6 then satalive = 4
 temp5 = rand & $30
 satalive = satalive | temp5
 rem usually 1 satellite, sometimes 2, rarely 3
 temp5 = rand
 satmask = 1
 if temp5 < 64 then satmask = 3
 if temp5 < 12 then satmask = 7
 goto spawn_threat

kill_sat
 gosub points_now
 for temp5 = 1 to temp6
 if sc1 < $99 then score = score + 5
 next
 boomt = 24 : boomkind = 1
 temp5 = satbit[temp4] ^ $FF
 satmask = satmask & temp5
 return

hit_base
 if invuln > 0 then return
 ships = ships - 1
 invuln = 60
 beamon = 0
 gosub hide_beam
 pfclear
 boomt = 31 : boomkind = 1
 state = 3
 return

 rem ============================================================
 rem  ART — compact core; laser is the weapon
 rem ============================================================

draw_base
 COLUP0 = aimcols[aim]
 if invuln > 0 && frame{0} then COLUP0 = $0E
 rem double-width player: each bit is 2 clocks, so 5 bits = 10 wide
 NUSIZ0 = $05
 player0:
 %00100000
 %01110000
 %01110000
 %11111000
 %11111000
 %11111000
 %01110000
 %01110000
 %00100000
end
 return

spr_crack1
 player0:
 %00100000
 %01110000
 %01110000
 %11011000
 %11101000
 %11111000
 %01110000
 %01110000
 %00100000
end
 return

spr_crack2
 player0:
 %00100000
 %01010000
 %01100000
 %11011000
 %10111000
 %11011000
 %01010000
 %01110000
 %00000000
end
 return

spr_split
 player0:
 %00000000
 %01000100
 %01000100
 %11000110
 %11000110
 %11000110
 %01000100
 %01000100
 %00000000
end
 return

spr_shards
 player0:
 %10000010
 %00000000
 %00101000
 %10000010
 %00010000
 %10000010
 %00101000
 %00000000
 %10000010
end
 return

spr_dust
 player0:
 %10000010
 %00000000
 %00000000
 %00000000
 %00010000
 %00000000
 %00000000
 %00000000
 %10000010
end
 return

draw_threat
 COLUP1 = $46
 player1:
 %00011000
 %00111100
 %01111110
 %11011011
 %01111110
 %00111100
 %00011000
 %00000000
end
 return

 data aimcols
 $1E, $2A, $3A, $CA
end

