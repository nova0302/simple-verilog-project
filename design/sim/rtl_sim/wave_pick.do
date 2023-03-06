onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /pick_tb/CLK
add wave -noupdate /pick_tb/nRST
add wave -noupdate /pick_tb/GO
add wave -noupdate /pick_tb/DIN
add wave -noupdate /pick_tb/PUSH
add wave -noupdate /pick_tb/PIXEL_DATA
add wave -noupdate -radix unsigned /pick_tb/index
add wave -noupdate /pick_tb/dut/currState
add wave -noupdate -radix unsigned /pick_tb/dut/pixel_cnt
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {243 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {249 ns} {560 ns}
