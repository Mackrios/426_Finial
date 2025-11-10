#!/usr/bin/env python3
"""
Simple MIPS Assembler - Generates opcodes only
Output file: opcodes.txt
"""

class MIPSAssembler:
    def __init__(self):
        self.opcodes = {
            'add': 0x0, 'sub': 0x1, 'and': 0x2, 'or': 0x3,
            'sll': 0x4, 'srl': 0x5, 'sra': 0x6, 'xor': 0x7,
            'lw': 0x8, 'sw': 0x9, 'addi': 0xA, 'beq': 0xB,
            'bgt': 0xC, 'bge': 0xD, 'b': 0xE, 'j': 0xF
        }
        
        self.registers = {
            'r0': 0, 'r1': 1, 'r2': 2, 'r3': 3,
            'r4': 4, 'r5': 5, 'r6': 6, 'r7': 7,
            '$v0': 0, '$v1': 1, '$v2': 2, '$v3': 3,
            '$t0': 4, '$a0': 5, '$a1': 6, '$res': 7,
        }
        
    def parse_register(self, reg_str: str) -> int:
        reg = reg_str.lower().strip().rstrip(',')
        if reg in self.registers:
            return self.registers[reg]
        raise ValueError(f"Unknown register: {reg}")
    
    def parse_immediate(self, imm_str: str) -> int:
        imm_str = imm_str.strip()
        if imm_str.startswith('0x'):
            val = int(imm_str, 16)
        else:
            val = int(imm_str)
        return val & 0xF
    
    def assemble(self, code: str) -> list:
        """Assemble assembly code to machine instructions"""
        lines = code.strip().split('\n')
        instructions = []
        
        for line_num, line in enumerate(lines, 1):
            # Remove comments
            if '#' in line:
                line = line[:line.index('#')]
            
            line = line.strip()
            if not line or ':' in line:
                continue
            
            parts = line.split()
            if not parts:
                continue
            
            mnemonic = parts[0].lower()
            
            if mnemonic not in self.opcodes:
                continue
            
            opcode = self.opcodes[mnemonic]
            instr = 0
            
            try:
                # R-type: add, sub, and, or, xor
                if mnemonic in ['add', 'sub', 'and', 'or', 'xor']:
                    rd = self.parse_register(parts[1])
                    rs = self.parse_register(parts[2])
                    rt = self.parse_register(parts[3])
                    instr = (opcode << 12) | (rs << 9) | (rt << 6) | (rd << 3)
                
                # Shift instructions: sll, srl, sra
                elif mnemonic in ['sll', 'srl', 'sra']:
                    rd = self.parse_register(parts[1])
                    rs = self.parse_register(parts[2])
                    shamt = self.parse_immediate(parts[3])
                    instr = (opcode << 12) | (rs << 9) | (rd << 3) | shamt
                
                # I-type: addi, beq, bgt, bge, b
                elif mnemonic in ['addi', 'beq', 'bgt', 'bge', 'b']:
                    rt = self.parse_register(parts[1])
                    rs = self.parse_register(parts[2])
                    imm = self.parse_immediate(parts[3])
                    instr = (opcode << 12) | (rs << 9) | (rt << 6) | imm
                
                # Jump
                elif mnemonic == 'j':
                    addr = self.parse_immediate(parts[1])
                    instr = (opcode << 12) | addr
                
                instructions.append(instr)
                
            except Exception as e:
                print(f"Error at line {line_num}: {e}")
                continue
        
        return instructions

def main():
    # EDIT THIS ASSEMBLY CODE
    assembly_code = """
    # MIPS Test Program
    
    add r4, r0, r1          # R4 = R0 + R1
    sub r5, r1, r0          # R5 = R1 - R0
    and r6, r2, r3          # R6 = R2 AND R3
    or r7, r2, r3           # R7 = R2 OR R3
    xor r4, r2, r3          # R4 = R2 XOR R3
    """
    
    print("="*80)
    print("MIPS Assembler - Generate Opcodes")
    print("="*80)
    
    assembler = MIPSAssembler()
    instructions = assembler.assemble(assembly_code)
    
    print(f"\n✓ Assembled {len(instructions)} instructions\n")
    
    # Display
    print("GENERATED OPCODES:")
    print("-"*80)
    print(f"{'Address':<12} {'Hex':<10} {'Decimal':<10} {'Binary':<20}")
    print("-"*80)
    for i, instr in enumerate(instructions):
        addr = i * 2
        print(f"0x{addr:04X}       0x{instr:04X}     {instr:<10} {instr:016b}")
    print("-"*80)
    
    # Save to file - ONE OPCODE PER LINE
    output_filename = "opcodes.txt"
    with open(output_filename, 'w') as f:
        for i, instr in enumerate(instructions):
            f.write(f"{instr:04X}\n")
    
    print(f"\n✓ Opcodes exported to FILE: {output_filename}")
    print(f"\nFile contents (one opcode per line):")
    print("-"*80)
    with open(output_filename, 'r') as f:
        content = f.read()
        print(content)
    print("-"*80)
    
    print(f"\n✓ Ready to use with VHDL testbench!")
    print(f"  The testbench will read from: {output_filename}")

if __name__ == "__main__":
    main()