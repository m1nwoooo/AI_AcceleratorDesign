/***************************************************************************
 * Copyright (C) 2025 Intelligent System Architecture (ISA) Lab. All rights reserved. 
 * 
 * This file is written solely for academic use in
 * AI Accelerator Design course assignement 
 * School of Electrical and Electronic Engineering, Konkuk University 
 *
 * Unauthorized distribution is strictly prohibited.
 ***************************************************************************/
 
`timescale 1ns/1ns
 

// Behavioral memory 
module mem_behavior # (      //we can ctrl param optional       
    parameter firmware = "",
    parameter bitline = 16, 
    parameter bitaddr = 8, 
    parameter binary = 1 ) (
    input                   clk,
    input                   en,
    input                   we,
    input  [bitaddr-1:0]    addr,//addr to READ or WRITE
    input  [bitline-1:0]    din,//Input Data
    output [bitline-1:0]    dout//Output Data
);
    reg                 test; 
    reg [bitline-1:0]   dout_;
    reg [bitline-1:0]   memory [2**bitaddr - 1:0];//Mem array with 2^b addr
    assign #1 dout = dout_;
    //Initialize memory with FILE
    initial begin
        if (binary)
            $readmemb(firmware, memory);   
        else
            $readmemh(firmware, memory);
        test <= 1;
    end
 
    wire [bitline-1:0] memory_debug;
    assign memory_debug = memory[addr];
    
    always @ (posedge clk) begin
        if (we && en)
            memory[addr] <= din;//Write data2mem
        if (~we && en)
            dout_ <= memory[addr];//verify data
        if (we && en)     
            test <= (memory[addr] == din);//read mem2data
    end
endmodule


                      // Half Adder
module half_adder(        //module declaration
input  a,
input  b,
output sum,
output carry
);                        // Half Adder는 Carry in이 없다.
assign sum   = a ^ b; // Sum = a'b + ba' -> xor 
assign carry = a & b; //1+1인 경우에만 carry가 발생
endmodule                 //end declaration

                      // Full Adder
module full_adder(        //module declaration
input  a,
input  b,
input  cin,
output sum,
output carry
);
assign sum   = a ^ b ^ cin;             //a,b,cin의 조합이 1이 두개거나 모두 0이어야 sum이 0이다.
assign carry = (a & b) | (b ^ a) & cin; //a와 b가 1일 때 혹은,
                                        //a와 b 둘 중 하나가 1이고 carry in이 있어야 carry가 생긴다.
endmodule                                   //end declaration

                                                                            // 8bits Ripple Carry Adder
module adder8(                                                                  //Module declaration
input  [7:0] A,
input  [7:0] B,
output [7:0] S,
output       Cout
);
wire [7:0] carry;                                                           //handle carry with vector
                                                                             //by name 방식으로 instance화 한다.
half_adder HA0 (.a(A[0]),.b(B[0]),.sum(S[0]),.carry(carry[0]));              //LSB에는 carry in이 없어 반가산기를 사용한다.
full_adder FA0(.a(A[1]),.b(B[1]),.cin(carry[0]),.sum(S[1]),.carry(carry[1]));//이전 adder의 carry가 넘어오고 넘어간다.
full_adder FA1(.a(A[2]),.b(B[2]),.cin(carry[1]),.sum(S[2]),.carry(carry[2]));
full_adder FA2(.a(A[3]),.b(B[3]),.cin(carry[2]),.sum(S[3]),.carry(carry[3]));
full_adder FA3(.a(A[4]),.b(B[4]),.cin(carry[3]),.sum(S[4]),.carry(carry[4]));
full_adder FA4(.a(A[5]),.b(B[5]),.cin(carry[4]),.sum(S[5]),.carry(carry[5]));
full_adder FA5(.a(A[6]),.b(B[6]),.cin(carry[5]),.sum(S[6]),.carry(carry[6]));
full_adder FA6(.a(A[7]),.b(B[7]),.cin(carry[6]),.sum(S[7]),.carry(Cout));     //output으로 sum[7:0],Cout을 뱉는
                                                                              //Ripple Carry Adder가 완성되었다.

endmodule                                                                         //end declaration

                                                                        //4bits Multiplier 
module multiplier4(                                                         //module declaration
input   [3:0] A,
input   [3:0] B,
output  [7:0] P
);

wire signed [3:0] signed_A = A;                                         //A를 unsigned에서 signed 데이터로 전환해 음수의 곱까지 고려한다.
wire signed [7:0] signedEx_A= {{4{signed_A[3]}}, signed_A};             //A를 concatenate로 8비트까지 부호확장하여 추후 bit shift시 MSB를 보장한다.
                                                                         //B는 곱셈에만 이용되므로 굳이 필요없다.
wire signed [7:0] result0, result1, result2, result3;                   //B의 자리수와 A의 곱셈 결과를 전부 더하기 위해 wire선언
wire signed [7:0] sum1, sum2, sum3;
wire c1, c2, c3;

assign result0 = {8{B[0]}} & signedEx_A;                                //operand B의 자리수를 고려하여 signedEx_A와 연산
assign result1 = ({8{B[1]}} & signedEx_A) << 1;                         //10의 자리를 맞추기 위해 1비트 shift
assign result2 = ({8{B[2]}} & signedEx_A) << 2;                         //100의 자리를 맞추기 위해 2비트 shift
assign result3 = (({8{B[3]}} & signedEx_A) << 3) - (({4{B[3]}} & signedEx_A) << 4); //MSB(B[3])가 1인 경우 음수 이므로
                                                                                    //음수곱을 하도록 보정해준다.
// Adder로 합산
adder8 add1(.A(result0),  .B(result1), .S(sum1), .Cout(c1));            //각 자리수를 Adder로 연산한다.
adder8 add2(.A(sum1),     .B(result2), .S(sum2), .Cout(c2));            //add1의 sum1이 add2의 input이 되어 여러번의
adder8 add3(.A(sum2),     .B(result3), .S(sum3), .Cout(c3));            //add를 수행할 수 있게 된다.

// 최종 출력
assign P = sum3;                                                        //최종 연산 결과를 multiplier의 output으로 설정한다.
endmodule


// 16-bit Ripple Carry Adder
module adder16(
input  [15:0] A,
input  [15:0] B,
output [15:0] S,
output        Cout
);
wire [15:0] carry;
half_adder ha0 (.a(A[0]), .b(B[0]), .sum(S[0]), .carry(carry[0]));//1개의 HA instance화 
genvar i;
generate                                                //8비트 adder와 동일한 원리
    for (i = 1; i < 16; i = i + 1) begin : full_adders  //함수 선언, 반환 값이 크게 의미있지는 않다.
        full_adder fa (                                 //반복문을 이용해 가독성을 향상
            .a(A[i]),               //15개의 FA를 instance화
            .b(B[i]),               
            .cin(carry[i-1]),
            .sum(S[i]),
            .carry(carry[i])
        );
    end
endgenerate
assign Cout = carry[15];
endmodule

// Unsigned 4-bit Multiplier
module multiplier4_unsigned(                                        //A하위 4비트와 B하위 4비트를 연산할 곱셈기
input   [3:0] A,
input   [3:0] B,
output  [7:0] P
);
wire [7:0] multiplicand = {4'b0000, A};                         //unsigned extension해도 괜찮다.
wire [7:0] partial0, partial1, partial2, partial3;              //B의 자리수와 A의 곱셈 결과를 전부 더하기 위해 wire선언
wire [7:0] sum1, sum2, sum3;
wire c1, c2, c3;

assign partial0 = B[0] ? multiplicand : 8'b0;
assign partial1 = B[1] ? (multiplicand << 1) : 8'b0;
assign partial2 = B[2] ? (multiplicand << 2) : 8'b0;
assign partial3 = B[3] ? (multiplicand << 3) : 8'b0;            //양수*양수이ㅣ므로 음수 곱 고려가 필요없다.

adder8 add1(.A(partial0), .B(partial1), .S(sum1), .Cout(c1));
adder8 add2(.A(sum1),     .B(partial2), .S(sum2), .Cout(c2));
adder8 add3(.A(sum2),     .B(partial3), .S(sum3), .Cout(c3));

assign P = sum3;
endmodule

module signed_unsigned_mul4 (                                   //A의 상위 4비트와 B의 하위 4비트 곱셈기
input  [3:0] A,  
input  [3:0] B,  
output [7:0] P   
);
wire sign_A = A[3];                      //A는 상위 비트이므로 부호를 고려해야한다.
wire [3:0] abs_A = (sign_A) ? (~A + 1'b1) : A;  // 절대값을 이용해 연산 후, MSB를 고려할 예정이다.
                    

wire [3:0] unsigned_B = B;                      

wire [7:0] partial0 = unsigned_B[0] ? {4'b0, abs_A} : 8'b0;         //A와 B의 연산을 취해준다.
wire [7:0] partial1 = unsigned_B[1] ? {3'b0, abs_A, 1'b0} : 8'b0; //8비트에 맞추어 해당하는 자리수에 맞추어준다.
wire [7:0] partial2 = unsigned_B[2] ? {2'b0, abs_A, 2'b0} : 8'b0;
wire [7:0] partial3 = unsigned_B[3] ? {1'b0, abs_A, 3'b0} : 8'b0;

wire [7:0] sum1;                                          
wire [7:0] sum2;
wire [7:0] unsigned_product;
wire carry1, carry2, carry3;

adder8 add1 (.A(partial0), .B(partial1), .S(sum1), .Cout(carry1));  //각 partial 곱들을 add해준다.
adder8 add2 (.A(sum1), .B(partial2), .S(sum2), .Cout(carry2));
adder8 add3 (.A(sum2), .B(partial3), .S(unsigned_product), .Cout(carry3));

// 결과에 부호 적용
assign P = (sign_A) ? (~unsigned_product + 1'b1) : unsigned_product;//MSB가 1이었다면 다시 2의 보수를 취해 반환한다.
endmodule

module unsigned_signed_mul4 (                           //A의 하위 4비트와 B의 상위 4비트를 곱셈한다.
input  [3:0] A,  
input  [3:0] B,  
output [7:0] P   
);
wire [3:0] unsigned_A = A;

wire sign_B = B[3];                                 //B의 음/양을 판단한다.
wire [3:0] abs_B = (sign_B) ? (~B + 1'b1) : B;  // 절대값으로 연산 후, 나중에 부호 고려해준다.

wire [7:0] partial0 = abs_B[0] ? {4'b0, unsigned_A} : 8'b0;     //partial 곱들을 생성하고 , 자리수에 맞추어 shift해준다.
wire [7:0] partial1 = abs_B[1] ? {3'b0, unsigned_A, 1'b0} : 8'b0;
wire [7:0] partial2 = abs_B[2] ? {2'b0, unsigned_A, 2'b0} : 8'b0;
wire [7:0] partial3 = abs_B[3] ? {1'b0, unsigned_A, 3'b0} : 8'b0;

wire [7:0] sum1;
wire [7:0] sum2;
wire [7:0] unsigned_product;
wire carry1, carry2, carry3;

adder8 add1 (.A(partial0), .B(partial1), .S(sum1), .Cout(carry1));
adder8 add2 (.A(sum1), .B(partial2), .S(sum2), .Cout(carry2));
adder8 add3 (.A(sum2), .B(partial3), .S(unsigned_product), .Cout(carry3));

assign P = (sign_B) ? (~unsigned_product + 1'b1) : unsigned_product;    //최종 결과에 부호를 고려해준다.
endmodule

module mac8(
input               clk,        
input               rst,
input               en,             //연산 enable 신호
input   [7:0]       A,
input   [7:0]       B,
output reg          busy,           //연산 중임을 나타내는 플래그
output reg [15:0]   M               //누적된 결과
); 
wire [7:0] signed_A = A;            // 입력 A, B를 부호 있는 8비트 값으로
wire [7:0] signed_B = B;
reg [2:0] state;                    //fsm state 변수
reg [15:0] total;                   //누적값 저장 reg

wire [3:0] A_high = signed_A[7:4];  //A와 B를 분할하여 4비트씩 연산할 예정이다 
wire [3:0] A_low = signed_A[3:0];
wire [3:0] B_high = signed_B[7:4];
wire [3:0] B_low = signed_B[3:0];

wire [7:0] out0, out1, out2, out3;  //연산 결과를 wire로 받고
reg [7:0] out0_reg, out1_reg, out2_reg, out3_reg;//reg에 곱셈 결과를 저장해야한다

wire [15:0] total0, total1, total2, totalAll;//곱셈 결과를 덧셈하여 저장할 곳
wire carry_total, c1, c2, cAll;

multiplier4_unsigned mul0 (.A(A_low), .B(B_low), .P(out0));//각 비트들을 곱셈할 모듈 인스턴스화
unsigned_signed_mul4 mul1 (.A(A_low), .B(B_high), .P(out1));
signed_unsigned_mul4 mul2 (.A(A_high), .B(B_low), .P(out2));
multiplier4          mul3 (.A(A_high), .B(B_high), .P(out3));


wire [15:0] out0_ext = {{8'b0}, out0_reg}; //각각의 곱셈 결과를 16비트로 extension하고 자리수를 맞춰준다.
wire [15:0] out1_ext = {{4{out1_reg[7]}}, out1_reg, 4'b0};
wire [15:0] out2_ext = {{4{out2_reg[7]}}, out2_reg, 4'b0}; 
wire [15:0] out3_ext = {out3_reg, {8'b0}};

adder16 add0    (.A(total), .B(out0_ext), .S(total0), .Cout(carry_total));//각 곱셈 결과를 ext한 결과를 덧셈하는 모듈 instanceㅇ화
adder16 add1   (.A(total0), .B(out1_ext), .S(total1), .Cout(c1));
adder16 add2  (.A(total1), .B(out2_ext), .S(total2), .Cout(c2));
adder16 addAll (.A(total2), .B(out3_ext), .S(totalAll), .Cout(cAll));

always @(posedge clk) begin
    if (rst) begin
        // 리셋 시 모든 상태, 누산값, busy 플래그를 초기화한다.
        state <= 3'b000;
        M <= 16'b0;
        total <= 16'b0;  
        busy <= 1'b0;
        //$display(state);
    end 
    else begin
        case (state)
            3'b000: begin 
                //en 신호가 있을 때 부분 곱 out0를 레지스터에 저장한다.
                if (en) begin
                    busy <= 1'b1;      // 연산 중임을 표시
                    out0_reg <= out0;  // A_low * B_low 결과를 저장
                    state <= 3'b001;
                end
            end
            3'b001: begin 
                // out1 곱셈 결과를 저장하고, total과 결합한 결과를 출력
                out1_reg <= out1;      
                M <= M;         // 누산 초기값+ 첫 부분 곱
                state <= 3'b010;
                //$display("total0: %b", total0);
            end
            3'b010: begin
                // out2 곱셈 결과 저장, 이전 누산과 결합하여 total1 갱신
                out2_reg <= out2;
                M <= M;         // 누산값 + 두 번째 부분 곱
                state <= 3'b011;
                //$display("total1: %b", total1);
            end
            3'b011: begin
                // out3 곱셈 결과 저장 및 total2 결과 출력
                out3_reg <= out3;
                M <= M;         // 누산값 +  세 번째 부분 곱
                state <= 3'b100;
                //$display("total2: %b", total2);
            end
            3'b100: begin
                // 최종 누산값(totalAll)을 업데이트한다.
                total <= totalAll;  //total 계산용
                M <= totalAll;       // 최종 MAC 결과 출력
                out0_reg <= out0;
                state <= 3'b001;
               // $display("totalAll: %b", totalAll);
                
                if (en) begin// en 신호에 따라 다음 연산을 시작하거나 busy 플래그를 해제한다.
                    out0_reg <= out0;
                    state <= 3'b001;
                end else begin
                    busy <= 1'b0;  // 연산 종료 시 busy 를 0 및 state 초기화
                    state <= 3'b101;
                end   
            end
            3'b101: begin
                state<=3'b110;
                end
            3'b110:
                state<=3'b111;
            3'b111:begin
                state<=3'b000;
                busy<=0;
                end
                
            default: begin              //예외처리
                //$display("wrong state");  // state가 튀면 에러 발생 시 메시지 출력
                state <= 3'b000;    //x나 z같은 예상치 못한값이면 0들어갈 수 있게해준다.
            end
        endcase 
    end
end

endmodule


// 8-bit Output Stationary Systolic Element
module se8 (
input               clk,             
input               rst,              
input [6:0]         cnt,             

input       [7:0]   data_from_left,   // 왼쪽에서 들어오는 8비트 데이터 (A 행렬)
output reg  [7:0]   data_to_right,    // 오른쪽으로 전달되는 8비트 데이터

input       [15:0]  data_from_top,    // 위쪽에서 들어오는 16비트 데이터 (B 행렬)
output reg  [15:0]  data_to_bottom,   // 아래로 전달되는 16비트 데이터 (연산 결과)

input               en,              
input               req_out           // 출력 요청
);
wire [15:0] mac_M;                        // MAC 연산 결과
wire        mac_busy;                     // MAC 모듈의 busy 상태 신호

wire [7:0] se_A = data_from_left;           // 왼쪽에서 들어온 데이터를 MAC 입력 A로 연결
wire [7:0] se_B = data_from_top[7:0];       // 위쪽에서 들어온 데이터의 하위 8비트를 MAC 입력 B로 연결

// 8비트 MAC 모듈 인스턴스화
mac8 se_mac (
    .clk  (clk),                         
    .rst  (rst),                 
    .en   (en),                          
    .A    (se_A),                           // A 입력 데이터 연결
    .B    (se_B),                           // B 입력 데이터 연결
    .busy (mac_busy),                     // MAC의 busy
    .M    (mac_M)                         // MAC 연산 결과 출력
);

// 클럭 동기화 블록
always @(posedge clk) begin
    if (rst) begin
        data_to_right <= 8'd0;            // 리셋 시 오른쪽 출력 데이터 초기화
        data_to_bottom<= 16'd0;           // 리셋 시 아래쪽 출력 데이터 초기화
    end
    else begin
        data_to_right <= data_to_right;   // 디폴트로 오른쪽 출력 유지
        data_to_bottom<= data_to_bottom;  // 디폴트로 아래쪽 출력 유지
        
        if (en && (cnt % 4 == 0)) begin
            data_to_right <= data_from_left;  // 활성화되고 카운터가 4의 배수일 때, 왼쪽 데이터를 오른쪽으로 전달
            data_to_bottom <= data_from_top;  // 위쪽 데이터를 아래로 전달
        end
    
        if (req_out)
            data_to_bottom <= mac_M;         // 출력 요청 시 MAC 결과를 아래로 전달
    end
end
endmodule

// 4x4 Systolic Array 모듈
module sa8_4x4 (
input                   clk,              
input                   rst,              
input                   en,               
input                   req_out,          // 출력 요청
input       [8*4-1:0]   A,                
input       [8*4-1:0]   B,                
output  reg [16*4-1:0]  C,                // 4x16비트 출력 행렬 (연산 결과)
output  reg             busy              
);
wire [7:0] A_row[0:3];                        // A 행렬을 행 단위로 분리
wire [7:0] B_col[0:3];                        // B 행렬을 열 단위로 분리

// A 행렬을 8비트 행 단위로 분리
assign A_row[0] = A[31:24];                  
assign A_row[1] = A[23:16];                   
assign A_row[2] = A[15:8];                    
assign A_row[3] = A[7:0];                    

// B 행렬을 8비트 열 단위로 분리
assign B_col[0] = B[31:24];                   
assign B_col[1] = B[23:16];                
assign B_col[2] = B[15:8];                    
assign B_col[3] = B[7:0];                     

wire [7:0]  data_right[0:3][0:3];             // 각 SE의 오른쪽 출력 데이터
wire [15:0] data_bottom[0:3][0:3];            // 각 SE의 아래쪽 출력 데이터

reg [6:0] cnt;                       
// 카운터 및 busy 신호 제어 블록
always @(posedge clk) begin
    if(rst) begin
        cnt <= 6'd1;//리셋시 count와 busy를 초기화
        busy <= 1'b0;
    end
    if(en||cnt!=6'd1)begin
        if(cnt==6'd47)
            cnt<=1'd1;
            else
            cnt<=cnt+1'd1;//사이클 수에 따른 busy 처리
        end
        busy <= (cnt!=6'd0) && (cnt<6'd41);
        
end

// 4x4 SE 모듈을 인스턴스화 하여 행렬 생성
genvar i, j;
generate
    for (i = 0; i < 4; i = i + 1) begin : row           // 행 단위로 루프
        for (j = 0; j < 4; j = j + 1) begin : col       // 열 단위로 루프
            se8 sa_se8 (
                .clk(clk),                              // 클럭 신호 연결
                .rst(rst),                              // 리셋 신호 연결
                .data_from_left( (j == 0) ? A_row[i] : data_right[i][j-1] ), // 첫 열은 A_row, 나머지는 이전 SE의 출력
                .data_from_top(  (i == 0) ? {8'b0, B_col[j]} : data_bottom[i-1][j] ), // 첫 행은 B_col, 나머지는 위 SE의 출력
                .data_to_right(  data_right[i][j] ),    // 오른쪽으로 데이터 전달
                .data_to_bottom( data_bottom[i][j] ),   // 아래로 데이터 전달
                .en((cnt >= (i+j)*4 + 1) && (cnt <= (i+j)*4 + 16)), 
                .req_out(req_out),                      // req_out 신호 연결
                .cnt(cnt)                               
            );
        end
    end
endgenerate

// 출력 행렬 C 생성
//req_out 신호를 전달받고 연산완료된 C행렬들을 출력한다.
//1cycle 간격으로 가장 마지막 행부터 뽑는다.
always @(*) begin
    case(cnt)
        43: C <= {data_bottom[3][0], data_bottom[3][1], data_bottom[3][2], data_bottom[3][3]};
        44: C <= {data_bottom[2][0], data_bottom[2][1], data_bottom[2][2], data_bottom[2][3]}; 
        45: C <= {data_bottom[1][0], data_bottom[1][1], data_bottom[1][2], data_bottom[1][3]}; 
        46: C <= {data_bottom[0][0], data_bottom[0][1], data_bottom[0][2], data_bottom[0][3]};  
        default: C <= {data_bottom[3][0], data_bottom[3][1], data_bottom[3][2], data_bottom[3][3]}; //default는 B에서 아래로 넘겨주는 행렬 row값들이다.
    endcase
end

endmodule
// 

// Controller included inside top module
module ctrl (
    /* signals transferred from/to external (out of top) */
    input               clk,
    input               rst,
    input               run,//start signal to begin ctrl
    output  reg [1:0]   state,//state of ctrl (IDLE,LOAD,COMP,WRITE)
    
    output  reg         re_A,//read enable signal A
    output  reg [5:0]   addr_A,//Address from Mem A
    input       [7:0]   data_A,//data from Mem A
    
    output  reg         re_B,//read enable signal B
    output  reg [5:0]   addr_B,//Address from Mem B
    input       [7:0]   data_B,//data from Mem B
    
    output  reg         we_C,//write enable signal to store C
    output  reg [5:0]   addr_C,//addr in C mem..to write
    output  reg [15:0]  data_C,//result of A * B data
    
    /* signals transferred from/to systolic array */
    output  reg         sa_en,//enable signal to activate SA
    output  reg         sa_req_out,//request output from SA
    input               sa_busy,//when SA is computing 1
    output  reg [31:0]  sa_data_A,//input for SA
    output  reg [31:0]  sa_data_B,//input for SA
    input       [63:0]  sa_data_C//result from SA
    
);
    
    localparam IDLE    = 2'b00,  //waiting for run
               LOAD    = 2'b01,  //READ A ,B from MEM
               COMP = 2'b10,  //Compute data in SA
               WRITE   = 2'b11;//store result SA2MEM_C
               
    reg [1:0] tile_i, tile_j, tile_k;//IDX for tile
    reg [7:0] ctrl_cnt;   //have to track cycle to contrl each state
    reg [15:0] result_C [0:3][0:3];//result from SA(already accumulated values)
    reg [31:0] sa_A [0:6];//reg for transfer MEM_A2SA
    reg [31:0] sa_B [0:6];//reg for transfer MEM_B2SA

    integer i, j, n;
    
    always @(posedge clk or posedge rst) begin
        if(rst) begin       //default values are inserted in rst edge
            ctrl_cnt <= 0;  
            tile_i <= 0; tile_j <= 0; tile_k <= 0;
            
            re_A <= 0; re_B <= 0; we_C <= 0;
            addr_A <= 0; addr_B <= 0; addr_C <= 0;

            sa_en <= 0; sa_req_out <= 0;

            state <= IDLE;//default state is IDLE
            for(i = 0; i < 4; i = i + 1) 
                for(j= 0;j< 4; j = j+ 1)
                    result_C[i][j] <= 0;
            for (n = 0; n < 7; n = n + 1) begin
                sa_A[n] = 32'd0;    
                sa_B[n] = 32'd0;
            end

            sa_data_A <= 32'b0;
            sa_data_B <= 32'b0;

        end else begin
            case(state)
                IDLE: begin//IDLE state....waiting for run signal
                    if(run) begin
                        state <= LOAD;//state transfer
                        //Since rst is only set at start
                        //run have to act as a rst

                        //default values----------
                        tile_i <= 0; tile_j <= 0; tile_k <= 0;
                        ctrl_cnt <= 0;
                        for(i = 0; i < 4; i = i + 1) 
                            for(j= 0;j< 4; j = j+ 1)
                                result_C[i][j] <= 0;

                        for (n = 0; n < 7; n = n + 1) begin
                            sa_A[n] = 32'd0;    
                            sa_B[n] = 32'd0;
                        end
                        
                        sa_data_A <= 32'd0;
                        sa_data_B <= 32'd0;
                        //---------------default values
                    end
                end

                LOAD: begin
                    ctrl_cnt <= ctrl_cnt + 1;//cnt to trace each state
        
                    if(!(ctrl_cnt==18)) begin//if loading is still progress...
                        re_A <= 1; re_B <= 1;//en signal to read A,B from MEM
                        
                        //get addr A with row-wise(tile e.g. 0,1,2,3,8,9...)
                        //get addr B with col-wise(tile e.g. 0,8,16,24,1,9...)
                        addr_A <= (tile_i * 4 + ctrl_cnt / 4) * 8 + (tile_k * 4 + ctrl_cnt % 4);
                        addr_B <= (tile_k * 4 + ctrl_cnt % 4) * 8 + (tile_j * 4 + ctrl_cnt / 4);
                        
                        //delay 2 cycles to account for MEM read cycle 
                        //then store data_A, data_B to SA reg
                         if(ctrl_cnt >= 2 && ctrl_cnt <= 17) begin
                             sa_A[(ctrl_cnt - 2) % 4 + (ctrl_cnt - 2) / 4][31 - ((ctrl_cnt - 2) / 4) * 8 -: 8] <= data_A;
                             sa_B[(ctrl_cnt - 2) % 4 + (ctrl_cnt - 2) / 4][31 - ((ctrl_cnt - 2) / 4) * 8 -: 8] <= data_B;
                         end
//                        

                    end else begin//loading is over
                        addr_A <= 0; addr_B <= 0;//rst addr, en signal
                        re_A <= 0; re_B <= 0;
                        ctrl_cnt <= 0;//rst ctrl_cnt to count COMP
                        state <= COMP;//transfer to COMP
                    end
                end

                COMP: begin
                    ctrl_cnt <= ctrl_cnt + 1;//cnt to trace each state
                    sa_en <= 1'b0;          //sa_en rst
                    sa_req_out <= 1'b0;     //sa_req rst
                    if(!(ctrl_cnt==48)) begin  //if computing is still progress...
                        if(ctrl_cnt < 17 && (ctrl_cnt %4== 0 )) begin
                            sa_en <= 1'b1;//en_sa set 4 times to run SA
                        end else if(ctrl_cnt == 41) begin//SA need 40 cycles to caculate
                            sa_req_out <= 1'b1;//after calculating get data_C
                        end else if(ctrl_cnt > 41 && ctrl_cnt <= 46) begin//have to get data 4 times since 4*4 matrix...
                            for(i = 0; i < 4; i = i + 1)                //store SA result to result_C reg
                                result_C[ctrl_cnt - 43][i] <= sa_data_C[i * 16 +: 16];
                        end else begin
                            sa_en <= 1'b0;      //rst SA signals
                            sa_req_out <= 1'b0;
                        end
                        
                        if(ctrl_cnt < 28) begin //load data mem2SA 
                            sa_data_A <= sa_A[ctrl_cnt / 4];
                            sa_data_B <= sa_B[ctrl_cnt / 4];
                        end  

                    end else begin
                        ctrl_cnt <= 0; //rst ctrl_cnt
                        sa_data_A <= 32'b0;//rst sa signals
                        sa_data_B <= 32'b0;
                        
                        //if tile_k is 0 : tiling is not over.. goto LOAD
                        //if tile_k is 1 : tiling computation is over..goto WRITE
                        if (tile_k == 1) state <= WRITE;
                        else begin
                            tile_k <= tile_k + 1;//update k for next tile LOAD->COMP
                            state <= LOAD;
                        end
                    end
                end

                WRITE: begin
                    ctrl_cnt <= ctrl_cnt + 1;//cnt to trace each state

                    if(!(ctrl_cnt==16)) begin//if writing is still progress...
                        we_C <= 1;//write en signal set
                        //addr_c is same as addr_a...but changed tile_k to tile_j(row-wise)
                        //A[i][k] * B[k][j] = C[i][j]
                        addr_C <= (tile_i * 4 + ctrl_cnt / 4) * 8 + tile_j * 4 + (ctrl_cnt % 4);
                        //As we get SA output backward in assignment 3
                        //the index must be shape of(3-idx...) 
                        data_C <= result_C[3 - (ctrl_cnt) / 4][3 - (ctrl_cnt) % 4];
                    end else begin//when writing end
                        we_C <= 0;//rst write_signal
                        ctrl_cnt <= 0;
                        if (tile_j == 1) begin
                            if (tile_i == 1)//if all of c[i][j] datas written...
                                state <= IDLE;//state transfer
                            else begin//if not all the tile written
                                tile_i <= tile_i + 1;//update tile_i to LOAD
                                tile_j <= 0;
                                tile_k <= 0;
                                for(i = 0; i < 4; i = i + 1) //rst tile
                                    for(j= 0;j< 4; j = j+ 1)
                                        result_C[i][j] <= 0;
                                state <= LOAD;//go to second phase of LOAD
                            end
                        end else begin//if not all the tile written
                            tile_j <= tile_j + 1;//update tile_j to LOAD
                            tile_k <= 0;
                            for(i = 0; i < 4; i = i + 1) //rst tile
                                for(j= 0;j< 4; j = j+ 1)
                                    result_C[i][j] <= 0;
                            state <= LOAD;//go to second phase of LOAD
                        end
                    
                    end
                end
                
            endcase
        end
    end


endmodule


// MM with assignment 4 SA
module MM_sa (
    input               clk,
    input               rst,
    input               run,
    output      [1:0]   state,
    output              re_A,
    output      [5:0]   addr_A,
    input       [7:0]   data_A,
    output              re_B,
    output      [5:0]   addr_B,
    input       [7:0]   data_B,
    output              we_C,
    output      [5:0]   addr_C,
    output      [15:0]  data_C
);
    wire    [1:0]   state_;
    wire            re_A_, re_B_, we_C_;
    wire    [5:0]   addr_A_, addr_B_, addr_C_;
    wire    [15:0]  data_C_;
    reg             we_C_delay;
    
    wire         sa_en, sa_req_out, sa_busy;
    wire   [31:0]   sa_data_A, sa_data_B;
    wire   [63:0]   sa_data_C;
    wire            sa_rst;

    assign state = state_;
    assign re_A = re_A_; 
    assign re_B = re_B_; 
    assign we_C = we_C_;
    assign addr_A = addr_A_; 
    assign addr_B = addr_B_; 
    assign addr_C = addr_C_;
    assign data_C = data_C_;
    
    always @ (posedge clk or posedge rst) begin
        if (rst) we_C_delay <= 0;
        else we_C_delay <= we_C_;
    end
    assign sa_rst = we_C_ && ~we_C_delay;

    ctrl U_ctrl (
        .clk(clk), .rst(rst), .run(run), .state(state_),
        .re_A(re_A_), .addr_A(addr_A_), .data_A(data_A),
        .re_B(re_B_), .addr_B(addr_B_), .data_B(data_B),
        .we_C(we_C_), .addr_C(addr_C_), .data_C(data_C_),
        .sa_en(sa_en), .sa_req_out(sa_req_out), .sa_busy(sa_busy),
        .sa_data_A(sa_data_A), .sa_data_B(sa_data_B), .sa_data_C(sa_data_C)
    );

    sa8_4x4 U_sa (
        .clk(clk), .rst(rst || sa_rst), .en(sa_en), .req_out(sa_req_out), .busy(sa_busy),
        .A(sa_data_A), .B(sa_data_B), .C(sa_data_C)
    );              
endmodule

// Norm divide 32 (<<5)
module norm_layer (
    input               clk,
    input               rst,
    input               en,
    input       [15:0]  din,
    output reg  [7:0]   dout,
    output reg          valid
);
    always @(posedge clk) begin
        if (rst) begin
            dout <= 8'd0;
            valid <= 1'b0;
        end else if (en) begin
            dout <= din[12:5];  // divide by 32 (shift 5 bits)
            valid <= 1'b1;
        end else begin
            valid <= 1'b0;
        end
    end
endmodule

// ReLU max(0,x)
module relu_layer (
    input               clk,
    input               rst,
    input               en,
    input       [7:0]   din,
    output reg  [7:0]   dout,
    output reg          valid
);
    always @(posedge clk) begin
        if (rst) begin
            dout <= 8'd0;
            valid <= 1'b0;
        end else if (en) begin
            dout <= din[7] ? 8'd0 : din;// max(0,x) relu activate
            valid <= 1'b1;
        end else begin
            valid <= 1'b0;
        end
    end
endmodule

module TNN (
    input               clk,
    input               rst,
    input               run,
    input               batch_mode,    // 0 for 8-batch, 1 for 16-batch
    output reg  [2:0]   state,         // current state
    output              busy,         
    

    output              re_X,
    output      [6:0]   addr_X,        // 7bit for 16-batch(Max expression 127..)
    input       [7:0]   data_X,        // input x for 8b
    
    // Weight W1 from Mem
    output              re_W1,
    output      [5:0]   addr_W1,
    input       [7:0]   data_W1,
    
    // Weight W2 from Mem
    output              re_W2,
    output      [5:0]   addr_W2,
    input       [7:0]   data_W2,
    
    // Output Y from Mem
    output              we_Y,
    output      [6:0]   addr_Y,        // 7bit for 16-batch 
    output      [15:0]  data_Y
);
    //define states
    localparam  IDLE   = 3'b000,
                FC1    = 3'b001,
                NORM   = 3'b010,
                RELU   = 3'b011,
                FC2    = 3'b100,
                TRANSFER  = 3'b101;
    
    // Mem X1,X2,X3 provide results and sorces for FC1, NORM, RELU
    reg         we_X1, re_X1;
    reg  [6:0]  addr_X1;
    reg  [15:0] din_X1;
    wire [15:0] dout_X1;
    
    reg         we_X2, re_X2;
    reg  [6:0]  addr_X2;
    reg  [7:0]  din_X2;
    wire [7:0]  dout_X2;
    
    reg         we_X3, re_X3;
    reg  [6:0]  addr_X3;
    reg  [7:0]  din_X3;
    wire [7:0]  dout_X3;
    
    // Mem X4 keep FC2 results(Y)- batch 8 
    reg         we_X4, re_X4;
    reg  [6:0]  addr_X4;
    reg  [15:0] din_X4;
    wire [15:0] dout_X4;
    
    // Mem X5 keep FC2 results(Y)- batch 16
    reg         we_X5, re_X5;
    reg  [6:0]  addr_X5;
    reg  [15:0] din_X5;
    wire [15:0] dout_X5;
    
    
    // memory instantiation
    mem_behavior #("", 16, 7, 1) U_mem_X1 (
        .clk(clk), .en(we_X1 || re_X1), .we(we_X1),
        .addr(addr_X1), .din(din_X1), .dout(dout_X1)
    );
    
    mem_behavior #("", 8, 7, 1) U_mem_X2 (
        .clk(clk), .en(we_X2 || re_X2), .we(we_X2),
        .addr(addr_X2), .din(din_X2), .dout(dout_X2)
    );
    
    mem_behavior #("", 8, 7, 1) U_mem_X3 (
        .clk(clk), .en(we_X3 || re_X3), .we(we_X3),
        .addr(addr_X3), .din(din_X3), .dout(dout_X3)
    );
    
    // Memory for FC2 results - batch 8
    mem_behavior #("", 16, 7, 1) U_mem_X4 (
        .clk(clk), .en(we_X4 || re_X4), .we(we_X4),
        .addr(addr_X4), .din(din_X4), .dout(dout_X4)
    );
    
    // Memory for FC2 results - batch 16
    mem_behavior #("", 16, 7, 1) U_mem_X5 (
        .clk(clk), .en(we_X5 || re_X5), .we(we_X5),
        .addr(addr_X5), .din(din_X5), .dout(dout_X5)
    );
    
    //MM control signals 
    reg         fc_run;  // Single run signal for shared MM_sa
    wire [1:0]  fc_state;
    wire        fc_busy;
    
    // Shared FC signals
    wire        fc_re_A, fc_re_B, fc_we_C;
    wire [5:0]  fc_addr_A, fc_addr_B, fc_addr_C;
    wire [15:0] fc_data_C;
    
    // Input selection signals for shared MM_sa
    wire [7:0]  fc_data_A, fc_data_B;
    
    // Norm signals
    reg         norm_en;
    wire        norm_valid; 
    wire [7:0]  norm_dout;
    // RELU signals
    reg         relu_en;
    wire        relu_valid;
    wire [7:0]  relu_dout;
    // counters
    reg [6:0]   cycle_cnt;  // Overall cnt
    reg         batch_cnt; // in batch 16, we use this reg for offset to execute (9~16)batch
    reg         norm_done, relu_done;
    reg         batch_done; // batches have been completed
    
    // Weight memory connection based on state
    assign re_W1 = (state == FC1) ? fc_re_A : 1'b0;
    assign re_W2 = (state == FC2) ? fc_re_A : 1'b0;
    assign addr_W1 = fc_addr_A;
    assign addr_W2 = fc_addr_A;
    
    // Select appropriate weight data based on state
    assign fc_data_A = (state == FC1) ? data_W1 : data_W2;
    
    //busy signal accelerator is working when in any of these states
    assign busy = (state == FC1) || (state == NORM) ||(state == RELU) || (state == FC2)||(state==TRANSFER);

    // Memory addressing calculation for 16-batch mode
    // for 16-batch: X matrix is 8x16, need special addressing for batch 9~16
    // for 8-batch: X matrix is 8x8, use simple addressing
    wire [6:0] x_addr_batch16;
    wire [2:0] x_row, x_col;
    
    // convert linear address to row/column format
    assign x_row = fc_addr_B[5:3];  // row (0-7)
    assign x_col = fc_addr_B[2:0];  // column within 8x8 block
    
    // address calculation for 16-batch mode:
    // Final address = row * 16 + column + batch_offset
    assign x_addr_batch16 = batch_mode ? (x_row * 16 + x_col + (batch_cnt * 8)) :{1'b0, fc_addr_B};
    
    assign re_X = (state == FC1) ? fc_re_B : 1'b0;
    assign addr_X = (state == FC1) ? x_addr_batch16 : 7'd0;
    
    // Select appropriate input data based on state
    assign fc_data_B = (state == FC1) ? data_X : dout_X3;
    
    // FC2 reads from internal memory X3 (output of ReLU layer)
    wire [6:0] x3_addr_batch16;
    
    // apply same addressing conversion for X3 memory access
    assign x3_addr_batch16 = batch_mode ? ((fc_addr_B / 8) * 16 + (fc_addr_B % 8) + (batch_cnt * 8)) :{1'b0, fc_addr_B};
    
    // output Y memory connections - writes final results to external memory
    wire y_ready;
    wire [15:0] y_data;
    wire [6:0] y_addr;
    
    // Determine when to write output data
    assign y_ready = (state == TRANSFER) && (cycle_cnt >= 2) && (cycle_cnt < 66);
    assign y_data = (batch_cnt == 1'b0) ? dout_X4 : dout_X5;
    
    // calculate correct output address for Y mem
    wire [5:0] y_idx;
    wire [2:0] y_row, y_col;
    
    assign y_idx = cycle_cnt - 2;
    assign y_row = y_idx[5:3];  // Which row in result matrix
    assign y_col = y_idx[2:0];  // Which column in result matrix
    
    // Convert to proper addressing format for 16-batch mode
    assign y_addr = batch_mode ? (y_row * 16 + y_col + (batch_cnt * 8)) : y_idx;
    
    assign we_Y = y_ready;
    assign addr_Y = y_addr;
    assign data_Y = y_data;
    
    // Single shared MM_sa instance
    MM_sa FC (
        .clk(clk),
        .rst(rst),
        .run(fc_run),
        .state(fc_state),
        .re_A(fc_re_A),
        .addr_A(fc_addr_A),
        .data_A(fc_data_A),
        .re_B(fc_re_B),
        .addr_B(fc_addr_B),
        .data_B(fc_data_B),
        .we_C(fc_we_C),
        .addr_C(fc_addr_C),
        .data_C(fc_data_C)
    );
    
    // Norm (div by 32)
    norm_layer _norm (
        .clk(clk),
        .rst(rst),
        .en(norm_en),
        .din(dout_X1),
        .dout(norm_dout),
        .valid(norm_valid)
    );
    
    // RELU(max(0,x))
    relu_layer _relu (
        .clk(clk),
        .rst(rst),
        .en(relu_en),
        .din(dout_X2),
        .dout(relu_dout),
        .valid(relu_valid)
    );

    
    // Control logic for X3 memory read operations
    always @(*) begin
        if (state == FC2 && fc_re_B) begin
            re_X3 = 1'b1;
            addr_X3 = x3_addr_batch16;
        end else begin
            re_X3 = 1'b0;
            addr_X3 = 7'd0;
        end
    end

    // Main FSM for TNN
    always @(posedge clk) begin
        if (rst) begin
            // reset all control signals and cnts
            state <= 3'b0;
            fc_run <= 1'b0;
            cycle_cnt <= 7'd0;
            norm_en <= 1'b0;
            relu_en <= 1'b0;
            batch_cnt <= 1'b0;
            batch_done <= 1'b0;
            we_X1 <= 1'b0;
            re_X1 <= 1'b0;
            we_X2 <= 1'b0;
            re_X2 <= 1'b0;
            we_X3 <= 1'b0;
            we_X4 <= 1'b0;
            we_X5 <= 1'b0;
            norm_done <= 1'b0;
            relu_done <= 1'b0;

        end else begin

            case (state)
                IDLE: begin
                    // Wait for run signal, then start processing
                    if (run) begin
                        state <= FC1;
                        batch_cnt <= 1'b0;
                        batch_done <= 1'b0;
                        fc_run <= 1'b1;
                    end
                end
                
                FC1: begin
                    // FC1 running
                    fc_run <= 1'b0;
                    
                    //store FC1 results in X1 memory
                    if (fc_we_C) begin
                        we_X1 <= 1'b1;
                        // use different addressing modes for 8-batch, 16-batch
                        // if 16-batch 2nd phase-> batch cnt == 1 -> batch (9~16) execute 
                        if (batch_mode) begin
                            addr_X1 <= ((fc_addr_C / 8) * 16 + (fc_addr_C % 8) + (batch_cnt * 8));
                        end else begin
                            addr_X1 <= {1'b0, fc_addr_C};
                        end
                        din_X1 <= fc_data_C;
                    end else begin
                        we_X1 <= 1'b0;
                    end
                    
                    // transfer to norm when FC1 completes
                    if (fc_state == 2'b00 && !fc_run) begin
                        state <= NORM;
                        cycle_cnt <= 7'd0;
                        norm_done <= 1'b0;
                    end
                end
                
                NORM: begin
                    // NORM running
                    // read from X1
                    if (!norm_done) begin
                        if (cycle_cnt < 66) begin  // process 64 elements per batch
                            re_X1 <= 1'b1;
                            // calculate proper memory address based on batch mode
                            if (batch_mode) begin
                                addr_X1 <= ((cycle_cnt / 8) * 16 + (cycle_cnt % 8) + (batch_cnt * 8));
                            end else begin
                                addr_X1 <= cycle_cnt;
                            end
                            norm_en <= 1'b1;
                            cycle_cnt <= cycle_cnt + 1;
                        end else begin
                            re_X1 <= 1'b0;
                            norm_en <= 1'b0;
                            norm_done <= 1'b1;
                            cycle_cnt <= 7'd0;
                        end
                    end
                    
                    // write norm data to X2
                    if (norm_valid && cycle_cnt >= 3) begin
                        we_X2 <= 1'b1;
                        if (batch_mode) begin
                            addr_X2 <= (((cycle_cnt - 3) / 8) * 16 + ((cycle_cnt - 3) % 8) + (batch_cnt * 8));
                        end else begin
                            addr_X2 <= cycle_cnt - 3;
                        end
                        din_X2 <= norm_dout;
                    end else begin
                        we_X2 <= 1'b0;
                    end
                    
                    // move to RELU
                    if (norm_done && !norm_valid) begin
                        state <= RELU;
                        cycle_cnt <= 7'd0;
                        relu_done <= 1'b0;
                    end
                end
                
                RELU: begin
                    // RELU running
                    // read from X2
                    if (!relu_done) begin
                        if (cycle_cnt < 66) begin  // Process 64 elements per batch
                            re_X2 <= 1'b1;
                            // calculate proper memory address based on batch mode
                            if (batch_mode) begin
                                addr_X2 <= ((cycle_cnt / 8) * 16 + (cycle_cnt % 8) + (batch_cnt * 8));
                            end else begin
                                addr_X2 <= cycle_cnt;
                            end
                            relu_en <= 1'b1;
                            cycle_cnt <= cycle_cnt + 1;
                        end else begin
                            re_X2 <= 1'b0;
                            relu_en <= 1'b0;
                            relu_done <= 1'b1;
                            cycle_cnt <= 7'd0;
                        end
                    end
                    
                    // write RELU result X3
                    if (relu_valid && cycle_cnt >= 3) begin
                        we_X3 <= 1'b1;
                        if (batch_mode) begin
                            addr_X3 <= (((cycle_cnt - 3) / 8) * 16 + ((cycle_cnt - 3) % 8) + (batch_cnt * 8));
                        end else begin
                            addr_X3 <= cycle_cnt - 3;
                        end
                        din_X3 <= relu_dout;
                    end else begin
                        we_X3 <= 1'b0;
                    end
                    
                    // FC2
                    if (relu_done && !relu_valid ) begin
                        state <= FC2;
                        fc_run <= 1'b1;
                    end
                end
                
                FC2: begin
                    // FC2 ruunning
                    fc_run <= 1'b0;
                    
                    // store FC2 results in different memories based on which batch mode
                    if (fc_we_C) begin
                        if (batch_cnt == 1'b0) begin
                            // First batch results go to X4 memory
                            we_X4 <= 1'b1;
                            we_X5 <= 1'b0;
                            if (batch_mode) begin
                                addr_X4 <= ((fc_addr_C / 8) * 16 + (fc_addr_C % 8) + (batch_cnt * 8));
                            end else begin
                                addr_X4 <= {1'b0, fc_addr_C};
                            end
                            din_X4 <= fc_data_C;
                        end else begin
                            // Second batch results go to X5 memory
                            we_X4 <= 1'b0;
                            we_X5 <= 1'b1;
                            addr_X5 <= ((fc_addr_C / 8) * 16 + (fc_addr_C % 8) + (batch_cnt * 8));
                            din_X5 <= fc_data_C;
                        end
                    end else begin
                        we_X4 <= 1'b0;
                        we_X5 <= 1'b0;
                    end
                    
                    // move to TRANSFER
                    if (fc_state == 2'b00 && !fc_run) begin
                        state <= TRANSFER;
                        cycle_cnt <= 7'd0;
                    end
                end
                
                TRANSFER: begin
                    // output final results to external memory
                    if (cycle_cnt < 65) begin  // read 64 elements
                        if (cycle_cnt >= 0) begin
                            // Read from appropriate memory based on current batch
                            if (batch_cnt == 1'b0) begin
                                re_X4 <= 1'b1;
                                re_X5 <= 1'b0;
                                if (batch_mode) begin
                                    addr_X4 <= (((cycle_cnt) / 8) * 16 + ((cycle_cnt) % 8) + (batch_cnt * 8));
                                end else begin
                                    addr_X4 <= cycle_cnt;
                                end
                            end else begin
                                re_X4 <= 1'b0;
                                re_X5 <= 1'b1;
                                addr_X5 <= (((cycle_cnt) / 8) * 16 + ((cycle_cnt) % 8) + (batch_cnt * 8));
                            end
                        end
                        cycle_cnt <= cycle_cnt + 1;
                    end else begin
                        re_X4 <= 1'b0;
                        re_X5 <= 1'b0;
                        cycle_cnt <= 7'd0;
                        
                        // decide whether to process another batch or finish
                        if (batch_mode == 1'b1 && batch_cnt == 1'b0) begin
                            //batch 16 - need to process second batch(9~16)
                            batch_cnt <= 1'b1;
                            state <= FC1;
                            fc_run <= 1'b1;
                        end else begin
                            // all processing complete (8-batch or 16-batch second batch done)
                            batch_done <= 1'b1;
                            state <= IDLE;
                        end
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule
