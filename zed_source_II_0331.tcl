###############################################################################
#
# Vivado 2015.01 tcl file
# Usage :
# cd $work_dir
# source source.tcl
#
###############################################################################

set work_dir D:/Work/01_Zed_v201501/SBFILTER_II_0331
cd $work_dir
pwd

 set prj_name zed_filter
 set bd_name  zynq_system
 set wrp_name ${bd_name}_wrapper
 set phase_2  true
 set phase_3  false

###############################################################################

### Create Projects

 create_project $prj_name $prj_name -part xc7z020clg484-1 -force
 set_property board_part em.avnet.com:zed:part0:1.3 [current_project]

### Update IP Catalog

 set_property ip_repo_paths ip_repo [current_fileset]
 update_ip_catalog
#update_ip_catalog -add_ip ip_repo/cic.narl.org.tw_user_axi_clkgen_v3_0.zip -repo_path ip_repo
#update_ip_catalog -add_ip ip_repo/cic.narl.org.tw_user_axi_hdmi_tx_v1_0.zip -repo_path ip_repo
#update_ip_catalog -add_ip ip_repo/cic.narl.org.tw_user_filter_top_v4_0.zip -repo_path ip_repo
#update_ip_catalog -add_ip ip_repo/cic.narl.org.tw_user_fmc_gennum_vin_1080p_v2_0.zip -repo_path ip_repo

### Create Block Design

 if { [get_files *.bd] eq "" } {
   puts "INFO: Currently there are no designs in project, so creating one..."
   create_bd_design $bd_name
 } else {
   open_bd_design [get_files *.bd]
 }

### Top level instance

 current_bd_instance


###############################################################################

### Create instance: processing_system7_0, and set properties

 create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
 apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]
 set_property -dict [list CONFIG.PCW_USE_S_AXI_HP0 {1}] [get_bd_cells processing_system7_0]
 set_property -dict [list CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} CONFIG.PCW_EN_CLK0_PORT {1}] [get_bd_cells processing_system7_0]
 set_property -dict [list CONFIG.PCW_FPGA1_PERIPHERAL_FREQMHZ {150} CONFIG.PCW_EN_CLK1_PORT {1}] [get_bd_cells processing_system7_0]
 set_property -dict [list CONFIG.PCW_FPGA2_PERIPHERAL_FREQMHZ {200} CONFIG.PCW_EN_CLK2_PORT {1}] [get_bd_cells processing_system7_0]
 set_property -dict [list CONFIG.PCW_EN_RST1_PORT {1}] [get_bd_cells processing_system7_0]

 connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] [get_bd_pins processing_system7_0/FCLK_CLK0]
 connect_bd_net -net processing_system7_0_FCLK_CLK1 [get_bd_pins processing_system7_0/S_AXI_HP0_ACLK] [get_bd_pins processing_system7_0/FCLK_CLK1]

### Create instance: hdmitx_iic_U

 create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic:2.0 hdmitx_iic_U
 apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" Clk "/processing_system7_0/FCLK_CLK0 (100 MHz)" }  [get_bd_intf_pins hdmitx_iic_U/S_AXI]
 create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 hd_iic
 connect_bd_intf_net  [get_bd_intf_pins hdmitx_iic_U/IIC] [get_bd_intf_ports hd_iic]

### Create instance: hdmitx_clkgen_U

 create_bd_cell -type ip -vlnv cic.narl.org.tw:user:axi_clkgen:3.0 hdmitx_clkgen_U
 apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" Clk "/processing_system7_0/FCLK_CLK0 (100 MHz)" }  [get_bd_intf_pins hdmitx_clkgen_U/S_AXI]
 connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK2] [get_bd_pins hdmitx_clkgen_U/ref_clk]

### Create instance: hdmitx_U
### Create instance: hdmitx_vdma_U

 create_bd_cell -type ip -vlnv cic.narl.org.tw:user:axi_hdmi_tx:1.0 hdmitx_U
 create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vdma:6.2 hdmitx_vdma_U
 apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" Clk "/processing_system7_0/FCLK_CLK0 (100 MHz)" }  [get_bd_intf_pins hdmitx_U/s_axi]
 apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" Clk "/processing_system7_0/FCLK_CLK0 (100 MHz)" }  [get_bd_intf_pins hdmitx_vdma_U/S_AXI_LITE]
 apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/hdmitx_vdma_U/M_AXI_MM2S" Clk "/processing_system7_0/FCLK_CLK1 (142 MHz)" }  [get_bd_intf_pins processing_system7_0/S_AXI_HP0]

 set_property -dict [list CONFIG.c_m_axi_mm2s_data_width {64} CONFIG.c_m_axis_mm2s_tdata_width {64} CONFIG.c_mm2s_max_burst_length {16}] [get_bd_cells hdmitx_vdma_U]
 set_property -dict [list CONFIG.c_use_mm2s_fsync {1}] [get_bd_cells hdmitx_vdma_U]
 set_property -dict [list CONFIG.c_include_s2mm {0}] [get_bd_cells hdmitx_vdma_U]

 connect_bd_intf_net [get_bd_intf_pins hdmitx_vdma_U/M_AXIS_MM2S] [get_bd_intf_pins hdmitx_U/m_axis_mm2s]
 
 connect_bd_net [get_bd_pins hdmitx_clkgen_U/clk] [get_bd_pins hdmitx_U/hdmi_clk]
 
 connect_bd_net -net [get_bd_nets processing_system7_0_FCLK_CLK1] [get_bd_pins processing_system7_0/FCLK_CLK1] \
   [get_bd_pins hdmitx_U/m_axis_mm2s_clk] \
   [get_bd_pins hdmitx_vdma_U/m_axis_mm2s_aclk]

 connect_bd_net [get_bd_pins hdmitx_U/m_axis_mm2s_fsync] \
   [get_bd_pins hdmitx_vdma_U/mm2s_fsync] \
   [get_bd_pins hdmitx_U/m_axis_mm2s_fsync_ret]


if { $phase_2 eq "true" } {
### Create instance: filter_top_U
### Create instance: filter_vdma_U

 set_property -dict [list CONFIG.PCW_USE_S_AXI_HP1 {1}] [get_bd_cells processing_system7_0]
 connect_bd_net -net processing_system7_0_FCLK_CLK1 [get_bd_pins processing_system7_0/S_AXI_HP1_ACLK] [get_bd_pins processing_system7_0/FCLK_CLK1]

 create_bd_cell -type ip -vlnv cic.narl.org.tw:user:filter_top:4.0 filter_top_U
 create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vdma:6.2 filter_vdma_U
 set_property -dict [list CONFIG.c_m_axi_mm2s_data_width {64} CONFIG.c_m_axis_mm2s_tdata_width {32} CONFIG.c_mm2s_max_burst_length {16}] [get_bd_cells filter_vdma_U]
 set_property -dict [list CONFIG.c_m_axi_s2mm_data_width {64} CONFIG.c_s2mm_max_burst_length {16}] [get_bd_cells filter_vdma_U]
 set_property -dict [list CONFIG.c_use_mm2s_fsync {1} CONFIG.c_use_s2mm_fsync {1}] [get_bd_cells filter_vdma_U]

 apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" Clk "/processing_system7_0/FCLK_CLK0 (100 MHz)" }  [get_bd_intf_pins filter_vdma_U/S_AXI_LITE]
 apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/filter_vdma_U/M_AXI_MM2S" Clk "/processing_system7_0/FCLK_CLK1 (142 MHz)" }  [get_bd_intf_pins processing_system7_0/S_AXI_HP1]
 apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Slave  "/processing_system7_0/S_AXI_HP1" Clk "/processing_system7_0/FCLK_CLK1 (142 MHz)" }  [get_bd_intf_pins filter_vdma_U/M_AXI_S2MM]

 connect_bd_intf_net [get_bd_intf_pins filter_vdma_U/M_AXIS_MM2S] [get_bd_intf_pins filter_top_U/S_AXIS_MM2S]
 connect_bd_intf_net [get_bd_intf_pins filter_vdma_U/S_AXIS_S2MM] [get_bd_intf_pins filter_top_U/M_AXIS_S2MM]

 connect_bd_net -net [get_bd_nets hdmitx_U_m_axis_mm2s_fsync] \
   [get_bd_pins hdmitx_U/m_axis_mm2s_fsync] \
   [get_bd_pins filter_vdma_U/mm2s_fsync] \
   [get_bd_pins filter_vdma_U/s2mm_fsync]
 
 connect_bd_net -net [get_bd_nets processing_system7_0_FCLK_CLK1] \
   [get_bd_pins processing_system7_0/FCLK_CLK1] \
   [get_bd_pins filter_vdma_U/m_axis_mm2s_aclk] \
   [get_bd_pins filter_vdma_U/s_axis_s2mm_aclk]
 connect_bd_net -net [get_bd_nets processing_system7_0_FCLK_CLK1] \
   [get_bd_pins processing_system7_0/FCLK_CLK1] \
   [get_bd_pins filter_top_U/S_AXIS_MM2S_ACLK] \
   [get_bd_pins filter_top_U/M_AXIS_S2MM_ACLK] \
   [get_bd_pins filter_top_U/aclk]

 connect_bd_net -net [get_bd_nets rst_processing_system7_0_142M_peripheral_aresetn] \
   [get_bd_pins rst_processing_system7_0_142M/peripheral_aresetn] \
   [get_bd_pins filter_top_U/aresetn]

### Create instance: For constant value vcc & gnd

 set const_vcc_U [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 const_vcc_U]
 set_property -dict [list CONFIG.CONST_WIDTH {1} CONFIG.CONST_VAL {1}] [get_bd_cells const_vcc_U]
 set const_gnd_U [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 const_gnd_U]
 set_property -dict [list CONFIG.CONST_WIDTH {1} CONFIG.CONST_VAL {0}] [get_bd_cells const_gnd_U]

 connect_bd_net -net const_vcc_s [get_bd_pins const_vcc_U/dout] \
   [get_bd_pins filter_top_U/rgb2y_bypass]
 connect_bd_net -net const_gnd_s [get_bd_pins const_gnd_U/dout] \
   [get_bd_pins filter_top_U/filter_bypass]
}


if { $phase_3 eq "true" } {
### Create instance: sdi1_vin_U
### Create instance: sdi1_vin2axi4s_U
### Create instance: sdi1_vdma_U

 create_bd_cell -type ip -vlnv cic.narl.org.tw:user:fmc_gennum_vin_1080p:2.0 sdi1_vin_U
 create_bd_cell -type ip -vlnv xilinx.com:ip:v_vid_in_axi4s:3.0 sdi1_vin2axi4s_U
 set_property -dict [list CONFIG.C_M_AXIS_VIDEO_DATA_WIDTH {16} CONFIG.C_M_AXIS_VIDEO_FORMAT {0}] [get_bd_cells sdi1_vin2axi4s_U]
 create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vdma:6.2 sdi1_vdma_U
 set_property -dict [list CONFIG.c_m_axi_s2mm_data_width {64} CONFIG.c_s2mm_max_burst_length {8} CONFIG.c_s2mm_linebuffer_depth {1024}] [get_bd_cells sdi1_vdma_U]
 set_property -dict [list CONFIG.c_use_s2mm_fsync {0}] [get_bd_cells sdi1_vdma_U]
 set_property -dict [list CONFIG.c_include_mm2s {0}] [get_bd_cells sdi1_vdma_U]

### Create instance: sdi2_vin_U
### Create instance: sdi2_vin2axi4s_U
### Create instance: sdi2_vdma_U

 create_bd_cell -type ip -vlnv cic.narl.org.tw:user:fmc_gennum_vin_1080p:2.0 sdi2_vin_U
 create_bd_cell -type ip -vlnv xilinx.com:ip:v_vid_in_axi4s:3.0 sdi2_vin2axi4s_U
 set_property -dict [list CONFIG.C_M_AXIS_VIDEO_DATA_WIDTH {16} CONFIG.C_M_AXIS_VIDEO_FORMAT {0}] [get_bd_cells sdi2_vin2axi4s_U]
 create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vdma:6.2 sdi2_vdma_U
 set_property -dict [list CONFIG.c_m_axi_s2mm_data_width {64} CONFIG.c_s2mm_max_burst_length {8} CONFIG.c_s2mm_linebuffer_depth {1024}] [get_bd_cells sdi2_vdma_U]
 set_property -dict [list CONFIG.c_use_s2mm_fsync {0}] [get_bd_cells sdi2_vdma_U]
 set_property -dict [list CONFIG.c_include_mm2s {0}] [get_bd_cells sdi2_vdma_U]

 apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" Clk "/processing_system7_0/FCLK_CLK0 (100 MHz)" }  [get_bd_intf_pins sdi1_vdma_U/S_AXI_LITE]
 apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/processing_system7_0/M_AXI_GP0" Clk "/processing_system7_0/FCLK_CLK0 (100 MHz)" }  [get_bd_intf_pins sdi2_vdma_U/S_AXI_LITE]
 apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Slave "/processing_system7_0/S_AXI_HP0" Clk "/processing_system7_0/FCLK_CLK1 (142 MHz)" }  [get_bd_intf_pins sdi1_vdma_U/M_AXI_S2MM]
 apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Slave "/processing_system7_0/S_AXI_HP0" Clk "/processing_system7_0/FCLK_CLK1 (142 MHz)" }  [get_bd_intf_pins sdi2_vdma_U/M_AXI_S2MM]

 connect_bd_intf_net [get_bd_intf_pins sdi1_vin2axi4s_U/video_out] [get_bd_intf_pins sdi1_vdma_U/S_AXIS_S2MM]
 connect_bd_intf_net [get_bd_intf_pins sdi2_vin2axi4s_U/video_out] [get_bd_intf_pins sdi2_vdma_U/S_AXIS_S2MM]
 connect_bd_net -net [get_bd_nets processing_system7_0_FCLK_CLK1] [get_bd_pins processing_system7_0/FCLK_CLK1] \
   [get_bd_pins sdi1_vdma_U/s_axis_s2mm_aclk] \
   [get_bd_pins sdi1_vin2axi4s_U/aclk] \
   [get_bd_pins sdi1_vin_U/vdma_clk] \
   [get_bd_pins sdi2_vdma_U/s_axis_s2mm_aclk] \
   [get_bd_pins sdi2_vin2axi4s_U/aclk] \
   [get_bd_pins sdi2_vin_U/vdma_clk]
 connect_bd_net -net [get_bd_nets rst_processing_system7_0_142M_peripheral_aresetn] [get_bd_pins rst_processing_system7_0_142M/peripheral_aresetn] \
   [get_bd_pins sdi1_vin2axi4s_U/aresetn] \
   [get_bd_pins sdi2_vin2axi4s_U/aresetn]
 connect_bd_net [get_bd_pins sdi1_vin_U/vclk] [get_bd_pins sdi1_vin2axi4s_U/vid_io_in_clk]
 connect_bd_net [get_bd_pins sdi1_vin_U/video_vblank] [get_bd_pins sdi1_vin2axi4s_U/vid_vblank]
 connect_bd_net [get_bd_pins sdi1_vin_U/video_hblank] [get_bd_pins sdi1_vin2axi4s_U/vid_hblank]
 connect_bd_net [get_bd_pins sdi1_vin_U/video_de] [get_bd_pins sdi1_vin2axi4s_U/vid_active_video]
 connect_bd_net [get_bd_pins sdi1_vin_U/video_d] [get_bd_pins sdi1_vin2axi4s_U/vid_data]
 connect_bd_net [get_bd_pins sdi2_vin_U/vclk] [get_bd_pins sdi2_vin2axi4s_U/vid_io_in_clk]
 connect_bd_net [get_bd_pins sdi2_vin_U/video_vblank] [get_bd_pins sdi2_vin2axi4s_U/vid_vblank]
 connect_bd_net [get_bd_pins sdi2_vin_U/video_hblank] [get_bd_pins sdi2_vin2axi4s_U/vid_hblank]
 connect_bd_net [get_bd_pins sdi2_vin_U/video_de] [get_bd_pins sdi2_vin2axi4s_U/vid_active_video]
 connect_bd_net [get_bd_pins sdi2_vin_U/video_d] [get_bd_pins sdi2_vin2axi4s_U/vid_data]

 connect_bd_net -net const_vcc_s [get_bd_pins const_vcc_U/dout] \
   [get_bd_pins sdi1_vin_U/sel_in_ch1] \
   [get_bd_pins sdi1_vin_U/dly_rstn] \
   [get_bd_pins sdi1_vin2axi4s_U/aclken] \
   [get_bd_pins sdi1_vin2axi4s_U/axis_enable] \
   [get_bd_pins sdi1_vin2axi4s_U/vid_io_in_ce] \
   [get_bd_pins sdi2_vin_U/dly_rstn] \
   [get_bd_pins sdi2_vin2axi4s_U/aclken] \
   [get_bd_pins sdi2_vin2axi4s_U/axis_enable] \
   [get_bd_pins sdi2_vin2axi4s_U/vid_io_in_ce] \
 connect_bd_net -net const_gnd_s [get_bd_pins const_gnd_U/dout] \
   [get_bd_pins sdi1_vin_U/yydebug] \
   [get_bd_pins sdi1_vin2axi4s_U/rst] \
   [get_bd_pins sdi2_vin_U/sel_in_ch1] \
   [get_bd_pins sdi2_vin_U/yydebug] \
   [get_bd_pins sdi2_vin2axi4s_U/rst] \
}


### Create address segments

 set_property range 64K         [get_bd_addr_segs {processing_system7_0/Data/SEG_hdmitx_clkgen_U_reg0}]
 set_property offset 0x79000000 [get_bd_addr_segs {processing_system7_0/Data/SEG_hdmitx_clkgen_U_reg0}]
 set_property range 64K         [get_bd_addr_segs {processing_system7_0/Data/SEG_hdmitx_U_reg0}]
 set_property offset 0x70e00000 [get_bd_addr_segs {processing_system7_0/Data/SEG_hdmitx_U_reg0}]
if { $phase_2 eq "true" } {
 set_property offset 0x430C0000 [get_bd_addr_segs {processing_system7_0/Data/SEG_filter_vdma_U_Reg}]
}
if { $phase_3 eq "true" } {
 set_property offset 0x430C0000 [get_bd_addr_segs {processing_system7_0/Data/SEG_filter_vdma_U_Reg}]
}


###############################################################################
### Create interface ports
### Create ports

#HDMI IIC ports

#set HD_SDA [ create_bd_port -dir IO HD_SDA ]
#set HD_SCL [ create_bd_port -dir IO HD_SCL ]

#HDMI ports

 set HD_CLK   [ create_bd_port -dir O HD_CLK ]
 set HD_VSYNC [ create_bd_port -dir O HD_VSYNC ]
 set HD_HSYNC [ create_bd_port -dir O HD_HSYNC ]
 set HD_DE    [ create_bd_port -dir O HD_DE ]
 set HD_D     [ create_bd_port -dir O -from 15 -to 0 HD_D ]

 connect_bd_net [get_bd_ports HD_CLK] [get_bd_pins hdmitx_U/hdmi_out_clk]
 connect_bd_net [get_bd_ports HD_VSYNC] [get_bd_pins hdmitx_U/hdmi_16_vsync]
 connect_bd_net [get_bd_ports HD_HSYNC] [get_bd_pins hdmitx_U/hdmi_16_hsync]
 connect_bd_net [get_bd_ports HD_DE] [get_bd_pins hdmitx_U/hdmi_16_data_e]
 connect_bd_net [get_bd_ports HD_D] [get_bd_pins hdmitx_U/hdmi_16_data]


if { $phase_3 eq "true" } {
#SDI ports

 set p1CLK     [ create_bd_port -dir I -type clk p1CLK ]
 set p1H       [ create_bd_port -dir I p1H ]
 set p1V       [ create_bd_port -dir I p1V ]
 set p1F       [ create_bd_port -dir I p1F ]
 set p1DATA    [ create_bd_port -dir I -from 19 -to 0 p1DATA ]
 set p2CLK     [ create_bd_port -dir I -type clk p2CLK ]
 set p2H       [ create_bd_port -dir I p2H ]
 set p2V       [ create_bd_port -dir I p2V ]
 set p2F       [ create_bd_port -dir I p2F ]
 set p2DATA    [ create_bd_port -dir I -from 19 -to 0 p2DATA ]

 connect_bd_net [get_bd_pins sdi1_vin_U/p1clk]  [get_bd_pins sdi2_vin_U/p1clk]  [get_bd_ports p1CLK]
 connect_bd_net [get_bd_pins sdi1_vin_U/p1H]    [get_bd_pins sdi2_vin_U/p1H]    [get_bd_ports p1H]
 connect_bd_net [get_bd_pins sdi1_vin_U/p1V]    [get_bd_pins sdi2_vin_U/p1V]    [get_bd_ports p1V]
 connect_bd_net [get_bd_pins sdi1_vin_U/p1F]    [get_bd_pins sdi2_vin_U/p1F]    [get_bd_ports p1F]
 connect_bd_net [get_bd_pins sdi1_vin_U/p1data] [get_bd_pins sdi2_vin_U/p1data] [get_bd_ports p1DATA]
 connect_bd_net [get_bd_pins sdi1_vin_U/p2CLK]  [get_bd_pins sdi2_vin_U/p2CLK]  [get_bd_ports p2CLK]
 connect_bd_net [get_bd_pins sdi1_vin_U/p2H]    [get_bd_pins sdi2_vin_U/p2H]    [get_bd_ports p2H]
 connect_bd_net [get_bd_pins sdi1_vin_U/p2V]    [get_bd_pins sdi2_vin_U/p2V]    [get_bd_ports p2V]
 connect_bd_net [get_bd_pins sdi1_vin_U/p2F]    [get_bd_pins sdi2_vin_U/p2F]    [get_bd_ports p2F]
 connect_bd_net [get_bd_pins sdi1_vin_U/p2data] [get_bd_pins sdi2_vin_U/p2data] [get_bd_ports p2DATA]
}

###

 save_bd_design
 validate_bd_design
 make_wrapper -files [get_files *.bd] -top
 add_files -norecurse $prj_name/$prj_name.srcs/sources_1/bd/$bd_name/hdl/${bd_name}_wrapper.v

###

if { $phase_3 eq "true" } {
 add_files -fileset constrs_1 -norecurse $prj_name.xdc
 import_files -fileset constrs_1 $prj_name.xdc
} else {
 add_files -fileset constrs_1 -norecurse ${prj_name}_1.xdc
 import_files -fileset constrs_1 ${prj_name}_1.xdc
}


if { $bd_name eq "" } {
###report

 report_clocks > rpt/pre_report_clocks.rpt
 report_clock_interaction > rpt/pre_report_clock_interaction.rpt
 report_clock_networks > rpt/pre_report_clock_networks.rpt
#report_cdc > rpt/pre_report_cdc.rpt
 report_timing_summary > rpt/pre_report_timing_summary.rpt
 report_timing > rpt/pre_report_timing.rpt
#report_timing -from [all_inputs] -setup
#report_timing -to [all_outputs] -setup
#report_compile_order –constraints
}

if { [file exists $prj_name/$prj_name.runs/impl_1/${bd_name}_wrapper.sysdef] } {
 reset_run synth_1
}
 launch_runs impl_1 -to_step write_bitstream
#file mkdir $prj_name/$prj_name.sdk
#file copy -force $prj_name/$prj_name.runs/impl_1/${bd_name}_wrapper.sysdef $prj_name/$prj_name.sdk/${bd_name}_wrapper.hdf
#launch_sdk -workspace $prj_name/$prj_name.sdk -hwspec $prj_name/$prj_name.sdk/${bd_name}_wrapper.hdf

#close_project