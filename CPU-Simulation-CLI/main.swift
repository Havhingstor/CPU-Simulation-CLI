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
    let args = CommandLine.arguments
    
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
    
    do {
        let parseResults = try parseAssembler(input: assembler, mem: mem)
        
        let cpu = CPU(memory: mem)
        
        var continueRunning = true
        
        while continueRunning {
            continueRunning = cpu.run()
            
            if continueRunning {
                print("Code executed successfull.")
            } else {
                print("Code executed unsuccessfull!")
            }
            
            print("\n\(getCPUString(cpu: cpu))\n\(getVars(parseResult: parseResults, mem: mem))\n\(getMemoryRepresentation(mem: mem, results: parseResults))")
            
            while true {
                print("What should be done next?\n'P' to print the memory without transformation or additional information.")
                
                if continueRunning {
                    print("'C' to continue running the CPU after the HOLD-instruction")
                }
                print("Everything else will end the program.")
                
                let answer = readLine()
                
                if answer == "P" {
                    print("\n\(mem)")
                } else if answer != "C" {
                    continueRunning = false
                    break
                } else {
                    break
                }
            }
        }
    } catch ParsingErrors.operatorStringDoesNotExist(let input, let lineNr) {
        print("The operator \"\(input)\" in line \(lineNr) couldn't be parsed!")
    } catch ParsingErrors.literalIsNotAllowed(let input, let lineNr) {
        print("The operator \"\(input)\" in line \(lineNr) couldn't be parsed, because it's not allowed to receive a literal!")
    } catch ParsingErrors.doubleLiteral(let input, let lineNr) {
        print("The operator \"\(input)\" in line \(lineNr) tries to declare a literal twice, which isn't allowed!")
    } catch ParsingErrors.hasToBeLiteral(let input, let lineNr) {
        print("The operator \"\(input)\" in line \(lineNr) has to receive an simple literal, everything else, even literals in relation of the stackpointer aren't allowed.")
    } catch ParsingErrors.wrongNumberOfArguments(let input, let mode, let lineNr) {
        if mode {
            print("The operator \"\(input)\" in line \(lineNr) has to receive a operator, but does not!")
        } else {
            print("The operator \"\(input)\" in line \(lineNr) is not allowed to receive a operator, but does so!")
        }
    } catch ParsingErrors.unreadableAddressInput(let input, let lineNr) {
        print("The address or literal \"\(input)\" in line \(lineNr) couldn't be parsed!")
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
