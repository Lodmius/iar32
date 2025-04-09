/*------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Copyright (c) 2016, Loongson Technology Corporation Limited.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this 
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, 
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3. Neither the name of Loongson Technology Corporation Limited nor the names of 
its contributors may be used to endorse or promote products derived from this 
software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
DISCLAIMED. IN NO EVENT SHALL LOONGSON TECHNOLOGY CORPORATION LIMITED BE LIABLE
TO ANY PARTY FOR DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE 
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--------------------------------------------------------------------------------
------------------------------------------------------------------------------*/

`include "config.h"

module soc_top #(parameter SIMULATION=1'b0)
(
    input           clk,                //50MHz ʱ������
    input           reset,              //BTN6�ֶ���λ��ť���أ���������·������ʱΪ1

    //ͼ������ź�
    output [2:0]    video_red,          //��ɫ���أ�3λ
    output [2:0]    video_green,        //��ɫ���أ�3λ
    output [1:0]    video_blue,         //��ɫ���أ�2λ
    output          video_hsync,        //��ͬ����ˮƽͬ�����ź�
    output          video_vsync,        //��ͬ������ֱͬ�����ź�
    output          video_clk,          //����ʱ�����
    output          video_de,           //��������Ч�źţ���������������

    input           clock_btn,          //BTN5�ֶ�ʱ�Ӱ�ť���أ���������·������ʱΪ1
    input  [3:0]    touch_btn,          //BTN1~BTN4����ť���أ�����ʱΪ1
    input  [31:0]   dip_sw,             //32λ���뿪�أ�������ON��ʱΪ1
    output [15:0]   leds,               //16λLED�����ʱ1����
    output [7:0]    dpy0,               //����ܵ�λ�źţ�����С���㣬���1����
    output [7:0]    dpy1,               //����ܸ�λ�źţ�����С���㣬���1����

    //BaseRAM�ź�
    inout  [31:0]   base_ram_data,      //BaseRAM���ݣ���8λ��CPLD���ڿ���������
    output [19:0]   base_ram_addr,      //BaseRAM��ַ
    output [ 3:0]   base_ram_be_n,      //BaseRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output          base_ram_ce_n,      //BaseRAMƬѡ������Ч
    output          base_ram_oe_n,      //BaseRAM��ʹ�ܣ�����Ч
    output          base_ram_we_n,      //BaseRAMдʹ�ܣ�����Ч
    //ExtRAM�ź�
    inout  [31:0]   ext_ram_data,       //ExtRAM����
    output [19:0]   ext_ram_addr,       //ExtRAM��ַ
    output [ 3:0]   ext_ram_be_n,       //ExtRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output          ext_ram_ce_n,       //ExtRAMƬѡ������Ч
    output          ext_ram_oe_n,       //ExtRAM��ʹ�ܣ�����Ч
    output          ext_ram_we_n,       //ExtRAMдʹ�ܣ�����Ч

    //Flash�洢���źţ��ο� JS28F640 оƬ�ֲ�
    output [22:0]   flash_a,            //Flash��ַ��a0����8bitģʽ��Ч��16bitģʽ������
    inout  [15:0]   flash_d,            //Flash����
    output          flash_rp_n,         //Flash��λ�źţ�����Ч
    output          flash_vpen,         //Flashд�����źţ��͵�ƽʱ���ܲ�������д
    output          flash_ce_n,         //FlashƬѡ�źţ�����Ч
    output          flash_oe_n,         //Flash��ʹ���źţ�����Ч
    output          flash_we_n,         //Flashдʹ���źţ�����Ч
    output          flash_byte_n,       //Flash 8bitģʽѡ�񣬵���Ч����ʹ��flash��16λģʽʱ����Ϊ1

    //------uart-------
    inout           UART_RX,            //����RX����
    inout           UART_TX             //����TX����
);

wire cpu_clk;
wire cpu_resetn;
wire sys_clk;
wire sys_resetn;

generate if(SIMULATION) begin: sim_clk
    //simulation clk.
    reg clk_sim;
    initial begin
        clk_sim = 1'b0;
    end
    always #15 clk_sim = ~clk_sim;

    assign cpu_clk = clk_sim;
    assign sys_clk = clk;
    rst_sync u_rst_sys(
        .clk(sys_clk),
        .rst_n_in(~reset),
        .rst_n_out(sys_resetn)
    );
    rst_sync u_rst_cpu(
        .clk(cpu_clk),
        .rst_n_in(sys_resetn),
        .rst_n_out(cpu_resetn)
    );
end
else begin: pll_clk
    clk_pll u_clk_pll(
        .cpu_clk    (cpu_clk),
        .sys_clk    (sys_clk),
        .resetn     (~reset),
        .locked     (pll_locked),
        .clk_in1    (clk)
    );
    rst_sync u_rst_sys(
        .clk(sys_clk),
        .rst_n_in(pll_locked),
        .rst_n_out(sys_resetn)
    );
    rst_sync u_rst_cpu(
        .clk(cpu_clk),
        .rst_n_in(sys_resetn),
        .rst_n_out(cpu_resetn)
    );
end
endgenerate

//TODO: add your code

endmodule

