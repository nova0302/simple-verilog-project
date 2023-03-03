onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /FPGA/serialOut
add wave -noupdate /FPGA/fifoOut
add wave -noupdate /FPGA/nRST
add wave -noupdate /FPGA/GO
add wave -noupdate /FPGA/PUSH
add wave -noupdate /FPGA/PIXEL_DATA
add wave -noupdate /FPGA/full
add wave -noupdate -color Orchid /FPGA/empty
add wave -noupdate /FPGA/DIN
add wave -noupdate /FPGA/pick0/currState
add wave -noupdate /FPGA/index
add wave -noupdate /FPGA/rd
add wave -noupdate /FPGA/currState
add wave -noupdate /FPGA/ldXmtDataReg
add wave -noupdate /FPGA/byteReady
add wave -noupdate /FPGA/tByte
add wave -noupdate -color Gold /FPGA/txDone
add wave -noupdate -color Magenta /FPGA/selMsb
add wave -noupdate /FPGA/selMsbNext
add wave -noupdate /FPGA/dataBus
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1611 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 184
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
WaveRestoreZoom {1587 ns} {1690 ns}
