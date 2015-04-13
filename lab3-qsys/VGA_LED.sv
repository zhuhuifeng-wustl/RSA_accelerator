/*
 * Code for RSA Box, a hardware implementation of the RSA algorithm.
 */

module VGA_LED(input logic      clk,
        input logic             reset,
        input logic[31:0]       data_in,
        input logic             write,
        input                   chipselect,
        input logic[2:0]        address,
        output logic[31:0]      data_out 
    ); 

    /* instruction bits (KEY, ENCYPT, or DECRYPT) */
    logic[31:0] instrBits;
     
    /* structures for different things */
    logic[127:0] keyBits; 
    logic[159:0] encryptBits;
    logic[383:0] decryptBits;
    logic[127:0] outputBits; 

    /* enabler for ALU */
    logic[1:0] functionCall; 
  
    ALU alu_input( .*  );

    /*
        sidenote: addr selects WHICH 32 bit components
        of structures above to write into
    */

    /*
        sidenote: e will always be 65537
    */

    always_ff @(posedge clk)     
        
        if (reset) begin
            
            /* reset triggered when clock starts */
            data_out <= 32'd0; 
            instrBits <= 32'd0;     // reset typeof(instr)
            keyBits <= 128'd0;
            encryptBits <= 160'd0;
            decryptBits <= 384'd0;
            functionCall <= 2'd0; 

        end 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
        /* writing */                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
        else if (chipselect && write) begin
        
            /* instruction */
            if (address == 3'b000) begin
                instrBits[31:0] <= data_in[31:0];
            end
            
            /* keys instruction */  
            if(instrBits[1:0] == 2'b01) begin
                case(address)
                    3'b001: keyBits[31:0] <= data_in[31:0];
                    3'b010: keyBits[63:32] <= data_in[31:0];
                    3'b011: keyBits[95:64] <= data_in[31:0];
                    3'b100: begin
                        keyBits[127:96] <= data_in[31:0];
                        functionCall <= 2'b01; // all data recvd (trigger call)
                    end 
                endcase
            end
              
            /* encryption instruction */
            else if(instrBits[1:0] == 2'b10) begin
                case(address)
                    3'b001: encryptBits[31:0] <= data_in[31:0];
                    3'b010: encryptBits[63:32] <= data_in[31:0];
                    3'b011: encryptBits[95:64] <= data_in[31:0];
                    3'b100: encryptBits[127:96] <= data_in[31:0];
                    3'b101: begin
                        encryptBits[159:128] <= data_in[31:0];
                        functionCall <= 2'b10; // all data recvd
                    end
                endcase
            end
                 
            /* decryption instruction */
            else if(instrBits[1:0] == 2'b11) begin
                case(instrBits[4:2])
                    2'b00: begin
                        case(address)
                            3'b001: decryptBits[31:0] <= data_in[31:0];
                            3'b010: decryptBits[63:32] <= data_in[31:0];
                            3'b011: decryptBits[95:64] <= data_in[31:0];
                            3'b100: decryptBits[127:96] <= data_in[31:0];
                        endcase
                    end
                    
                    2'b01: begin
                        case(address)
                            3'b001: decryptBits[159:128] <= data_in[31:0];
                            3'b010: decryptBits[191:160] <= data_in[31:0];
                            3'b011: decryptBits[223:192] <= data_in[31:0];
                            3'b100: decryptBits[255:224] <= data_in[31:0];
                        endcase
                    end
                    
                    2'b10: begin
                        case(address)
                            3'b001: decryptBits[287:256] <= data_in[31:0];
                            3'b010: decryptBits[319:288] <= data_in[31:0];
                            3'b011: decryptBits[351:320] <= data_in[31:0];
                            3'b100: begin
                                decryptBits[383:352] <= data_in[31:0];
                                functionCall <= 2'b11;
                            end
                        endcase
                    end    
                endcase // endcase for _decryption instr_
            end
        end // end for _writing_
         
        /* reading */
        else if (chipselect && !write)
            case (address)
                4'b0000: data_out[31:0] <= outputBits[31:0];
                4'b0001: data_out[31:0] <= outputBits[63:32];
                4'b0010: data_out[31:0] <= outputBits[95:64];
                4'b0011: data_out[31:0] <= outputBits[127:96]; 
            endcase  
endmodule

module ALU(
        input logic             clk, 
        input logic             reset,
        input logic[127:0]      keyBits,
        input logic[1:0]        functionCall,
        input logic[383:0]      decryptBits,
        input logic[159:0]      encryptBits,
        output logic[127:0]     outputBits
    );
   
    /* used for Blakely algorithm (encrypt/decrypt) */
    logic[1:0] state; 
    logic[4:0] r, a, b, n; 
    logic[4:0] count; 
    logic step1, step2, step3; 
   
    always_ff @(posedge clk) begin
        
        /* reset triggered when clock starts */
        if(reset) begin
            state <= 2'b0; 
            r <= 5'd0; 
            count <= 5'd0;
            step1 <= 1'b1; 
            step2 <= 1'b0; 
            step3 <= 1'b0;
        end
    
        case(functionCall)
            
            2'b01: 
                outputBits[127:0] <= (keyBits[63:0] * keyBits[127:64]);
            
            2'b10:  
                case(state)
                    
                    /* state 0: idle */
                    1'b0: begin
                        r <= 5'd0; 
                        state <= 1'b1;
                        count <= 5'd0;
                        step1 <= 1'b1; 
                        step2 <= 1'b0; 
                        step3 <= 1'b0; 
                        a[4:0] <= encryptBits[4:0]; 
                        b[4:0] <= encryptBits[36:32]; 
                        n[4:0] <= encryptBits[66:64]; 
                        // outputBits[4:0] <= 5'd0; 
                    end
                    
                    1'b1:
                        case(count)
                            
                            5'd5: begin
                                outputBits[4:0] <= r[4:0]; 
                                state <= 1'b0;
                            end
                            
                            5'd0: begin
                                
                                if(step1) begin
                                    r[4:0]<= ((r[4:0] << 1) + (a[4] * b[4:0])); 
                                    step1 <= 1'b0; 
                                    step2 <= 1'b1; 
                                end
                                
                                else if(step2) begin
                                    if(r[4:0] >= n[4:0]) begin
                                        r[4:0] <= (r[4:0] - n[4:0]); 
                                    end
                                    step2 <= 1'b0; 
                                    step3 <= 1'b1; 
                                end
                                
                                else begin
                                    if(r[4:0] >= n[4:0]) begin
                                        r[4:0] <= (r[4:0] - n[4:0]); 
                                    end
                                    step3 <= 1'b0; 
                                    step1 <= 1'b1; 
                                    count <= (count+1); 
                                end
                            end
                            
                            5'd1: begin
                                if(step1) begin
                                    r[4:0] <= ((r[4:0] << 1) + (a[3] * b[4:0])); 
                                    step1 <= 1'b0; 
                                    step2 <= 1'b1; 
                                end
                                
                                else if(step2) begin
                                    if(r[4:0] >= n[4:0]) begin
                                        r[4:0] <= (r[4:0] - n[4:0]); 
                                    end
                                    step2 <= 1'b0; 
                                    step3 <= 1'b1; 
                                end
                                
                                else begin
                                    if(r[4:0] >= n[4:0]) begin
                                        r[4:0] <= (r[4:0]- n[4:0]); 
                                    end
                                    step3 <= 1'b0; 
                                    step1 <= 1'b1; 
                                    count <= (count + 1); 
                                end
                            end
                            
                            5'd2: begin
                                if(step1) begin
                                    r[4:0]<= ((r[4:0] << 1) + (a[2] * b[4:0])); 
                                    step1 <=1'b0; 
                                    step2 <= 1'b1; 
                                end
                                
                                else if(step2) begin
                                    if(r[4:0] >= n[4:0]) begin
                                        r[4:0] <= (r[4:0] - n[4:0]); 
                                    end
                                    step2 <= 1'b0; 
                                    step3 <= 1'b1; 
                                end
                                
                                else begin
                                    if(r[4:0] >= n[4:0]) begin
                                        r[4:0] <= (r[4:0] - n[4:0]); 
                                    end
                                    step3 <= 1'b0; 
                                    step1 <= 1'b1; 
                                    count <= (count+1); 
                                    end
                                end
                            
                            5'd3: begin
                                if(step1) begin
                                    r[4:0] <= ((r[4:0]<<1) + (a[1] * b[4:0])); 
                                    step1 <= 1'b0; 
                                    step2 <= 1'b1; 
                                end
                                
                                else if(step2) begin
                                    if(r[4:0] >= n[4:0]) begin
                                        r[4:0] <= (r[4:0] - n[4:0]); 
                                    end
                                    step2 <= 1'b0; 
                                    step3 <= 1'b1; 
                                    end
                                
                                else begin
                                    if(r[4:0] >= n[4:0]) begin
                                        r[4:0] <= (r[4:0] - n[4:0]); 
                                        end
                                    step3 <= 1'b0; 
                                    step1 <= 1'b1; 
                                    count <= (count+1); 
                                    end
                                end
                            
                            5'd4: begin
                                if(step1) begin
                                    r[4:0] <= ((r[4:0] << 1) + (a[0] * b[4:0])); 
                                    step1 <= 1'b0; 
                                    step2 <= 1'b1; 
                                    end
                                
                                else if(step2) begin
                                    if(r[4:0] >= n[4:0]) begin
                                        r[4:0] <= (r[4:0] - n[4:0]); 
                                        end
                                    step2 <= 1'b0; 
                                    step3 <= 1'b1; 
                                    end
                                
                                else begin
                                    if(r[4:0] >= n[4:0]) begin
                                        r[4:0] <= (r[4:0] - n[4:0]); 
                                        end
                                    step3 <= 1'b0; 
                                    step1 <= 1'b1; 
                                    count <= (count + 1); 
                                    end
                                end
                            endcase
                endcase
            
            /* will implement Extended Euclid's here */
            2'b11:
                outputBits[127:0] <= 2'd2; 
        endcase
        
    end
endmodule