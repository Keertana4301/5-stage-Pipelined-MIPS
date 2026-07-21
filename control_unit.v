module control_unit(
    input      [5:0]        opcode,
    input      [5:0]        funct,
    output reg [1:0]        RegDst,
    output reg              Jump,
    output reg              Branch,
    output reg              MemRead,
    output reg              MemtoReg,
    output reg [2:0]        ALUOp,
    output reg              MemWrite,
    output reg              ALUSrc,
    output reg              RegWrite
);
    always @(*) begin
        RegDst = 2'b00;
        Jump = 1'b0;
        Branch = 1'b0;
        MemRead = 1'b0;
        MemtoReg = 1'b0;
        ALUOp = 3'b000;
        MemWrite = 1'b0;
        ALUSrc = 1'b0;
        RegWrite = 1'b0;
        
        case(opcode)
            6'b000000: begin 
                RegDst = 2'b01;     
                RegWrite = 1'b1;
                case(funct)
                    6'b100000: ALUOp = 3'b000; 
                    6'b100010: ALUOp = 3'b001; 
                    6'b100100: ALUOp = 3'b011; 
                    6'b100101: ALUOp = 3'b100; 
                    6'b101010: ALUOp = 3'b010; 
                    6'b100110: ALUOp = 3'b101; 
                    6'b100111: ALUOp = 3'b110; 
                    default:   ALUOp = 3'b000;
                endcase
            end
            
            6'b100011: begin 
                ALUSrc = 1'b1;
                MemtoReg = 1'b1;
                RegWrite = 1'b1;
                MemRead = 1'b1;
                ALUOp = 3'b000;    
            end
            
            6'b101011: begin 
                ALUSrc = 1'b1;
                MemWrite = 1'b1;
                ALUOp = 3'b000;     
            end
            
            6'b000100: begin 
                Branch = 1'b1;
                ALUOp = 3'b001;    
            end
            
            6'b001000: begin 
                ALUSrc = 1'b1;
                RegWrite = 1'b1;
                ALUOp = 3'b000;     
            end
            
            6'b001100: begin 
                ALUSrc = 1'b1;
                RegWrite = 1'b1;
                ALUOp = 3'b011;     
            end
            
            6'b001101: begin 
                ALUSrc = 1'b1;
                RegWrite = 1'b1;
                ALUOp = 3'b100;     
            end
            
            6'b001010: begin 
                ALUSrc = 1'b1;
                RegWrite = 1'b1;
                ALUOp = 3'b010;    
            end
            
            6'b000010: begin 
                Jump = 1'b1;
            end
            
            default: begin
                RegDst = 2'b00;
                Jump = 1'b0;
                Branch = 1'b0;
                MemRead = 1'b0;
                MemtoReg = 1'b0;
                ALUOp = 3'b000;
                MemWrite = 1'b0;
                ALUSrc = 1'b0;
                RegWrite = 1'b0;
            end
        endcase
    end
endmodule
