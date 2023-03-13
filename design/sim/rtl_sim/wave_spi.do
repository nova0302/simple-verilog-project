onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /SPI_Master_With_Single_CS_TB/r_Rst_L
add wave -noupdate /SPI_Master_With_Single_CS_TB/r_SPI_En
add wave -noupdate /SPI_Master_With_Single_CS_TB/r_Clk
add wave -noupdate /SPI_Master_With_Single_CS_TB/w_SPI_Clk
add wave -noupdate /SPI_Master_With_Single_CS_TB/w_SPI_CS_n
add wave -noupdate /SPI_Master_With_Single_CS_TB/w_SPI_MOSI
add wave -noupdate /SPI_Master_With_Single_CS_TB/r_Master_TX_Byte
add wave -noupdate /SPI_Master_With_Single_CS_TB/r_Master_TX_DV
add wave -noupdate /SPI_Master_With_Single_CS_TB/w_Master_TX_Ready
add wave -noupdate /SPI_Master_With_Single_CS_TB/w_Master_RX_DV
add wave -noupdate /SPI_Master_With_Single_CS_TB/w_Master_RX_Byte
add wave -noupdate /SPI_Master_With_Single_CS_TB/w_Master_RX_Count
add wave -noupdate /SPI_Master_With_Single_CS_TB/r_Master_TX_Count
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {368 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 220
configure wave -valuecolwidth 64
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
WaveRestoreZoom {0 ns} {1678 ns}
