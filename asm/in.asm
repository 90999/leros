//
// A small hello world
//
// write Leros to the UART
//

	nop	// first instruction is not executed
	nop // second instruction is exectuted twice
//Stack is increasing, starting at zero
//All registers are callee save

//Register Layout
//r0 link register
//r1 stack pointer
//r2 return value
//r3 first argument
//r3 second argument

start:
	load 0
	loadh	4 //4kb
	store r1 //Stack pointer
	load <main
	nop
	jal r0
	nop

main:
	FUNCTION_ENTER(r3)
	
	load 76
	loadh 0
	loadhl 0
	loadhh 0
	store r3
	FUNCTION_CALL(send)

	load 101
	store r3
	FUNCTION_CALL(send)

	load 114
	store r3
	FUNCTION_CALL(send)

	load 111
	store r3
	FUNCTION_CALL(send)

	load 115
	store r3
	FUNCTION_CALL(send)

	load 13 //CR
	store r3
	FUNCTION_CALL(send)

	load 10 //LF
	store r3
	FUNCTION_CALL(send)

	FUNCTION_CALL(nesttest)

	load 116
	store r3
	FUNCTION_CALL(send)


	FUNCTION_CALL(foo_func)

	load 117
	store r3
	FUNCTION_CALL(send)


	FUNCTION_CALL(foo_func2)

	load 118
	store r3
	FUNCTION_CALL(send)

	FUNCTION_CALL(foo_func3)

	load 119
	store r3
	FUNCTION_CALL(send)


	FUNCTION_CALL(foo_func4)

	load 120
	store r3
	FUNCTION_CALL(send)

	load 10
	store r3
	FUNCTION_CALL(fibonacci)

	load r2
	out 0

	load 121
	store r3
	FUNCTION_CALL(send)

	FUNCTION_CALL(mem_test)

	load 122
	store r3
	FUNCTION_CALL(send)

	FUNCTION_CALL(mem_test2)
//	FUNCTION_CALL(mem_write)

	load 123
	store r3
	FUNCTION_CALL(send)


	load r2
	out 0


end:
	branch end
	nop	//delay slot

	FUNCTION_END(r3)

	nop
	nop

//foo_func5:
//	FUNCTION_ENTER(r3)
//	FUNCTION_END(r3,r4)

foo_func:
	FUNCTION_ENTER(r2,r3,r4,r5,r6,r7,r8)
	FUNCTION_END(r2,r3,r4,r5,r6,r7,r8)

foo_func2:
	FUNCTION_ENTER(r2,r3,r4,r5,r6,r7,r8,r9,r10)
	FUNCTION_END(r2,r3,r4,r5,r6,r7,r8,r9,r10)

foo_func3:
	FUNCTION_ENTER(r2,r3,r4,r5,r6,r7,r8,r9,r10)
	FUNCTION_END(r2,r3,r4,r5,r6,r7,r8,r9,r10)

foo_func4:
	FUNCTION_ENTER(r2,r3,r4,r5,r6,r7,r8,r9,r10)
	FUNCTION_END(r2,r3,r4,r5,r6,r7,r8,r9,r10)


//Send doesn't require function prologue and epilogue since it doesn't use the stack, clobbers no registers and makes no function calls
send:
	//FUNCTION_ENTER(r2)
check_tdre:
	in 0	// check tdre
	and 1
	nop	// one delay slot
	brz check_tdre
	load r3
	out 1
	load r0
	nop
	jal r0
	nop
	//FUNCTION_END(r2)

//foo_func6:
//	FUNCTION_ENTER(r3)
//	FUNCTION_END(r3)

nesttest:
	FUNCTION_ENTER(r3)
	load 115
	store r3
	FUNCTION_CALL(send)
	FUNCTION_END(r3)

nop
nop
nop
nop

nop
nop
nop
nop

nop
nop
nop
nop

nop
nop
nop
nop



nop
nop
nop
nop

nop
nop
nop
nop

nop
nop
nop
nop

nop
nop
nop
nop

//fails to work at 562. works at 563,561,560,559,558,554

fibonacci:
	FUNCTION_ENTER(r3,r4)
	load r3
	nop
	brz fib_ret
	sub 1
	nop
	brz fib_ret
//Must actually calcuate the thing
	store r3	
	FUNCTION_CALL(fibonacci)
	load r2
	nop
	store r4
	load r3
	nop
	sub 1
	store r3
	FUNCTION_CALL(fibonacci)
	load r2
	add r4
	store r3
	nop
fib_ret:
	load r3
	nop
	store r2
	FUNCTION_END(r3,r4)

mem_write_line:
	FUNCTION_ENTER(r3,r4)

	load 0
	add r4
	loadaddr r3
	store(ar+0)

	load 1
	add r4
	loadaddr r3
	store(ar+1)

	load 2
	add r4
	loadaddr r3
	store(ar+2)

	load 3
	add r4
	loadaddr r3
	store(ar+3)

	load 4
	add r4
	loadaddr r3
	store(ar+4)

	load 5
	add r4
	loadaddr r3
	store(ar+5)

	load 6
	add r4
	loadaddr r3
	store(ar+6)

	load 7
	add r4
	loadaddr r3
	store(ar+7)

	FUNCTION_END(r3,r4)

mem_test:
	FUNCTION_ENTER(r3,r4)

	load 128
	loadh	4
	loadhl 0
	loadhh 0
	store r3 
	load 0
	store r4

	FUNCTION_CALL(mem_write_line)
	
	load r3
	loadh 6
	store r3
	
	load 20
	store r4

	FUNCTION_CALL(mem_write_line)

	FUNCTION_END(r3,r4)

mem_write:
	FUNCTION_ENTER(r3,r4)
	
	//r3 is count
	//r4 is base
	load 0
	loadh 4
	store r3
	load 0	
	loadh 5
	store r4

loop:
	load r3
	loadaddr r4
	store(ar+0)

	load r4
	add 1
	store r4

	load r3
	sub 1
	store r3
	nop

	brnz loop
	nop

	FUNCTION_END(r3,r4)

mem_test2:
	FUNCTION_ENTER(r3,r4,r5)

	FUNCTION_CALL(mem_write)

	//Checksum
	//r3 is count
	//r4 is base
	//r5 is sum
	load 0 //6 fails
	loadh 4
	loadhl 0
	loadhh 0
	store r3
	load 0	
	loadh 5
	store r4
	load 0
	store r5

//	load 2
//	loadh 8
//	loadhl 0
//	loadhh 0
//	store r4
//	nop
//	loadaddr r4
//	load (ar+0)
//	store r5
//	nop
//	branch sum_done

loop2:
	loadaddr r4
	load(ar+0)

	xor r5
	store r5

	load r4
	add 1
	store r4

	load r3
	sub 1
	store r3
	nop

	brnz loop2

sum_done:
	load r5
	store r2

	FUNCTION_END(r3,r4,r5)
