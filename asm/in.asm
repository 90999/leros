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
	loadh	0 //4kb
	store r1 //Stack pointer
	load <main
	nop
	jal r0
	nop

main:
	FUNCTION_ENTER(r3)
	
	load 76
	loadh 1
	loadhl 2
	loadhh 3
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
	FUNCTION_CALL(foo_func2)
	FUNCTION_CALL(foo_func3)
	FUNCTION_CALL(foo_func4)

	load 10
	store r3
	FUNCTION_CALL(fibonacci)

	load 117
	store r3
	FUNCTION_CALL(send)

	load r2
	out 0

end:
	branch end
	nop	//delay slot

	FUNCTION_END(r3)

//foo_func5:
//	FUNCTION_ENTER(r3)
//	FUNCTION_END(r3)

foo_func:
	FUNCTION_ENTER(r2,r3,r4,r5,r6,r7,r8,r9,r10)
	FUNCTION_END(r2,r3,r4,r5,r6,r7,r8,r9,r10)

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

