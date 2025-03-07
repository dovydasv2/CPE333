module CU_FSM( 
    input logic CLK, 
    input logic RST, 
    input logic [6:0] IR_OPCODE, 
    input logic cache_hit,          // Cache hit signal 
    input logic cache_dirty,        // Cache dirty bit signal 
    output logic PC_WRITE, 
    output logic REG_WRITE, 
    output logic MEM_WE2, 
    output logic MEM_RDEN1, 
    output logic MEM_RDEN2, 
    output logic cache_update,      // Cache update signal 
    output logic cache_we,          // Cache write enable signal 
    output logic rst 
); 
 
    // Define FSM states 
    typedef enum logic [2:0] { 
        RESET_STATE, 
        FETCH_STATE, 
        DECODE_STATE, 
        EXECUTE_STATE, 
        CACHE_STATE,     // New state for cache handling 
        MEMORY_STATE, 
        WRITEBACK_STATE 
    } state_t; 
 
    state_t current_state, next_state; 
 
    // State transition logic 
    always_ff @(posedge CLK or posedge RST) begin 
        if (RST) 
            current_state <= RESET_STATE; 
        else 
            current_state <= next_state; 
    end 
 
    // Next state and output logic 
    always_comb begin 
        // Default outputs 
        PC_WRITE = 0; 
        REG_WRITE = 0; 
        MEM_WE2 = 0; 
        MEM_RDEN1 = 0; 
        MEM_RDEN2 = 0; 
        cache_update = 0; 
        cache_we = 0; 
        rst = 0; 
 
        case (current_state) 
            RESET_STATE: begin 
                rst = 1;  // Reset signal 
                next_state = FETCH_STATE; 
            end 
 
            FETCH_STATE: begin 
                PC_WRITE = 1;   // Allow PC to increment 
                MEM_RDEN1 = 1;  // Read instruction from memory 
                next_state = DECODE_STATE; 
            end 
 
            DECODE_STATE: begin 
                // Transition based on opcode 
                case (IR_OPCODE) 
                    7'b0110111: next_state = EXECUTE_STATE; // LUI 
                    7'b0010111: next_state = EXECUTE_STATE; // AUIPC 
                    7'b1101111: next_state = EXECUTE_STATE; // JAL 
                    7'b1100111: next_state = EXECUTE_STATE; // JALR 
                    7'b1100011: next_state = EXECUTE_STATE; // BRANCH 
                    7'b0000011: next_state = CACHE_STATE;   // LOAD (start with cache) 
                    7'b0100011: next_state = CACHE_STATE;   // STORE (start with cache) 
                    7'b0010011: next_state = EXECUTE_STATE; // OP-IMM 
                    7'b0110011: next_state = EXECUTE_STATE; // OP 
                    7'b1110011: next_state = EXECUTE_STATE; // SYSTEM 
                    default:    next_state = RESET_STATE;    // Invalid opcode 
                endcase 
            end 
 
            EXECUTE_STATE: begin 
                // Execute the instruction (e.g., ALU operations) 
                next_state = WRITEBACK_STATE; 
            end 
 
            CACHE_STATE: begin 
                // Cache handling state 
                if (cache_hit) begin 
                    // If cache hit, proceed to memory or writeback 
                    if (IR_OPCODE == 7'b0100011) begin // STORE 
                        cache_we = 1;  // Enable cache write 
                        next_state = WRITEBACK_STATE; 
                    end else if (IR_OPCODE == 7'b0000011) begin // LOAD 
                        next_state = WRITEBACK_STATE; 
                    end 
                end else begin 
                    // Cache miss: Update cache with memory data 
                    cache_update = 1; 
                    if (cache_dirty) begin 
                        // Dirty block: Handle write-back 
                        MEM_WE2 = 1;   // Write back dirty block to memory 
                    end 
                    next_state = MEMORY_STATE; 
                end 
            end 
 
            MEMORY_STATE: begin 
                if (IR_OPCODE == 7'b0000011) begin // LOAD 
                    MEM_RDEN2 = 1;  // Enable memory read 
                end else if (IR_OPCODE == 7'b0100011) begin // STORE 
                    MEM_WE2 = 1;   // Enable memory write 
                end 
                next_state = WRITEBACK_STATE; 
            end 
 
            WRITEBACK_STATE: begin 
                if (IR_OPCODE != 7'b0100011) begin // Not STORE 
                    REG_WRITE = 1;  // Write back to register file 
                end 
                next_state = FETCH_STATE; 
            end 
 
            default: begin 
                next_state = RESET_STATE; 
            end 
        endcase 
    end 
 
endmodule