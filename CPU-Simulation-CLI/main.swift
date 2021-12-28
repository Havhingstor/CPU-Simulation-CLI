//
//  main.swift
//  CPU-Simulation-CLI
//
//  Created by Paul on 20.12.21.
//

import Foundation
import CPU_Simulation_Lib

try main()

func main() throws {
    var args = CommandLine.arguments
    
    let s = parseCLIArgs(args: &args)
    
    if args.count < 2 {
        print("No file is specified!")
        return
    }
    
    let fm = FileManager.default
    
    if args[1] == "-h" {
        print("Specify the location of a assembler-file!")
        return
    }
    
    var fileName = args[1]
    
    if fileName.first != "/" {
        fileName = fm.currentDirectoryPath + "/" + fileName
    }
    
    if !fm.isReadableFile(atPath: fileName) {
        print("File is not readable or doesn't exist!")
        return
    }
    
    let assembler = try String(contentsOf: URL(fileURLWithPath: fileName))
    
    let mem = Memory()
    
    let cpu = CPU(programStart: s,memory: mem)
    
    var parseResults: ParseResults? = nil
    do {
        parseResults = try parseAssembler(input: assembler, mem: mem)
        
        
        var continueRunning = true
        
        while continueRunning {
            try cpu.run()
            
            continueRunning = printAll(cpu: cpu, mem: mem, parseResults: parseResults!, continueRunningAllowed: true)
        }
    } catch ParsingError.operatorStringDoesNotExist(let input, let lineNr) {
        print("The operator \"\(input)\" in line \(lineNr) couldn't be parsed!")
    } catch ParsingError.literalIsNotAllowed(let input, let lineNr) {
        print("The operator \"\(input)\" in line \(lineNr) couldn't be parsed, because it's not allowed to receive a literal!")
    } catch ParsingError.doubleLiteral(let input, let lineNr) {
        print("The operator \"\(input)\" in line \(lineNr) tries to declare a literal twice, which isn't allowed!")
    } catch ParsingError.hasToBeLiteral(let input, let lineNr) {
        print("The operator \"\(input)\" in line \(lineNr) has to receive an simple literal, everything else, even literals in relation of the stackpointer aren't allowed.")
    } catch ParsingError.wrongNumberOfArguments(let input, let mode, let lineNr) {
        if mode {
            print("The operator \"\(input)\" in line \(lineNr) has to receive a operator, but does not!")
        } else {
            print("The operator \"\(input)\" in line \(lineNr) is not allowed to receive a operator, but does so!")
        }
    } catch ParsingError.unreadableAddressInput(let input, let lineNr) {
        print("The address or literal \"\(input)\" in line \(lineNr) couldn't be parsed!")
    } catch ExecutionError.decodingError(let opcode, let address) {
        print("Error: the opcode \(hex(opcode)) (\(opcode)) at address 0x\(hex(address)) cannot be decoded.")
        _ = printAll(cpu: cpu, mem: mem, parseResults: parseResults!, continueRunningAllowed: false)
    } catch ExecutionError.cannotReceiveLiteral(let opcode, let operatorString, let address) {
        print("Error: the operator \"\(operatorString)\" with the opcode \(hex(opcode)) (\(opcode)) at address 0x\(hex(address)) cannot receive a literal, but does so.")
        _ = printAll(cpu: cpu, mem: mem, parseResults: parseResults!, continueRunningAllowed: false)
    } catch ExecutionError.mustReceiveLiteral(let opcode, let operatorString, let address) {
        print("Error: the operator \"\(operatorString)\" with the opcode \(hex(opcode)) (\(opcode)) at address 0x\(hex(address)) has to receive a literal, but doesn't.")
        _ = printAll(cpu: cpu, mem: mem, parseResults: parseResults!, continueRunningAllowed: false)
    } catch {
        print("Error: \(error)")
    }
}

func getCPUString(cpu: CPU) -> String {
    return "CPU:\nprogram counter: 0x\(hex(cpu.programCounterExternal))\t\tstack-pointer: 0x\(hex(cpu.stackpointerExternal))\naccumulator: \(cpu.accumulatorExternal)\t\t\texecution cycles: \(cpu.cycleCountExternal)\n"
}

func getVars(parseResult: ParseResults, mem: Memory) -> String {
    var result = "Variables:\n"
    let vars = parseResult.vars
    
    for variable in vars {
        if parseResult.operators[variable.value] != nil {
            continue
        }
        result += "\"\(variable.key)\" at 0x\(hex(variable.value)): "
        if parseResult.addresses.contains(variable.value) {
            result += "0x" + hex(mem.read(address: variable.value))
        } else {
            result += String(mem.read(address: variable.value))
        }
        result += "\n"
    }
    
    result += "\nJump-Markers:\n"
    
    for variable in vars {
        if parseResult.operators[variable.value] == nil {
            continue
        }
        result += "\"\(variable.key)\" at 0x\(hex(variable.value)): "
        result += "\(parseResult.operators[variable.value]!.string) (0x\(hex(mem.read(address: variable.value))))"
        result += "\n"
    }
    
    return result
}

func printAll(cpu: CPU, mem: Memory, parseResults: ParseResults, continueRunningAllowed: Bool) -> Bool {
    if continueRunningAllowed {
        print("Execution successfull.")
    }
    print("\n\(getCPUString(cpu: cpu))\n\(getVars(parseResult: parseResults, mem: mem))\n\(getMemoryRepresentation(mem: mem, results: parseResults))")
    
    while true {
        print("What should be done next?\n'P' to print the memory without transformation or additional information.")
        
        if continueRunningAllowed {
            print("'C' to continue running the CPU after the HOLD-instruction")
        }
        print("Everything else will end the program.")
        
        let answer = readLine()
        
        if answer == "P" {
            print("\n\(mem)")
        } else if answer == "C" && continueRunningAllowed {
            return true
        } else {
            return false
        }
    }
}

func parseCLIArgs(args: inout [String]) -> UInt16 {
    for i in 0 ... args.count {
        let val = args[i]
        if i == args.count - 1 {
            return 0
        }
        if val.lowercased() == "-s" {
            if args[i+1].isNumberWithoutNegative {
                let nrI = Int(args[i+1])!
                if nrI > "FFFF".uHex {
                    continue
                }
                let nr = UInt16(nrI)
                args.remove(at: i)
                args.remove(at: i)
                return nr
            } else if args[i+1].isHexadecimalWithoutNegative {
                if args[i+1].count > 6 {
                    continue
                }
                let nr = args[i+1].uHex
                args.remove(at: i)
                args.remove(at: i)
                return nr
            }
        }
    }
    return 0
}
