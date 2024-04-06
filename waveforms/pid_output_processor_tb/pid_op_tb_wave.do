onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /PID_output_processor_tb/uut/clk
add wave -noupdate /PID_output_processor_tb/uut/rstn
add wave -noupdate /PID_output_processor_tb/uut/clk_pwm
add wave -noupdate -color Magenta -itemcolor Magenta /PID_output_processor_tb/uut/u_valid_o
add wave -noupdate -color Magenta -itemcolor Magenta /PID_output_processor_tb/uut/u_chn_o
add wave -noupdate -color Magenta -itemcolor Magenta -radix decimal /PID_output_processor_tb/uut/u_data_o
add wave -noupdate -color Turquoise -itemcolor Turquoise -radix decimal /PID_output_processor_tb/uut/u_data_ch0
add wave -noupdate -color Turquoise -itemcolor Turquoise -radix decimal /PID_output_processor_tb/uut/u_data_ch1
add wave -noupdate -color Turquoise -itemcolor Turquoise -radix decimal /PID_output_processor_tb/uut/u_data_ch2
add wave -noupdate -color Turquoise -itemcolor Turquoise -radix decimal /PID_output_processor_tb/uut/u_data_ch3
add wave -noupdate -color Turquoise -itemcolor Turquoise -radix decimal /PID_output_processor_tb/uut/u_data_ch0_abs
add wave -noupdate -color Turquoise -itemcolor Turquoise -radix decimal /PID_output_processor_tb/uut/u_data_ch1_abs
add wave -noupdate -color Turquoise -itemcolor Turquoise -radix decimal /PID_output_processor_tb/uut/u_data_ch2_abs
add wave -noupdate -color Turquoise -itemcolor Turquoise -radix decimal /PID_output_processor_tb/uut/u_data_ch3_abs
add wave -noupdate -color {Yellow Green} -itemcolor {Yellow Green} -radix decimal /PID_output_processor_tb/uut/counter_pwm
add wave -noupdate -color {Yellow Green} -itemcolor {Yellow Green} -radix decimal /PID_output_processor_tb/uut/pwm_thr_ch0
add wave -noupdate -color {Yellow Green} -itemcolor {Yellow Green} -radix decimal /PID_output_processor_tb/uut/pwm_thr_ch1
add wave -noupdate -color {Yellow Green} -itemcolor {Yellow Green} -radix decimal /PID_output_processor_tb/uut/pwm_thr_ch2
add wave -noupdate -color {Yellow Green} -itemcolor {Yellow Green} -radix decimal /PID_output_processor_tb/uut/pwm_thr_ch3
add wave -noupdate -color Gold -itemcolor Gold /PID_output_processor_tb/uut/motor_0_in_1
add wave -noupdate -color Gold -itemcolor Gold /PID_output_processor_tb/uut/motor_0_in_2
add wave -noupdate -color Gold -itemcolor Gold /PID_output_processor_tb/uut/motor_1_in_1
add wave -noupdate -color Gold -itemcolor Gold /PID_output_processor_tb/uut/motor_1_in_2
add wave -noupdate -color Gold -itemcolor Gold /PID_output_processor_tb/uut/motor_2_in_1
add wave -noupdate -color Gold -itemcolor Gold /PID_output_processor_tb/uut/motor_2_in_2
add wave -noupdate -color Gold -itemcolor Gold /PID_output_processor_tb/uut/motor_3_in_1
add wave -noupdate -color Gold -itemcolor Gold /PID_output_processor_tb/uut/motor_3_in_2
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {173881 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 458
configure wave -valuecolwidth 136
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
WaveRestoreZoom {476 ns} {197998 ns}
