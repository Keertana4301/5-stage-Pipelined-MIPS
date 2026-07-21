# Pipelined MIPS Processor (5-Stage, Verilog)

A 5-stage pipelined MIPS datapath (IF → ID → EX → MEM → WB) built from the
original single-cycle design, with full data-hazard forwarding, load-use
stalling, and control-hazard flushing for branches and jumps. Synthesizable
in Quartus; verified with a self-checking SystemVerilog testbench under
Icarus Verilog, and timing-closed in Quartus at ~74 MHz worst-case.

## Pipeline overview

```
IF  --[IF/ID]-->  ID  --[ID/EX]-->  EX  --[EX/MEM]-->  MEM  --[MEM/WB]-->  WB
```

| Stage | What happens |
|-------|--------------|
| **IF**  | PC update, instruction fetch, PC+4 |
| **ID**  | Instruction decode, control unit, register read, sign-extend, branch-offset shift, jump target calc, hazard detection |
| **EX**  | Operand forwarding, ALU op, branch target add, branch condition (zero) evaluation |
| **MEM** | Data memory access (load/store) |
| **WB**  | Write-back mux, register file write |

### Where control hazards are resolved
- **Jump (`j`)** is decoded from the opcode alone, so it's resolved in **ID**.
  One bubble (the instruction fetched right after the jump) is flushed.
- **Branch (`beq`)** needs the ALU's `zero` flag, which isn't available until
  **EX** (this mirrors the original single-cycle ALU, which computes `zero`
  by subtracting the two operands). Two bubbles (the instructions in IF and
  ID at the time the branch is in EX) are flushed.
- If a branch and a younger jump would both fire in the same cycle, the
  (older) branch takes priority — both younger instructions are squashed
  either way.

### Where data hazards are resolved
- **ALU-to-ALU / ALU-to-store forwarding**: a `forwarding_unit` compares the
  EX-stage source registers against the destination registers latched in
  `EX/MEM` and `MEM/WB`, forwarding the most recent value into the ALU
  inputs (and into the store-data path, independent of the `ALUSrc` mux).
- **Load-use hazard**: a `hazard_unit` detects when the instruction in EX is
  a load whose destination is needed by the instruction currently in ID, and
  stalls the pipeline (holds PC/IF-ID, bubbles ID/EX) for one cycle — the
  value is then available via forwarding on the next cycle.
- **WB-to-ID same-cycle hazard**: since WB and ID happen on the same clock
  edge, the register file itself does a "write-first" internal bypass
  (`register.v`) so a value written back this cycle is visible to a
  simultaneous register read.

## What changed from the single-cycle version

- `register.v`: expanded from 16 to the full 32 MIPS registers (address
  fields are 5 bits, so this also fixes a latent addressing bug in the
  original), and added the internal WB→ID bypass described above.
- `branch_mux.v` / `jump_mux.v` are no longer used as-is: branch resolution
  moved to EX and jump resolution to ID, so PC selection is now a single
  priority mux in `mips_pipelined_top.v` (`branch_taken_EX` > `jump_ID` >
  `stall` > `pc+4`) rather than two independent muxes evaluated in the same
  cycle.
- All purely combinational modules (`alu`, `control_unit`, `sign_extend`,
  `shift_left_2`, `branch_adder`, `jump_calc`, `mux2`, `mux3`, `pc_adder`,
  `program_counter`, `data_memory`) are reused unmodified — their behavior
  doesn't change, only *when* in the pipeline they're invoked.
- `mips_pipelined_top.v` exposes a few debug output ports
  (`debug_wb_data`, `debug_wb_reg`, `debug_wb_regwrite`, `debug_pc`) so the
  synthesized design has real, observable outputs. Without at least one
  output pin, Quartus's Fitter treats the entire datapath as unreachable
  dead logic and optimizes it all away — which shows up as a design with no
  registers left for TimeQuest to report timing on ("no paths to report").
  These signals aren't required for functional simulation (the testbench
  probes internal signals directly via hierarchical reference) — they exist
  purely so real synthesis keeps the logic. `write_data_WB` in particular
  transitively depends on nearly the whole datapath (ALU, forwarding,
  memory), so tying it to a pin is enough to anchor everything upstream.
- `id_ex_reg.v`'s reset structure was written as `if (rst || flush)` inside
  an `always @(posedge clk or posedge rst)` block. That's valid Verilog and
  simulates correctly, but Quartus's synthesis only recognizes the
  async-reset idiom when the outer `if` tests *only* the signal that
  matches the sensitivity-list edge (`rst` alone) — mixing in a synchronous
  signal like `flush` at that top level throws
  `Error (10200): ... cannot match operand(s) in the condition to the
  corresponding edges`. It's restructured as
  `if (rst) ... else if (flush) ... else ...` (same reset values in both
  branches), matching the pattern `if_id_reg.v` already used correctly.

## File structure

```
src/
  mips_pipelined_top.v   Top-level pipeline datapath + control wiring
                          (also exposes debug_* output ports, see above)
  if_id_reg.v             IF/ID pipeline register (stall + flush)
  id_ex_reg.v             ID/EX pipeline register (bubble insertion)
  ex_mem_reg.v            EX/MEM pipeline register
  mem_wb_reg.v            MEM/WB pipeline register
  hazard_unit.v           Load-use stall detection
  forwarding_unit.v       EX-stage operand forwarding mux control
  register.v              32x32 register file (write-first bypass)
  instruction_memory.v    Instruction ROM (test program preloaded)
  data_memory.v           Data RAM
  alu.v, control_unit.v, sign_extend.v, shift_left_2.v,
  branch_adder.v, jump_calc.v, mux2.v, mux3.v, pc_adder.v,
  program_counter.v       Unchanged combinational/sequential building blocks
tb/
  tb_mips_pipelined.sv    Self-checking SystemVerilog testbench
mips.sdc                  Quartus timing constraint (clock definition)
Makefile                  `make sim` to run the testbench with Icarus Verilog
```

## Test program

`instruction_memory.v` is preloaded with a program designed to exercise
every hazard path in the pipeline:

| # | Instruction | Purpose |
|---|-------------|---------|
| 1 | `addi $1, $0, 5`  | |
| 2 | `addi $2, $0, 10` | |
| 3 | `add  $3, $1, $2` | back-to-back RAW → EX/MEM→EX forward |
| 4 | `sw   $3, 0($0)`  | store-data RAW → EX/MEM→EX forward into MEM stage |
| 5 | `lw   $4, 0($0)`  | |
| 6 | `add  $5, $4, $1` | load-use hazard → 1-cycle stall |
| 7 | `beq  $1, $1, 2`  | taken branch → 2-bubble flush |
| 8–9 | `addi $6,999` / `addi $7,888` | must be squashed, never execute |
| 10 | `addi $8, $0, 42` | branch target |
| 11 | `j 14`            | jump → 1-bubble flush |
| 12 | `addi $9,777`     | must be squashed, never executes |
| 14 | `addi $10, $0, 55`| jump target |
| 15 | `beq $1, $2, 5`   | not taken, falls through normally |
| 16 | `addi $11, $0, 111`| must execute (branch not taken) |

Expected final architectural state:
`$1=5 $2=10 $3=15 $4=15 $5=20 $6=0 $7=0 $8=42 $9=0 $10=55 $11=111`,
`mem[0]=15`.

## Simulating

Requires [Icarus Verilog](http://iverilog.icarus.com/) (`apt install iverilog`
on Debian/Ubuntu).

```bash
make sim
```

or directly:

```bash
iverilog -g2012 -o sim.out src/*.v tb/tb_mips_pipelined.sv
vvp sim.out
```

Expected output ends with:

```
RESULT: ALL 12 CHECKS PASSED
```

To dump a waveform for viewing in GTKWave, add `$dumpfile`/`$dumpvars` calls
to the testbench (or use `make wave` after adding them) and open the
resulting `.vcd`.

## Synthesizing in Quartus

1. Create a new Quartus project and add **only the files under `src/`**
   (do **not** add `tb/tb_mips_pipelined.sv` — it's SystemVerilog testbench
   code, not synthesizable RTL, and isn't needed for the build).
2. Set `mips_pipelined_top` as the **Top-Level Entity**.
3. `clk` and `rst` can be mapped to a board push-button/clock pin. The
   `debug_*` outputs can be left unassigned (or wired to LEDs) — they exist
   to keep the Fitter from optimizing away the whole design; see
   "What changed" above.
4. Add `mips.sdc` to the project (Assignments → Settings → TimeQuest Timing
   Analyzer, or drop it in the project directory and add it under Files)
   so TimeQuest has a clock to analyze against. It defines:
   ```tcl
   create_clock -name clk -period 20.000 [get_ports clk]
   derive_clock_uncertainty
   ```
   Without an SDC, Quartus will synthesize and fit fine, but the Timing
   Analyzer reports "no clocks" / "no paths to report" since it has no
   launch/capture edges to measure against.
5. Run **Start Compilation** (the full flow: Synthesis → Fitter →
   Assembler → TimeQuest), not just Analysis & Synthesis — Fmax numbers
   only come out of the Fitter + TimeQuest stages.
6. All modules use plain, portable Verilog-2001 (behavioral
   `always`/`assign`, inferred RAM/ROM via `initial` blocks in
   `instruction_memory.v`/`data_memory.v`, inferred register file in
   `register.v`) — no vendor primitives are used, so this should synthesize
   cleanly on any Quartus version (Prime Lite/Standard/Pro).
7. For RTL/gate-level simulation inside Quartus, use ModelSim-Altera or a
   ModelSim edition with SystemVerilog support enabled for the testbench;
   Icarus Verilog (above) is the quickest way to verify functional
   correctness independent of the toolchain.

## Timing results

Compiled and timing-analyzed in Quartus Prime with `mips.sdc` constraining
`clk` to a 20 ns (50 MHz) period. Full TimeQuest summary across all four
process/voltage/temperature corners:

| Corner | Worst-case setup slack | Worst-case hold slack |
|---|---|---|
| Slow 1100mV 85°C | 6.507 ns | 0.263 ns |
| Slow 1100mV 0°C  | 6.694 ns | 0.222 ns |
| Fast 1100mV 85°C | 12.019 ns | 0.172 ns |
| Fast 1100mV 0°C  | 12.774 ns | 0.132 ns |

The **Slow 1100mV 85°C** corner is the binding one (worst-case
silicon/temperature combination). Critical path delay = `20 ns − 6.507 ns
= 13.493 ns`, giving:

**Fmax ≈ 74.1 MHz** (1000 / 13.493)

Hold slack is positive in every corner, so there are no hold violations at
this constraint. Quartus reports "Design is not fully constrained for
setup/hold requirements" — this is expected and benign here: it refers to
`rst`, an unconstrained asynchronous input with no `set_input_delay`, not a
synchronous path that TimeQuest needs to check.

To retarget a different frequency, edit the `-period` value in `mips.sdc`
(in ns) and recompile; if setup slack goes negative, Fmax has been exceeded
for the current corner.

## Known limitations / scope

- Implements R-type `add/sub/and/or/slt/xor/nor`, `addi`, `lw`, `sw`, `beq`,
  and `j`. No `jal`, `jr`, other branch types, or exceptions/interrupts.
- No delay-slot (this pipeline resolves branches/jumps via flush+bubble
  rather than exposing an architectural delay slot).
- Structural hazards aren't modeled beyond what's needed for this ISA
  subset (e.g., no separate instruction/data caches, single-port memories
  are assumed conflict-free given the instruction mix).
- Test coverage is directed, not exhaustive: one program exercising each
  hazard type once. Not tested: overlapping/stacked hazards in the same
  cycle (e.g. a load-use stall coinciding with a branch resolving), the
  full ALU op set in-pipeline (only `add` is exercised; `sub/and/or/slt/
  xor/nor` reuse the unmodified `alu.v` from the single-cycle version but
  aren't hit by the pipelined test program), or hardware-in-the-loop
  validation on an actual FPGA.
