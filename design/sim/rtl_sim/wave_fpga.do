onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /FPGA/serialOut
add wave -noupdate /FPGA/addi_clk
add wave -noupdate /FPGA/uart_clk
add wave -noupdate -expand /FPGA/fifoOut
add wave -noupdate /FPGA/nRST
add wave -noupdate /FPGA/PIXEL_DATA
add wave -noupdate /FPGA/full
add wave -noupdate -color Orchid -expand -subitemconfig {{/FPGA/empty[3]} {-color Orchid -height 17} {/FPGA/empty[2]} {-color Orchid -height 17} {/FPGA/empty[1]} {-color Orchid -height 17} {/FPGA/empty[0]} {-color Orchid -height 17}} /FPGA/empty
add wave -noupdate /FPGA/DIN
add wave -noupdate /FPGA/rd
add wave -noupdate /FPGA/currState
add wave -noupdate /FPGA/ldXmtDataReg
add wave -noupdate /FPGA/byteReady
add wave -noupdate /FPGA/tByte
add wave -noupdate -color Gold /FPGA/txDone
add wave -noupdate /FPGA/dataBus
add wave -noupdate -color Magenta -radix unsigned /FPGA/channelCounter
add wave -noupdate -divider {New Divider}
add wave -noupdate -expand /FPGA/fifoOutVector
add wave -noupdate {/FPGA/pick_fifo_gen[3]/pick0/nRST}
add wave -noupdate {/FPGA/pick_fifo_gen[3]/pick0/DIN}
add wave -noupdate {/FPGA/pick_fifo_gen[3]/pick0/PIXEL_VALID}
add wave -noupdate {/FPGA/pick_fifo_gen[3]/pick0/PIXEL_DATA}
add wave -noupdate {/FPGA/pick_fifo_gen[3]/pick0/currState}
add wave -noupdate -radix unsigned {/FPGA/pick_fifo_gen[3]/pick0/pixel_cnt}
add wave -noupdate {/FPGA/pick_fifo_gen[3]/fifo_async_top0/resetw}
add wave -noupdate {/FPGA/pick_fifo_gen[3]/fifo_async_top0/wr}
add wave -noupdate {/FPGA/pick_fifo_gen[3]/fifo_async_top0/full}
add wave -noupdate {/FPGA/pick_fifo_gen[3]/fifo_async_top0/fifoIn}
add wave -noupdate {/FPGA/pick_fifo_gen[3]/fifo_async_top0/resetr}
add wave -noupdate {/FPGA/pick_fifo_gen[3]/fifo_async_top0/rd}
add wave -noupdate -color Wheat {/FPGA/pick_fifo_gen[3]/fifo_async_top0/empty}
add wave -noupdate {/FPGA/pick_fifo_gen[3]/fifo_async_top0/fifoOut}
add wave -noupdate {/FPGA/pick_fifo_gen[3]/fifo_async_top0/mem}
add wave -noupdate {/FPGA/pick_fifo_gen[3]/fifo_async_top0/w_addr}
add wave -noupdate {/FPGA/pick_fifo_gen[3]/fifo_async_top0/r_addr}
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {5280 ns} 0}
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
WaveRestoreZoom {0 ns} {13999 ns}
