.data
macros:
	.equ NUM_NODE, 7   # Define macro of NUM_NODE 7
        .equ null    , 101 # Define macro of null 101
	.equ NULL    , 0   # Load ASCII code of NULL
tree_list:
	.word 3, 9, 20, null, null, 15, 7 # Stores tree_list[] array

.text
main:
	la  t0, tree_list # Load address of tree_list
 	lw  a0, 0(t0)	  # put tree_list[0] to argument register, a0
	jal init_node     # Save return address and jump to the init_node function
	add a0, x0, a0    # 1st Parameter: root
	add a1, x0, t0    # 2nd Parameter: tree_list
	add a2, x0, x0    # 3rd Parameter: 0
	jal add_child_nodes

init_node:
	# Prologue: Make space on the stack and back-up registers
	addi sp, sp, -12
	sw ra, 8(sp)
	sw s1, 4(sp)
	sw s0, 0(sp)
	addi s0, a0, 0	# Store the parameters before calling other function
	li s1, NULL     # Load ASCII code of NULL

	# Allocate a memory region on heap by the `malloc` implmented by `ecall`
	li a0, 12    	# Number of bytes to be allcated, 4*3 bytes for TreeNode
	jal malloc
	lw t0,  (s0)	# new_node->val = value;
	sw t0, 0(a0) 	#
	sw s1, 4(a0)	# new_node->left = NULL;
	sw s1, 8(a0)   	# new_node->right = NULL;

	# Put result value in a place where calling code can access it
	add a0, x0, a0

	# Epilogue: Restore register values and free space from the stack
	lw ra, 8(sp)
	lw s1, 4(sp)
	lw s0, 0(sp)
	addi sp, sp, 12
	jr ra # Return to caller

# a0: root(parent in add_child_nodes), a1: tree_list, a2: parent_idx = 0
add_child_nodes:
	# TODO: printf(...);
	addi sp, sp, -4 	    # This is the Prologue
	sw   ra, 0(sp)		    # Save saved registers

	# if (++parent_idx < NUM_NODE && tree_list[parent_idx] != null)
	addi a2, a2, 1		    # a2 = ++parent_idx; a2 is volatile register
	slt  t0, a2, NUM_NODE	    # ++parent_idx < NUM_NODE
	slli t1, a2, 2	            # get array offset from
				    # byte-align-number*parent_idx
				    # t1 = 4*parent_idx
	lw   t2, 0(t1)       	    # t2 = tree_list[parent_idx]
	xori t3, t2, null           # t3 = 1 on (tree_list[parent_idx] != null)
	and  t1, t0, t3       	    # chose t1 prior to t2 to avoid data hazard
	bnez t1, left_node_isnt_null# jump on t1 != 0 <-> t1 == 1
	li   t3, NULL		    # parent->left = NULL;
	sw   t3, 4(a0)              #
	j check_right_node
left_node_isnt_null:
	# treenode_t *left_node = init_node(tree_list[parent_idx]);
	addi sp, sp, -12 # Save volatile registers (a0~a2)
	sw   a0, 0(sp)   #   before calling a function
	sw   a1, 4(sp)   #
	sw   a2, 8(sp)   #
	mv   a0, t2      # Prepare argument tree_list[parent_idx] from t2
 	jal  init_node	
	mv   t0, a0	 # store returned address of allocated node to t0
	lw   a0, 0(sp)   # Restore volatile registers
	lw   a1, 4(sp)	 #   before you use them again
	lw   a2, 8(sp)   #
	sw   t0, 4(a0)   # parent->left = left_node;
	# Check whether the right node is existed
	addi t1, a2, 2   # (parent_idx+1)+1 == parent_idx+2
	slt  t2, t1, NUM_NODE     # (parent_idx+1)+1 < NUM_NODE
	bnez t2, check_right_node # if ((parent_idx+1)+1 < NUM_NODE)
	# add_child_nodes(left_node, tree_list, parent_idx+1);
	mv   a0, t0      # Prepare arguments; 1st Parameter: left_node
                         # 2nd Parameter: tree_list, already in a1
	addi a2, a2, 1   # 3rd Parameter: parent_idx+1
	jal  add_child_nodes
check_right_node:
	# if (++parent_idx < NUM_NODE && tree_list[parent_idx] != null)
	addi a2, a2, 1		    # a2 = ++parent_idx; a2 is volatile register
	slt  t0, a2, NUM_NODE	    # ++parent_idx < NUM_NODE
	slli t1, a2, 2	            # get array offset from
				    # byte-align-number*parent_idx
				    # t1 = 4*parent_idx
	lw   t2, 0(t1)       	    # t2 = tree_list[parent_idx]
	xori t3, t2, null           # t3 = 1 on (tree_list[parent_idx] != null)
	and  t1, t0, t3       	    # chose t1 prior to t2 to avoid data hazard
	bnez t1, end_of_add_child_nodes # jump on t1 != 0 <-> t1 == 1
	li   t3, NULL		    # parent->right = NULL;
	sw   t3, 8(a0)              #
	j check_right_node
right_node_isnt_null:
	# treenode_t *right_node = init_node(tree_list[parent_idx]);
	addi sp, sp, -12 # Save volatile registers (a0~a2)
	sw   a0, 0(sp)   #   before calling a function
	sw   a1, 4(sp)   #
	sw   a2, 8(sp)   #
	mv   a0, t2      # Prepare argument tree_list[parent_idx] from t2
	jal  init_node
	mv   t0, a0	 # store returned address of allocated node to t0
	lw   a0, 0(sp)   # Restore volatile registers
	lw   a1, 4(sp)	 #   before you use them again
	lw   a2, 8(sp)   #
	sw   t0, 4(a0)   # parent->right = right_node;
	# Check whether the right node is existed
	addi t1, a2, 3   # (parent_idx+2)+1 == parent_idx+3
	slt  t2, t1, NUM_NODE           # (parent_idx+2)+1 < NUM_NODE
	bnez t2, end_of_add_child_nodes # if ((parent_idx+2)+1 < NUM_NODE)
	# add_child_nodes(right_node, tree_list, parent_idx+1);
	mv   a0, t0      # Prepare arguments; 1st Parameter: right_node
                         # 2nd Parameter: tree_list, already in a1
	addi a2, a2, 2   # 3rd Parameter: parent_idx+2
	jal  add_child_nodes

end_of_add_child_nodes:
	addi sp, sp, -4	 # This is the Epilogue
	sw   ra, 0(sp) 	 # Restore saved registers
	jr   ra	       	 # return

# === Allocates a1 bytes on the heap, returns pointer to start in a0 ===
malloc:
	addi a1, a0, 0	# Can the number 0 be replaced by x0?
	addi a0, x0, 9
	ecall
	jr ra		# Return to caller
