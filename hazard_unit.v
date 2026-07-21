module hazard_unit(
    input               id_ex_memread,
    input      [4:0]    id_ex_rt,
    input      [4:0]    if_id_rs,
    input      [4:0]    if_id_rt,
    output              stall
);

    assign stall = id_ex_memread &&
                   (id_ex_rt != 5'd0) &&
                   ((id_ex_rt == if_id_rs) || (id_ex_rt == if_id_rt));
endmodule
