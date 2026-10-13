package aes_types_pkg;

    typedef logic [3:0][3:0][7:0] state_t;

    typedef enum logic [3:0] {
        IDLE,
        INIT_ROUND,
        ADD_KEY,
        SUB_BYTES,
        SHIFT_ROWS,
        MIX_COLUMNS,
        LAST_ROUND_ADD_KEY,
        DONE
    } state_e;

endpackage : aes_types_pkg
