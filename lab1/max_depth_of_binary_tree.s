# Follow Normal C Memory Management
# Stack
# -----
#   |
#   v
# 
#   ^
#   |
# -----
# Heap
# -----
# BSS
# -----
# DATA
# -----
# Text

.data
macros:
	.equ NUM_NODE, 7   # Define macro of NUM_NODE 7
	.equ null    , 101 # Define macro of null 101
	.equ NULL    , 0   # Load ASCII code of NULL
tree_list:
	.word 3, 9, 20, null, null, 15, 7 # Stores tree_list[] array
str1:	.string "===== Print_sub_tree ====="
str2:	.string "Parent"
str3:	.string "LeftNode"
str4:	.string "RightNode"
str5:	.string "NULL"

# Reference the example from author of Ripes:
#    https://github.com/mortbopet/Ripes/discussions/176#discussioncomment-1699129
brk_ptr: .word 0
# Define a symbol at the end of your static data segment. This will be where
# your heap will grow from.
_brk_start:

.text

# In your entry point to your program you need to setup your
# dynamic memory management. This also happens in a C program
# when initializing the standard library

_start:
	la t0, _brk_start
	la t1, brk_ptr
	sw t0, 0(t1)
	j main

main:
	la  t0, tree_list # Load address of tree_list
 	lw  a0, 0(t0)	  # put tree_list[0] to argument register, a0
	jal init_node     # Save return address and jump to the init_node function
	mv  t1, a0	  # Save reference of *root for useof function calls 
	add a0, x0, a0	  # 1st Parameter: root
	jal print_subTree

	# Exit program
	li a7, 10
	ecall
# === Implement sbrk() supported in OS ===
#   Reference: https://github.com/riscv-collab/riscv-newlib/blob/riscv-newlib-3.1.0/libgloss/libnosys/sbrk.c
#     Note that heap_end is initialized in _start
#
# Steps:
#   load the current brk_ptr
#   store it in a temporary reg
#   modify it according to the argument in a0 (increment bytes)
#   store value of temporary reg back to brk_ptr 
#   return the temporary reg (brk ptr before modification)
sbrk:
	la t0, brk_ptr
	mv t1, t0
	add t2, t0, a0
	sw t2, 0(t0)
	mv a0, t1
	jr ra

init_node:
	# Prologue: Make space on the stack and back-up registers
	addi sp, sp, -12
	sw   ra, 8(sp)
	sw   s1, 4(sp)
	sw   s0, 0(sp)
	addi s0, a0, 0	# Store the parameters before calling other function
	li   s1, NULL     # Load ASCII code of NULL

	# Allocate a memory region on heap by the `malloc` 
	# implmented by above `sbrk` function  
	li   a0, 12    	# Number of bytes to be allcated, 4*3 bytes for TreeNode
	jal  sbrk
	sw   s0, 0(a0) 	# new_node->val = value;
	sw   s1, 4(a0)	# new_node->left = NULL;
	sw   s1, 8(a0)  # new_node->right = NULL;

	# Put result value in a place where calling code can access it
	add  a0, x0, a0

	# Epilogue: Restore register values and free space from the stack
	lw s0, 0(sp)
	lw s1, 4(sp)
	lw ra, 8(sp)
	addi sp, sp, 12
	jr ra # Return to caller

# Input: reference of *parent
print_subTree:
	# Prologue: Make space on the stack and back-up registers
	addi sp, sp, -8
	sw   ra, 4(sp)
	sw   s0, 0(sp)
	addi s0, a0, 0	  # Store *root before calling other function

	# printf("\n===== Print_sub_tree =====\n");
	addi a0, x0, 10 	 # Print newline '\n'
	jal print_char   #
	la  a0, str1	 # Print "===== Print_sub_tree ====="	
	jal print_string #
	addi a0, x0, 10 	 # Print newline '\n'
	jal print_char   #

	# printf("\tParent[%0d]\n", parent->val);
	addi a0, x0, 9	 # Print '\t'     	
        jal print_char   
	mv  a0, s0
	la  a1, str2
	jal print_nodeValue	
	addi a0, x0, 10
	jal print_char

   	# printf("\t/\t\\\n"); Print connection of nodes "	/	\"
	addi a0, x0, 9	 # Print '\t'     	
        jal print_char   
	addi a0, x0, 47	 # Print '/'
        jal print_char   
	addi a0, x0, 9	 # Print '\t'     	
        jal print_char   
	addi a0, x0, 92	 # Print '\'
        jal print_char   
	addi a0, x0, 10
	jal print_char
	
	# if (parent->left != NULL) {
	#     printf("LeftNode[%0d]", parent->left->val);
	# } else printf("\tNULL");

	#   Load operands for use of control statments
  	li  t0, NULL   
	la  t1, str5  

	lw  t2, 4(s0) 	 # parent->left
 	bne t2, t0, leftNode_doesnt_equ_NULL  
	addi a0, x0, 9	 # Print '\t'   	 # } else printf("\tNULL");
	jal print_char
	mv  a0, t1	
	jal print_string
	j check_rightNode_null
leftNode_doesnt_equ_NULL:
	#     printf("LeftNode[%0d]", parent->left->val);
	mv  a0, t2
	la  a1, str3
	jal print_nodeValue	
check_rightNode_null:

	# if (parent->right != NULL) {
	#     printf("\tRightNode[%0d]", parent->right->val);
	# } else printf("\tNULL");

 	bne t2, t0, rightNode_doesnt_equ_NULL  
	addi a0, x0, 9	 # Print '\t'   	 # } else printf("\tNULL");
	jal print_char
	mv  a0, t1	
	jal print_string
	j end_of_print_subTree
rightNode_doesnt_equ_NULL:
	#     printf("RightNode[%0d]", parent->right->val);
	lw  t2, 8(s0) 	 # parent->right
	mv  a0, t2
	la  a1, str4     # Load "RightNode"
	jal print_nodeValue	
end_of_print_subTree:
	addi a0, x0, 10   	 # printf("\n");
	jal print_char
  		
	# Epilogue: Restore register values and free space from the stack
	lw ra, 4(sp)
	lw s0, 0(sp)
	addi sp, sp,8 
	jr ra # Return to caller

# a0: node value, a1: Print node type (i.e., Parent, LeftNode or RightNode)
print_nodeValue:
	mv  t0, a0 	 # Backup arg *parent before calling print_char
	mv  a0, a1       # Print node type before node value	
	jal print_string
	addi a0, x0, 91
	jal print_char
	lw  t1, 0(t0)	
	mv  a0, t1   	 # Print nodeValue in int type
	jal print_int
	addi a0, x0, 93
	jal print_char
	jr  ra

print_int:	
	li a7, 1	
	ecall
	jr ra

print_char:
	# Get char from caller
	#addi a1, x0, 10   # Load in ascii code for newline
	li a7, 11
	ecall
	jr ra

print_string:
	li a7, 4 
	ecall
	jr ra

# Not supported in Ripes simulator for unconventional on riscv-proxy kernel ABI
# === Allocates a0 bytes on the heap, returns pointer to start in a0 ===
#malloc:
#	#addi a1, a0, 0	# Can the number 0 be replaced by x0?
#	li   a7, 10
#	ecall
#	jr ra		# Return to caller
