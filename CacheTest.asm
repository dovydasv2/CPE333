    .text
    .globl _start
_start:
    #---------------------------------------------------
    # Step 1: Write to block A (address 0x3f60)
    # This makes the cache block dirty.
    #---------------------------------------------------
    li      t0, 0xDEADBEEF         # test value to store
    li      t1, 0x3f60             # base address for block A
    sw      t0, 0(t1)              # store word at 0x3f60

    #---------------------------------------------------
    # Step 2: Fill the cache set with additional blocks.
    # The cache is 4-way; we now bring in blocks B, C, D.
    # All these addresses map to the same set as 0x3f60.
    #---------------------------------------------------
    li      t2, 0x3f60             # base address for block A
    li      t3, 0x40               # offset increment (64 bytes) maintains same index

    # Block B: address = 0x3f60 + 0x40 = 0x3fa0
    add     t4, t2, t3             # t4 = 0x3fa0
    lw      t5, 0(t4)              # load block B into cache

    # Block C: address = 0x3f60 + 0x80 = 0x3fe0
    add     t4, t2, t3             # t4 = 0x3f60 + 0x40
    add     t4, t4, t3             # t4 = 0x3f60 + 0x80 = 0x3fe0
    lw      t5, 0(t4)              # load block C into cache

    # Block D: address = 0x3f60 + 0xc0 = 0x4020
    add     t4, t2, t3             # t4 = 0x3f60 + 0x40
    add     t4, t4, t3             # t4 = 0x3f60 + 0x80
    add     t4, t4, t3             # t4 = 0x3f60 + 0xc0 = 0x4020
    lw      t5, 0(t4)              # load block D into cache
    # At this point, the set contains blocks A, B, C, D.
    
    #---------------------------------------------------
    # Step 3: Force eviction of block A by accessing block E.
    # Block E is chosen so that it maps to the same set:
    # address = 0x3f60 + 0x100 = 0x4060.
    # The LRU block (block A) should be evicted, triggering a writeback.
    #---------------------------------------------------
    li      t6, 0x100             # offset for block E (256 bytes)
    add     s1, t2, t6            # t7 = 0x3f60 + 0x100 = 0x4060
    lw      t5, 0(s1)             # load block E, evicting block A (dirty)

    #---------------------------------------------------
    # Step 4: Verify that the writeback occurred.
    # Reload the data from block A’s memory location.
    # If the value matches 0xDEADBEEF, the writeback worked.
    #---------------------------------------------------
    lw      s2, 0(t1)             # load from 0x3f60 (should reflect our store)
    li      s3, 0xDEADBEEF
    bne     s2, s3, fail          # if not equal, branch to fail

    # Success: infinite loop at "pass"
pass:
    j       pass

fail:
    j       fail
