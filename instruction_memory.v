module instruction_memory
(
     input                    clk,
     input      [31:0]        pc_addr,
     output     [31:0]        instruction
);
     integer i;
     reg [31:0] rom [255:0];
     wire [7:0] rom_addr = pc_addr[9:2];

     initial begin
          for (i = 0; i < 256; i = i + 1)
               rom[i] <= 32'd0;

          // idx0                                     comment
          rom[0]  <= 32'h00000000;  
          rom[1]  <= 32'h20010005;  // addi $1, $0, 5        $1=5
          rom[2]  <= 32'h2002000A;  
          rom[3]  <= 32'h00221820;  // add  $3, $1, $2       $3=15  (EX/MEM->EX forward, back-to-back)
          rom[4]  <= 32'hAC030000;  
          rom[5]  <= 32'h8C040000;  // lw   $4, 0($0)        $4=15
          rom[6]  <= 32'h00812820;  
          rom[7]  <= 32'h10210002;  // beq  $1, $1, 2        taken -> skip 2 instructions
          rom[8]  <= 32'h200603E7;  
          rom[9]  <= 32'h20070378;  // addi $7, $0, 888      (squashed, must NOT execute)
          rom[10] <= 32'h2008002A;  
          rom[11] <= 32'h0800000E;  // j    14               jump to word index 14
          rom[12] <= 32'h20090309;  
          rom[13] <= 32'h00000000;  // nop
          rom[14] <= 32'h200A0037;  
          rom[15] <= 32'h10220005;  // beq  $1, $2, 5        not taken ($1 != $2)
          rom[16] <= 32'h200B006F;  
          rom[17] <= 32'h00000000;  // nop
          rom[18] <= 32'h00000000;  
          rom[19] <= 32'h00000000;  
     end

     assign instruction = rom[rom_addr];
endmodule
