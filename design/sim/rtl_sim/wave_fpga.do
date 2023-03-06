onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /FPGA/serialOut
add wave -noupdate /FPGA/fifoOut
add wave -noupdate /FPGA/nRST
add wave -noupdate /FPGA/rcvReady
add wave -noupdate /FPGA/PIXEL_VALID
add wave -noupdate /FPGA/PIXEL_DATA
add wave -noupdate /FPGA/full
add wave -noupdate /FPGA/empty
add wave -noupdate /FPGA/DIN
add wave -noupdate /FPGA/rd
add wave -noupdate /FPGA/uart_clk
add wave -noupdate /FPGA/uart_skew
add wave -noupdate /FPGA/addi_clk
add wave -noupdate /FPGA/addi_skew
add wave -noupdate /FPGA/currState
add wave -noupdate /FPGA/byteReady
add wave -noupdate /FPGA/ldXmtDataReg
add wave -noupdate /FPGA/tByte
add wave -noupdate /FPGA/txDone
add wave -noupdate -radix unsigned /FPGA/channelCounter
add wave -noupdate -radix unsigned /FPGA/pixelCounter
add wave -noupdate /FPGA/ldFifoOut2Vector
add wave -noupdate /FPGA/fifoOutVector
add wave -noupdate /FPGA/dataBus
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {141895 ns} 0}
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
WaveRestoreZoom {0 ns} {151597 ns}
