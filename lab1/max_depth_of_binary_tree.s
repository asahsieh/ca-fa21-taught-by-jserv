.data
macros:
	.equ NUM_NODE, 7   # Define macro of NUM_NODE 7
        .equ null    , 101 # Define macro of null 101
tree_list: 
        .word 3, 9, 20, null, null, 15, 7 # Stores tree_list[] array

.text
main:  
	lw t0, tree_list # Load address of tree_list 
	mv a0, t0	 # Put parameters to argument registers
	jal init_node    # Save return address and jump to the init_node function 
        addi a0, x0, a0  # 1st Parameter: root		
        addi a1, x0, t0  # 2nd Parameter: tree_list		
        addi a2, x0, x0  # 3rd Parameter: 0		
	jal add_child_nodes

init_node:  
	# Prologue: Make space on the stack and back-up registers
	addi sp, sp, -12
    	sw s0, 0(sp)
    	sw s1, 4(sp)
    	sw ra, 8(sp)
	addi s0, a0, 0	# Store the parameters before calling other function 
	li s1, 0      	# Load ASCII code of NULL 

	# Allocate a memory region on heap by the `malloc` implmented by `ecall`
	li a0, 12    	# Number of bytes to be allcated, 4*3 bytes for TreeNode 
	jal ra, malloc
        lw t0,  (s0)	# new_node->val = value;
    	sw t0, 0(a0) 	# 
    	sw s1, 4(a0)	# new_node->left = NULL;
	sw s1, 8(a0)   	# new_node->right = NULL;

	# Put result value in a place where calling code can access it
	addi a0, x0, a0

	# Epilogue: Restore register values and free space from the stack
    	lw s0, 0(sp)
    	lw s1, 4(sp)
    	lw ra, 8(sp)
    	addi sp, sp, 12
    	jr ra # Return to caller

add_child_nodes:
	addi sp, sp, -4
	sw s0,
	# if (++parent_idx < NUM_NODE && tree_list[parent_idx] != null)
	
	

# === Allocates a1 bytes on the heap, returns pointer to start in a0 ===
malloc:
	addi a1, a0, 0	# Can the number 0 be replaced by x0?  
	addi a0, x0, 9
	ecall
	jr ra		# Return to caller
