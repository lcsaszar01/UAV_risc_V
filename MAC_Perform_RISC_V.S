#RISC-V text for graph.c 
#author@lcsaszar01

#start of assembly code

SB s1, 0, imm #store the accumulator bit at 0 to start



#start of main Function 
MAIN:
    LW t1, 0(s1) # Load the result to print.


    jal x0, FEXIT
#Code for the PerformMAC Function

#The For Loop
addi s1, s1, 0
FOR1: #start of the for loop in performMAC func
    beq s1, x0, EXIT

    

    jal x0, MAIN

EXIT1:

FEXIT: 